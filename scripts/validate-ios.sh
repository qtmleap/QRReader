#!/bin/bash
# Own one headless simulator for this run. Never touch pre-existing devices/windows.
set -euo pipefail
# Background commands get a separate, verifiable process group for interruption cleanup.
set -m
qr_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$qr_root"
qr_run="${QR_VALIDATION_DIR:-$qr_root/.build/validation/ios-$(date +%Y%m%d-%H%M%S)-$$}"
qr_set="$HOME/Library/Developer/CoreSimulator/Devices"
qr_runtime="${QR_SIM_RUNTIME:-com.apple.CoreSimulator.SimRuntime.iOS-26-5}"
qr_type="${QR_SIM_DEVICE_TYPE:-com.apple.CoreSimulator.SimDeviceType.iPhone-16}"
qr_device=""
qr_device_name="QRReader validation $(uuidgen)"
qr_worker=""
qr_group=""
qr_lock="$qr_root/.build/validation-ios.lock"
qr_owns_lock=false
# Opt-in simulator language: QR_UI_LANGUAGE=en|ja; QR_UI_LOCALE defaults to en_US|ja_JP.
qr_language="${QR_UI_LANGUAGE:-}"
qr_locale="${QR_UI_LOCALE:-}"
if [[ -n "$qr_language" ]]; then
    case "$qr_language" in
        en) qr_locale="${qr_locale:-en_US}"; qr_supported="en_US" ;;
        ja) qr_locale="${qr_locale:-ja_JP}"; qr_supported="ja_JP" ;;
        *) printf 'Unsupported QR_UI_LANGUAGE %s (supported: en, ja).\n' "$qr_language" >&2; exit 2 ;;
    esac
    if [[ "$qr_locale" != "$qr_supported" ]]; then
        printf 'Unsupported QR_UI_LOCALE %s for %s (supported: %s).\n' "$qr_locale" "$qr_language" "$qr_supported" >&2
        exit 2
    fi
elif [[ -n "$qr_locale" ]]; then
    printf 'QR_UI_LOCALE requires QR_UI_LANGUAGE.\n' >&2
    exit 2
fi
mkdir -p "$qr_run"

cleanup() {
    qr_exit=$?
    trap - EXIT INT TERM
    set +e
    # Stop/wait only the xcodebuild launched by this script before deleting its device.
    if [[ -n "$qr_worker" ]]; then
        if [[ "$qr_group" == "$qr_worker" ]]; then
            kill -TERM -- "-$qr_group" 2>/dev/null
        else
            kill -TERM "$qr_worker" 2>/dev/null
        fi
        wait "$qr_worker" 2>/dev/null
        if [[ "$qr_group" == "$qr_worker" ]] && kill -0 -- "-$qr_group" 2>/dev/null; then
            kill -KILL -- "-$qr_group" 2>/dev/null
        fi
    fi
    # Recover only our pre-recorded unique name if interrupted during simctl create.
    if [[ -z "$qr_device" && -f "$qr_run/devices-before.json" ]]; then
        xcrun simctl --set "$qr_set" list devices -j > "$qr_run/devices-recovery.json"
        qr_device="$(/usr/bin/python3 - "$qr_run/devices-before.json" "$qr_run/devices-recovery.json" "$qr_device_name" <<'PY'
import json, sys
before = json.load(open(sys.argv[1]))['devices']
known = {d['udid'] for group in before.values() for d in group}
after = json.load(open(sys.argv[2]))['devices']
owned = [d['udid'] for group in after.values() for d in group if d['name'] == sys.argv[3] and d['udid'] not in known]
if len(owned) > 1:
    sys.exit('Ambiguous simulator ownership; no devices deleted.')
print(owned[0] if owned else '')
PY
)"
        if [[ $? -ne 0 ]]; then qr_exit=1; fi
    fi
    if [[ -n "$qr_device" ]]; then
        xcrun simctl --set "$qr_set" terminate "$qr_device" jp.qleap.qrreader.uitests.xctrunner >> "$qr_run/cleanup.log" 2>&1
        xcrun simctl --set "$qr_set" terminate "$qr_device" jp.qleap.qrreader >> "$qr_run/cleanup.log" 2>&1
        xcrun simctl --set "$qr_set" shutdown "$qr_device" >> "$qr_run/cleanup.log" 2>&1
        xcrun simctl --set "$qr_set" delete "$qr_device" >> "$qr_run/cleanup.log" 2>&1
        xcrun simctl --set "$qr_set" list devices -j > "$qr_run/devices-after.json"
        if /usr/bin/python3 - "$qr_run/devices-after.json" "$qr_device" <<'PY'
