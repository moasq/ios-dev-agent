#!/usr/bin/env python3
"""
Apple Developer Portal authentication — standalone, zero external dependencies.
Replicates Fastlane Spaceship's exact auth flow: SRP-6a + hashcash + 2FA + session cookies.

Usage:
  python3 apple-developer-auth.py login [--user user@apple.com]
  python3 apple-developer-auth.py status
  python3 apple-developer-auth.py list-apps
  python3 apple-developer-auth.py list-certs
  python3 apple-developer-auth.py list-profiles
  python3 apple-developer-auth.py register-bundle <bundle_id> <name>
  python3 apple-developer-auth.py setup-asc

Environment:
  APPLE_ID          — Apple ID email (skips prompt)
  APPLE_PASSWORD    — Password (skips prompt)
  APPLE_2FA_SMS     — Phone number for auto-SMS 2FA
"""

import hashlib
import hmac
import http.cookiejar
import json
import os
import re
import secrets
import struct
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from getpass import getpass
from pathlib import Path

# ── SRP-6a Implementation (mirrors grempe/sirp + fastlane-sirp) ──────────────

# RFC 5054 — 2048-bit group parameters
SRP_N = int(
    "AC6BDB41324A9A9BF166DE5E1389582FAF72B6651987EE07FC3192943DB56050"
    "A37329CBB4A099ED8193E0757767A13DD52312AB4B03310DCD7F48A9DA04FD50"
    "E8083969EDB767B0CF6095179A163AB3661A05FBD5FAAAE82918A9962F0B93B8"
    "55F97993EC975EEAA80D740ADBF4FF747359D041D5C33EA71D281E446B14773B"
    "CA97B43A23FB801676BD207A436C6481F1D2B9078717461A5B9D32E688F87748"
    "544523B524B0D57D5EA77A2775D2ECFA032CFBDBF52FB3786160279004E57AE6"
    "AF874E7303CE53299CCC041C7BC308D82A5698F3A8D0C38271AE35F8E9DBFBB6"
    "94B5C803D89F7AE435DE236D525F54759B65E372FCD68EF20FA7111F9E4AFF73",
    16,
)
SRP_g = 2


def num_to_hex(n: int) -> str:
    """Convert integer to lowercase even-length hex string."""
    h = format(n, "x")
    return ("0" + h) if len(h) % 2 else h


def hex_to_bytes(h: str) -> bytes:
    return bytes.fromhex(h)


def sha256_hex(hex_str: str) -> str:
    """SHA-256 of the raw bytes represented by a hex string, returned as hex."""
    return hashlib.sha256(bytes.fromhex(hex_str)).hexdigest()


def sha256_str(s: str) -> str:
    """SHA-256 of a UTF-8 string, returned as hex."""
    return hashlib.sha256(s.encode()).hexdigest()


def H(n: int, *args) -> int:
    """Hashing function with zero-padding to match N's hex width (mirrors SIRP.H)."""
    nlen = 2 * ((len(format(n, "x")) * 4 + 7) >> 3)
    hashin = ""
    for a in args:
        if a is None:
            continue
        shex = a if isinstance(a, str) else num_to_hex(a)
        hashin += "0" * (nlen - len(shex)) + shex
    return int(sha256_hex(hashin), 16) % n


def calc_k(n: int, g: int) -> int:
    return H(n, n, g)


def calc_x(username: str, password_hex: str, salt_hex: str) -> int:
    """x = SHA256(salt || SHA256(username:password)) — but password is already hashed."""
    spad = "0" if len(salt_hex) % 2 else ""
    return int(sha256_hex(spad + salt_hex + password_hex), 16)


def calc_u(xaa: str, xbb: str, n: int) -> int:
    return H(n, xaa, xbb)


def mod_exp(base: int, exp: int, mod: int) -> int:
    return pow(base, exp, mod)


def calc_A(a: int, n: int, g: int) -> int:
    return mod_exp(g, a, n)


def calc_client_S(bb: int, a: int, k: int, x: int, u: int, n: int, g: int) -> int:
    """S = (B - k * g^x)^(a + u*x) mod N"""
    return mod_exp((bb - k * mod_exp(g, x, n)) % n, a + x * u, n)


def calc_M(xaa: str, xbb: str, xkk: str) -> str:
    """M = SHA256(A || B || K) — using raw byte concatenation."""
    data = hex_to_bytes(xaa) + hex_to_bytes(xbb) + hex_to_bytes(xkk)
    return hashlib.sha256(data).hexdigest()


def calc_H_AMK(xaa: str, xmm: str, xkk: str) -> int:
    data = hex_to_bytes(xaa + xmm + xkk)
    return int(hashlib.sha256(data).hexdigest(), 16)


