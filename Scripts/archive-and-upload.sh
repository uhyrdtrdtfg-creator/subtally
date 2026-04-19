#!/usr/bin/env bash
#
# One-shot: regenerate project → archive → upload to App Store Connect (TestFlight).
# Auto-bumps build number using current timestamp (monotonic-per-run).
#
# Setup (once):
#   1. Put .p8 at ~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8
#   2. cp .env.example .env   # fill in ASC_KEY_ID + ASC_ISSUER_ID
#   3. brew install xcodegen  # if not installed
#
# Run:
#   ./Scripts/archive-and-upload.sh
#
# After ~2-3 min local archive + ~15-30 min ASC processing, build shows in
# App Store Connect → your app → TestFlight.

set -euo pipefail

# --- Locate repo root (script lives in Scripts/) ---
cd "$(dirname "$0")/.."
REPO_ROOT="$(pwd)"

# --- Load .env ---
if [[ -f .env ]]; then
    set -a
    # shellcheck disable=SC1091
    source .env
    set +a
else
    echo "ERROR: .env not found at $REPO_ROOT/.env" >&2
    echo "       Run: cp .env.example .env  and fill in values." >&2
    exit 1
fi

: "${ASC_KEY_ID:?ASC_KEY_ID not set in .env}"
: "${ASC_ISSUER_ID:?ASC_ISSUER_ID not set in .env}"

ASC_API_KEY_PATH="${ASC_API_KEY_PATH:-$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8}"
if [[ ! -f "$ASC_API_KEY_PATH" ]]; then
    echo "ERROR: API key not found at $ASC_API_KEY_PATH" >&2
    echo "       Download it from appstoreconnect.apple.com → Users and Access → Integrations → Keys" >&2
    exit 1
fi

# --- Config ---
PROJECT="SubscribeApp.xcodeproj"
SCHEME="SubscribeApp"
BUILD_NUMBER="$(date +%Y%m%d%H%M)"
BUILD_DIR="build"
ARCHIVE="$BUILD_DIR/Subtally-$BUILD_NUMBER.xcarchive"
EXPORT_OPTS="ExportOptions.plist"

# --- 1. Regenerate project from project.yml (catches any yaml edits) ---
if command -v xcodegen &>/dev/null; then
    echo "==> xcodegen generate"
    xcodegen generate >/dev/null
else
    echo "WARN: xcodegen not found; skipping project regen (install: brew install xcodegen)" >&2
fi

# --- 2. Clean build dir ---
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# --- 3. Archive ---
echo "==> Archive (version from project.yml, build $BUILD_NUMBER)"
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE" \
    -allowProvisioningUpdates \
    -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
    -authenticationKeyID "$ASC_KEY_ID" \
    -authenticationKeyPath "$ASC_API_KEY_PATH" \
    CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
    | tail -60

# --- 4. Export + upload in one step (destination=upload in ExportOptions.plist) ---
echo "==> Upload to App Store Connect"
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE" \
    -exportOptionsPlist "$EXPORT_OPTS" \
    -allowProvisioningUpdates \
    -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
    -authenticationKeyID "$ASC_KEY_ID" \
    -authenticationKeyPath "$ASC_API_KEY_PATH" \
    | tail -40

echo ""
echo "=============================================="
echo " DONE. Build $BUILD_NUMBER uploaded."
echo " ASC processing takes 15-30 min."
echo " Check: https://appstoreconnect.apple.com → TestFlight"
echo "=============================================="
