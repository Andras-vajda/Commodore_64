#!/usr/bin/env python3
"""Verifica LOAD dal D64, SYS e ritorno al BASIC nel C64 emulato da VICE."""
from pathlib import Path
import argparse
import hashlib
import json
import subprocess
from capture_vice import screen_text
from verify import ROOT, labels


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--vice", default="x64sc")
    p.add_argument("--data")
    p.add_argument("--roms", type=Path)
    a = p.parse_args()
    sym = labels()
    build = ROOT / "build"
    commands = [
        "radix D",
        'keybuf load\\x22arazi\\x22,8,1\\x0d',
        "step 1000000",
        f'bsave "{build / "basic-loaded.bin"}" 0 $c000 $c548',
        f'bsave "{build / "basic-load-screen.bin"}" 0 $0400 $07e7',
        f'break ${sym["page1ready"]:04x}',
        'keybuf sys49152\\x0d',
        "g",
        "step 20000",
        f'bsave "{build / "basic-page1.bin"}" 0 $0400 $07e7',
        "> $0277 $20",
        "> $00c6 $01",
        f'break ${sym["page2ready"]:04x}',
        "g",
        "step 20000",
        f'bsave "{build / "basic-page2.bin"}" 0 $0400 $07e7',
        "> $0277 $20",
        "> $00c6 $01",
        "delete",
        "step 200000",
        f'bsave "{build / "basic-return.bin"}" 0 $0400 $07e7',
        "quit"]
    mon = build / "verify-basic.mon"
    mon.write_text("\n".join(commands)+"\n", encoding="ascii")
    command = [a.vice, "-console", "-default", "-model", "c64",
               "-drive8type", "0", "+drive8truedrive", "-virtualdev8",
               "-iecdevice8",
               "-8", str(build / "AraziNaccache.d64"), "+sound", "-warp",
               "-initbreak", "ready", "-moncommands", str(mon)]
    if a.data:
        command += ["-directory", str(Path(a.data).resolve())]
    if a.roms:
        for flag, name in [("-kernal", "kernal-901227-03.bin"),
                           ("-basic", "basic-901226-01.bin"),
                           ("-chargen", "chargen-901225-01.bin")]:
            command += [flag, str((a.roms / name).resolve())]
    with (build / "vice-basic.log").open("w") as log:
        subprocess.run(command, stdout=log, stderr=subprocess.STDOUT,
                       check=True, timeout=60)
    prg = (build / "AraziNaccache.prg").read_bytes()
    assert (build / "basic-loaded.bin").read_bytes() == prg[2:]
    screens = {}
    for name in ["basic-load-screen", "basic-page1", "basic-page2",
                 "basic-return"]:
        screens[name] = screen_text(build / (name+".bin"))
        (build / (name+".txt")).write_text(screens[name]+"\n")
    assert "READY." in screens["basic-load-screen"]
    assert "4294967295" in screens["basic-page1"]
    assert str(2**256-1) in screens["basic-page2"].replace("\n", "")
    assert "READY." in screens["basic-return"]
    assert str(2**256-1) in screens["basic-return"].replace("\n", "")
    report = {"esito": "PASS", "emulatore": "VICE x64sc 3.9, C64 PAL",
              "disco": "D64, dispositivo 8, emulazione IEC virtuale",
              "avvio": 'LOAD "ARAZI",8,1 / SYS 49152',
              "controlli": ["RAM caricata uguale al PRG", "due pagine",
                            "ritorno al prompt READY."],
              "prg_sha256": hashlib.sha256(prg).hexdigest()}
    (build / "vice-basic-verification.json").write_text(
        json.dumps(report, indent=2)+"\n", encoding="ascii")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