def pbkdf2_password(password: str, salt: bytes, iterations: int, key_length: int, protocol: str) -> bytes:
    """Derive key from password using PBKDF2-HMAC-SHA256 (mirrors Spaceship's pbkdf2)."""
    # First hash the password with SHA-256
    pw_hash = hashlib.sha256(password.encode()).digest()

    if protocol == "s2k_fo":
        # Legacy: convert hash bytes to hex string, then use that as the password
        pw_input = pw_hash.hex().encode()
    else:
        # s2k: use raw hash bytes
        pw_input = pw_hash

    return hashlib.pbkdf2_hmac("sha256", pw_input, salt, iterations, dklen=key_length)


# ── Hashcash (mirrors Spaceship::Hashcash) ───────────────────────────────────

def make_hashcash(bits: int, challenge: str) -> str:
    """Compute hashcash proof-of-work matching Apple's requirements."""
    version = 1
    date_str = datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S")
    counter = 0
    while True:
        hc = f"{version}:{bits}:{date_str}:{challenge}::{counter}"
        digest = hashlib.sha1(hc.encode()).digest()
        # Check if first `bits` bits are zero
        bit_string = "".join(format(b, "08b") for b in digest)
        if bit_string[:bits] == "0" * bits:
            return hc
        counter += 1


# ── HTTP Client with Cookie Persistence ──────────────────────────────────────

SESSION_DIR = Path.home() / ".apple-developer-auth"
COOKIE_FILE = SESSION_DIR / "cookies.txt"
SESSION_FILE = SESSION_DIR / "session.json"


