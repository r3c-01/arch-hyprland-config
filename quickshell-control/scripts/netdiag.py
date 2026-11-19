#!/usr/bin/env python3
"""Read-only network diagnostics for Quickshell.

Modes:
  --stream    Passive local snapshots every 5 seconds.
  --probe     One short, user-initiated gateway/WAN/DNS test.
  --public-ip One user-initiated HTTPS public-IP lookup.
"""
import argparse
import ipaddress
import json
import os
import re
import shutil
import subprocess
import time
import urllib.request
from worker_runtime import execute, setup
from nettool import dns_lookup


def run(args, timeout=2):
    result = execute(args, timeout)
    return result['result'] if result['ok'] else ''


def devices():
    values = {}
    try:
        for row in open('/proc/net/dev', encoding='utf8').read().splitlines()[2:]:
            name, nums = row.split(':', 1)
            name = name.strip()
            if name == 'lo':
                continue
            fields = nums.split()
            base = f'/sys/class/net/{name}'
            def read(prop):
                try:
                    with open(f'{base}/{prop}', encoding='utf8') as handle:
                        return handle.read().strip()
                except OSError:
                    return ''
            speed = read('speed')
            values[name] = {
                'name': name, 'totalRx': int(fields[0]), 'totalTx': int(fields[8]),
                'state': read('operstate') or 'unknown', 'mac': read('address'),
                'mtu': read('mtu'), 'speed': speed if speed.isdigit() else 'unknown',
                'ipv4': '', 'ipv6': ''
            }
    except (OSError, ValueError, IndexError):
        pass
    if shutil.which('ip'):
        raw = run(['ip', '-j', 'address', 'show'], timeout=2)
        try:
            for item in json.loads(raw):
                target = values.get(item.get('ifname', ''))
                if not target:
                    continue
                for address in item.get('addr_info', []):
                    family = address.get('family')
                    local = address.get('local', '')
                    if family == 'inet' and not target['ipv4']:
                        target['ipv4'] = local
                    elif family == 'inet6' and not target['ipv6'] and address.get('scope') == 'global':
                        target['ipv6'] = local
        except (ValueError, TypeError):
            pass
    return list(values.values())


def gateway():
    output = run(['ip', '-4', 'route', 'show', 'default'])
    match = re.search(r'\bvia\s+(\S+)', output)
    return match.group(1) if match else ''


def dns_servers():
    servers = []
    try:
        with open('/etc/resolv.conf', encoding='utf8') as f:
            for line in f:
                parts = line.split()
                if len(parts) >= 2 and parts[0] == 'nameserver':
                    servers.append(parts[1])
    except OSError:
        pass
    return servers


class HostnameResolver:
    """One bounded PTR query per snapshot, with positive/negative cache TTLs."""
    def __init__(self):
        self.cache = {}

    def update(self, addresses):
        now = time.monotonic()
        self.cache = {ip: entry for ip, entry in self.cache.items() if entry[1] > now}
        if len(self.cache) > 512:
            self.cache.clear()
        for ip in dict.fromkeys(addresses):
            try:
                address = ipaddress.ip_address(ip.split('%', 1)[0])
            except ValueError:
                continue
            if not address.is_global or ip in self.cache:
                continue
            result = dns_lookup(str(address), 'PTR')
            answers = [line.split()[-1].rstrip('.') for line in result['result'].splitlines()
                       if not line.startswith(';') and ' PTR ' in line.replace('\t', ' ')]
            name = answers[0] if result['ok'] and answers else ''
            self.cache[ip] = (name, now + (600 if name else 120))
            break

    def name(self, ip):
        value = self.cache.get(ip)
        return value[0] if value and value[1] > time.monotonic() else ''


def remote_ip(endpoint):
    """Extract address from ss address:port, including bracketed IPv6."""
    if endpoint.startswith('[') and ']:' in endpoint:
        return endpoint[1:endpoint.rindex(']:')]
    return endpoint.rsplit(':', 1)[0] if ':' in endpoint else ''


