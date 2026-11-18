# Feather Kernel — OnePlus 9 / 9 Pro (SM8350)

`5.4.254-Feather` for the OnePlus 9 (`lemonade`) and 9 Pro (`lemonadep`) on
Android 16 based ColorOS / OxygenOS ports.

- **Base:** [toraidl/android_kernel_oppo_sm8350](https://github.com/toraidl/android_kernel_oppo_sm8350)
  (`oneplus/sm8350v_15.0.0_oneplus9pro`) by BRUCE, with its BPF backports for newer Android
- **Root:** [ReSukiSU](https://github.com/ReSukiSU/ReSukiSU) (KernelSU fork), as the `KernelSU` submodule
- **Hiding:** [SUSFS](https://gitlab.com/simonpunk/susfs4ksu) **v2.4.0**, hand-ported from the 5.10 GKI patch to 5.4
- **Toolchain:** AOSP Clang `r383902b1` (11.0.2), ThinLTO + CFI + Shadow Call Stack
- **Config:** matches Pedestrian's known-good Android 16 build, plus SUSFS

## Flashing

Flash the AnyKernel3 zip with the KernelSU/ReSukiSU manager, Kernel Flasher or a
recovery. It only replaces the kernel and keeps your current ramdisk. Install the
ReSukiSU manager that matches the pinned submodule commit.

Keep a known-good boot image (or kernel zip) ready to flash back.

## Building

The tree must sit at `<workspace>/kernel/msm-5.4`, because OPlus features are
symlinks into `<workspace>/vendor` (toraidl's repo-manifest layout).

```sh
mkdir feather && cd feather
git clone -b feather https://github.com/ozyern/Feather-Kernel-SM8350 kernel/msm-5.4
kernel/msm-5.4/feather/setup.sh      # submodule, OPlus vendor repo, toolchains
kernel/msm-5.4/feather/build.sh      # -> out/arch/arm64/boot/Image
kernel/msm-5.4/feather/package.sh    # -> dist/Feather_OP9_<version>_<date>.zip
```

`package.sh <stock-boot.img>` also writes a `boot.img` built from that image's
header and ramdisk (header v3). Use your current ROM's boot image for that.

Host packages: `build-essential bc bison flex libssl-dev libelf-dev cpio git curl python3`.
Without root, the build can instead use host tools unpacked from `.deb`s via
`FEATHER_HOSTTOOLS` (see the top of `feather/build.sh`).

### Build options

| Variable | Effect |
|---|---|
| `FEATHER_PREINIT=1` | Enable ReSukiSU's preinit runner (off by default; untested on this kernel) |
| `FEATHER_NOKSU=1` | Control build without KernelSU and SUSFS |
| `FEATHER_OUT`, `FEATHER_DIST`, `FEATHER_WS` | Output, package and workspace directories |

## Things that make or break a boot

`feather/build.sh` refuses to build if any of these are wrong.

- **`CONFIG_ANDROID_BPF_UNAME_COMPAT=n`.** The base tree tells `bpfloader`/`netd`
  the kernel is `5.10.240`. On Android 16 that leaves the phone stuck at the boot logo.
- **`OPLUS_VND_ENV_CHG_OP9_PRO=yes`** in the build environment. It selects the
  OnePlus 9 charger (`drivers/power/oplus_chg`: PM8350B, HL7227, P9415). Without
  it the generic OPPO charger is built and the battery reads 0%.
- **No 32-bit vDSO** (`CROSS_COMPILE_COMPAT` unset), matching the known-good build.

## SUSFS on 5.4

SUSFS only supports 5.10+. The `gki-android12-5.10` v2.4.0 patch was ported by hand:

- **exec:** hooks wrap `__do_execve_file()`, holding a `struct filename` reference for the post-exec and preinit-retry paths
- **open:** sus-path and open-redirect live in `do_last()` (5.4 has no `open_last_lookups()`/`do_open()`)
- **stat:** no `kstat->mnt_id` on 5.4; the internal `STATX_SUS_*` bits are cleared before reaching userspace
- **SELinux:** the type-hiding helpers were rebuilt from 5.4's rwlock-based policy code
- **`/proc/*/fdinfo`:** keeps 5.4's format (no `ino:` line)
- **fsnotify:** adapter for 5.4's `->handle_event` plus the `->free_mark` 5.4 requires
- **`/proc/cmdline`:** spoofing added, since this non-GKI kernel exposes `androidboot.*` there
- **Legacy hooks:** the base tree's old KernelSU manual hooks were removed (ReSukiSU rejects them alongside SUSFS)

## Credits

BRUCE ([toraidl](https://github.com/toraidl)) for the kernel source and BPF work;
PEDESTRIAN ([t.me/pedestrian1603](https://t.me/pedestrian1603)) for the reference
Android 16 build; simonpunk for SUSFS; the ReSukiSU and KernelSU developers;
osm0sis for AnyKernel3.

Licensed under GPL-2.0, like the Linux kernel.