import json, sys
devices = json.load(open(sys.argv[1]))['devices']
sys.exit(1 if any(d['udid'] == sys.argv[2] for group in devices.values() for d in group) else 0)
PY
        then
            printf 'Owned device deleted: %s\n' "$qr_device" >> "$qr_run/cleanup.log"
        else
            printf 'Cleanup failed: owned device remains %s\n' "$qr_device" >&2
            qr_exit=1
        fi
    fi
    if [[ "$qr_owns_lock" == true ]]; then
        rmdir "$qr_lock"
    fi
    # No Simulator.app is launched here. Any pre-existing app/windows are preserved.
    printf 'Validation artifacts: %s\n' "$qr_run"
    exit "$qr_exit"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

if ! mkdir "$qr_lock" 2>/dev/null; then
    printf 'Another QRReader validation owns %s. Wait for that run to finish.\n' "$qr_lock" >&2
    exit 1
fi
qr_owns_lock=true

hostname > "$qr_run/host.txt"
printf '%s\n' "$qr_set" > "$qr_run/device-set.txt"
xcrun simctl --set "$qr_set" list devices -j > "$qr_run/devices-before.json"
printf '%s\n' "$qr_device_name" > "$qr_run/owned-device-name.txt"
ps -axo pid=,command= | /usr/bin/grep '[S]imulator.app/Contents/MacOS/Simulator' > "$qr_run/simulator-processes-before.txt" || true

swift test > "$qr_run/core-tests.log" 2>&1
./scripts/generate-project.sh > "$qr_run/project-generation.log" 2>&1
qr_device="$(xcrun simctl --set "$qr_set" create "$qr_device_name" "$qr_type" "$qr_runtime")"
printf '%s\n' "$qr_device" > "$qr_run/owned-device.txt"
if [[ -n "$qr_language" ]]; then
    # Written before first boot so every simulator process (including the UI test runner) starts localized.
    qr_prefs="$qr_set/$qr_device/data/Library/Preferences"
    mkdir -p "$qr_prefs"
    /usr/bin/python3 - "$qr_prefs/.GlobalPreferences.plist" "$qr_language" "$qr_locale" <<'PY'
import os, plistlib, sys, tempfile
path, language, locale = sys.argv[1:4]
prefs = {}
if os.path.exists(path):
    with open(path, 'rb') as f:
        prefs = plistlib.load(f)
prefs['AppleLanguages'] = [language]
prefs['AppleLocale'] = locale
fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path), prefix='.GlobalPreferences.')
with os.fdopen(fd, 'wb') as f:
    plistlib.dump(prefs, f, fmt=plistlib.FMT_BINARY)
os.replace(tmp, path)
PY
    printf 'language=%s\nlocale=%s\n' "$qr_language" "$qr_locale" > "$qr_run/ui-language.txt"
fi
xcrun simctl --set "$qr_set" boot "$qr_device"
xcrun simctl --set "$qr_set" bootstatus "$qr_device" -b > "$qr_run/boot.log" 2>&1
xcrun simctl --set "$qr_set" status_bar "$qr_device" override --time '9:41' --dataNetwork wifi --batteryState charged --batteryLevel 100
if [[ -n "${QR_UI_CONTENT_SIZE:-}" ]]; then
    xcrun simctl --set "$qr_set" ui "$qr_device" content_size "$QR_UI_CONTENT_SIZE"
fi
if [[ -n "${QR_UI_APPEARANCE:-}" ]]; then
    xcrun simctl --set "$qr_set" ui "$qr_device" appearance "$QR_UI_APPEARANCE"
fi

xcodebuild test -project QRReader.xcodeproj -scheme QRReader \
    -destination "platform=iOS Simulator,id=$qr_device" \
    -derivedDataPath "$qr_root/.build/DerivedData" \
    -clonedSourcePackagesDirPath "$qr_root/.build/SourcePackages" \
    -parallel-testing-enabled NO \
    -disableAutomaticPackageResolution -onlyUsePackageVersionsFromResolvedFile \
    -resultBundlePath "$qr_run/Tests.xcresult" \
    CODE_SIGNING_ALLOWED=NO "$@" > "$qr_run/xcode-tests.log" 2>&1 &
qr_worker=$!
qr_group="$(ps -o pgid= -p "$qr_worker" | tr -d '[:space:]')"
wait "$qr_worker"
qr_worker=""
qr_group=""

ps -axo pid=,command= | /usr/bin/grep '[S]imulator.app/Contents/MacOS/Simulator' > "$qr_run/simulator-processes-after.txt" || true
printf 'Core and iOS tests passed.\n'