class AppleAuthClient:
    BASE_AUTH = "https://idmsa.apple.com/appleauth/auth"
    OLYMPUS_CONFIG = "https://appstoreconnect.apple.com/olympus/v1/app/config?hostname=itunesconnect.apple.com"
    OLYMPUS_SESSION = "https://appstoreconnect.apple.com/olympus/v1/session"
    SERVICE_KEY_CACHE = Path("/tmp/spaceship_itc_service_key.txt")

    def __init__(self):
        SESSION_DIR.mkdir(parents=True, exist_ok=True)
        self.cookie_jar = http.cookiejar.MozillaCookieJar(str(COOKIE_FILE))
        if COOKIE_FILE.exists():
            try:
                self.cookie_jar.load(ignore_discard=True, ignore_expires=True)
            except Exception:
                pass
        self.opener = urllib.request.build_opener(
            urllib.request.HTTPCookieProcessor(self.cookie_jar)
        )
        self.x_apple_id_session_id = None
        self.scnt = None
        self.service_key = None

    def _request(self, method: str, url: str, data: dict = None, headers: dict = None) -> tuple:
        """Make HTTP request, return (status, headers, body_dict_or_str)."""
        hdrs = {
            "Accept": "application/json",
            "Content-Type": "application/json",
            "User-Agent": "Spaceship 2.225.0",
        }
        if headers:
            hdrs.update(headers)

        body = json.dumps(data).encode() if data else None

        req = urllib.request.Request(url, data=body, headers=hdrs, method=method)

        try:
            resp = self.opener.open(req)
            resp_body = resp.read().decode("utf-8", errors="replace")
            try:
                resp_json = json.loads(resp_body)
            except (json.JSONDecodeError, ValueError):
                resp_json = resp_body
            return resp.status, dict(resp.headers), resp_json
        except urllib.error.HTTPError as e:
            resp_body = e.read().decode("utf-8", errors="replace") if e.fp else ""
            try:
                resp_json = json.loads(resp_body)
            except (json.JSONDecodeError, ValueError):
                resp_json = resp_body
            return e.code, dict(e.headers), resp_json

    def _save_cookies(self):
        self.cookie_jar.save(ignore_discard=True, ignore_expires=True)

    # ── Service Key (Widget Key) ─────────────────────────────────────────────

    def get_service_key(self) -> str:
        """Fetch the auth service key from Olympus (cached)."""
        if self.service_key:
            return self.service_key

        if self.SERVICE_KEY_CACHE.exists():
            key = self.SERVICE_KEY_CACHE.read_text().strip()
            if key:
                self.service_key = key
                return key

        status, _, body = self._request("GET", self.OLYMPUS_CONFIG)
        if isinstance(body, dict):
            key = body.get("authServiceKey", "")
        else:
            raise RuntimeError(f"Failed to fetch service key: {body}")

        if not key:
            raise RuntimeError("Service key is empty")

        self.SERVICE_KEY_CACHE.write_text(key)
        self.service_key = key
        return key

    # ── Hashcash Fetch ───────────────────────────────────────────────────────

    def fetch_hashcash(self) -> str | None:
        """GET the signin endpoint to retrieve hashcash challenge parameters."""
        widget_key = self.get_service_key()
        url = f"{self.BASE_AUTH}/signin?widgetKey={widget_key}"
        status, headers, _ = self._request("GET", url)

        bits = headers.get("X-Apple-HC-Bits") or headers.get("x-apple-hc-bits")
        challenge = headers.get("X-Apple-HC-Challenge") or headers.get("x-apple-hc-challenge")

        if not bits or not challenge:
            return None

        return make_hashcash(int(bits), challenge)

    # ── SRP Login (SIRP flow) ────────────────────────────────────────────────

    def login(self, user: str, password: str):
        """Full login flow: SRP-6a init → complete → 2FA if needed → session."""
        widget_key = self.get_service_key()

        # Check existing session first
        if self._has_valid_session():
            print(f"Existing session valid for {user}")
            return True

        # SRP Phase 1: init
        a = secrets.randbelow(SRP_N)  # Client secret
        A = calc_A(a, SRP_N, SRP_g)
        A_hex = num_to_hex(A)

        import base64

        init_data = {
            "a": base64.b64encode(hex_to_bytes(A_hex)).decode(),
            "accountName": user,
            "protocols": ["s2k", "s2k_fo"],
        }

        auth_headers = {
            "X-Requested-With": "XMLHttpRequest",
            "X-Apple-Widget-Key": widget_key,
        }

        status, resp_hdrs, body = self._request("POST", f"{self.BASE_AUTH}/signin/init", init_data, auth_headers)

        if not isinstance(body, dict):
            raise RuntimeError(f"Unexpected init response: {body}")

        if body.get("serviceErrors"):
            errors = body["serviceErrors"]
            msg = errors[0].get("message", str(errors)) if errors else str(body)
            raise RuntimeError(f"Apple auth error: {msg}")

        iterations = body["iteration"]
        salt = base64.b64decode(body["salt"])
        b_bytes = base64.b64decode(body["b"])
        c = body["c"]
        protocol = body["protocol"]

        # Derive encrypted password
        encrypted_pw = pbkdf2_password(password, salt, iterations, 32, protocol)

        # SRP math
        bb = int.from_bytes(b_bytes, "big")
        if bb % SRP_N == 0:
            raise RuntimeError("SRP safety check failed: B mod N is zero")

        k = calc_k(SRP_N, SRP_g)
        # x uses the hex of the encrypted password as the "password" input
        x = calc_x(user, encrypted_pw.hex(), salt.hex())
        u = calc_u(A_hex, num_to_hex(bb), SRP_N)
        if u == 0:
            raise RuntimeError("SRP safety check failed: u is zero")

        S = calc_client_S(bb, a, k, x, u, SRP_N, SRP_g)
        S_hex = num_to_hex(S)
        K_hex = sha256_hex(S_hex)

        M1 = calc_M(A_hex, num_to_hex(bb), K_hex)
        M2 = num_to_hex(calc_H_AMK(A_hex, M1, K_hex))

        # SRP Phase 2: complete
        hashcash = self.fetch_hashcash()
        complete_data = {
            "accountName": user,
            "c": c,
            "m1": base64.b64encode(hex_to_bytes(M1)).decode(),
            "m2": base64.b64encode(hex_to_bytes(M2)).decode(),
            "rememberMe": False,
        }

        complete_headers = dict(auth_headers)
        if hashcash:
            complete_headers["X-Apple-HC"] = hashcash

        status, resp_hdrs, body = self._request(
            "POST",
            f"{self.BASE_AUTH}/signin/complete?isRememberMeEnabled=false",
            complete_data,
            complete_headers,
        )

        if status == 403:
            raise RuntimeError("Invalid Apple ID or password.")

        if status == 409:
            # 2FA required
            self.x_apple_id_session_id = (
                resp_hdrs.get("X-Apple-Id-Session-Id")
                or resp_hdrs.get("x-apple-id-session-id")
            )
            self.scnt = resp_hdrs.get("scnt") or resp_hdrs.get("Scnt")
            self._handle_2fa()
            self._fetch_olympus_session()
            self._save_session(user)
            return True

        if status == 200:
            self._save_cookies()
            self._fetch_olympus_session()
            self._save_session(user)
            return True

        if status == 412:
            # Privacy acknowledgment needed
            raise RuntimeError(
                "Apple requires you to acknowledge the Apple ID & Privacy statement. "
                "Please log into https://appleid.apple.com manually first."
            )

        raise RuntimeError(f"Unexpected response (HTTP {status}): {body}")

    # ── 2FA Handling ─────────────────────────────────────────────────────────

    def _2fa_headers(self) -> dict:
        return {
            "X-Apple-Id-Session-Id": self.x_apple_id_session_id,
            "X-Apple-Widget-Key": self.get_service_key(),
            "Accept": "application/json",
            "scnt": self.scnt,
        }

    def _handle_2fa(self):
        """Determine 2FA type and handle it."""
        status, _, body = self._request("GET", self.BASE_AUTH, headers=self._2fa_headers())

        if not isinstance(body, dict):
            raise RuntimeError(f"Unexpected 2FA response: {body}")

        trusted_phones = body.get("trustedPhoneNumbers", [])
        no_trusted_devices = body.get("noTrustedDevices", False)
        code_length = body.get("securityCode", {}).get("length", 6)

        # Check env var for auto-SMS
        env_phone = os.environ.get("APPLE_2FA_SMS", "")

        if env_phone:
            phone_id, push_mode = self._match_phone(trusted_phones, env_phone)
            self._request_sms_code(phone_id, push_mode)
            code = input(f"Enter the {code_length}-digit code sent to {env_phone}: ").strip()
            self._verify_sms_code(phone_id, code, push_mode)
        elif len(trusted_phones) == 1 and no_trusted_devices:
            # Only one phone, no devices — auto SMS
            phone = trusted_phones[0]
            phone_number = phone.get("numberWithDialCode", "unknown")
            phone_id = phone["id"]
            push_mode = phone.get("pushMode", "sms")
            print(f"SMS sent automatically to {phone_number}")
            code = input(f"Enter the {code_length}-digit code: ").strip()
            self._verify_sms_code(phone_id, code, push_mode)
        elif no_trusted_devices:
            # Multiple phones, no trusted devices — let user choose
            self._choose_phone_and_verify(trusted_phones, code_length)
        else:
            # Trusted devices available — code pushed automatically
            print(f"A {code_length}-digit code has been pushed to your trusted devices.")
            print("(Type 'sms' to receive it via text message instead)")
            print()
            code = input(f"Enter the {code_length}-digit code: ").strip()

            if code.lower() == "sms":
                self._choose_phone_and_verify(trusted_phones, code_length)
            else:
                self._verify_device_code(code)

        # Trust this session
        self._request("GET", f"{self.BASE_AUTH}/2sv/trust", headers=self._2fa_headers())
        self._save_cookies()

    def _match_phone(self, phones: list, phone_number: str) -> tuple:
        """Match a full phone number against masked numbers from Apple."""
        clean = re.sub(r'[\s\-\(\)"]+', "", phone_number)
        for phone in phones:
            masked = re.sub(r'[\s\-\(\)"]+', "", phone.get("numberWithDialCode", ""))
            # Build regex: replace masked digits with [0-9] pattern
            mask_count = masked.count("\u2022")  # bullet character
            pattern = re.sub(
                r"^([0-9+]{2,4})(\u2022+)([0-9]{2})$",
                lambda m: re.escape(m.group(1))
                + f"[0-9]{{{mask_count - 2},{mask_count}}}"
                + re.escape(m.group(3)),
                masked,
            )
            if re.match(f"^\\+?{pattern}$", clean):
                return phone["id"], phone.get("pushMode", "sms")

        raise RuntimeError(
            f"Could not match phone {phone_number} against {[p.get('numberWithDialCode') for p in phones]}"
        )

    def _choose_phone_and_verify(self, phones: list, code_length: int):
        """Let user select a phone number for SMS 2FA."""
        print("Select a phone number to receive the code:")
        for i, phone in enumerate(phones):
            print(f"  [{i + 1}] {phone.get('numberWithDialCode', 'unknown')}")

        choice = int(input("Choice: ").strip()) - 1
        phone = phones[choice]
        phone_id = phone["id"]
        push_mode = phone.get("pushMode", "sms")
        phone_number = phone.get("numberWithDialCode", "unknown")

        self._request_sms_code(phone_id, push_mode)
        code = input(f"Enter the {code_length}-digit code sent to {phone_number}: ").strip()
        self._verify_sms_code(phone_id, code, push_mode)

    def _request_sms_code(self, phone_id: int, push_mode: str = "sms"):
        """Request a verification code via SMS/push."""
        data = {"phoneNumber": {"id": phone_id}, "mode": push_mode}
        self._request("PUT", f"{self.BASE_AUTH}/verify/phone", data, self._2fa_headers())

    def _verify_device_code(self, code: str):
        """Verify a code received on a trusted device."""
        data = {"securityCode": {"code": code}}
        status, _, body = self._request(
            "POST",
            f"{self.BASE_AUTH}/verify/trusteddevice/securitycode",
            data,
            self._2fa_headers(),
        )
        if status >= 400:
            if isinstance(body, dict) and "service_errors" in str(body).lower():
                raise RuntimeError(f"Incorrect verification code. Try again.")
            if status == 401:
                raise RuntimeError("Incorrect verification code.")

    def _verify_sms_code(self, phone_id: int, code: str, push_mode: str = "sms"):
        """Verify a code received via SMS."""
        data = {
            "securityCode": {"code": code},
            "phoneNumber": {"id": phone_id},
            "mode": push_mode,
        }
        status, _, body = self._request(
            "POST",
            f"{self.BASE_AUTH}/verify/phone/securitycode",
            data,
            self._2fa_headers(),
        )
        if status >= 400:
            raise RuntimeError(f"Incorrect verification code (HTTP {status}).")

    # ── Session Management ───────────────────────────────────────────────────

    def _has_valid_session(self) -> bool:
        """Check if existing cookies form a valid session."""
        if not COOKIE_FILE.exists():
            return False
        try:
            self.cookie_jar.load(ignore_discard=True, ignore_expires=True)
            return self._fetch_olympus_session()
        except Exception:
            return False

    def _fetch_olympus_session(self) -> bool:
        """Validate session by fetching Olympus session endpoint."""
        status, _, body = self._request("GET", self.OLYMPUS_SESSION)
        if status == 200 and isinstance(body, dict):
            user_map = body.get("user", {})
            provider = body.get("provider", {})
            if provider or user_map:
                return True
        return False

    def _save_session(self, user: str):
        """Persist cookies and session metadata."""
        self._save_cookies()
        session_data = {
            "user": user,
            "authenticated_at": datetime.now(timezone.utc).isoformat(),
            "cookie_path": str(COOKIE_FILE),
        }
        SESSION_FILE.write_text(json.dumps(session_data, indent=2))

    # ── Developer Portal API ─────────────────────────────────────────────────

    def _portal_request(self, method: str, path: str, data: dict = None) -> dict:
        """Make an authenticated request to the Developer Portal."""
        url = f"https://developer.apple.com/services-account/v1/{path}"
        status, _, body = self._request(method, url, data)
        if status == 401:
            raise RuntimeError("Session expired. Please login again.")
        if status >= 400:
            raise RuntimeError(f"Portal API error (HTTP {status}): {body}")
        return body if isinstance(body, dict) else {}

    def list_apps(self) -> list:
        """List all registered bundle IDs."""
        body = self._portal_request(
            "POST",
            "account/ios/identifiers/listAppIds.action",
            {"pageNumber": 1, "pageSize": 500, "sort": "name=asc", "teamId": self._get_team_id()},
        )
        apps = body.get("appIds", [])
        return [
            {
                "bundle_id": a.get("identifier", ""),
                "name": a.get("name", ""),
                "app_id": a.get("appIdId", ""),
                "prefix": a.get("prefix", ""),
            }
            for a in apps
        ]

    def list_certificates(self) -> dict:
        """List all signing certificates."""
        body = self._portal_request(
            "POST",
            "account/ios/certificate/listCertRequests.action",
            {"pageNumber": 1, "pageSize": 500, "sort": "certRequestStatusCode=asc", "teamId": self._get_team_id()},
        )
        certs = body.get("certRequests", [])
        result = {"development": [], "distribution": []}
        for c in certs:
            cert_info = {
                "name": c.get("name", ""),
                "id": c.get("certificateId", ""),
                "type": c.get("certificateType", {}).get("name", ""),
                "status": c.get("statusString", ""),
                "expires": c.get("expirationDateString", ""),
            }
            if "development" in cert_info["type"].lower():
                result["development"].append(cert_info)
            else:
                result["distribution"].append(cert_info)
        return result

    def list_provisioning_profiles(self) -> list:
        """List all provisioning profiles."""
        body = self._portal_request(
            "POST",
            "account/ios/profile/listProvisioningProfiles.action",
            {"pageNumber": 1, "pageSize": 500, "sort": "name=asc", "teamId": self._get_team_id(), "includeInactiveProfiles": True},
        )
        profiles = body.get("provisioningProfiles", [])
        return [
            {
                "name": p.get("name", ""),
                "uuid": p.get("UUID", ""),
                "type": p.get("type", ""),
                "status": p.get("status", ""),
                "bundle_id": p.get("appId", {}).get("identifier", ""),
                "expires": p.get("dateExpire", ""),
            }
            for p in profiles
        ]

    def register_bundle_id(self, bundle_id: str, name: str) -> dict:
        """Register a new bundle ID."""
        body = self._portal_request(
            "POST",
            "account/ios/identifiers/addAppId.action",
            {
                "identifier": bundle_id,
                "name": name,
                "type": "explicit",
                "teamId": self._get_team_id(),
            },
        )
        app = body.get("appId", {})
        return {
            "bundle_id": app.get("identifier", bundle_id),
            "name": app.get("name", name),
            "app_id": app.get("appIdId", ""),
        }

    def _get_team_id(self) -> str:
        """Get the current team ID from Olympus session."""
        status, _, body = self._request("GET", self.OLYMPUS_SESSION)
        if isinstance(body, dict):
            provider = body.get("provider", {})
            return provider.get("providerId", "")
        return ""


