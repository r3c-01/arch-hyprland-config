"""Offline tests: no host telemetry, signals, services, desktop IPC, or network calls."""
import importlib.machinery
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'quickshell-control/scripts'))
import nettool
import metrics
from worker_runtime import execute

loader = importlib.machinery.SourceFileLoader('game_mode', str(ROOT / 'scripts/game-mode'))
spec = importlib.util.spec_from_loader(loader.name, loader)
game_mode = importlib.util.module_from_spec(spec)
loader.exec_module(game_mode)


class FakeDesktop:
    def __init__(self):
        self.options = dict.fromkeys(game_mode.OPTIONS, 1)
        self.fail_once = False

    def session(self): return 'test-session'
    def recorder(self): return {'test': 'unchanged'}
    def discover(self):
        return [{'kind': 'option', 'name': name, 'before': value}
                for name, value in self.options.items()]
    def option(self, name): return self.options[name]
    def set_option(self, name, value):
        self.options[name] = value
        if self.fail_once:
            self.fail_once = False
            raise RuntimeError('Simulated failure after changing option')


class SafetyTests(unittest.TestCase):
    def test_destinations_reject_shell_syntax_and_options(self):
        for target in ('-help', 'host;id', '$(id)', 'two hosts', '', 'a..b'):
            with self.subTest(target=target), self.assertRaises(ValueError):
                nettool.validate(target)
        self.assertEqual(nettool.validate('example.com'), 'example.com')
        self.assertEqual(nettool.validate('2001:db8::1'), '2001:db8::1')

    def test_dns_missing_tool_returns_unavailable_without_network(self):
        with patch.object(nettool.shutil, 'which', return_value=None):
            self.assertEqual(nettool.dns_lookup('example.com', 'A')['status'], 'UNAVAILABLE')

    def test_cpu_guest_time_not_counted_twice(self):
        with tempfile.TemporaryDirectory(dir=ROOT / 'work') as tmp:
            p = Path(tmp) / 'stat'
            p.write_text('cpu 10 2 3 40 5 6 7 8 9 1\n')
            self.assertEqual(metrics.cpu_sample(p), (81, 45))
        self.assertIsNone(metrics.cpu_percent(None, (10, 1)))
        self.assertEqual(metrics.cpu_percent((100, 50), (200, 75)), 75)

    def test_worker_timeout_is_bounded(self):
        result = execute([sys.executable, '-c', 'import time; time.sleep(5)'], .05)
        self.assertFalse(result['ok'])
        self.assertEqual(result['status'], 'TIMEOUT')

    def test_game_mode_restores_captured_options(self):
        with tempfile.TemporaryDirectory(dir=ROOT / 'work') as tmp:
            desktop = FakeDesktop()
            desktop.options[game_mode.OPTIONS[0]] = 0
            before = desktop.options.copy()
            controller = game_mode.Controller(desktop, Path(tmp))
            controller.enable()
            self.assertTrue(all(value == 0 for value in desktop.options.values()))
            controller.disable()
            self.assertEqual(desktop.options, before)
            self.assertFalse(controller.path.exists())

    def test_game_mode_rolls_back_partial_change(self):
        with tempfile.TemporaryDirectory(dir=ROOT / 'work') as tmp:
            desktop = FakeDesktop()
            desktop.fail_once = True
            controller = game_mode.Controller(desktop, Path(tmp))
            with self.assertRaises(RuntimeError):
                controller.enable()
            self.assertTrue(all(value == 1 for value in desktop.options.values()))
            self.assertFalse(controller.path.exists())


if __name__ == '__main__':
    (ROOT / 'work').mkdir(exist_ok=True)
    unittest.main()
