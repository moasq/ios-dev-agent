#!/usr/bin/env python3
"""
MCP Server for Apple Developer Authentication.
Wraps apple-developer-auth.py as a stdio MCP server so Claude can call it as tools.

Implements the Model Context Protocol (JSON-RPC over stdio with Content-Length framing).
Zero external dependencies — pure Python 3 stdlib.
"""

import importlib.util
import json
import sys
import threading
from pathlib import Path

# ── Import the auth module ───────────────────────────────────────────────────

AUTH_SCRIPT = Path(__file__).parent / "apple-developer-auth.py"
spec = importlib.util.spec_from_file_location("apple_auth", str(AUTH_SCRIPT))
apple_auth = importlib.util.module_from_spec(spec)
spec.loader.exec_module(apple_auth)

AppleAuthClient = apple_auth.AppleAuthClient
check_auth_status = apple_auth.check_auth_status
SESSION_FILE = apple_auth.SESSION_FILE
COOKIE_FILE = apple_auth.COOKIE_FILE


# ── Tool Definitions ─────────────────────────────────────────────────────────

TOOLS = [
    {
        "name": "status",
        "description": "Check Apple Developer authentication status. Returns green (valid), yellow (expired), or red (not connected). Validates LIVE against Apple — not just checking if a cookie file exists.",
        "inputSchema": {
            "type": "object",
            "properties": {},
            "required": [],
        },
    },
    {
        "name": "login_init",
        "description": "Start Apple Developer sign-in with Apple ID + password. Performs SRP-6a key exchange. If successful without 2FA, returns authenticated. If 2FA is required, returns needs_2fa with the session state for login_2fa. IMPORTANT: Ask the user for their Apple ID and password BEFORE calling this tool.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "apple_id": {
                    "type": "string",
                    "description": "Apple ID email address",
                },
                "password": {
                    "type": "string",
                    "description": "Apple ID password",
                },
            },
            "required": ["apple_id", "password"],
        },
    },
    {
        "name": "login_2fa",
        "description": "Complete Apple Developer sign-in by submitting the 2FA verification code. Call this after login_init returns needs_2fa. Ask the user for the 6-digit code pushed to their trusted device.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "code": {
                    "type": "string",
                    "description": "6-digit 2FA verification code from trusted device or SMS",
                },
                "method": {
                    "type": "string",
                    "description": "Verification method: 'device' (default) or 'sms'",
                    "enum": ["device", "sms"],
                },
                "phone_id": {
                    "type": "integer",
                    "description": "Phone ID for SMS verification (from login_init response). Only needed if method is 'sms'.",
                },
            },
            "required": ["code"],
        },
    },
    {
        "name": "request_sms",
        "description": "Request a 2FA code via SMS to a specific phone number. Use when the user can't receive device push notifications. Call after login_init.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "phone_id": {
                    "type": "integer",
                    "description": "Phone ID from the trusted_phones list returned by login_init",
                },
            },
            "required": ["phone_id"],
        },
    },
    {
        "name": "revoke",
        "description": "Sign out — clear Apple Developer session cookies and cached data. After this, status will show 'not connected'.",
        "inputSchema": {
            "type": "object",
            "properties": {},
            "required": [],
        },
    },
    {
        "name": "list_apps",
        "description": "List all registered bundle IDs in the Apple Developer portal. Requires active session.",
        "inputSchema": {
            "type": "object",
            "properties": {},
            "required": [],
        },
    },
    {
        "name": "list_certs",
        "description": "List all signing certificates (development + distribution). Requires active session.",
        "inputSchema": {
            "type": "object",
            "properties": {},
            "required": [],
        },
    },
    {
        "name": "list_profiles",
        "description": "List all provisioning profiles. Requires active session.",
        "inputSchema": {
            "type": "object",
            "properties": {},
            "required": [],
        },
    },
    {
        "name": "register_bundle",
        "description": "Register a new bundle ID in the Apple Developer portal. Requires active session.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "bundle_id": {
                    "type": "string",
                    "description": "Bundle identifier (e.g. com.example.app)",
                },
                "name": {
                    "type": "string",
                    "description": "Display name for the app",
                },
            },
            "required": ["bundle_id", "name"],
        },
    },
    # ── RevenueCat Tools ────────────────────────────────────────────────────
    {
        "name": "rc_status",
        "description": "Check RevenueCat connection status. Validates the API key LIVE by calling the RevenueCat API. Returns green (valid key + project), yellow (key exists but invalid), or red (not configured).",
        "inputSchema": {
            "type": "object",
            "properties": {},
            "required": [],
        },
    },
    {
        "name": "rc_setup",
        "description": "Configure RevenueCat API credentials. Validates the key and project ID against the RevenueCat API before storing. Ask the user for their API v2 secret key and project ID BEFORE calling this.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "api_key": {
                    "type": "string",
                    "description": "RevenueCat API v2 secret key (starts with sk_)",
                },
                "project_id": {
                    "type": "string",
                    "description": "RevenueCat project ID (starts with proj)",
                },
            },
            "required": ["api_key", "project_id"],
        },
    },
    {
        "name": "rc_revoke",
        "description": "Remove stored RevenueCat credentials. After this, rc_status will show 'not configured'.",
        "inputSchema": {
            "type": "object",
            "properties": {},
            "required": [],
        },
    },
]

