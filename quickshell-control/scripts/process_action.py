#!/usr/bin/env python3
"""SIGTERM only, pinned to the process identity displayed in the confirmation."""
import argparse
import os
from pathlib import Path
import signal
import sys

def identity(pid):
    # comm may contain spaces and parentheses: split after the final closing paren.
    return Path(f'/proc/{pid}/stat').read_text().rsplit(')', 1)[1].split()[19]

def terminate(pid, expected):
    if pid <= 1 or not expected:
        raise ValueError('No safe process identity available; refresh the table.')
    if not hasattr(os, 'pidfd_open') or not hasattr(signal, 'pidfd_send_signal'):
        raise ValueError('This system lacks pidfd support; refusing a racy PID-only signal.')
    fd = os.pidfd_open(pid)
    try:
        if identity(pid) != expected:
            raise ValueError('Process identity changed; refresh the table.')
        signal.pidfd_send_signal(fd, signal.SIGTERM)
    finally:
        os.close(fd)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('pid', type=int)
    parser.add_argument('start_time')
    args = parser.parse_args()
    try:
        terminate(args.pid, args.start_time)
    except (OSError, ValueError) as exc:
        print(str(exc), file=sys.stderr)
        return 1
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
