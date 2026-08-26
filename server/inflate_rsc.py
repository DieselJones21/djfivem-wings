#!/usr/bin/env python3
"""Best-effort RSC7/ytyp inflate so the server can print real archetype names."""
import re
import sys
import zlib

SKIP = {
    "RSC5", "RSC7", "RSC8", "Ysu", "YTD", "YDR", "YTYP", "YFT", "YBN", "YDD",
    "CBaseArchetypeDef", "CMapTypes", "CEntityDef",
}


def inflate(payload: bytes):
    for wbits in (15, -15, 31, 47, -zlib.MAX_WBITS):
        try:
            return zlib.decompress(payload, wbits)
        except Exception:
            continue
    return None


def main(path: str) -> int:
    data = open(path, "rb").read()
    magic = data[:4]
    blob = data
    if magic in (b"RSC7", b"RSC8", b"RSC5") and len(data) > 16:
        blob = inflate(data[16:]) or inflate(data[20:]) or data[16:]
        if not blob:
            return 0
    names = []
    seen = set()
    for match in re.findall(rb"[A-Za-z_][A-Za-z0-9_]{5,47}", blob):
        name = match.decode("ascii")
        if name in SKIP or name in seen:
            continue
        seen.add(name)
        names.append(name)
    sys.stdout.write("\n".join(names))
    return 0


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(0)
    try:
        sys.exit(main(sys.argv[1]))
    except Exception:
        sys.exit(0)