def sockets():
    report = execute(['ss', '-H', '-tunap'], 3)
    output = report['result'] if report['ok'] else ''
    result, counts, listeners = [], {}, set()
    for line in output.splitlines():
        cols = line.split(None, 6)
        if len(cols) < 6:
            continue
        proto, state, _recv, _send, local, remote = cols[:6]
        detail = cols[6] if len(cols) > 6 else ''
        name = re.search(r'\("([^"\n]+)"', detail)
        pid = re.search(r'\bpid=(\d+)', detail)
        state = state.upper()
        counts[state] = counts.get(state, 0) + 1
        if state in ('LISTEN', 'UNCONN') and (state == 'LISTEN' or proto.startswith('udp')):
            listeners.add(f'{proto} {local}')
        result.append({'protocol': proto, 'state': state, 'local': local,
                       'remote': remote, 'process': name.group(1) if name else '—',
                       'pid': pid.group(1) if pid else '—'})
    return result[:400], counts, listeners, ('' if report['ok'] else report['result'])


def snapshot(baseline, resolver, include_sockets=True):
    rows, counts, listeners, error = sockets() if include_sockets else ([], {}, set(), '')
    resolver.update([remote_ip(row["remote"]) for row in rows])
    for row in rows:
        row["remoteName"] = resolver.name(remote_ip(row["remote"]))
    newly_seen = sorted(listeners - baseline) if baseline is not None else []
    return {'kind': 'passive', 'interfaces': devices(), 'gateway': gateway(),
            'dns': dns_servers(), 'sockets': rows, 'states': counts,
            'listenerCount': len(listeners), 'newListeners': newly_seen[:30], 'socketError': error}, listeners


def ping(host):
    if not host or not shutil.which('ping'):
        return {'status': 'unavailable', 'latencyMs': None, 'lossPercent': None}
    report = execute(['ping', '-n', '-c', '2', '-W', '1', host], 4)
    output = report['result']
    loss_match = re.search(r'(\d+(?:\.\d+)?)% packet loss', output)
    rtt_match = re.search(r'(?:rtt|round-trip) min/avg/max/(?:mdev|stddev) = [\d.]+/([\d.]+)', output)
    return {'status': 'ok' if rtt_match else 'unreachable',
            'latencyMs': float(rtt_match.group(1)) if rtt_match else None,
            'lossPercent': float(loss_match.group(1)) if loss_match else None}


def probe():
    gw = gateway()
    result = dns_lookup('example.com', 'A')
    dns = {'status': result['status'].lower(),
           'latencyMs': result.get('elapsedMs') if result['ok'] else None}
    return {'kind': 'probe', 'gateway': ping(gw), 'wan': ping('1.1.1.1'), 'dnsProbe': dns}


def public_ip():
    try:
        request = urllib.request.Request('https://api.ipify.org', headers={'User-Agent': 'quickshell-netdiag/1'})
        with urllib.request.urlopen(request, timeout=5) as response:
            value = response.read(80).decode('ascii').strip()
        ipaddress.ip_address(value)
        return {'kind': 'publicIp', 'value': value}
    except (OSError, ValueError, UnicodeError):
        return {'kind': 'publicIp', 'value': 'Unavailable'}


def main():
    setup()
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--stream', action='store_true')
    group.add_argument('--probe', action='store_true')
    group.add_argument('--public-ip', action='store_true')
    parser.add_argument('--no-sockets', action='store_true')
    args = parser.parse_args()
    if args.probe:
        print(json.dumps(probe()), flush=True)
    elif args.public_ip:
        print(json.dumps(public_ip()), flush=True)
    else:
        baseline = None
        resolver = HostnameResolver()
        while True:
            data, baseline = snapshot(baseline, resolver, not args.no_sockets)
            print(json.dumps(data), flush=True)
            time.sleep(5)


if __name__ == '__main__':
    try:
        main()
    except (KeyboardInterrupt, BrokenPipeError):
        pass
