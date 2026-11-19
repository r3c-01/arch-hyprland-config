"""Linux worker lifetime and bounded, shell-free subprocess execution."""
import ctypes
import os
import signal
import subprocess
import time

_children = set()

def parent_guard():
    parent = os.getppid()
    if ctypes.CDLL(None, use_errno=True).prctl(1, signal.SIGTERM, 0, 0, 0) != 0:
        raise OSError(ctypes.get_errno(), 'prctl(PR_SET_PDEATHSIG) failed')
    if os.getppid() != parent or parent == 1:
        raise SystemExit(0)

def stop(signum, frame):
    for child in tuple(_children):
        if child.poll() is None:
            child.terminate()
    for child in tuple(_children):
        try:
            child.wait(timeout=.3)
        except subprocess.TimeoutExpired:
            child.kill()
            child.wait()
    raise SystemExit(0)

def setup():
    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    parent_guard()

def execute(command, timeout):
    started = time.monotonic()
    child = None
    try:
        child = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                 text=True, errors='replace', env={**os.environ, 'LC_ALL': 'C'},
                                 preexec_fn=parent_guard)
        _children.add(child)
        try:
            out, err = child.communicate(timeout=timeout)
            status = 'OK' if child.returncode == 0 else 'ERROR'
        except subprocess.TimeoutExpired:
            child.kill()
            out, err = child.communicate()
            status = 'TIMEOUT'
        output = '\n'.join(part.strip() for part in (out, err) if part.strip())
        if status == 'TIMEOUT':
            output = f'Timed out after {timeout} seconds.\n' + output
        return {'ok': status == 'OK', 'status': status, 'result': output[:12000],
                'exitCode': child.returncode, 'elapsedMs': round((time.monotonic()-started)*1000)}
    except OSError as exc:
        return {'ok': False, 'status': 'UNAVAILABLE', 'result': str(exc),
                'elapsedMs': round((time.monotonic()-started)*1000)}
    finally:
        if child is not None:
            _children.discard(child)
