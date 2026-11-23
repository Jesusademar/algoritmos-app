import http.client
import json
from pathlib import Path
import tempfile
import sys
import threading
import unittest
from unittest.mock import Mock, patch

from local_matlab_server import LocalHandler, MatlabBridge, ThreadingHTTPServer


class BridgeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="logiverse 'test ")
        self.addCleanup(self.temp.cleanup)
        self.bridge = MatlabBridge(sys.executable, self.temp.name)

    @patch('local_matlab_server.subprocess.Popen')
    @patch.dict('local_matlab_server.os.environ', {'XDG_SESSION_TYPE': 'wayland', 'DISPLAY': ':0'}, clear=True)
    def test_selected_file_is_data_and_waits_for_matlab(self, popen):
        popen.return_value.poll.return_value = None
        job_id = self.bridge.launch({'name': "../../evil');system('bad.fis", 'content': '[System]\n[Rules]'})
        directory, _, _ = self.bridge.jobs[job_id]
        self.assertEqual((directory / 'sistema.fis').read_text(), '[System]\n[Rules]')
        command = popen.call_args.args[0]
        self.assertIn('-desktop', command)
        self.assertEqual(popen.call_args.kwargs['env']['QT_QPA_PLATFORM'], 'xcb')
        self.assertNotIn('evil', ' '.join(command))
        script = (directory / 'open_fuzzy.m').read_text()
        self.assertIn("''test", script)  # MATLAB string literal escaping.
        self.assertIn('readfis(', script)
        self.assertIn('fuzzyLogicDesigner(fis)', script)
        self.assertEqual(self.bridge.status(job_id)['state'], 'starting')
        with self.assertRaises(ValueError):
            self.bridge.launch({})
        (directory / 'ready').touch()
        self.assertEqual(self.bridge.status(job_id)['state'], 'ready')

    @patch('local_matlab_server.subprocess.Popen')
    def test_blank_designer_and_license_failure(self, popen):
        popen.return_value.poll.return_value = 1
        job_id = self.bridge.launch({})
        directory, _, _ = self.bridge.jobs[job_id]
        self.assertIn('fuzzyLogicDesigner;', (directory / 'open_fuzzy.m').read_text())
        (directory / 'matlab.log').write_text('License checkout failed')
        self.assertIn('licencia activa', self.bridge.status(job_id)['message'])
        (directory / 'error').write_text('Fuzzy Logic Toolbox is missing')
        self.assertIn('Toolbox', self.bridge.status(job_id)['message'])

    @patch('local_matlab_server.subprocess.Popen')
    def test_invalid_upload_never_launches(self, popen):
        for payload in [[], {'command': 'anything'}, {'name': 'x.txt', 'content': '[System]'},
                        {'name': 'x.fis', 'content': 'bad'}, {'content': '[System]'}]:
            with self.assertRaises(ValueError):
                self.bridge.launch(payload)
        popen.assert_not_called()


class HttpTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.bridge = Mock(token='secret')
        self.bridge.launch.return_value = 'a' * 32
        self.bridge.status.return_value = {'state': 'ready'}
        def handler(*args, **kwargs):
            return LocalHandler(*args, directory=self.temp.name, bridge=self.bridge, **kwargs)
        self.server = ThreadingHTTPServer(('127.0.0.1', 0), handler)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        self.addCleanup(self.stop)
        self.host = f'127.0.0.1:{self.server.server_port}'

    def stop(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join()

    def request(self, method, path, payload=None, headers=None):
        connection = http.client.HTTPConnection('127.0.0.1', self.server.server_port)
        data = None if payload is None else json.dumps(payload)
        connection.request(method, path, body=data, headers={
            'Host': self.host, 'Content-Type': 'application/json',
            'X-Logiverse-Token': 'secret', **(headers or {}),
        })
        response = connection.getresponse()
        result = response.status, response.getheader('Cache-Control'), json.loads(response.read())
        connection.close()
        return result

    def test_same_origin_session_launch_and_status(self):
        self.assertEqual(self.request('GET', '/api/matlab/session'), (200, 'no-store', {'token': 'secret'}))
        self.assertEqual(self.request('POST', '/api/matlab/open-fuzzy', {})[0], 202)
        self.bridge.launch.assert_called_once_with({})
        self.assertEqual(self.request('GET', '/api/matlab/jobs/' + 'a' * 32)[2]['state'], 'ready')

    def test_cross_origin_rebinding_and_missing_token_are_denied(self):
        for headers in [{'Origin': 'https://evil.example'}, {'Host': 'evil.example'},
                        {'Sec-Fetch-Site': 'cross-site'}, {'X-Logiverse-Token': ''}]:
            self.assertEqual(self.request('POST', '/api/matlab/open-fuzzy', {}, headers)[0], 403)
        self.assertEqual(self.request('OPTIONS', '/api/matlab/open-fuzzy')[0], 403)
        self.bridge.launch.assert_not_called()


if __name__ == '__main__':
    unittest.main()
