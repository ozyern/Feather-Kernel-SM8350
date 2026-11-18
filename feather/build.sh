#!/usr/bin/env bash
# Feather-Kernel build: OnePlus 9 / 9 Pro (SM8350 "lahaina", 5.4 qgki),
# ReSukiSU + SUSFS v2.4.0. Run feather/setup.sh once first.
#
# Toolchain mirrors toraidl's build.config.common (AOSP clang r383902b1 +
# GCC 4.9 binutils) and the resulting config matches Pedestrian's known-good
# Android 16 kernel except for the name and SUSFS.
#
# Environment:
#   FEATHER_WS         workspace (default: two levels above this repo)
#   FEATHER_OUT        build output dir (default: $FEATHER_WS/out)
#   FEATHER_HOSTTOOLS  optional no-root host tools dir (see README)
#   FEATHER_PREINIT=1  enable ReSukiSU's "preinit" runner (off: not in the
#                      known-good build, and untested on this kernel)
#   FEATHER_NOKSU=1    control build without KernelSU/SUSFS
set -euo pipefail

K="$(cd "$(dirname "$0")/.." && pwd)"
WS="${FEATHER_WS:-$(cd "$K/../.." && pwd)}"
P="$WS/prebuilts"
OUT="${FEATHER_OUT:-$WS/out}"
HT="${FEATHER_HOSTTOOLS:-$WS/hosttools}"

KCF="-D__ANDROID_COMMON_KERNEL__"
[ "${FEATHER_PREINIT:-0}" = 1 ] || KCF="$KCF -DKSU_NO_PREINIT"

export PATH="$P/clang-r383902b1/bin:$P/gcc-aarch64-linux-android-4.9/bin:$PATH"

# Optional no-root host tools (make/flex/bison/m4 + glibc/openssl headers
# unpacked into $HT/root); AOSP clang doubles as the host compiler via hostcc.
if [ -d "$HT/root" ]; then
	export PATH="$HT/root/usr/bin:$PATH"
	export BISON_PKGDATADIR="$HT/root/usr/share/bison"
	export M4="$HT/root/usr/bin/m4"
	HOSTTOOLS=(HOSTCC="$HT/hostcc" HOSTCXX="$HT/hostcxx" HOSTLD=ld.lld HOSTAR=llvm-ar)
else
	HOSTTOOLS=()
fi

export LOCALVERSION=            # keep "5.4.254-Feather" (no "+" for a modified tree)
# OplusKernelEnvConfig.mk turns this into CONFIG_CHG_FOR_OP9_PRO, which makes
# drivers/power/Makefile build the OnePlus 9 / 9 Pro charger (oplus_chg/:
# PM8350B, HL7227, P9415). Without it the generic OPPO charger is built and
# the battery reads 0%.
export OPLUS_VND_ENV_CHG_OP9_PRO=yes
# Also exported by toraidl's build.config.lemonade (OnePlus haptics etc.).
export BRAND_SHOW_FLAG=oneplus
export TARGET_BUILD_VARIANT=user
export KBUILD_BUILD_USER="Aditya"
export KBUILD_BUILD_HOST="Feather-Kernel"

ARGS=(
	-C "$K" O="$OUT" ARCH=arm64
	CC=clang LD=ld.lld NM=llvm-nm OBJCOPY=llvm-objcopy
	CLANG_TRIPLE=aarch64-linux-gnu-
	CROSS_COMPILE=aarch64-linux-androidkernel-
	# No CROSS_COMPILE_COMPAT: the known-good kernel has no 32-bit vDSO.
	KCFLAGS="$KCF"
	"${HOSTTOOLS[@]}"
)

clang --version | head -1
make "${ARGS[@]}" vendor/feather_defconfig

# Guard rails: settings that differ from the known-good Android 16 kernel.
grep -q '^CONFIG_COMPAT_VDSO=y' "$OUT/.config" && { echo "!! COMPAT_VDSO is on (known-good build has none)"; exit 1; }
grep -q '^CONFIG_ANDROID_BPF_UNAME_COMPAT=y' "$OUT/.config" && { echo "!! BPF uname compat is on (hangs Android 16 at the boot logo)"; exit 1; }

if [ "${FEATHER_NOKSU:-0}" = 1 ]; then
	"$K/scripts/config" --file "$OUT/.config" -d KSU
	make "${ARGS[@]}" olddefconfig
	grep -q '^CONFIG_KSU=y' "$OUT/.config" && { echo "!! KSU still on"; exit 1; }
	echo "control build: KernelSU/SUSFS disabled"
else
	# olddefconfig silently drops options whose dependencies fail.
	missing=0
	for opt in KSU KSU_SUSFS KSU_SUSFS_SUS_PATH KSU_SUSFS_SUS_MOUNT KSU_SUSFS_SUS_KSTAT \
		   KSU_SUSFS_SPOOF_UNAME KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS \
		   KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG KSU_SUSFS_OPEN_REDIRECT KSU_SUSFS_SUS_MAP; do
		grep -q "^CONFIG_${opt}=y" "$OUT/.config" || { echo "!! CONFIG_${opt} not enabled"; missing=1; }
	done
	grep -q '^CONFIG_KSU_MANUAL_HOOK=y' "$OUT/.config" && { echo "!! manual hook still selected"; missing=1; }
	[ "$missing" = 0 ] || exit 1
	echo "config OK (preinit: $([ "${FEATHER_PREINIT:-0}" = 1 ] && echo on || echo off))"
fi

make "${ARGS[@]}" -j"$(nproc)" Image 2>&1 | tee "$OUT/build.log"

IMG="$OUT/arch/arm64/boot/Image"
ls -la "$IMG"
strings "$IMG" | grep -m1 "Linux version 5" || true
# The OnePlus 9 charger stack must be in the Image (battery reads 0% otherwise).
IMG_STRINGS="$(strings "$IMG")"   # not piped into grep -q: pipefail + SIGPIPE
for tag in PM8350B P9415 HL7227; do
	grep -q "OPLUS_CHG\[$tag" <<<"$IMG_STRINGS" \
		|| { echo "!! OnePlus 9 charger ($tag) missing from Image (OPLUS_VND_ENV_CHG_OP9_PRO?)"; exit 1; }
done
echo "charger OK (OnePlus 9: PM8350B / P9415 / HL7227)"