# ── RevenueCat credential storage ────────────────────────────────────────────

RC_CREDS_FILE = apple_auth.SESSION_DIR / "revenuecat.json"
RC_API_BASE = "https://api.revenuecat.com/v2"


def _rc_load_creds() -> dict | None:
    """Load stored RevenueCat credentials."""
    if not RC_CREDS_FILE.exists():
        return None
    try:
        return json.loads(RC_CREDS_FILE.read_text())
    except (json.JSONDecodeError, OSError):
        return None


def _rc_save_creds(api_key: str, project_id: str):
    """Store RevenueCat credentials."""
    apple_auth.SESSION_DIR.mkdir(parents=True, exist_ok=True)
    RC_CREDS_FILE.write_text(json.dumps({
        "api_key": api_key,
        "project_id": project_id,
        "configured_at": apple_auth.datetime.now(apple_auth.timezone.utc).isoformat(),
    }, indent=2))
    RC_CREDS_FILE.chmod(0o600)


def _rc_api_call(method: str, path: str, api_key: str) -> tuple:
    """Make an authenticated request to RevenueCat API v2. Returns (status, body)."""
    import urllib.request
    import urllib.error

    url = f"{RC_API_BASE}/{path}"
    req = urllib.request.Request(url, method=method, headers={
        "Authorization": f"Bearer {api_key}",
        "Accept": "application/json",
        "Content-Type": "application/json",
    })
    try:
        resp = urllib.request.urlopen(req)
        body = json.loads(resp.read().decode("utf-8", errors="replace"))
        return resp.status, body
    except urllib.error.HTTPError as e:
        body_text = e.read().decode("utf-8", errors="replace") if e.fp else ""
        try:
            body = json.loads(body_text)
        except (json.JSONDecodeError, ValueError):
            body = {"error": body_text}
        return e.code, body


# ── Shared state for multi-step login ────────────────────────────────────────

_login_client = None  # Persists across login_init → login_2fa calls


# ── Tool Handlers ────────────────────────────────────────────────────────────

def handle_status(params: dict) -> dict:
    s = check_auth_status()
    if s["valid"]:
        indicator = "green"
        msg = f"Connected as {s['user']}"
    elif s["expired"]:
        indicator = "yellow"
        msg = f"Expired session for {s['user']} — needs re-authentication"
    else:
        indicator = "red"
        msg = "Not connected"

    return {
        "status": indicator,
        "message": msg,
        "user": s["user"],
        "authenticated_at": s["authenticated_at"],
        "valid": s["valid"],
        "expired": s["expired"],
    }