# ── ANSI Colors ──────────────────────────────────────────────────────────────

class C:
    GREEN  = "\033[32m"
    RED    = "\033[31m"
    YELLOW = "\033[33m"
    CYAN   = "\033[36m"
    DIM    = "\033[2m"
    BOLD   = "\033[1m"
    RESET  = "\033[0m"


# ── Status Check (validates session live against Apple, not just file) ───────

def check_auth_status() -> dict:
    """
    Returns dict with:
      authenticated: bool
      valid: bool        — session cookie exists AND Apple accepted it
      user: str | None
      authenticated_at: str | None
      expired: bool      — cookie exists but Apple rejected it
    """
    result = {
        "authenticated": False,
        "valid": False,
        "user": None,
        "authenticated_at": None,
        "expired": False,
    }

    if not SESSION_FILE.exists():
        return result

    try:
        session = json.loads(SESSION_FILE.read_text())
    except (json.JSONDecodeError, OSError):
        return result

    result["user"] = session.get("user")
    result["authenticated_at"] = session.get("authenticated_at")
    result["authenticated"] = True

    # Validate live against Apple
    client = AppleAuthClient()
    if client._has_valid_session():
        result["valid"] = True
    else:
        result["expired"] = True

    return result


# ── CLI Commands ─────────────────────────────────────────────────────────────

