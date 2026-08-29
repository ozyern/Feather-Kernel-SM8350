import struct, sys, os

out = sys.argv[1]
srcs = sys.argv[2:]
blobs = []
for s in srcs:
    d = open(s, 'rb').read()
    assert d[:4] == b'\xd0\x0d\xfe\xed', "%s is not an FDT" % s
    blobs.append((os.path.basename(s), d))

HDR, ENT = 32, 32
n = len(blobs)
data_off = HDR + n * ENT
entries, payload, off = b'', b'', data_off
for name, d in blobs:
    entries += struct.pack('>IIIIIIII', len(d), off, 0, 0, 0, 0, 0, 0)
    payload += d
    off += len(d)
total = data_off + len(payload)
hdr = struct.pack('>IIIIIIII', 0xd7b7ab1e, total, HDR, ENT, n, HDR, 4096, 0)
open(out, 'wb').write(hdr + entries + payload)

print("wrote %s  (%d bytes, %d entries)" % (out, total, n))
for i, (name, d) in enumerate(blobs):
    print("  [%d] %-42s %9d bytes" % (i, name, len(d)))
