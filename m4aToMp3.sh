#!/bin/bash
set -euo pipefail

install_ffmpeg() {
    if command -v apt >/dev/null 2>&1; then
        sudo apt update && sudo apt install -y ffmpeg
    elif command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y ffmpeg
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y ffmpeg
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm ffmpeg
    elif command -v brew >/dev/null 2>&1; then
        brew install ffmpeg
    else
        echo "Unsupported package manager. Please install ffmpeg manually."
        exit 1
    fi
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    echo "Usage: $0 <input.m4a> [output.mp3]"
    echo "       $0 --install"
    echo "       $0 --help"
    exit 0
fi

if [ "${1:-}" = "--install" ]; then
    install_ffmpeg
    echo "ffmpeg installed successfully."
    exit 0
fi

if [ $# -lt 1 ]; then
    echo "Usage: $0 <input.m4a> [output.mp3]"
    echo "       $0 --install"
    echo "       $0 --help"
    exit 1
fi

INPUT="$1"
if [ ! -f "$INPUT" ]; then
    echo "Error: Input file not found: $INPUT"
    exit 1
fi

if [ $# -ge 2 ]; then
    OUTPUT="$2"
else
    OUTPUT="${INPUT%.*}.mp3"
fi

OUTPUT_DIR=$(dirname "$OUTPUT")
if [ ! -d "$OUTPUT_DIR" ]; then
    echo "Error: Output directory does not exist: $OUTPUT_DIR"
    exit 1
fi
if [ ! -w "$OUTPUT_DIR" ]; then
    echo "Error: No write permission for directory: $OUTPUT_DIR"
    exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "ffmpeg is required but not installed."
    echo "Run: $0 --install"
    echo "Or install manually:"
    echo "  Ubuntu/Debian: sudo apt install ffmpeg"
    echo "  Fedora:        sudo dnf install ffmpeg"
    echo "  Arch Linux:    sudo pacman -S ffmpeg"
    echo "  macOS:         brew install ffmpeg"
    exit 1
fi

if ffmpeg -y -i "$INPUT" -vn -codec:a libmp3lame -qscale:a 2 -map_metadata 0 "$OUTPUT"; then
    echo "Converted successfully: $OUTPUT"
else
    echo "Error: Conversion failed."
    echo "Possible causes:"
    echo "  - ffmpeg lacks MP3 support (libmp3lame). Reinstall ffmpeg."
    echo "  - Corrupted or unsupported input file."
    echo "  - Insufficient disk space or permissions."
    echo "Verify encoder with: ffmpeg -encoders | grep -E 'mp3|lame'"
    exit 1
fi