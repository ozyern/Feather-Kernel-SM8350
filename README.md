# Feather Kernel — SM8350

A custom Linux **5.4.302** kernel for the **OnePlus 9 Pro** (`lemonadep`) and **OnePlus 9** (`lemonade`), Qualcomm **SM8350 / lahaina**.

```
Linux 5.4.302-Feather
```

## Features

| | |
|---|---|
| **Base** | Linux 5.4.302 (LineageOS `lineage-23.2` sm8350 tree) |
| **Root** | [SukiSU Ultra](https://github.com/SukiSU-Ultra/SukiSU-Ultra) — `builtin` (non-GKI) variant, manual syscall + inline hooks, no kprobes |
| **Hiding** | [SusFS **v2.2.0**](https://gitlab.com/simonpunk/susfs4ksu) — backported to 5.4, which upstream only supports up to v1.5.9 |
| **Charging** | SuperVOOC / Warp charging animation restored on OOS15+ and AOSP-based ROMs |
| **Toolchain** | AOSP Clang r563880c (21.0.0), `LLVM=1 LLVM_IAS=1`, full-kernel LTO |
| **Packaging** | [AnyKernel3](https://github.com/osm0sis/AnyKernel3) |

Enabled SusFS options: `SUS_PATH`, `SUS_MOUNT`, `SUS_KSTAT`, `SUS_MAP`, `SPOOF_UNAME`, `SPOOF_CMDLINE_OR_BOOTCONFIG`, `OPEN_REDIRECT`, `HIDE_KSU_SUSFS_SYMBOLS`, `ENABLE_LOG`.

## Building

```bash
export PATH=/path/to/aosp-clang/bin:$PATH
make O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 vendor/lahaina-qgki_defconfig
make O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 -j$(nproc)
```

The flashable image is `out/arch/arm64/boot/Image` (uncompressed — this is what the lahaina `boot` partition expects). Drop it into AnyKernel3 with `is_slot_device=1` and `block=/dev/block/bootdevice/by-name/boot`.

## Credits

This kernel is not written from scratch. It is twenty years of other people's work with a small amount of mine on top, and the full commit history in this repository is preserved unmodified so that every one of those authors keeps their attribution.

- **OnePlus / OPPO** — the SM8350 device kernel, the `oplus_chg` charging stack, display, haptics and camera drivers that make this hardware work. Released at [OnePlusOSS/android_kernel_oneplus_sm8350](https://github.com/OnePlusOSS/android_kernel_oneplus_sm8350).
- **Qualcomm / CodeLinaro (CLO)** — the lahaina BSP, techpack, and the vast majority of the SoC support.
- **LineageOS** — the maintained sm8350 tree this is based on, and the 5.4.254 → 5.4.302 stable rebase.
- **Linus Torvalds and the Linux kernel community** — everything underneath all of the above.
- **[ShirkNeko / SukiSU-Ultra](https://github.com/SukiSU-Ultra/SukiSU-Ultra)** and **[tiann / KernelSU](https://github.com/tiann/KernelSU)** — the root implementation.
- **[simonpunk / susfs4ksu](https://gitlab.com/simonpunk/susfs4ksu)** and **sidex15** — SusFS.
- **[JackA1ltman / NonGKI_Kernel_Build_2nd](https://github.com/JackA1ltman/NonGKI_Kernel_Build_2nd)** — the SusFS 2.2.0 → 5.4 backport patch.
- **[osm0sis](https://github.com/osm0sis/AnyKernel3)** — AnyKernel3.
- ****Sabrina Carpenter**-Mommy's blessings

## License

GPL-2.0, per `COPYING`. Every file retains the license and copyright headers it shipped with. Source is published here in fulfilment of GPL-2.0 §3 for the binaries distributed from this tree.

## Disclaimer

Flashing a custom kernel can leave your device unbootable. Back up your `boot` partition first and have a way to recover. No warranty of any kind — see `COPYING`.
