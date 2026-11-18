#!/usr/bin/env python3
"""Swap the kernel inside an Android boot image (header v3, 4K pages).

usage: repack_boot.py <stock-boot.img> <Image> <out-boot.img>

Keeps the original header fields (OS version / patch level / cmdline) and the
ramdisk; only kernel_size and the kernel payload change. The stock AVB footer is
dropped because its hash no longer matches (fine on an unlocked bootloader).
"""
import struct
import sys

PAGE = 4096


def pad(n):
    return (n + PAGE - 1) // PAGE * PAGE


def main(src, image, dst):
    d = open(src, 'rb').read()
    if d[:8] != b'ANDROID!':
        sys.exit('not an Android boot image')
    ks, rs, osv, hs = struct.unpack('<4I', d[8:24])
    ver = struct.unpack('<I', d[40:44])[0]
    if ver != 3:
        sys.exit(f'only header v3 supported, got v{ver}')
    ramdisk = d[PAGE + pad(ks):PAGE + pad(ks) + rs]
    kernel = open(image, 'rb').read()

    hdr = bytearray(d[:PAGE])
    struct.pack_into('<I', hdr, 8, len(kernel))
    out = bytes(hdr)
    out += kernel + b'\0' * (pad(len(kernel)) - len(kernel))
    out += ramdisk + b'\0' * (pad(rs) - rs)
    open(dst, 'wb').write(out)
    print(f'{dst}: kernel {len(kernel)} B (was {ks}), ramdisk {rs} B kept, '
          f'os_version 0x{osv:08x} kept, {len(out)} B total')


if __name__ == '__main__':
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    main(*sys.argv[1:])
