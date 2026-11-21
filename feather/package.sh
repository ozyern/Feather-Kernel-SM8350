#!/usr/bin/env bash
# Package the built Image into an AnyKernel3 flashable zip, and optionally a
# boot.img when given a stock boot image to take the header/ramdisk from:
#   feather/package.sh [stock-boot.img]
# Environment: FEATHER_WS, FEATHER_OUT (as build.sh), FEATHER_VERSION (default 1.5),
#              FEATHER_TAG (name suffix),
#              FEATHER_DIST (output dir, default $FEATHER_WS/dist)
set -euo pipefail
K="$(cd "$(dirname "$0")/.." && pwd)"
WS="${FEATHER_WS:-$(cd "$K/../.." && pwd)}"
OUT="${FEATHER_OUT:-$WS/out}"
DIST="${FEATHER_DIST:-$WS/dist}"
IMG="$OUT/arch/arm64/boot/Image"
[ -f "$IMG" ] || { echo "no Image, run feather/build.sh first"; exit 1; }

VER=$(strings "$IMG" | grep -o -m1 "Linux version 5[^ ]*" | cut -d" " -f3 || true)
# e.g. Feather-Kernel-1.5_SM8350-SD888-lahaina_OP9-9Pro_5.4.254
FEATHER_VERSION="${FEATHER_VERSION:-1.5}"
NAME="Feather-Kernel-${FEATHER_VERSION}_SM8350-SD888-lahaina_OP9-9Pro_${VER%-Feather}${FEATHER_TAG:+_$FEATHER_TAG}"
mkdir -p "$DIST"

python3 -I - "$K/feather/anykernel3" "$IMG" "$DIST/$NAME.zip" "$VER" <<'PY'
import os, sys, zipfile
ak3, img, out, ver = sys.argv[1:]
with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
    for d, _, fs in os.walk(ak3):
        for f in fs:
            p = os.path.join(d, f)
            zi = zipfile.ZipInfo.from_file(p, os.path.relpath(p, ak3))
            zi.compress_type = zipfile.ZIP_DEFLATED
            z.writestr(zi, open(p, 'rb').read())
    z.writestr('version', f'Kernel: {ver}\n')
    zi = zipfile.ZipInfo.from_file(img, 'Image'); zi.compress_type = zipfile.ZIP_DEFLATED
    z.writestr(zi, open(img, 'rb').read())
print(out)
PY

if [ "${1:-}" ]; then
	python3 -I "$K/feather/repack_boot.py" "$1" "$IMG" "$DIST/${NAME}_boot.img"
fi
