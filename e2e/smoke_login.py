"""Verify first-run administrator login through the local Compose stack."""

import json
import subprocess
import time
from http.cookiejar import CookieJar
from urllib.error import HTTPError
from urllib.parse import urlencode
from urllib.request import HTTPCookieProcessor, HTTPRedirectHandler, Request, build_opener

BASE_URL = "http://localhost:8000"


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def request(opener, path, *, data=None, headers=None):
    req = Request(BASE_URL + path, data=data, headers=headers or {})
    try:
        return opener.open(req, timeout=5)
    except HTTPError as error:
        return error  # Inspect the original response, including redirects.


def expect_status(opener, path, expected, *, data=None, headers=None):
    with request(opener, path, data=data, headers=headers) as response:
        if response.status != expected:
            method = "POST" if data is not None else "GET"
            raise SystemExit(f"{method} {path}: expected HTTP {expected}, got {response.status}")


def wait_until_ready(opener):
    deadline = time.monotonic() + 90
    while time.monotonic() < deadline:
        try:
            with request(opener, "/healthz") as response:
                if response.status == 200 and response.read(3) == b"ok":
                    return
        except OSError:
            pass  # Traefik or the app may still be starting.
        time.sleep(2)
    raise SystemExit("The Compose app did not become healthy at /healthz.")


def main():
    config = json.loads(subprocess.check_output(
        ["docker", "compose", "-f", "compose.yaml", "config", "--format", "json"],
        text=True,
    ))
    env = config["services"]["setup"]["environment"]
    username = env.get("KIK_ADMIN_EMAIL", "").strip().lower()
    password = env.get("KIK_ADMIN_PASSWORD", "")
    if not username or not password:
        raise SystemExit("Set KIK_ADMIN_EMAIL and KIK_ADMIN_PASSWORD in .env.")

    cookies = CookieJar()
    opener = build_opener(NoRedirect(), HTTPCookieProcessor(cookies))
    wait_until_ready(opener)
    expect_status(opener, "/beheer/", 302)
    expect_status(opener, "/login/", 200)
    csrf_token = next((cookie.value for cookie in cookies if cookie.name == "csrftoken"), None)
    if not csrf_token:
        raise SystemExit("GET /login/: expected a Django CSRF cookie.")

    expect_status(
        opener, "/login/", 302,
        data=urlencode({"username": username, "password": password}).encode(),
        headers={"X-CSRFToken": csrf_token, "Origin": BASE_URL},
    )
    expect_status(opener, "/beheer/", 200)
    print("The .env administrator logged in through Compose.")


if __name__ == "__main__":
    main()
