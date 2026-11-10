"""Confirm the approved manager/admin accounts using the official Auth admin API.

Credentials stay in ignored local files. No Auth tables or password hashes are edited.
"""
import json
from pathlib import Path
import sys
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parents[1]


def config(name):
    return dict(line.split("=", 1) for line in (ROOT / name).read_text(encoding="utf-8").splitlines()
                if "=" in line and not line.lstrip().startswith("#"))


def main():
    public = config(".env")
    admin = config(".env.admin.local")
    tests = config(".env.test.local")
    secret = admin.get("SUPABASE_SECRET_KEY", "").strip()
    password = tests.get("TEST_ACCOUNT_PASSWORD", "")
    if not secret or not password:
        sys.exit("Fill SUPABASE_SECRET_KEY in .env.admin.local and the private test password before running.")
    base = public["SUPABASE_URL"].rstrip("/")

    def request(path, method="GET", body=None):
        req = urllib.request.Request(base + path, method=method,
            data=None if body is None else json.dumps(body).encode(),
            headers={"apikey": secret, "Authorization": "Bearer " + secret, "Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=30) as response:
                payload = response.read()
                return json.loads(payload) if payload else None
        except urllib.error.HTTPError as error:
            # Never print request headers, passwords, tokens or provider error bodies.
            sys.exit("Supabase request refused (HTTP %s). Verify project and admin key locally." % error.code)

    users = {}
    page = 1
    while True:
        data = request("/auth/v1/admin/users?page=%s&per_page=100" % page)
        batch = data.get("users", [])
        users.update({u["email"].lower(): u for u in batch if u.get("email")})
        if len(batch) < 100:
            break
        page += 1
    for variable, role in [("TEST_MANAGER_EMAIL", "GESTIONNAIRE_ESPACE"), ("TEST_ADMIN_EMAIL", "ADMIN")]:
        email = tests[variable].strip().lower()
        user = users.get(email)
        if not user:
            sys.exit("An approved account is missing. Create it through Supabase Auth before retrying.")
        request("/auth/v1/admin/users/" + user["id"], "PUT", {"email_confirm": True, "password": password})
        request("/rest/v1/profiles?id=eq." + user["id"], "PATCH", {"role": role, "actif": True})
        print(variable + ": confirmed and configured.")
    print("Completed. Keep the admin key private; remove it from the local file when finished.")


if __name__ == "__main__":
    main()
