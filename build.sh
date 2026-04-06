#!/bin/bash
# ──────────────────────────────────────────────────────────────────
# Build pve-freq Docker image locally
#
# Usage:
#   ./build.sh              # Build using wheel from pve-freq repo
#   ./build.sh /path/to.whl # Build using specific wheel file
# ──────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="$SCRIPT_DIR/dist"
IMAGE_NAME="pve-freq"
IMAGE_TAG="local"

echo "▸ Preparing dist/ directory"
mkdir -p "$DIST_DIR"

if [ -n "${1:-}" ] && [ -f "$1" ]; then
    # Use provided wheel
    cp "$1" "$DIST_DIR/"
    echo "  Using provided wheel: $1"
elif [ -f "$DIST_DIR"/*.whl ] 2>/dev/null; then
    echo "  Using existing wheel in dist/"
else
    # Build from pve-freq source
    FREQ_SRC="${FREQ_SRC:-../pve-freq}"
    if [ -d "$FREQ_SRC" ] && [ -f "$FREQ_SRC/pyproject.toml" ]; then
        echo "  Building wheel from $FREQ_SRC (via Docker)"
        docker run --rm \
            -v "$FREQ_SRC:/src:ro" \
            -v "$DIST_DIR:/out" \
            python:3.13-slim \
            sh -c "pip install --no-cache-dir build && cp -r /src /tmp/build-src && cd /tmp/build-src && python3 -m build --wheel --outdir /out/"
    else
        echo "  ERROR: No wheel found and pve-freq source not at $FREQ_SRC"
        echo "  Either:"
        echo "    1. Place a .whl file in dist/"
        echo "    2. Run: ./build.sh /path/to/pve_freq-x.y.z.whl"
        echo "    3. Set FREQ_SRC to pve-freq repo path"
        exit 1
    fi
fi

echo ""
echo "▸ Building Docker image: $IMAGE_NAME:$IMAGE_TAG"
docker build -t "$IMAGE_NAME:$IMAGE_TAG" "$SCRIPT_DIR"

echo ""
echo "▸ Verifying image"
docker run --rm "$IMAGE_NAME:$IMAGE_TAG" freq --version

echo ""
echo "════════════════════════════════════════════════════════"
echo " Image built: $IMAGE_NAME:$IMAGE_TAG"
echo ""
echo " Run:  docker compose up -d"
echo " CLI:  docker exec pve-freq freq doctor"
echo " TUI:  docker exec -it pve-freq freq"
echo "════════════════════════════════════════════════════════"
