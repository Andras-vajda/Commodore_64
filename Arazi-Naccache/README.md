# Arazi-Naccache sul Commodore 64 (MOS 6502/6510)

Retroimplementazione completa dell'algoritmo di **Benjamin Arazi e David Naccache** (1992) per la conversione binario-decimale multiprecisione mediante divisione esatta per $2^r - 1$, sviluppata in Assembly NMOS 6502/6510 per Commodore 64 (sintassi **CBM prg Studio**).

L'algoritmo estrae ciascuna cifra decimale con un numero costante di scansioni lineari dei byte, senza moltiplicatori hardware, divisori generali né istruzioni BCD (`SED`). Il nucleo di divisione esatta per 255 (`Div255Exact`, 19 byte `RTS` incluso) fonde il complemento a due e la somma cumulativa in una singola scansione con `SBC`.

## Struttura del repository

```text
Arazi-Naccache/
├── README.md
├── AraziNaccache.pdf              # Articolo completo (24 pagine)
├── asm/
│   ├── AN_BCD.asm                 # Sorgente principale (CBM prg Studio)
│   ├── AN_data.asm                # Dati demo PETSCII espliciti (incluso via IncAsm)
│   ├── AN_BCD.lst                 # Listato assemblato con indirizzi e cicli
│   ├── README.md
│   └── AN_ST6225.asm              # Sorgente storico per ST6225
├── img/
│   ├── VICE_interi_32bit.png      # Schermata VICE PAL (pagina 1: 0..32 bit)
│   └── VICE_interi_256bit.png     # Schermata VICE PAL (pagina 2: 64..256 bit)
├── tests/
│   ├── build.py                   # Generazione dati, build 64tass e collaudo
│   ├── CompareBCD.asm             # Routine di confronto (Horner + SED)
│   └── compare_bcd.py             # Benchmark cicli 6502 contro Horner BCD
├── build/
│   └── comparison-bcd.json        # Resoconto riproducibile del confronto
└── st62/                          # Reperto storico extra-articolo (ST6220/ST6225)
```

## Specifiche tecniche (C64 / MOS 6502-6510)

* **ISA:** esclusivamente istruzioni documentate NMOS 6502/6510; aritmetica binaria (`D=0`), nessuna mascheratura degli IRQ, nessuna chiamata alla ROM BASIC.
* **Portata:** interi non negativi little-endian da 1 a 32 byte ($0 \le N < 256^n$, $1 \le n \le 32$, fino a 256 bit / 78 cifre decimali).
* **Ingombro PRG:** **1353 byte** (`$C000`–`$C548`, esclusi i 2 byte di indirizzo di caricamento); **272 byte** di variabili e buffer statici (routine non rientrante).
* **Nucleo `/255` (`Div255Exact`):** 19 byte (`$C1F6`–`$C208`, `RTS` incluso); $17k + 14$ cicli nella collocazione consegnata (`Div255Loop` a `$C1FE`).
* **Interfaccia pubblica:**
  * `ConvertNumber`: `A = n` (`1..32`), `X/Y = lo/hi` indirizzo sorgente. Restituisce `C = 0`, `X = numero di cifre`, stringa ASCII/PETSCII terminata da zero in `DecimalText`; `C = 1`, `X = 0` e stringa vuota per lunghezza non valida. Preserva il numero sorgente e `$FB/$FC`.
  * `PrintNumber`: stessi parametri; emette la stringa sul canale KERNAL corrente tramite `CHROUT` (`$FFD2`) senza ritorno a capo.

## Costruzione ed esecuzione

### CBM prg Studio

1. Aggiungere `asm/AN_BCD.asm` come sorgente Assembly principale di un progetto C64.
2. Mantenere `asm/AN_data.asm` nella stessa directory (viene incluso tramite `IncAsm "AN_data.asm"` e non va assemblato come unità autonoma).
3. Assemblare: l'origine `* = $C000` è già definita nel sorgente.

> **Nota case-sensitivity:** su file system case-sensitive (Linux/macOS) verificare che il nome del file dati coincida con la direttiva `IncAsm "AN_data.asm"`.

### Avvio su Commodore 64 o VICE

```basic
LOAD "ANBCD",8,1
SYS 49152
```

La barra spaziatrice passa alla seconda pagina (massimi a 64, 128 e 256 bit); una seconda pressione restituisce il controllo al BASIC tramite `RTS`.

## Collaudo e prestazioni

L'assemblaggio nativo in **CBM prg Studio** e la build di test tramite **64tass 1.59.3120** (adattando le sole direttive `BYTE`, `DCB` e `IncAsm`) producono codice macchina identico al singolo byte. Il file PRG è stato verificato sul modello NMOS 6502 (`py65`) contro gli interi esatti di Python e su **VICE x64sc 3.9** (C64 PAL):

* **516** multipli di 255 su 16 bit (`Div255Exact` e `Div255Reference`).
* **65 536** resti modulo 10 (esaustivo a 16 bit).
* **65 536** conversioni complete (esaustivo a 16 bit).
* **573** conversioni multiprecisione da 1 a 32 byte (seme `0x65026510`, con attraversamento di confine di pagina a `$30FD`).
* **4** test di stampa con alterazione intenzionale di `X,Y` nel servizio emulato e **4** lunghezze non valide (`0, 33, 128, 255`).

Confronto sui massimi $256^n - 1$ (cicli 6502 dall'ingresso a `RTS` incluso, esclusi stampa, interrupt, contesa VIC-II e attese):

| Byte | Bit | Cifre | Arazi-Naccache | Horner BCD (`SED`) | Rapporto |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 8 | 3 | 2 503 | 830 | 3,02x |
| 2 | 16 | 5 | 5 161 | 1 745 | 2,96x |
| 4 | 32 | 10 | 14 478 | 4 545 | 3,19x |
| 8 | 64 | 20 | 45 885 | 15 346 | 2,99x |
| 16 | 128 | 39 | 155 825 | 56 139 | 2,78x |
| 32 | 256 | 78 | 577 480 | 209 340 | 2,76x |

Sul 6502, dotato di modo decimale hardware (`SED`), Horner BCD prevale nei cicli (a prezzo della mascheratura degli IRQ nel nucleo decimale); il dominio elettivo di Arazi-Naccache resta il quadrante privo sia di subset BCD sia di moltiplicatore hardware rapido (MCU minimaliste a 4/8/16 bit e soft-core FPGA).

## Riferimenti essenziali

* B. Arazi, D. Naccache, *"Binary-to-decimal conversion based on the divisibility of* $2^8 - 1$ *by 5"*, Electronics Letters, 28(23):2151–2152, 1992. DOI: `10.1049/el:19921381`.
* J. J. F. Cavanagh, *Digital Computer Arithmetic: Design and Implementation*, McGraw-Hill, 1984.

## Licenza

* **Articolo, testo e materiale editoriale:** Creative Commons Attribuzione - Non commerciale - Condividi allo stesso modo 4.0 Internazionale (**CC BY-NC-SA 4.0**), Copyright 1990–2026 M.A.W. 1968.
* **Codice sorgente di esempio:** **MIT License**, Copyright (c) 2026 M.A.W. 1968.