def handle_login_init(params: dict) -> dict:
    global _login_client
    import base64

    apple_id = params["apple_id"]
    password = params["password"]

    client = AppleAuthClient()
    widget_key = client.get_service_key()

    # Check existing session
    if client._has_valid_session():
        return {
            "status": "already_authenticated",
            "message": f"Already connected as a valid session. Use 'revoke' first to re-authenticate.",
        }

    # SRP Phase 1: init
    import secrets as _secrets
    a = _secrets.randbelow(apple_auth.SRP_N)
    A = apple_auth.calc_A(a, apple_auth.SRP_N, apple_auth.SRP_g)
    A_hex = apple_auth.num_to_hex(A)

    init_data = {
        "a": base64.b64encode(apple_auth.hex_to_bytes(A_hex)).decode(),
        "accountName": apple_id,
        "protocols": ["s2k", "s2k_fo"],
    }
    auth_headers = {
        "X-Requested-With": "XMLHttpRequest",
        "X-Apple-Widget-Key": widget_key,
    }

    status, resp_hdrs, body = client._request("POST", f"{client.BASE_AUTH}/signin/init", init_data, auth_headers)

    if not isinstance(body, dict):
        return {"status": "error", "message": f"Unexpected response: {body}"}

    if body.get("serviceErrors"):
        errors = body["serviceErrors"]
        msg = errors[0].get("message", str(errors)) if errors else str(body)
        return {"status": "error", "message": f"Apple error: {msg}"}

    # SRP math
    iterations = body["iteration"]
    salt = base64.b64decode(body["salt"])
    b_bytes = base64.b64decode(body["b"])
    c = body["c"]
    protocol = body["protocol"]

    encrypted_pw = apple_auth.pbkdf2_password(password, salt, iterations, 32, protocol)

    bb = int.from_bytes(b_bytes, "big")
    if bb % apple_auth.SRP_N == 0:
        return {"status": "error", "message": "SRP safety check failed: B mod N is zero"}

    k = apple_auth.calc_k(apple_auth.SRP_N, apple_auth.SRP_g)
    x = apple_auth.calc_x(apple_id, encrypted_pw.hex(), salt.hex())
    u = apple_auth.calc_u(A_hex, apple_auth.num_to_hex(bb), apple_auth.SRP_N)
    if u == 0:
        return {"status": "error", "message": "SRP safety check failed: u is zero"}

    S = apple_auth.calc_client_S(bb, a, k, x, u, apple_auth.SRP_N, apple_auth.SRP_g)
    S_hex = apple_auth.num_to_hex(S)
    K_hex = apple_auth.sha256_hex(S_hex)
    M1 = apple_auth.calc_M(A_hex, apple_auth.num_to_hex(bb), K_hex)
    M2 = apple_auth.num_to_hex(apple_auth.calc_H_AMK(A_hex, M1, K_hex))

    # SRP Phase 2: complete
    hashcash = client.fetch_hashcash()
    complete_data = {
        "accountName": apple_id,
        "c": c,
        "m1": base64.b64encode(apple_auth.hex_to_bytes(M1)).decode(),
        "m2": base64.b64encode(apple_auth.hex_to_bytes(M2)).decode(),
        "rememberMe": False,
    }
    complete_headers = dict(auth_headers)
    if hashcash:
        complete_headers["X-Apple-HC"] = hashcash

    status, resp_hdrs, body = client._request(
        "POST",
        f"{client.BASE_AUTH}/signin/complete?isRememberMeEnabled=false",
        complete_data,
        complete_headers,
    )

    if status == 403:
        return {"status": "error", "message": "Invalid Apple ID or password."}

    if status == 200:
        client._save_cookies()
        client._fetch_olympus_session()
        client._save_session(apple_id)
        return {"status": "authenticated", "message": f"Connected as {apple_id}. No 2FA required."}

    if status == 409:
        # 2FA required — stash client state
        client.x_apple_id_session_id = (
            resp_hdrs.get("X-Apple-Id-Session-Id")
            or resp_hdrs.get("x-apple-id-session-id")
        )
        client.scnt = resp_hdrs.get("scnt") or resp_hdrs.get("Scnt")

        _login_client = {"client": client, "user": apple_id}

        # Fetch 2FA info
        fa_status, _, fa_body = client._request("GET", client.BASE_AUTH, headers=client._2fa_headers())
        trusted_phones = []
        if isinstance(fa_body, dict):
            for phone in fa_body.get("trustedPhoneNumbers", []):
                trusted_phones.append({
                    "id": phone.get("id"),
                    "number": phone.get("numberWithDialCode", ""),
                    "push_mode": phone.get("pushMode", "sms"),
                })

        code_length = 6
        if isinstance(fa_body, dict):
            code_length = fa_body.get("securityCode", {}).get("length", 6)

        return {
            "status": "needs_2fa",
            "message": f"A {code_length}-digit code has been pushed to your trusted devices. Ask the user for the code.",
            "code_length": code_length,
            "trusted_phones": trusted_phones,
            "no_trusted_devices": fa_body.get("noTrustedDevices", False) if isinstance(fa_body, dict) else False,
        }

    if status == 412:
        return {
            "status": "error",
            "message": "Apple requires you to acknowledge the Apple ID & Privacy statement at https://appleid.apple.com",
        }

    return {"status": "error", "message": f"Unexpected response (HTTP {status}): {body}"}


