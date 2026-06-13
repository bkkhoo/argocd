#!/usr/bin/env python3
'''
version:     1.0
description: receive json payload from POST request and print to stdout

configurable environment variables:
* WEBHOOK_ENDPOINT: default "/webhook"
* HEALTHZ_ENDPOINT: default "/healthz"
* SERVICE_PORT: default 8443
* CERT_FILE: default "/opt/webhook-backend/secrets/tls.crt"
* KEY_FILE: default "/opt/webhook-backend/secrets/tls.key"
'''

import json
import os
import signal
import ssl
import sys

import asyncio
from aiohttp import web

_DEFAULT_WEBHOOK_ENDPOINT = "/webhook"
_DEFAULT_HEALTHZ_ENDPOINT = "/healthz"
_DEFAULT_SERVICE_PORT = "8443"
_DEFAULT_CERT_FILE = "/opt/webhook-backend/secrets/tls.crt"
_DEFAULT_KEY_FILE = "/opt/webhook-backend/secrets/tls.key"
EXIT_CODE = type("ExitCode", (object, ), {"ok": 0, "config": 11, "forceExit": 12, "unknown": 99})()

class WebhookBackend():
    '''webhook backend'''
    def __init__(self, settings):
        self.site = None
        self.settings = settings

    async def __aenter__(self):
        return self

    async def __aexit__(self, *args, **kwargs):
        if self.site:
            await self.site.stop()    # stop handling site

    async def serve_forever(self):
        '''setup and start http server'''
        ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        ssl_context.load_cert_chain(self.settings.cert, self.settings.key)
        server = web.Server(self.handler)
        runner = web.ServerRunner(server)
        await runner.setup()
        self.site = web.TCPSite(runner, host="0.0.0.0", port=self.settings.port, ssl_context=ssl_context)
        await self.site.start()
        while True:
            await asyncio.sleep(600)

    async def handler(self, request):
        '''request handler'''
        payload, status, auth_string, emit_payload = {}, 400, "", False
        if request.method == "GET" and request.path == self.settings.healthz_endpoint:
            status = 200
        elif request.method == "POST" and request.path == self.settings.webhook_endpoint:
            try:
                payload = await request.json()
                status = 200
                if payload:
                    asyncio.ensure_future(log(payload))  # schedule the task, don"t wait
            except json.decoder.JSONDecodeError:
                status = 400
        return web.json_response(status=status)


async def log(details):
    '''print log to stdout in json format'''
    print(json.dumps(details, sort_keys=False, separators=(",", ":")), file=sys.stdout)
    sys.stdout.flush()   # must flush, otherwise log would not show up in stdout

async def start():
    '''startup'''
    settings = type("ServiceSetting",
                    (object,),
                    {"port": os.getenv("SERVICE_PORT", _DEFAULT_SERVICE_PORT),
                     "cert": os.getenv("CERT_FILE", _DEFAULT_CERT_FILE),
                     "key": os.getenv("KEY_FILE", _DEFAULT_KEY_FILE),
                     "webhook_endpoint": os.getenv("WEBHOOK_ENDPOINT", _DEFAULT_WEBHOOK_ENDPOINT),
                     "healthz_endpoint": os.getenv("HEALTHZ_ENDPOINT", _DEFAULT_HEALTHZ_ENDPOINT)
                    })
    try:
        for filename in [settings.cert, settings.key]:
            with open(filename, "rb") as fobj:   # the system ca bundle, /etc/ssl/certs/ca-bundle.crt, is binary
                _ = fobj.read()   # dummy read to ensure file exist and readable
    except (FileNotFoundError, PermissionError) as exception_err:
        await log({"message": f"Error reading file: {exception_err}"})
        sys.exit(EXIT_CODE.config)
    async with WebhookBackend(settings) as backend:
        tasks = [backend.serve_forever()]
        await asyncio.gather(*tasks) # asyncio.gather - allow crash trace and coroutines to fail
    return EXIT_CODE.ok

async def shutdown(loop):
    '''shutdown all tasks - SIGTERM/SIGINT/SIGUSR1'''
    tasks = [task for task in asyncio.all_tasks() if task is not asyncio.tasks.current_task()]
    list(map(lambda task: task.cancel(), tasks))
    await asyncio.gather(*tasks)
    loop.stop()

def main():
    '''main'''
    exit_code = EXIT_CODE.ok
    loop = asyncio.new_event_loop()
    for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGUSR1):  # using SIGUSR1 to terminate self abnormally
        loop.add_signal_handler(sig, lambda sig=sig: loop.create_task(shutdown(loop)))
    try:
        exit_code = loop.run_until_complete(start())
    except asyncio.CancelledError:
        pass
    finally:
        loop.close()
    return exit_code

if __name__ == "__main__":
    sys.exit(main())
