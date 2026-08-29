# Feather Kernel packaging

`Image` on its own does not boot this device. Two things bit hard enough to be
worth writing down.

## The device tree lives in `vendor_boot`, not `boot`

OnePlus 9 / 9 Pro use boot header v3: `boot` is kernel + generic ramdisk with no
dtb section at all, while `vendor_boot` carries the dtb (`dtb_size` 1419450 on
ColorOS16 / OOS16). A zip that flashes only the kernel therefore leaves the new
kernel paired with the old device tree.

`anykernel.sh` installs in two stages -- kernel to `boot`, then device tree to
`vendor_boot` via `reset_ak`. Shipping `dtb` at the zip root is enough to make
this work: `flash_boot` in `ak3-core.sh` prefers `$AKHOME/dtb` over
`split_img/dtb`, and only copies when `split_img/dtb` already exists, so it is
applied to `vendor_boot` and correctly skipped for `boot`.

Note this AnyKernel3 revision takes its install variables in **uppercase**
(`BLOCK`, `IS_SLOT_DEVICE`, `RAMDISK_COMPRESSION`, `PATCH_VBMETA_FLAG`). The
lowercase spellings older kernel repos use are silently ignored, and the install
aborts with `Unable to determine  partition` -- note the double space where the
empty variable expanded. `vbmeta_disable_verification` does not exist here
either; `PATCH_VBMETA_FLAG=auto` covers it.

## `cat *.dtb > dtb` does not produce a valid multi-DTB blob

The bootloader walks the blob by stepping `offset += ROUNDUP(fdt_totalsize, 4)`.
If any dtb's size is not a multiple of 4, every entry after it starts unaligned,
the next magic check misses, and the walk stops early. Qualcomm's own dtbs tend
to be 4-aligned by luck, so a stock blob survives plain concatenation and a
hand-built one does not:

    lahaina.dtb      466278 bytes   offset 0        ok
    lahaina-v2.dtb   476911 bytes   offset 466278   mod4=2   <- unreachable
    lahaina-v2.1.dtb 476903 bytes   offset 943189   mod4=1   <- unreachable

That blob exposes only the v1 tree. These phones are lahaina **v2.1**
(`qcom,msm-id` revision `0x20001`), so nothing matched and the bootloader never
launched a kernel. `mkdtb.py` pads each entry to a 4-byte boundary and prints a
simulation of the bootloader's walk, so a broken blob is caught at build time
rather than on the phone. Do not verify by counting `d00dfeed` hits -- a
byte-wise scan happily finds entries the bootloader can never reach.

## Reading a failed flash

- **Stuck on the splash, no reboot** -- the bootloader never started a kernel.
  Suspect device tree selection: no `qcom,msm-id` match for the SoC revision.
- **Bootloop** -- the kernel started and died. Suspect the kernel itself, or a
  mismatched device tree, but not DT discovery.

`vendor_boot` on this device ships no kernel modules, so a vermagic mismatch
against `/vendor/lib/modules` breaks wifi, camera and audio but never blocks
init. It is not a bootloop cause.

## Recovery

Nothing here touches critical firmware, so fastboot always gets you back:

    fastboot flash boot        boot.img
    fastboot flash vendor_boot vendor_boot.img
    fastboot flash dtbo        dtbo.img
