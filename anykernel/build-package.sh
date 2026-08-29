#!/bin/bash
# Assemble the Feather Kernel AnyKernel3 flashable zip.
#
# Usage: feather/build-package.sh <AnyKernel3 dir> <kernel out dir> <output zip>
#
# The kernel Image alone is not enough on lahaina -- see feather/README.md.
set -eu

AK=${1:?AnyKernel3 directory}
OUT=${2:?kernel out/ directory}
ZIP=${3:?output zip path}

HERE=$(cd "$(dirname "$0")" && pwd)
DTS=$OUT/arch/arm64/boot/dts/vendor/oplus/lemonadev

cp -f "$OUT/arch/arm64/boot/Image" "$AK/Image"
cp -f "$HERE/anykernel.sh"         "$AK/anykernel.sh"

# vendor_boot device tree: v1 + v2 + v2.1, each 4-byte aligned
python3 "$HERE/mkdtb.py" "$AK/dtb" \
  "$DTS/lahaina.dtb" "$DTS/lahaina-v2.dtb" "$DTS/lahaina-v2.1.dtb"

# dtbo: the four lemonade overlays, matching the stock 4-entry table
python3 "$HERE/mkdtbo.py" "$AK/dtbo.img" \
  "$DTS/lemonade-19825-overlay.dtbo" \
  "$DTS/lemonadep-19815-overlay.dtbo" \
  "$DTS/lemonadep-19815-overlay-t0.dtbo" \
  "$DTS/lemonadev-2080a-overlay.dtbo"

rm -f "$ZIP"
( cd "$AK" && zip -r9 "$ZIP" . -x ".git/*" "*.zip" >/dev/null )
echo "built $ZIP"
