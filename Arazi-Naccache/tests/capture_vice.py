#!/usr/bin/env python3
"""Acquisisce due schermate reali VICE e i corrispondenti dump dello schermo."""
from pathlib import Path
import argparse
import hashlib
import json
import subprocess
from verify import ROOT, labels


def screen_text(path):
    raw = path.read_bytes()
    assert len(raw) == 1000, len(raw)
    def char(b):
        b &= 127
        return chr(b+64) if b < 32 else chr(b)
    return "\n".join("".join(char(b) for b in raw[i:i+40]).rstrip()
                     for i in range(0, 1000, 40))


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--vice", default="x64sc")
    p.add_argument("--data", help="Directory dei dati VICE, se non installati")
    p.add_argument("--roms", type=Path,
                   help="Directory con i tre file ROM originali VICE/C64")
    a = p.parse_args()
    sym = labels()
    img = ROOT / "img"
    img.mkdir(exist_ok=True)
    commands = [
        f'load "{ROOT / "build/AraziNaccache.prg"}" 0',
        f'break ${sym["page1ready"]:04x}',
        f'g ${sym["start"]:04x}',
        "step 20000",
        f'screenshot "{img / "VICE_interi_32bit.png"}" 2',
        f'bsave "{ROOT / "build/screen1.bin"}" 0 $0400 $07e7',
        "> $0277 $20",          # SPAZIO nel buffer tastiera del KERNAL.
        "> $00c6 $01",
        f'break ${sym["page2ready"]:04x}',
        "g",
        "step 20000",
        f'screenshot "{img / "VICE_interi_256bit.png"}" 2',
        f'bsave "{ROOT / "build/screen2.bin"}" 0 $0400 $07e7',
        "quit"]
    mon = ROOT / "build/capture.mon"
    mon.write_text("\n".join(commands)+"\n")
    command = [a.vice, "-console", "-default", "-model", "c64",
               "-drive8type", "0", "+sound", "-warp",
               "-initbreak", "ready", "-moncommands", str(mon)]
    if a.data:
        command += ["-directory", str(Path(a.data).resolve())]
    if a.roms:
        for flag, name in [("-kernal", "kernal-901227-03.bin"),
                           ("-basic", "basic-901226-01.bin"),
                           ("-chargen", "chargen-901225-01.bin")]:
            command += [flag, str((a.roms / name).resolve())]
    with (ROOT / "build/vice.log").open("w") as log:
        subprocess.run(command, stdout=log, stderr=subprocess.STDOUT,
                       check=True, timeout=60)
    screens = []
    for i in [1, 2]:
        text = screen_text(ROOT / f"build/screen{i}.bin")
        (ROOT / f"build/screen{i}.txt").write_text(text+"\n")
        screens.append(text)
    for n in [0, 1, 9, 10, 255, 256, 65535, 2**32-1]:
        assert str(n) in screens[0]
    joined = screens[1].replace("\n", "")
    for n in [2**64-1, 2**128-1, 2**256-1]:
        assert str(n) in joined, n
    report = {"esito": "PASS", "emulatore": "VICE x64sc",
              "modello": "C64 PAL", "stampa": "KERNAL CHROUT $FFD2",
              "acquisizione": "comando screenshot del monitor VICE",
              "verifica": "dump RAM video $0400-$07E7 confrontato con Python",
              "schermate": []}
    for f in sorted(img.glob("VICE_*.png")):
        report["schermate"].append({"file": f.name,
            "sha256": hashlib.sha256(f.read_bytes()).hexdigest()})
    if a.roms:
        report["rom_sha256"] = {
            f.name: hashlib.sha256(f.read_bytes()).hexdigest()
            for f in sorted(a.roms.glob("*.bin"))}
    (ROOT / "build/vice-verification.json").write_text(
        json.dumps(report, indent=2)+"\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
