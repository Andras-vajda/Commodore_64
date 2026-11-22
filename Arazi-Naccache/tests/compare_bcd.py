#!/usr/bin/env python3
"""Confronto riproducibile fra il PRG dell'articolo e Horner con SED/ADC."""
from pathlib import Path
import argparse
import hashlib
import json
import random
import re
import subprocess
from py65.devices.mpu6502 import MPU
from verify import ROOT, labels


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--assembler", required=True)
    args = p.parse_args()
    build = ROOT / "build"
    src = ROOT / "tests/CompareBCD.asm"
    text = src.read_text(encoding="ascii")
    for a, b in [("BYTES", ".fill"), ("BYTE", ".byte")]:
        text = re.sub(r"\b"+a+r"\b", b, text)
    translated = build / "CompareBCD.64tass.asm"
    translated.write_text(text, encoding="ascii")
    subprocess.run([str(Path(args.assembler).resolve()), "--m6502",
                    "--cbm-prg", "--labels",
                    str(build / "CompareBCD.labels.txt"), "-o",
                    str(build / "CompareBCD.prg"), str(translated)],
                   check=True)
    symbols = {}
    for line in (build / "CompareBCD.labels.txt").read_text().splitlines():
        m = re.match(r"(\w+)\s*=\s*\$([0-9a-fA-F]+)", line)
        if m:
            symbols[m[1].lower()] = int(m[2], 16)
    symbols.update(labels())
    ram = [0]*65536
    for name in ["CompareBCD", "AraziNaccache"]:
        data = (build / (name+".prg")).read_bytes()
        start = int.from_bytes(data[:2], "little")
        ram[start:start+len(data)-2] = data[2:]
    cpu = MPU(memory=ram)
    source = 0x30FD

    def run(entry, output, n, length):
        original = list(n.to_bytes(length, "little"))
        ram[source:source+length] = original
        ram[0xFB:0xFD] = [0xA5, 0x5A]
        cpu.pc = symbols[entry]
        cpu.a, cpu.x, cpu.y = length, source & 255, source >> 8
        cpu.p = 0x28 | (4 if n & 1 else 0)
        initial_i = cpu.p & cpu.INTERRUPT
        cpu.sp = 255
        cpu.stPushWord(0x2FF)
        begin = cpu.processorCycles
        while cpu.pc != 0x300:
            cpu.step()
            assert cpu.processorCycles-begin < 2000000
        count = len(str(n))
        ptr = symbols[output]
        assert bytes(ram[ptr:ptr+count]) == str(n).encode()
        assert ram[ptr+count] == 0
        assert cpu.x == count and cpu.sp == 255
        assert not cpu.p & (cpu.CARRY | cpu.DECIMAL)
        assert cpu.p & cpu.INTERRUPT == initial_i
        assert ram[source:source+length] == original
        assert ram[0xFB:0xFD] == [0xA5, 0x5A]
        return cpu.processorCycles-begin

    for n in range(65536):
        run("convertbcd", "bcdtext", n, 2)
        if n and n % 16384 == 0:
            print(f"BCD: {n}/65536", flush=True)
    rng = random.Random(0x65026510)
    multiprecision = 0
    rows = []
    for length in range(1, 33):
        limit = 256**length
        values = {0, 1, 9, 10, 99, 100, limit-1, limit-2, limit//2,
                  limit//2-1, limit//256, limit//256-1}
        for _ in range(6):
            values.add(rng.randrange(limit))
        for n in sorted(values):
            if 0 <= n < limit:
                run("convertbcd", "bcdtext", n, length)
                multiprecision += 1
        if length in [1, 2, 4, 8, 16, 32]:
            n = limit-1
            an = run("convertnumber", "decimaltext", n, length)
            bcd = run("convertbcd", "bcdtext", n, length)
            rows.append({"byte": length, "cifre": len(str(n)),
                         "arazi_naccache_cicli": an,
                         "horner_bcd_cicli": bcd,
                         "rapporto_an_bcd": round(an/bcd, 3)})
    report = {
        "esito": "PASS", "cpu": "py65 NMOS 6502",
        "ingressi_bcd_16_bit": 65536,
        "ingressi_bcd_multiprecisione": multiprecision,
        "contratto": "stessa stringa numerica senza zeri iniziali e con NUL",
        "misura": "ingresso routine fino a RTS incluso, senza JSR chiamante",
        "esclusioni": "KERNAL, IRQ/NMI, contesa VIC-II, attese",
        "limite": "BCD usa SED e maschera IRQ; NMI non simulati",
        "interpretazione": "confronto fra due implementazioni, non ottimalita",
        "massimi": rows,
        "hash": {name: hashlib.sha256((build/name).read_bytes()).hexdigest()
                 for name in ["AraziNaccache.prg", "CompareBCD.prg"]}}
    (build / "comparison-bcd.json").write_text(
        json.dumps(report, indent=2)+"\n", encoding="ascii")
    print(json.dumps(report, indent=2), flush=True)


if __name__ == "__main__":
    main()