def cmd_menu(args: list):
    """Interactive menu — the default entry point."""
    print()
    print(f"{C.BOLD}  Apple Developer Authentication{C.RESET}")
    print(f"  {'=' * 34}")
    print()

    status = check_auth_status()

    if status["valid"]:
        # ── Authenticated: green status + revoke option ──
        print(f"  {C.GREEN}{C.BOLD}● Connected{C.RESET}  {C.DIM}as{C.RESET} {status['user']}")
        if status["authenticated_at"]:
            try:
                dt = datetime.fromisoformat(status["authenticated_at"])
                age = datetime.now(timezone.utc) - dt
                days = age.days
                print(f"  {C.DIM}  Session age: {days}d — valid for ~{max(30 - days, 0)}d more{C.RESET}")
            except Exception:
                pass
        print()
        print(f"  {C.DIM}[1]{C.RESET} Revoke session (sign out)")
        print(f"  {C.DIM}[2]{C.RESET} List apps")
        print(f"  {C.DIM}[3]{C.RESET} List certificates")
        print(f"  {C.DIM}[4]{C.RESET} List profiles")
        print(f"  {C.DIM}[5]{C.RESET} Register bundle ID")
        print(f"  {C.DIM}[6]{C.RESET} Setup asc CLI (.p8 key)")
        print(f"  {C.DIM}[q]{C.RESET} Quit")
        print()

        choice = input(f"  {C.CYAN}>{C.RESET} ").strip()
        print()

        if choice == "1":
            cmd_revoke([])
        elif choice == "2":
            cmd_list_apps([])
        elif choice == "3":
            cmd_list_certs([])
        elif choice == "4":
            cmd_list_profiles([])
        elif choice == "5":
            bundle_id = input("  Bundle ID: ").strip()
            name = input("  App name: ").strip()
            if bundle_id and name:
                cmd_register_bundle([bundle_id, name])
        elif choice == "6":
            cmd_setup_asc([])
        elif choice.lower() == "q":
            return
        else:
            print(f"  {C.DIM}Unknown option.{C.RESET}")

    elif status["expired"]:
        # ── Session exists but expired: yellow status ──
        print(f"  {C.YELLOW}{C.BOLD}● Expired{C.RESET}  {C.DIM}session for{C.RESET} {status['user']}")
        print(f"  {C.DIM}  Cookie exists but Apple rejected it.{C.RESET}")
        print()
        print(f"  {C.DIM}[1]{C.RESET} Sign in  {C.DIM}(Apple ID + password + 2FA){C.RESET}")
        print(f"  {C.DIM}[2]{C.RESET} Manual   {C.DIM}(provide .p8 API key){C.RESET}")
        print(f"  {C.DIM}[3]{C.RESET} Revoke   {C.DIM}(clear expired session){C.RESET}")
        print(f"  {C.DIM}[q]{C.RESET} Quit")
        print()

        choice = input(f"  {C.CYAN}>{C.RESET} ").strip()
        print()

        if choice == "1":
            cmd_login([])
        elif choice == "2":
            cmd_setup_asc([])
        elif choice == "3":
            cmd_revoke([])
        elif choice.lower() == "q":
            return

    else:
        # ── Not authenticated: red status + two options ──
        print(f"  {C.RED}{C.BOLD}● Not connected{C.RESET}")
        print()
        print(f"  {C.DIM}[1]{C.RESET} Sign in  {C.DIM}(Apple ID + password + 2FA){C.RESET}")
        print(f"  {C.DIM}[2]{C.RESET} Manual   {C.DIM}(provide .p8 API key for asc CLI){C.RESET}")
        print(f"  {C.DIM}[q]{C.RESET} Quit")
        print()

        choice = input(f"  {C.CYAN}>{C.RESET} ").strip()
        print()

        if choice == "1":
            cmd_login([])
        elif choice == "2":
            cmd_setup_asc([])
        elif choice.lower() == "q":
            return

    # Output machine-readable status for Claude
    final_status = check_auth_status()
    print()
    print(json.dumps({
        "authenticated": final_status["valid"],
        "user": final_status["user"],
        "expired": final_status["expired"],
    }))


