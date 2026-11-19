#!/usr/bin/env python3
"""Read-only network and process telemetry for Quickshell."""
import argparse, json, time
from worker_runtime import execute, setup
from process_action import identity

def interfaces():
    data = {}
    try:
        for line in open('/proc/net/dev', encoding='utf8').read().splitlines()[2:]:
            name, values = line.split(':', 1)
            name = name.strip()
            if name == 'lo': continue
            fields = values.split()
            data[name] = (int(fields[0]), int(fields[8]))
    except (OSError, ValueError, IndexError): pass
    return data

def processes():
    try:
        report = execute(['ps', '-eo', 'pid=,comm=,pcpu=,pmem=,rss=', '--sort=-pcpu'], 2)
        if not report['ok']:
            raise OSError(report['result'])
        output = report['result']
        result = []
        for line in output.splitlines():
            parts = line.split()
            if len(parts) >= 5:
                parts = [parts[0], " ".join(parts[1:-3]), *parts[-3:]]
            if len(parts) < 5: continue
            try:
                result.append({'startTime': identity(int(parts[0])), 'pid':int(parts[0]), 'name':parts[1], 'cpu':float(parts[2]), 'mem':float(parts[3]), 'rss':round(int(parts[4])/1024)})
            except (ValueError, OSError, IndexError): continue
        return result[:100]
    except OSError as exc:
        return [{"error": str(exc)}]

def main():
    setup()
    parser = argparse.ArgumentParser()
    parser.add_argument('--network-only', action='store_true')
    args = parser.parse_args()
    prior, prior_time = interfaces(), time.monotonic()
    proc, proc_deadline = [], 0
    while True:
        now = time.monotonic()
        current = interfaces()
        delta = max(.05, now - prior_time)
        net = [{'name':name, 'rx':round(max(0,rx-prior.get(name,(rx,tx))[0])/delta),
                'tx':round(max(0,tx-prior.get(name,(rx,tx))[1])/delta)} for name,(rx,tx) in current.items()]
        if not args.network_only and now >= proc_deadline:
            proc = processes()
            proc_deadline = now + 3
        error = proc[0].get('error', '') if proc else ''
        print(json.dumps({'interfaces':net, 'processes':[] if error else proc, 'processError':error}), flush=True)
        prior, prior_time = current, now
        time.sleep(1)
if __name__ == '__main__':
    try: main()
    except (KeyboardInterrupt, BrokenPipeError): pass
