#!/usr/bin/env python3
"""Prepare and validate GoogleService-Info.plist without ever printing its contents.

With --from-env, GOOGLE_SERVICE_INFO_PLIST_BASE64 is decoded to --path only when it is set.
Otherwise an existing file is validated. A missing or mismatched file fails with a clear message.
"""
import argparse
import base64
import binascii
import os
import plistlib
import sys
from pathlib import Path

ENV = "GOOGLE_SERVICE_INFO_PLIST_BASE64"


def fail(message):
    prefix = "::error title=GoogleService-Info.plist::" if os.environ.get("GITHUB_ACTIONS") else "error: "
    print(prefix + message, file=sys.stderr)
    sys.exit(1)


def validate(data, bundle_id):
    try:
        plist = plistlib.loads(data)
    except Exception:
        fail("GoogleService-Info.plist is not a valid property list.")
    if not isinstance(plist, dict):
        fail("GoogleService-Info.plist is not a dictionary.")
    if plist.get("BUNDLE_ID") != bundle_id:
        fail(f"GoogleService-Info.plist BUNDLE_ID does not match {bundle_id}.")
    for key in ("GOOGLE_APP_ID", "API_KEY", "GCM_SENDER_ID"):
        if not plist.get(key):
            fail(f"GoogleService-Info.plist is missing {key}.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--bundle-id", required=True)
    parser.add_argument("--path", required=True)
    parser.add_argument("--from-env", action="store_true")
    args = parser.parse_args()

    path = Path(args.path)
    encoded = os.environ.get(ENV, "").strip() if args.from_env else ""
    if encoded:
        try:
            data = base64.b64decode(encoded)
        except (binascii.Error, ValueError):
            fail(f"{ENV} is not valid base64.")
        validate(data, args.bundle_id)
        path.parent.mkdir(parents=True, exist_ok=True)
        descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
        with os.fdopen(descriptor, "wb") as handle:
            handle.write(data)
        print(f"Wrote {path} from {ENV} (BUNDLE_ID verified).")
    elif path.is_file():
        validate(path.read_bytes(), args.bundle_id)
        print(f"{path} present (BUNDLE_ID verified).")
    else:
        fail(
            f"{path} is missing. The file is gitignored and the app calls FirebaseApp.configure() at launch, "
            f"so tests and release builds cannot run without it. Set the repository secret {ENV} "
            f"(base64 of the Firebase iOS config for {args.bundle_id}) or place the file locally."
        )


main()
