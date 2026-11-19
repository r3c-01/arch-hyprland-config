#!/usr/bin/env python3
"""Control-center-only sampler. No desktop or recorder mutations."""
import argparse
import json
from pathlib import Path
import shutil
from worker_runtime import execute, setup
import time


def cpu_sample(path=Path('/proc/stat')):
    try:
        fields = list(map(int, path.read_text().splitlines()[0].split()[1:]))
        # guest time is already included in user/nice time.
        return sum(fields[:8]), sum(fields[3:5])
    except (OSError, ValueError, IndexError):
        return None


def cpu_percent(before, after):
    if before is None or after is None or after[0] <= before[0]:
        return None
    return round(max(0, min(100, 100 * (1 - (after[1] - before[1]) / (after[0] - before[0])))))


def memory(path=Path('/proc/meminfo')):
    try:
        values = {k: int(v.strip().split()[0]) for k, v in (line.split(':', 1) for line in path.read_text().splitlines())}
        total, available = values['MemTotal'], values['MemAvailable']
        if total <= 0:
            return None
        return {'used': round((total - available) / 1048576, 1), 'total': round(total / 1048576, 1),
                'percent': round((total - available) * 100 / total)}
    except (OSError, ValueError, KeyError, IndexError):
        return None


def temperature_sensor(base=Path('/sys/class/hwmon')):
    for device in sorted(base.glob('hwmon*')):
        try:
            if (device / 'name').read_text().strip() in ('coretemp', 'k10temp', 'zenpower'):
                return device / 'temp1_input'
        except OSError:
            pass
    return None


def temperature(sensor):
    try:
        return round(int(sensor.read_text()) / 1000) if sensor else None
    except (OSError, ValueError):
        return None


def gpu_sample(executable):
    if not executable:
        return None
    try:
        p = execute([executable, '--query-gpu=name,utilization.gpu,temperature.gpu,memory.used,memory.total',
                            '--format=csv,noheader,nounits'], 1.5)
        if not p['ok']:
            return None
        parts = [s.strip() for s in p['result'].splitlines()[0].split(',')]
        def numeric(i, scale=1):
            try:
                return round(float(parts[i]) / scale, 1)
            except (ValueError, IndexError):
                return None
        return {'name': parts[0].removeprefix('NVIDIA ').removeprefix('GeForce '),
                'percent': numeric(1), 'temperature': numeric(2), 'used': numeric(3, 1024), 'total': numeric(4, 1024)}
    except (OSError, IndexError):
        return None


def disk_sample():
    try:
        d = shutil.disk_usage('/')
        return {'used': round(d.used / 1073741824, 1), 'total': round(d.total / 1073741824, 1),
                'percent': round(d.used * 100 / d.total)}
    except OSError:
        return None


def main():
    setup()
    parser = argparse.ArgumentParser()
    parser.add_argument('--once', action='store_true')
    args = parser.parse_args()
    previous = None
    sensor = temperature_sensor()
    gpu = shutil.which('nvidia-smi')
    disk = None
    gpu_data = None
    gpu_deadline = 0
    disk_deadline = sensor_deadline = 0
    while True:
        start = time.monotonic()
        if start >= disk_deadline:
            disk = disk_sample()
            disk_deadline = start + 60
        if start >= sensor_deadline:
            sensor = temperature_sensor()
            sensor_deadline = start + 60
        if start >= gpu_deadline:
            gpu_data = gpu_sample(gpu)
            gpu_deadline = start + 2.5
        current = cpu_sample()
        data = {'cpu': cpu_percent(previous, current), 'cpuTemperature': temperature(sensor),
                'memory': memory(), 'gpu': gpu_data, 'disk': disk}
        previous = current
        print(json.dumps(data, allow_nan=False), flush=True)
        if args.once:
            return
        time.sleep(max(0.1, 1 - (time.monotonic() - start)))


if __name__ == '__main__':
    try:
        main()
    except (BrokenPipeError, KeyboardInterrupt):
        pass