def handle_login_2fa(params: dict) -> dict:
    global _login_client

    if not _login_client:
        return {"status": "error", "message": "No pending 2FA session. Call login_init first."}

    client = _login_client["client"]
    user = _login_client["user"]
    code = params["code"]
    method = params.get("method", "device")
    phone_id = params.get("phone_id")

    try:
        if method == "sms" and phone_id:
            client._verify_sms_code(phone_id, code, "sms")
        else:
            client._verify_device_code(code)

        # Trust session
        client._request("GET", f"{client.BASE_AUTH}/2sv/trust", headers=client._2fa_headers())
        client._save_cookies()
        client._fetch_olympus_session()
        client._save_session(user)

        _login_client = None
        return {"status": "authenticated", "message": f"Connected as {user}. Session valid for ~30 days."}

    except RuntimeError as e:
        return {"status": "error", "message": str(e)}


def handle_request_sms(params: dict) -> dict:
    if not _login_client:
        return {"status": "error", "message": "No pending 2FA session. Call login_init first."}

    client = _login_client["client"]
    phone_id = params["phone_id"]

    try:
        client._request_sms_code(phone_id, "sms")
        return {"status": "sms_sent", "message": f"SMS code sent to phone ID {phone_id}. Ask the user for the code."}
    except Exception as e:
        return {"status": "error", "message": str(e)}


def handle_revoke(params: dict) -> dict:
    removed = []
    if COOKIE_FILE.exists():
        COOKIE_FILE.unlink()
        removed.append("cookies")
    if SESSION_FILE.exists():
        SESSION_FILE.unlink()
        removed.append("session")
    cache = Path("/tmp/spaceship_itc_service_key.txt")
    if cache.exists():
        cache.unlink()
        removed.append("service_key_cache")

    return {"status": "revoked", "message": "Signed out. Session cleared.", "removed": removed}


def handle_list_apps(params: dict) -> dict:
    client = AppleAuthClient()
    if not client._has_valid_session():
        return {"status": "error", "message": "Not authenticated. Use login_init + login_2fa first."}
    try:
        apps = client.list_apps()
        return {"status": "ok", "count": len(apps), "apps": apps}
    except Exception as e:
        return {"status": "error", "message": str(e)}


def handle_list_certs(params: dict) -> dict:
    client = AppleAuthClient()
    if not client._has_valid_session():
        return {"status": "error", "message": "Not authenticated. Use login_init + login_2fa first."}
    try:
        certs = client.list_certificates()
        return {"status": "ok", **certs}
    except Exception as e:
        return {"status": "error", "message": str(e)}


def handle_list_profiles(params: dict) -> dict:
    client = AppleAuthClient()
    if not client._has_valid_session():
        return {"status": "error", "message": "Not authenticated. Use login_init + login_2fa first."}
    try:
        profiles = client.list_provisioning_profiles()
        return {"status": "ok", "count": len(profiles), "profiles": profiles}
    except Exception as e:
        return {"status": "error", "message": str(e)}


def handle_register_bundle(params: dict) -> dict:
    client = AppleAuthClient()
    if not client._has_valid_session():
        return {"status": "error", "message": "Not authenticated. Use login_init + login_2fa first."}
    try:
        result = client.register_bundle_id(params["bundle_id"], params["name"])
        return {"status": "created", **result}
    except Exception as e:
        return {"status": "error", "message": str(e)}


