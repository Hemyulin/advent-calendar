"""Exercise the restored synchronous firmware without hardware or networking."""
import ast
import json
from pathlib import Path
import types
import unittest


class Client:
    def __init__(self, method, path):
        self.request = (method + ' ' + path + ' HTTP/1.1\r\n\r\n').encode()
        self.output = b''

    def settimeout(self, _):
        pass

    def recv(self, _):
        return self.request

    def sendall(self, data):
        self.output += data


class FirmwareTest(unittest.TestCase):
    def setUp(self):
        source = Path(__file__).parents[1].joinpath('main.py').read_text()
        functions = [node for node in ast.parse(source).body
                     if isinstance(node, ast.FunctionDef)
                     and node.name in ('unlock', 'send_response', 'handle_request')]
        self.events = []
        self.fail = False

        def wait(milliseconds):
            self.events.append(('wait', milliseconds))
            if self.fail:
                raise OSError('interrupted')

        self.scope = {
            'lock': types.SimpleNamespace(value=lambda value: self.events.append(('pin', value))),
            'sleep_ms': wait, 'json': json, 'mode': 'connected',
            'time': types.SimpleNamespace(ticks_ms=lambda: 100, ticks_add=lambda a, b: a + b),
            'sta': types.SimpleNamespace(ifconfig=lambda: ('192.168.178.68',)),
            'victory_until': None,
        }
        exec(compile(ast.Module(body=functions, type_ignores=[]), source, 'exec'), self.scope)

    def request(self, method, path):
        client = Client(method, path)
        self.scope['handle_request'](client)
        header, body = client.output.split(b'\r\n\r\n', 1)
        return header, json.loads(body)

    def test_unlock_holds_high_for_five_seconds_then_confirms(self):
        header, body = self.request('POST', '/unlock')
        self.assertIn(b'200 OK', header)
        self.assertEqual(body['duration_ms'], 5000)
        self.assertTrue(body['success'])
        self.assertEqual(self.events, [('pin', 1), ('wait', 5000), ('pin', 0)])

    def test_exception_during_activation_still_switches_off(self):
        self.fail = True
        with self.assertRaises(OSError):
            self.scope['unlock']()
        self.assertEqual(self.events[-1], ('pin', 0))

    def test_health_and_completion_do_not_activate_lock(self):
        self.assertEqual(self.request('GET', '/health')[1]['device'], 'DoorZero')
        self.assertTrue(self.request('POST', '/game/completed')[1]['success'])
        self.assertEqual(self.events, [])


if __name__ == '__main__':
    unittest.main()
