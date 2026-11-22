#!/usr/bin/env python3
"""Collaudo del PRG su emulatore NMOS 6502 py65; oracolo: interi Python."""
from pathlib import Path
import hashlib
import json
import random
import re
import time
from py65.devices.mpu6502 import MPU

ROOT = Path(__file__).resolve().parents[1]


def labels():
    result = {}
    for line in (ROOT / "build/labels.txt").read_text().splitlines():
        m = re.match(r"(\w+)\s*=\s*\$([0-9a-fA-F]+)", line)
        if m:
            result[m[1].lower()] = int(m[2], 16)
    return result


def main():
    begin = time.time()
    sym = labels()
    data = (ROOT / "build/AraziNaccache.prg").read_bytes()
    start = int.from_bytes(data[:2], "little")
    ram = [0]*65536
    ram[start:start+len(data)-2] = data[2:]
    cpu = MPU(memory=ram)
    work, wlen = sym["work"], sym["worklen"]
    source = 0x30FD             # Attraversa una pagina gia' con quattro byte.
    stats = {}

    def run(name, a=0, x=0, y=0, decimal=False, capture=False):
        cpu.pc = sym[name.lower()]
        cpu.sp = 255
        cpu.a, cpu.x, cpu.y = a, x, y
        cpu.p = 0x28 if decimal else 0x20
        cpu.stPushWord(0x02FF)
        before = cpu.processorCycles
        count = 0
        chars = []
        while cpu.pc != 0x0300:
            if capture and cpu.pc == 0xFFD2:
                chars.append(cpu.a)
                cpu.x, cpu.y = 0xA5, 0x5A
                cpu.pc = (cpu.stPopWord()+1) & 65535
                continue
            cpu.step()
            count += 1
            if count > 2000000:
                raise AssertionError((name, "mancata terminazione", cpu.pc))
        assert cpu.sp == 255, (name, "stack sbilanciato", cpu.sp)
        return cpu.processorCycles-before, bytes(chars)

    def convert(n, length, capture=False):
        original = list(n.to_bytes(length, "little"))
        ram[source:source+length] = original
        ram[0xFB:0xFD] = [0xA5, 0x5A]
        cycles, chars = run("PrintNumber" if capture else "ConvertNumber",
                            length, source & 255, source >> 8,
                            decimal=True, capture=capture)
        text = sym["decimaltext"]
        result = bytes(ram[text:text+ram[sym["digitcount"]]])
        assert result == str(n).encode(), (n, length, result)
        assert ram[text+len(result)] == 0
        assert not cpu.p & (cpu.CARRY | cpu.DECIMAL)
        assert ram[source:source+length] == original
        assert ram[0xFB:0xFD] == [0xA5, 0x5A]
        if capture:
            assert chars == result
        else:
            assert cpu.x == len(result), (n, length, "X", cpu.x)
        return cycles

    # Tutti i multipli di 255 rappresentabili con due byte, zero compreso.
    for q in range(258):
        n = 255*q
        for entry in ["Div255Exact", "Div255Reference"]:
            ram[work:work+2] = n.to_bytes(2, "little")
            ram[wlen] = 2
            run(entry)
            assert int.from_bytes(bytes(ram[work:work+2]), "little") == q
    stats["divisioni_esatte_16_bit_due_versioni"] = 516
    print("Divisioni /255 a 16 bit: OK", flush=True)

    # Tutti i resti a 16 bit: modulo 5, parita', riporti circolari.
    for n in range(65536):
        ram[work:work+3] = [n & 255, n >> 8, 0]
        ram[wlen] = 3
        run("Remainder10")
        assert cpu.a == n % 10, (n, cpu.a)
    stats["resti_modulo_10_16_bit"] = 65536
    print("Resti modulo 10, 65536 ingressi: OK", flush=True)

    # Intera conversione, inclusi ordine delle cifre e zero iniziale.
    for n in range(65536):
        convert(n, 2)
        if n and n % 16384 == 0:
            print(f"Conversioni complete: {n}/65536", flush=True)
    stats["conversioni_complete_16_bit"] = 65536

    rng = random.Random(0x65026510)
    count = 0
    maxima = []
    for length in range(1, 33):
        limit = 256**length
        values = {0, 1, 9, 10, 99, 100, limit-1, limit-2, limit//2,
                  limit//2-1, limit//256, limit//256-1}
        for _ in range(6):
            values.add(rng.randrange(limit))
        for n in sorted(values):
            if 0 <= n < limit:
                cycles = convert(n, length)
                count += 1
                if n == limit-1 and length in [1, 2, 4, 8, 16, 32]:
                    maxima.append({"byte": length, "cifre": len(str(n)),
                                   "cicli_6502_conversione": cycles})
        print(f"Multiprecisione: {length}/32 byte OK", flush=True)
    stats["conversioni_multiprecisione"] = count

    for n, length in [(0, 1), (255, 1), (65535, 2), (2**256-1, 32)]:
        convert(n, length, capture=True)
    stats["stampe_con_registri_kernal_alterati"] = 4

    class GuardSource:
        """Fa fallire il test se un ingresso non valido legge la sorgente."""
        def __getitem__(self, address):
            assert not source <= address < source+255, address
            return ram[address]

        def __setitem__(self, address, value):
            ram[address] = value

    for length in [0, 33, 128, 255]:
        before = ram[:]
        cpu.memory = GuardSource()
        try:
            _, chars = run("PrintNumber", length, source & 255, source >> 8,
                           decimal=True, capture=True)
        finally:
            cpu.memory = ram
        assert cpu.p & cpu.CARRY
        assert not cpu.p & cpu.DECIMAL
        assert cpu.x == 0
        assert not chars
        assert ram[sym["decimaltext"]] == 0
        assert ram[sym["digitcount"]] == 0
        assert ram[0xFB:0xFD] == before[0xFB:0xFD]
        assert ram[source:source+255] == before[source:source+255]
    stats["lunghezze_non_valide"] = 4

    report = {"esito": "PASS", "cpu": "py65 NMOS 6502",
              "seed": "0x65026510", "test": stats, "massimi": maxima,
              "prg_sha256": hashlib.sha256(data).hexdigest(),
              "secondi_host": round(time.time()-begin, 3),
              "nota_cicli": "Esclusi KERNAL, IRQ, VIC-II e attese."}
    (ROOT / "build/verification.json").write_text(
        json.dumps(report, indent=2)+"\n", encoding="ascii")
    print(json.dumps(report, indent=2), flush=True)


if __name__ == "__main__":
    main()
