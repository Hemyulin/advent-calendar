"""Exercise the real firmware routes without importing hardware or credentials."""
import ast
import pathlib
import types
import unittest


class Client:
    def __init__(self, method, path):
        self.request = (method + " " + path + " HTTP/1.1\r\n\r\n").encode()

    def settimeout(self, _):
        pass

    def recv(self, _):
        return self.request


class RoutesTest(unittest.TestCase):
    def setUp(self):
        source = pathlib.Path(__file__).parents[1].joinpath("main.py").read_text()
        nodes = [n for n in ast.parse(source).body
                 if isinstance(n, ast.FunctionDef) and n.name in ("handle_request", "unlock")]
        self.pulses, self.waits, self.responses = [], [], []
        self.scope = {
            "lock": types.SimpleNamespace(value=self.pulses.append),
            "sleep_ms": self.waits.append,
            "time": types.SimpleNamespace(ticks_ms=lambda: 100, ticks_add=lambda a, b: a + b),
            "mode": "connected", "victory_until": None,
            "sta": types.SimpleNamespace(ifconfig=lambda: ("192.168.178.68",)),
            "ap": types.SimpleNamespace(ifconfig=lambda: ("192.168.4.1",)),
            "send_response": lambda client, status, data: self.responses.append((status, data)),
        }
        exec(compile(ast.Module(body=nodes, type_ignores=[]), "firmware-routes", "exec"), self.scope)

    def route(self, method, path):
        self.scope["handle_request"](Client(method, path))
        return self.responses[-1]

    def test_unlock_pulses_once_and_health_still_responds(self):
        self.assertEqual(self.route("GET", "/health")[1]["device"], "DoorZero")
        status, body = self.route("POST", "/unlock")
        self.assertEqual(status, "200 OK")
        self.assertTrue(body["success"])
        self.assertEqual(body["duration_ms"], 200)
        self.assertEqual(self.pulses, [1, 0])
        self.assertEqual(self.waits, [200])
        self.assertEqual(self.route("GET", "/health")[1]["device"], "DoorZero")
        self.assertEqual(self.pulses, [1, 0])

    def test_acknowledgement_and_unknown_routes_do_not_unlock(self):
        self.assertTrue(self.route("POST", "/game/completed")[1]["success"])
        self.assertEqual(self.scope["victory_until"], 1100)
        self.assertEqual(self.route("GET", "/unlock")[0], "404 Not Found")
        self.assertEqual(self.route("POST", "/missing")[0], "405 Method Not Allowed")
        self.assertEqual(self.pulses, [])

    def test_pin_is_reset_even_if_the_pulse_wait_fails(self):
        def failed_wait(_):
            raise OSError("interrupted")
        self.scope["sleep_ms"] = failed_wait
        with self.assertRaises(OSError):
            self.route("POST", "/unlock")
        self.assertEqual(self.pulses, [1, 0])


if __name__ == "__main__":
    unittest.main()
