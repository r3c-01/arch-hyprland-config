#!/usr/bin/env python3
"""Explicit, bounded DNS and route inspection; no shell or elevated privileges."""
import argparse
import ipaddress
import json
import re
import shutil
from worker_runtime import execute, setup

TYPES = {'A', 'AAAA', 'MX', 'TXT', 'CNAME', 'PTR'}

def validate(target):
    target = target.strip()
    if len(target) > 253 or not target or target.startswith('-') or any(c.isspace() for c in target):
        raise ValueError('Invalid or empty destination')
    try:
        ipaddress.ip_address(target)
        return target
    except ValueError:
        pass
    if not re.fullmatch(r'[A-Za-z0-9_][A-Za-z0-9_.-]*', target):
        raise ValueError('Use a hostname or IP address')
    if any(len(label) > 63 or not label or label.startswith('-') or label.endswith('-')
           for label in target.rstrip('.').split('.')):
        raise ValueError('Invalid hostname')
    return target

def dns_lookup(target, record_type):
    target = validate(target)
    if record_type not in TYPES:
        raise ValueError('Unsupported DNS record type')
    meta = {'kind': 'dns', 'query': target, 'recordType': record_type, 'tool': 'dig'}
    if not shutil.which('dig'):
        return {**meta, 'ok': False, 'status': 'UNAVAILABLE',
                'result': 'dig is required for bounded DNS queries. Install the Arch bind package.'}
    # Keep the header: dig exits zero for NXDOMAIN and SERVFAIL.
    command = ['dig', '+time=2', '+tries=1', '+noall', '+comments', '+answer']
    if record_type == 'PTR':
        try:
            ipaddress.ip_address(target)
            command += ['-x', target]
        except ValueError:
            command += [target, 'PTR']  # also accepts an explicit reverse DNS name
    else:
        command += [target, record_type]
    result = execute(command, 6)
    match = re.search(r'status:\s*([A-Z]+)', result['result'])
    if result['ok']:
        if not match:
            result.update(ok=False, status='ERROR', result='Resolver returned no DNS status.\n' + result['result'])
        elif match[1] != 'NOERROR':
            result.update(ok=False, status=match[1])
        elif not any(line.strip() and not line.startswith(';') for line in result['result'].splitlines()):
            result.update(status='NODATA', result=result['result'] + '\nNo answer records returned (NODATA).')
    return {**result, **meta}

def trace_route(target):
    target = validate(target)
    if shutil.which('traceroute'):
        result = execute(['traceroute', '-n', '-m', '12', '-w', '1', '-q', '1', target], 20)
        tool = 'traceroute'
    elif shutil.which('tracepath'):
        result = execute(['tracepath', '-n', '-m', '12', target], 20)
        tool = 'tracepath'
    else:
        return {'kind': 'trace', 'ok': False, 'status': 'UNAVAILABLE', 'query': target,
                'tool': 'missing', 'result': 'Install traceroute or iputils (tracepath) on Arch.'}
    if result['ok']:
        # Exit zero does not prove the destination replied. Preserve the raw route.
        result.update(status='COMPLETE', result=result['result'] +
                      '\nCommand completed; unanswered hops or a hop limit do not prove destination reachability.')
    return {**result, 'kind': 'trace', 'query': target, 'tool': tool}

def main():
    setup()
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--dns')
    group.add_argument('--trace')
    parser.add_argument('--type', default='A', choices=sorted(TYPES))
    args = parser.parse_args()
    try:
        result = dns_lookup(args.dns, args.type) if args.dns is not None else trace_route(args.trace)
    except ValueError as exc:
        result = {'kind': 'error', 'ok': False, 'status': 'INVALID', 'result': str(exc)}
    print(json.dumps(result), flush=True)

if __name__ == '__main__':
    main()