def cmd_login(args: list):
    user = None
    if "--user" in args:
        idx = args.index("--user")
        user = args[idx + 1] if idx + 1 < len(args) else None

    user = user or os.environ.get("APPLE_ID", "")
    if not user:
        user = input("  Apple ID: ").strip()
    if not user:
        print(f"  {C.RED}Apple ID is required.{C.RESET}", file=sys.stderr)
        sys.exit(1)

    password = os.environ.get("APPLE_PASSWORD", "")
    if not password:
        password = getpass("  Password: ")
    if not password:
        print(f"  {C.RED}Password is required.{C.RESET}", file=sys.stderr)
        sys.exit(1)

    client = AppleAuthClient()
    print(f"  Authenticating as {C.BOLD}{user}{C.RESET}...")
    print(f"  {C.DIM}2FA code will be pushed to your trusted devices.{C.RESET}")
    print()

    try:
        client.login(user, password)
        print()
        print(f"  {C.GREEN}{C.BOLD}● Connected{C.RESET}  {C.DIM}as{C.RESET} {user}")
        print(f"  {C.DIM}  Session stored at: {COOKIE_FILE}{C.RESET}")
        print(f"  {C.DIM}  Valid for ~30 days.{C.RESET}")
        print(json.dumps({"status": "authenticated", "user": user}))
    except RuntimeError as e:
        print(f"  {C.RED}ERROR: {e}{C.RESET}", file=sys.stderr)
        sys.exit(1)


