import struct, sys, os

out, srcs = sys.argv[1], sys.argv[2:]
blob = bytearray()
placed = []
for s in srcs:
    d = open(s, 'rb').read()
    assert d[:4] == b'\xd0\x0d\xfe\xed', s
    while len(blob) % 4:            # every entry must start 4-byte aligned
        blob += b'\x00'
    placed.append((os.path.basename(s), len(blob), len(d)))
    blob += d
while len(blob) % 4:
    blob += b'\x00'
open(out, 'wb').write(blob)

print("wrote %s  (%d bytes)" % (out, len(blob)))
for n, o, l in placed:
    print("  %-22s offset=%-9d mod4=%d  size=%d" % (n, o, o % 4, l))

# walk it exactly the way ABL does: step by totalsize, round up to 4
print("\nABL walk simulation:")
off, n = 0, 0
while off < len(blob) - 4:
    if blob[off:off+4] != b'\xd0\x0d\xfe\xed':
        print("  STOP at %d - no FDT magic" % off); break
    total = struct.unpack_from('>I', blob, off + 4)[0]
    print("  [%d] offset=%-9d totalsize=%d" % (n, off, total))
    n += 1
    off = (off + total + 3) & ~3
print("  reachable entries: %d of %d" % (n, len(srcs)))