# ── RevenueCat Handlers ──────────────────────────────────────────────────────

def handle_rc_status(params: dict) -> dict:
    creds = _rc_load_creds()

    if not creds:
        return {
            "status": "red",
            "message": "RevenueCat not configured. Use rc_setup to add credentials.",
            "configured": False,
            "valid": False,
        }

    api_key = creds["api_key"]
    project_id = creds["project_id"]

    # Validate live — try listing apps
    try:
        status_code, body = _rc_api_call("GET", f"projects/{project_id}/apps", api_key)
    except Exception as e:
        return {
            "status": "yellow",
            "message": f"RevenueCat credentials stored but validation failed: {e}",
            "configured": True,
            "valid": False,
            "project_id": project_id,
        }

    if status_code == 200:
        apps = body.get("items", body.get("apps", []))
        app_names = [a.get("name", a.get("app_name", "")) for a in apps]
        return {
            "status": "green",
            "message": f"RevenueCat connected. Project: {project_id}. Apps: {', '.join(app_names) or 'none'}",
            "configured": True,
            "valid": True,
            "project_id": project_id,
            "app_count": len(apps),
            "apps": app_names,
            "configured_at": creds.get("configured_at"),
        }
    elif status_code == 401:
        return {
            "status": "yellow",
            "message": "RevenueCat API key is invalid or expired. Use rc_setup to reconfigure.",
            "configured": True,
            "valid": False,
            "project_id": project_id,
        }
    elif status_code == 404:
        return {
            "status": "yellow",
            "message": f"RevenueCat project '{project_id}' not found. Check project ID.",
            "configured": True,
            "valid": False,
            "project_id": project_id,
        }
    else:
        return {
            "status": "yellow",
            "message": f"RevenueCat API returned HTTP {status_code}: {body}",
            "configured": True,
            "valid": False,
            "project_id": project_id,
        }


def handle_rc_setup(params: dict) -> dict:
    api_key = params["api_key"].strip()
    project_id = params["project_id"].strip()

    # Validate format
    if not api_key.startswith("sk_"):
        return {
            "status": "error",
            "message": "Invalid API key format. RevenueCat v2 secret keys start with 'sk_'.",
        }

    if not project_id.startswith("proj"):
        return {
            "status": "error",
            "message": "Invalid project ID format. RevenueCat project IDs start with 'proj'.",
        }

    # Validate live
    try:
        status_code, body = _rc_api_call("GET", f"projects/{project_id}/apps", api_key)
    except Exception as e:
        return {"status": "error", "message": f"Could not reach RevenueCat API: {e}"}

    if status_code == 401:
        return {"status": "error", "message": "API key is invalid. Check your RevenueCat dashboard."}

    if status_code == 404:
        return {"status": "error", "message": f"Project '{project_id}' not found. Check your project ID."}

    if status_code != 200:
        return {"status": "error", "message": f"Unexpected response (HTTP {status_code}): {body}"}

    # Valid — store
    _rc_save_creds(api_key, project_id)

    apps = body.get("items", body.get("apps", []))
    app_names = [a.get("name", a.get("app_name", "")) for a in apps]

    return {
        "status": "green",
        "message": f"RevenueCat connected! Project: {project_id}. Apps: {', '.join(app_names) or 'none yet'}.",
        "project_id": project_id,
        "app_count": len(apps),
        "apps": app_names,
    }


def handle_rc_revoke(params: dict) -> dict:
    if RC_CREDS_FILE.exists():
        RC_CREDS_FILE.unlink()
        return {"status": "revoked", "message": "RevenueCat credentials removed."}
    return {"status": "ok", "message": "No RevenueCat credentials to remove."}


# ── All Tool Handlers ────────────────────────────────────────────────────────

TOOL_HANDLERS = {
    # Apple Developer
    "status": handle_status,
    "login_init": handle_login_init,
    "login_2fa": handle_login_2fa,
    "request_sms": handle_request_sms,
    "revoke": handle_revoke,
    "list_apps": handle_list_apps,
    "list_certs": handle_list_certs,
    "list_profiles": handle_list_profiles,
    "register_bundle": handle_register_bundle,
    # RevenueCat
    "rc_status": handle_rc_status,
    "rc_setup": handle_rc_setup,
    "rc_revoke": handle_rc_revoke,
}


