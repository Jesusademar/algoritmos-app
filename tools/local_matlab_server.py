#!/usr/bin/env python3
"""Serve LogiVerse locally and open explicitly selected FIS files in MATLAB."""

import argparse
import hmac
import json
import os
from pathlib import Path
import secrets
import shutil
import subprocess
import threading
import time
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlsplit

MAX_BYTES = 2 * 1024 * 1024


def matlab_quote(value):
    return "'" + str(value).replace("'", "''") + "'"


class MatlabBridge:
    def __init__(self, executable, state_directory):
        self.executable = executable
        self.state_directory = Path(state_directory)
        self.token = secrets.token_urlsafe(32)
        self.jobs = {}
        self.lock = threading.Lock()

    def launch(self, payload):
        if not self.executable or not os.access(self.executable, os.X_OK):
            raise ValueError('No se encontró MATLAB instalado en esta computadora.')
        if not isinstance(payload, dict) or set(payload) - {'name', 'content'}:
            raise ValueError('Solicitud no válida.')
        has_file = 'name' in payload or 'content' in payload
        if has_file:
            name, content = payload.get('name'), payload.get('content')
            if (not isinstance(name, str) or not name.lower().endswith('.fis')
                    or not isinstance(content, str) or '\x00' in content
                    or len(content.encode('utf-8')) > MAX_BYTES
                    or '[System]' not in content):
                raise ValueError('Selecciona un archivo .fis válido de hasta 2 MB.')
        with self.lock:
            # Avoid starting another MATLAB while a previous launch is pending.
            for job_id in self.jobs:
                if self.status(job_id)['state'] == 'starting':
                    raise ValueError('MATLAB ya se está iniciando. Espera a que termine.')
            job_id = secrets.token_hex(16)
            directory = self.state_directory / job_id
            directory.mkdir(parents=True, mode=0o700)
            statement = 'fuzzyLogicDesigner;'
            if has_file:
                # Never use a browser-supplied name as a local path or MATLAB code.
                fis_path = directory / 'sistema.fis'
                fis_path.write_text(content, encoding='utf-8')
                statement = f'fis = readfis({matlab_quote(fis_path)});\nfuzzyLogicDesigner(fis);'
            script = directory / 'open_fuzzy.m'
            script.write_text(
                "try\n" + statement + "\n"
                f"fid = fopen({matlab_quote(directory / 'ready')}, 'w');\n"
                "if fid ~= -1, fprintf(fid, 'ready'); fclose(fid); end\n"
                "catch err\n"
                f"fid = fopen({matlab_quote(directory / 'error')}, 'w');\n"
                "if fid ~= -1, fprintf(fid, '%s', err.message); fclose(fid); end\n"
                "disp(getReport(err));\nend\n", encoding='utf-8')
            log = (directory / 'matlab.log').open('wb')
            environment = os.environ.copy()
            # MATLAB ships the X11 Qt backend. Use XWayland on Wayland desktops
            # without changing the user's desktop or global environment.
            if environment.get('XDG_SESSION_TYPE') == 'wayland' and environment.get('DISPLAY'):
                environment.setdefault('QT_QPA_PLATFORM', 'xcb')
            try:
                process = subprocess.Popen(
                    [str(self.executable), '-desktop', '-sd', str(directory),
                     '-logfile', str(directory / 'command-window.log'),
                     '-r', f'run({matlab_quote(script)});'],
                    stdout=log, stderr=subprocess.STDOUT, start_new_session=True,
                    env=environment)
            finally:
                log.close()
            self.jobs[job_id] = (directory, process, time.monotonic())
            return job_id

    def status(self, job_id):
        job = self.jobs.get(job_id)
        if job is None:
            return None
        directory, process, started = job
        if (directory / 'ready').exists():
            return {'state': 'ready', 'message': 'Fuzzy Logic Designer está abierto en MATLAB.'}
        if (directory / 'error').exists():
            detail = (directory / 'error').read_text(encoding='utf-8', errors='replace')[:1500]
            return {'state': 'error', 'message': 'MATLAB no pudo abrir Fuzzy Logic Designer: ' + detail}
        if process.poll() is not None:
            log = (directory / 'matlab.log').read_text(encoding='utf-8', errors='replace')[-12000:]
            command_log = directory / 'command-window.log'
            if command_log.exists():
                log += command_log.read_text(encoding='utf-8', errors='replace')[-12000:]
            if 'license' in log.lower() or 'licensing' in log.lower():
                message = 'MATLAB necesita una licencia activa. Actívalo y vuelve a intentarlo.'
            else:
                message = 'MATLAB terminó antes de abrir Fuzzy Logic Designer. Revisa su instalación y Fuzzy Logic Toolbox.'
            return {'state': 'error', 'message': message}
        if time.monotonic() - started > 120:
            return {'state': 'error', 'message': 'MATLAB sigue iniciándose o espera una acción. Revisa su ventana antes de volver a intentarlo.'}
        return {'state': 'starting', 'message': 'Iniciando MATLAB y Fuzzy Logic Designer…'}


class LocalHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, directory, bridge, **kwargs):
        self.bridge = bridge
        super().__init__(*args, directory=directory, **kwargs)

    def end_headers(self):
        self.send_header('Cache-Control', 'no-store')
        self.send_header('X-Content-Type-Options', 'nosniff')
        super().end_headers()

    def json_response(self, status, payload):
        data = json.dumps(payload, ensure_ascii=False).encode('utf-8')
        self.send_response(status)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def allowed(self):
        port = self.server.server_port
        allowed_hosts = {f'127.0.0.1:{port}', f'localhost:{port}'}
        host = self.headers.get('Host', '')
        origin = self.headers.get('Origin')
        # Host validation also prevents DNS rebinding. No cross-origin access.
        if (host not in allowed_hosts
                or (origin is not None and origin != f'http://{host}')
                or self.headers.get('Sec-Fetch-Site', 'none') not in {'same-origin', 'none'}):
            self.json_response(403, {'message': 'Solo se permiten solicitudes desde esta página local.'})
            return False
        return True

    def do_GET(self):
        if not self.allowed():
            return
        path = urlsplit(self.path).path
        if path == '/api/matlab/session':
            self.json_response(200, {'token': self.bridge.token})
        elif path.startswith('/api/matlab/jobs/'):
            job = self.bridge.status(path.rsplit('/', 1)[-1])
            self.json_response(200 if job else 404, job or {'message': 'Inicio no encontrado.'})
        elif path.startswith('/api/'):
            self.json_response(404, {'message': 'Ruta no encontrada.'})
        else:
            super().do_GET()

    def do_POST(self):
        if not self.allowed():
            return
        if self.path != '/api/matlab/open-fuzzy':
            self.json_response(404, {'message': 'Ruta no encontrada.'})
            return
        token = self.headers.get('X-Logiverse-Token', '')
        if not hmac.compare_digest(token, self.bridge.token):
            self.json_response(403, {'message': 'Sesión local no válida. Recarga la página.'})
            return
        try:
            length = int(self.headers.get('Content-Length', '0'))
            if self.headers.get('Content-Type', '').split(';')[0] != 'application/json':
                raise ValueError('Se esperaba JSON.')
            # JSON escapes can expand a 2 MB FIS by up to six times.
            if not 0 < length <= MAX_BYTES * 6 + 4096:
                self.json_response(413, {'message': 'El archivo es demasiado grande.'})
                return
            payload = json.loads(self.rfile.read(length))
            job_id = self.bridge.launch(payload)
            self.json_response(202, {'jobId': job_id})
        except (ValueError, UnicodeError) as error:
            self.json_response(400, {'message': str(error)})
        except OSError:
            self.json_response(500, {'message': 'No se pudo iniciar MATLAB. Revisa su instalación y los permisos locales.'})

    def do_OPTIONS(self):
        self.json_response(403, {'message': 'No se permite acceso desde otras páginas.'})


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port', type=int, default=4187)
    parser.add_argument('--directory', type=Path, default=Path(__file__).resolve().parents[1] / 'build/web')
    parser.add_argument('--matlab', default=shutil.which('matlab'))
    parser.add_argument('--state-directory', type=Path, default=Path.home() / '.cache/logiverse/matlab')
    args = parser.parse_args()
    if not (args.directory / 'index.html').is_file():
        parser.error('Primero ejecuta flutter build web --base-href /')
    bridge = MatlabBridge(args.matlab, args.state_directory)
    def handler(*positional, **keywords):
        return LocalHandler(*positional, directory=str(args.directory), bridge=bridge, **keywords)
    server = ThreadingHTTPServer(('127.0.0.1', args.port), handler)
    print(f'LogiVerse y MATLAB: http://localhost:{args.port}', flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == '__main__':
    main()
