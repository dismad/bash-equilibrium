#!/usr/bin/env bash
#
# x-dl.sh
# Download video or audio from X/Twitter URL using local ./yt-dlp_linux binary.
# - Checks for yt-dlp_linux and updates to latest if needed (version compare via GitHub)
# - Uses exactly: ./yt-dlp_linux -f "bv*+ba/b" <url>
# - Graceful error handling and clear messages

set -uo pipefail

YT_DLP="./yt-dlp_linux"
LATEST_URL="https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux"

error_exit() {
    echo "Error: $1" >&2
    exit "${2:-1}"
}

if [ $# -ne 1 ]; then
    echo "Usage: $0 <x_or_twitter_url>"
    echo "Example: $0 https://x.com/username/status/1234567890123456789"
    exit 1
fi

URL="$1"

if [[ ! "$URL" =~ (x\.com|twitter\.com)/ ]]; then
    error_exit "Provided URL does not look like an X/Twitter URL: $URL"
fi

get_latest_version() {
    curl -sI "https://github.com/yt-dlp/yt-dlp/releases/latest" 2>/dev/null | \
        grep -i '^location:' | cut -d'/' -f8 | tr -d '\r' || echo ""
}

get_current_version() {
    if [ -x "$YT_DLP" ]; then
        "$YT_DLP" --version 2>/dev/null | head -1 || echo ""
    else
        echo ""
    fi
}

echo "==> Checking yt-dlp_linux..."

CURRENT_VERSION=$(get_current_version)
LATEST_VERSION=$(get_latest_version)

if [ -z "$LATEST_VERSION" ]; then
    echo "Warning: Could not fetch latest version info from GitHub (network or API issue)."
    LATEST_VERSION="unknown"
fi

NEEDS_UPDATE=false

if [ ! -x "$YT_DLP" ]; then
    echo "yt-dlp_linux not found or not executable."
    NEEDS_UPDATE=true
elif [ "$CURRENT_VERSION" != "$LATEST_VERSION" ] && [ "$LATEST_VERSION" != "unknown" ]; then
    echo "Current: $CURRENT_VERSION"
    echo "Latest:  $LATEST_VERSION"
    echo "Update available."
    NEEDS_UPDATE=true
else
    echo "yt-dlp_linux is up to date (version: ${CURRENT_VERSION:-unknown})."
fi

if [ "$NEEDS_UPDATE" = true ]; then
    echo "==> Downloading latest yt-dlp_linux..."
    if ! curl -fL "$LATEST_URL" -o "${YT_DLP}.tmp" 2>/dev/null; then
        error_exit "Failed to download yt-dlp_linux binary. Check internet connection and try again."
    fi
    chmod +x "${YT_DLP}.tmp"
    mv -f "${YT_DLP}.tmp" "$YT_DLP"
    NEW_VER=$("$YT_DLP" --version 2>/dev/null | head -1 || echo "unknown")
    echo "Update successful. Now using version: $NEW_VER"
fi

echo "==> Downloading from tweet: $URL"
echo "==> Command: $YT_DLP -f \"bv*+ba/b\" \"$URL\""

if "$YT_DLP" -f "bv*+ba/b" "$URL"; then
    echo "==> Download completed successfully."
else
    EXIT_CODE=$?
    error_exit "yt-dlp exited with code $EXIT_CODE. Check if the tweet contains video/audio, is public, or if there are network/format issues."
fi