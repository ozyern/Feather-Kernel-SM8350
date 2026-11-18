#!/usr/bin/env bash
# Feather-Kernel workspace setup.
#
# The kernel tree must live at <workspace>/kernel/msm-5.4, because OPlus features
# are symlinks into <workspace>/vendor (toraidl's manifest layout). This script
# fills in everything else next to it:
#   <workspace>/modules_devicetree   toraidl's OPlus modules + device tree repo
#   <workspace>/vendor               -> modules_devicetree/vendor
#   <workspace>/prebuilts/           AOSP clang r383902b1 + GCC 4.9 binutils
# and initialises the ReSukiSU submodule with Feather's patch applied.
set -euo pipefail

K="$(cd "$(dirname "$0")/.." && pwd)"
WS="${FEATHER_WS:-$(cd "$K/../.." && pwd)}"
P="$WS/prebuilts"

[ "$(basename "$K")" = msm-5.4 ] && [ "$(basename "$(dirname "$K")")" = kernel ] || {
	echo "Clone the repo to <workspace>/kernel/msm-5.4 (see feather/README.md)"; exit 1; }

echo "[1/4] ReSukiSU submodule"
git -C "$K" submodule update --init KernelSU
if git -C "$K/KernelSU" apply --check "$K/feather/patches/resukisu-feather-preinit-switch.patch" 2>/dev/null; then
	git -C "$K/KernelSU" apply "$K/feather/patches/resukisu-feather-preinit-switch.patch"
	echo "      applied resukisu-feather-preinit-switch.patch"
else
	echo "      patch already applied"
fi

echo "[2/4] OPlus modules + device tree"
if [ ! -d "$WS/modules_devicetree" ]; then
	git clone --depth 1 -b oplus/sm8350v_15.0.0_oneplus_9Pro \
		https://github.com/toraidl/android_kernel_modules_and_devicetree_oppo_sm8350 \
		"$WS/modules_devicetree"
fi
ln -sfn modules_devicetree/vendor "$WS/vendor"
# WLAN sources the manifest links into drivers/staging (repo <linkfile>s)
for d in fw-api qcacld-3.0 qca-wifi-host-cmn utils; do
	ln -sfn "../../../../vendor/qcom/opensource/wlan/$d" "$K/drivers/staging/$d"
done

echo "[3/4] AOSP clang r383902b1"
if [ ! -x "$P/clang-r383902b1/bin/clang" ]; then
	mkdir -p "$P/clang-r383902b1"
	curl -sSfL "https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/android11-qpr3-release/clang-r383902b1.tar.gz" \
		| tar -xz -C "$P/clang-r383902b1"
fi

echo "[4/4] GCC 4.9 binutils"
if [ ! -d "$P/gcc-aarch64-linux-android-4.9" ]; then
	git clone -q --depth 1 -b master-kernel-build-2021 \
		https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 \
		"$P/gcc-aarch64-linux-android-4.9"
fi

broken=$(cd "$K" && find . -path ./KernelSU -prune -o -xtype l -print | wc -l)
echo "broken symlinks in tree: $broken"
[ "$broken" = 0 ] || { echo "!! some OPlus symlinks don't resolve"; exit 1; }
"$P/clang-r383902b1/bin/clang" --version | head -1
echo "workspace ready: $WS — now run feather/build.sh"