def cmd_status(args: list):
    """Check and display session status with colors."""
    print()
    status = check_auth_status()

    if status["valid"]:
        print(f"  {C.GREEN}{C.BOLD}● Connected{C.RESET}  {C.DIM}as{C.RESET} {status['user']}")
        if status["authenticated_at"]:
            print(f"  {C.DIM}  Since: {status['authenticated_at']}{C.RESET}")
    elif status["expired"]:
        print(f"  {C.YELLOW}{C.BOLD}● Expired{C.RESET}  {C.DIM}session for{C.RESET} {status['user']}")
        print(f"  {C.DIM}  Run 'login' to re-authenticate.{C.RESET}")
    else:
        print(f"  {C.RED}{C.BOLD}● Not connected{C.RESET}")

    print()
    print(json.dumps({
        "authenticated": status["valid"],
        "user": status["user"],
        "expired": status["expired"],
    }))


def cmd_revoke(args: list):
    """Clear session cookies and metadata — sign out."""
    removed = []

    if COOKIE_FILE.exists():
        COOKIE_FILE.unlink()
        removed.append("cookies")

    if SESSION_FILE.exists():
        SESSION_FILE.unlink()
        removed.append("session")

    # Also clear cached service key
    cache_key = Path("/tmp/spaceship_itc_service_key.txt")
    if cache_key.exists():
        cache_key.unlink()
        removed.append("service key cache")

    if removed:
        print(f"  {C.YELLOW}Revoked:{C.RESET} {', '.join(removed)}")
        print(f"  {C.RED}{C.BOLD}● Not connected{C.RESET}")
    else:
        print(f"  {C.DIM}No active session to revoke.{C.RESET}")

    print(json.dumps({"status": "revoked", "removed": removed}))


def cmd_list_apps(args: list):
    client = AppleAuthClient()
    if not client._has_valid_session():
        print(f"  {C.RED}Not authenticated. Run login first.{C.RESET}", file=sys.stderr)
        sys.exit(1)

    apps = client.list_apps()
    for app in apps:
        print(f"  {app['bundle_id']}  {C.DIM}—{C.RESET}  {app['name']}")
    print(f"\n  {C.DIM}Total: {len(apps)} apps{C.RESET}")
    print(json.dumps({"status": "ok", "count": len(apps), "apps": apps}))


