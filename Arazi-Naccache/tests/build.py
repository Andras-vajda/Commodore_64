#!/usr/bin/env python3
"""Genera i dati demo e assembla con 64tass il sorgente CBM prg Studio."""
from pathlib import Path
import argparse
import re
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
CASES = [("ZERO: ", 0, 1), ("UNO: ", 1, 1), ("NOVE: ", 9, 1),
         ("DIECI: ", 10, 1), ("255: ", 255, 1), ("256: ", 256, 2),
         ("MAX 16 BIT: ", 65535, 2),
         ("MAX 32 BIT: ", 2**32-1, 4),
         ("MAX 64 BIT:\r", 2**64-1, 8),
         ("\rMAX 128 BIT:\r", 2**128-1, 16),
         ("\rMAX 256 BIT:\r", 2**256-1, 32)]


def byte_lines(label, values):
    out = [label]
    for i in range(0, len(values), 12):
        out.append("        BYTE " + ",".join(
            f"${v:02X}" for v in values[i:i+12]))
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--assembler", default=shutil.which("64tass"))
    args = ap.parse_args()
    if not args.assembler:
        ap.error("Indicare --assembler /percorso/64tass")
    out = ["; Dati demo PETSCII, generati da tests/build.py. ASCII, MIT."]
    for label, text in [
        ("Title1", "ARAZI-NACCACHE / MOS 6502-6510\r"
         "BINARIO -> DECIMALE / KERNAL $FFD2\r\r"),
        ("Title2", "ARAZI-NACCACHE / MULTIPRECISIONE\r"
         "STESSA ROUTINE, FINO A 32 BYTE\r\r"),
        ("Prompt1", "\rSPAZIO: INTERI A 64, 128 E 256 BIT"),
        ("Prompt2", "\rSPAZIO: RITORNO AL BASIC"),
        ("ErrorText", "ERRORE: LUNGHEZZA NON VALIDA")]:
        out += byte_lines(label, list(text.encode("ascii"))+[0])
    for i, (name, value, length) in enumerate(CASES):
        out += byte_lines(f"Name{i}", list(name.encode("ascii"))+[0])
        out += byte_lines(f"Value{i}", list(value.to_bytes(length, "little")))
    for name, prefix, op in [("NameLo", "Name", "<"),
                             ("NameHi", "Name", ">"),
                             ("ValueLo", "Value", "<"),
                             ("ValueHi", "Value", ">")]:
        out.append(name)
        for first in range(0, len(CASES), 6):
            out.append("        BYTE " + ",".join(
                f"{op}{prefix}{i}" for i in
                range(first, min(first+6, len(CASES)))))
    out += ["ValueLen", "        BYTE " + ",".join(
        str(c[2]) for c in CASES)]
    (ROOT / "asm/demo_data.asm").write_text("\n".join(out)+"\n",
                                          encoding="ascii")
    build = ROOT / "build"
    generated = build / "64tass"
    generated.mkdir(parents=True, exist_ok=True)
    for source in (ROOT / "asm").glob("*.asm"):
        text = source.read_text(encoding="ascii")
        text = re.sub(r"\bBYTES\b", ".fill", text)
        text = re.sub(r"\bBYTE\b", ".byte", text)
        text = re.sub(r"\bINCLUDE\b", ".include", text)
        (generated / source.name).write_text(text, encoding="ascii")
    subprocess.run([str(Path(args.assembler).resolve()), "--m6502",
                    "--cbm-prg", "--labels",
                    str(build / "labels.txt"), "--list",
                    str(build / "listing.txt"), "-o",
                    str(build / "AraziNaccache.prg"),
                    str(generated / "AraziNaccache.asm")], check=True)


if __name__ == "__main__":
    main()
