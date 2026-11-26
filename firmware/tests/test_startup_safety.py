"""Boot/import-failure checks without touching a real board or credentials."""
import builtins
import pathlib
import types
import unittest

FIRMWARE = pathlib.Path(__file__).parents[1]


class StartupSafetyTest(unittest.TestCase):
    def run_startup(self, filename, fail_at=None):
        events = []
        levels = {15: 1}  # Simulate an output retained high across a soft reset.

        class Pin:
            OUT = "output"
            PULL_DOWN = "pull-down"

            def __init__(self, gpio, mode, pull, *, value):
                self.gpio = gpio
                levels[gpio] = value
                events.append(("pin", gpio, mode, pull, value))

            def off(self):
                levels[self.gpio] = 0
                events.append(("off", self.gpio))

        def timer(_):
            if fail_at == "timer":
                raise OSError("timer unavailable")
            raise AssertionError("test should stop before hardware setup")

        def load(name, *args, **kwargs):
            events.append(("import", name))
            if name == "machine":
                return types.SimpleNamespace(Pin=Pin, Timer=timer, disable_irq=lambda: 0, enable_irq=lambda _: None)
            if name == fail_at:
                raise ImportError("simulated missing " + name)
            if name == "time" and filename == "diagnose_lock_off.py":
                def stop(_):
                    raise KeyboardInterrupt()
                return types.SimpleNamespace(sleep_ms=stop)
            if name == "micropython":
                return types.SimpleNamespace(alloc_emergency_exception_buf=lambda _: None)
            if name in ("network", "socket"):
                return types.SimpleNamespace()
            if name == "config":
                return types.SimpleNamespace(WIFI_NAME="test", WIFI_PASSWORD="test",
                                             AP_NAME="test", AP_PASSWORD="test")
            return builtins.__import__(name, *args, **kwargs)

        environment = {"__builtins__": dict(vars(builtins), __import__=load), "print": lambda *args: None}
        error = None
        try:
            exec(compile(FIRMWARE.joinpath(filename).read_text(), filename, "exec"), environment)
        except (ImportError, OSError) as caught:
            error = caught
        return levels, events, error

    def test_boot_disables_only_the_actuator_and_terminates(self):
        levels, events, error = self.run_startup("boot.py")
        self.assertIsNone(error)
        self.assertEqual(levels, {15: 0})
        self.assertIn(("pin", 15, "output", "pull-down", 0), events)
        self.assertNotIn(("import", "config"), events)
        self.assertNotIn(("import", "network"), events)

    def test_off_only_diagnostic_never_enables_the_output_or_imports_networking(self):
        levels, events, error = self.run_startup("diagnose_lock_off.py")
        self.assertIsNone(error)
        self.assertEqual(levels, {15: 0})
        self.assertIn(("pin", 15, "output", "pull-down", 0), events)
        self.assertNotIn(("import", "network"), events)
        self.assertNotIn(("import", "socket"), events)
        self.assertNotIn(("import", "config"), events)
        self.assertGreaterEqual(events.count(("off", 15)), 3)



if __name__ == "__main__":
    unittest.main()