def cmd_list_certs(args: list):
    client = AppleAuthClient()
    if not client._has_valid_session():
        print(f"  {C.RED}Not authenticated. Run login first.{C.RESET}", file=sys.stderr)
        sys.exit(1)

    certs = client.list_certificates()
    print(f"  {C.BOLD}Development ({len(certs['development'])}){C.RESET}")
    for c in certs["development"]:
        print(f"    {c['name']}  {C.DIM}{c['id']}  expires {c['expires']}{C.RESET}")
    print(f"  {C.BOLD}Distribution ({len(certs['distribution'])}){C.RESET}")
    for c in certs["distribution"]:
        print(f"    {c['name']}  {C.DIM}{c['id']}  expires {c['expires']}{C.RESET}")
    print(json.dumps({"status": "ok", **certs}))


def cmd_list_profiles(args: list):
    client = AppleAuthClient()
    if not client._has_valid_session():
        print(f"  {C.RED}Not authenticated. Run login first.{C.RESET}", file=sys.stderr)
        sys.exit(1)

    profiles = client.list_provisioning_profiles()
    for p in profiles:
        status_color = C.GREEN if p['status'] == 'Active' else C.YELLOW
        print(f"  {C.DIM}[{p['type']}]{C.RESET} {p['name']}  {C.DIM}{p['bundle_id']}{C.RESET}  {status_color}{p['status']}{C.RESET}")
    print(f"\n  {C.DIM}Total: {len(profiles)} profiles{C.RESET}")
    print(json.dumps({"status": "ok", "count": len(profiles), "profiles": profiles}))


def cmd_register_bundle(args: list):
    if len(args) < 2:
        print(f"  {C.RED}Usage: register-bundle <bundle_id> <name>{C.RESET}", file=sys.stderr)
        sys.exit(1)

    bundle_id = args[0]
    name = args[1]

    client = AppleAuthClient()
    if not client._has_valid_session():
        print(f"  {C.RED}Not authenticated. Run login first.{C.RESET}", file=sys.stderr)
        sys.exit(1)

    try:
        result = client.register_bundle_id(bundle_id, name)
        print(f"  {C.GREEN}Registered{C.RESET} {result['bundle_id']} ({result['name']})")
        print(json.dumps({"status": "created", **result}))
    except RuntimeError as e:
        print(f"  {C.RED}ERROR: {e}{C.RESET}", file=sys.stderr)
        sys.exit(1)


def cmd_setup_asc(args: list):
    print(f"  {C.BOLD}ASC CLI Setup{C.RESET}")
    print(f"  {C.DIM}Provide an App Store Connect API Key (.p8 file).{C.RESET}")
    print()
    print(f"  {C.DIM}Create one at:{C.RESET}")
    print(f"  {C.CYAN}https://appstoreconnect.apple.com/access/integrations/api{C.RESET}")
    print(f"  {C.DIM}Role: App Manager or Admin. Download .p8 immediately (one-time!).{C.RESET}")
    print()

    key_id = input("  Key ID: ").strip()
    issuer_id = input("  Issuer ID: ").strip()
    key_path = input("  Path to .p8 file: ").strip().replace("~", str(Path.home()))

    if not key_id or not issuer_id:
        print(f"  {C.RED}Key ID and Issuer ID are required.{C.RESET}", file=sys.stderr)
        sys.exit(1)

    key_path = Path(key_path)
    if not key_path.exists():
        print(f"  {C.RED}.p8 file not found at {key_path}{C.RESET}", file=sys.stderr)
        sys.exit(1)

    asc_dir = Path.home() / ".asc"
    asc_dir.mkdir(exist_ok=True)
    dest = asc_dir / f"AuthKey_{key_id}.p8"
    dest.write_bytes(key_path.read_bytes())
    dest.chmod(0o600)

    ret = os.system(f'asc auth login --key-id "{key_id}" --issuer-id "{issuer_id}" --private-key-path "{dest}"')
    if ret == 0:
        print()
        print(f"  {C.GREEN}{C.BOLD}● ASC configured{C.RESET}  {C.DIM}Key at: {dest}{C.RESET}")
    else:
        print()
        print(f"  {C.RED}asc auth login failed. Is asc installed? (brew install asc){C.RESET}")


# ── Main ─────────────────────────────────────────────────────────────────────

def main():
    if len(sys.argv) < 2:
        # No args = show interactive menu
        cmd_menu([])
        return

    command = sys.argv[1]
    args = sys.argv[2:]

    commands = {
        "menu": cmd_menu,
        "login": cmd_login,
        "status": cmd_status,
        "revoke": cmd_revoke,
        "logout": cmd_revoke,
        "list-apps": cmd_list_apps,
        "list-certs": cmd_list_certs,
        "list-profiles": cmd_list_profiles,
        "register-bundle": cmd_register_bundle,
        "setup-asc": cmd_setup_asc,
    }

    if command in commands:
        commands[command](args)
    else:
        print(f"  {C.RED}Unknown command: {command}{C.RESET}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