# ── MCP JSON-RPC stdio transport ─────────────────────────────────────────────

def read_message() -> dict | None:
    """Read a JSON-RPC message with Content-Length framing from stdin."""
    headers = {}
    while True:
        line = sys.stdin.buffer.readline()
        if not line:
            return None  # EOF
        line_str = line.decode("utf-8").strip()
        if line_str == "":
            break  # End of headers
        if ":" in line_str:
            key, val = line_str.split(":", 1)
            headers[key.strip().lower()] = val.strip()

    content_length = int(headers.get("content-length", 0))
    if content_length == 0:
        return None

    body = sys.stdin.buffer.read(content_length)
    return json.loads(body.decode("utf-8"))


def write_message(msg: dict):
    """Write a JSON-RPC message with Content-Length framing to stdout."""
    body = json.dumps(msg).encode("utf-8")
    header = f"Content-Length: {len(body)}\r\n\r\n"
    sys.stdout.buffer.write(header.encode("utf-8"))
    sys.stdout.buffer.write(body)
    sys.stdout.buffer.flush()


def make_response(id, result):
    return {"jsonrpc": "2.0", "id": id, "result": result}


def make_error(id, code, message):
    return {"jsonrpc": "2.0", "id": id, "error": {"code": code, "message": message}}


def handle_rpc(msg: dict) -> dict | None:
    method = msg.get("method", "")
    id = msg.get("id")
    params = msg.get("params", {})

    if method == "initialize":
        return make_response(id, {
            "protocolVersion": "2024-11-05",
            "capabilities": {"tools": {}},
            "serverInfo": {
                "name": "apple-developer-auth",
                "version": "1.0.0",
            },
        })

    if method == "notifications/initialized":
        return None  # No response for notifications

    if method == "tools/list":
        return make_response(id, {"tools": TOOLS})

    if method == "tools/call":
        tool_name = params.get("name", "")
        tool_args = params.get("arguments", {})

        handler = TOOL_HANDLERS.get(tool_name)
        if not handler:
            return make_error(id, -32601, f"Unknown tool: {tool_name}")

        try:
            result = handler(tool_args)
            return make_response(id, {
                "content": [
                    {"type": "text", "text": json.dumps(result, indent=2)}
                ],
            })
        except Exception as e:
            return make_response(id, {
                "content": [
                    {"type": "text", "text": json.dumps({"status": "error", "message": str(e)})}
                ],
                "isError": True,
            })

    if method == "ping":
        return make_response(id, {})

    # Ignore unknown notifications (no id = notification)
    if id is None:
        return None

    return make_error(id, -32601, f"Method not found: {method}")


def main():
    """Run the MCP server — read JSON-RPC messages from stdin, write to stdout."""
    # Save real stdout BEFORE redirecting print() to stderr
    real_stdout = sys.stdout.buffer
    real_stdin = sys.stdin.buffer

    # Redirect Python's print()/sys.stdout to stderr so auth module
    # print() calls don't corrupt the JSON-RPC stream
    sys.stdout = sys.stderr

    def _write(msg):
        body = json.dumps(msg).encode("utf-8")
        header = f"Content-Length: {len(body)}\r\n\r\n".encode("utf-8")
        real_stdout.write(header + body)
        real_stdout.flush()

    while True:
        # Read headers
        headers = {}
        while True:
            line = real_stdin.readline()
            if not line:
                return  # EOF
            line_str = line.decode("utf-8").strip()
            if line_str == "":
                break
            if ":" in line_str:
                k, v = line_str.split(":", 1)
                headers[k.strip().lower()] = v.strip()

        content_length = int(headers.get("content-length", 0))
        if content_length == 0:
            continue

        body = real_stdin.read(content_length)
        msg = json.loads(body.decode("utf-8"))

        response = handle_rpc(msg)
        if response is not None:
            _write(response)


if __name__ == "__main__":
    main()
