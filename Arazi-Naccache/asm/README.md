# Reperto storico: Arazi-Naccache per MCU ST6220 / ST6225

Implementazione ricostruita in Assembly **ST AST6** (ST62 Macro Assembler) per i microcontrollori a 8 bit della famiglia ST62 (`ST6220` / `ST6225`), conservata in questo repository come reperto storico extra-articolo.

La famiglia ST62 rappresenta un caso esemplare del quadrante architetturale privo sia di istruzioni BCD sia di moltiplicatore hardware: niente `ADC`/`SBC` con riporto, nessuno shift/rotate a destra in hardware, salti relativi `JR` limitati a 5 bit con segno e stack di ritorno hardware profondo 6 livelli.

## File

* `AN_ST6225.asm` — Routine di conversione `ConvertNumber` (fino a 8 byte / 64 bit, 20 cifre decimali + terminatore `NUL`), completa di `Remainder10`, `DivideTwo`, `Div255Exact`, `CopyWork`, `ShiftWork`, `AddTemp` e `IsWorkZero`.

## Risorse e vincoli rispettati

* **RAM utente:** 45 byte lineari (`084h..0B0h`; `0B1h..0BFh` liberi; registri I/O da `0C0h`).
* **Ingombro ROM:** circa 330 byte (tutti gli scostamenti `JR` verificati entro `[-13, +12]`).
* **Stack hardware:** al più 2 livelli utilizzati (inclusa la `CALL ConvertNumber`), grazie all'inlining di `Quotient10`.
* **Nucleo `Div255Exact`:** 32 byte totali; utilizza il bit `W.0` per propagare il prestito entrante $b_i$, sfruttando l'invariante $b_i = 1 \implies q_{i-1} \ge 1$ per evitare un doppio controllo di borrow su `SUBI A, 1`.
* **Divisione per 2 (`DivideTwo`):** realizzata mediante 8 rotazioni `RLC A` sull'anello a 9 bit `[C, A]`, equivalenti a un `ROR` di un bit.

## Interfaccia

* **Ingresso:** `InputLen` in `[1..8]`, intero non negativo little-endian caricato in `Work[0..InputLen-1]`.
* **Uscita:** `C = 0`, `DigitCount` uguale al numero di cifre, stringa ASCII terminata da `0` in `DecimalText` (invertita in loco); `C = 1`, `DigitCount = 0` e stringa vuota se `InputLen` è fuori intervallo.

## Nota sulla verifica

Il listato è stato ricostruito a tavolino sulla base delle specifiche ISA ST622x e della sintassi AST6, senza riesumare la vecchia toolchain ST62 su Windows XP; va quindi inteso come riferimento architetturale e documentazione storica.

## Licenza

Codice distribuito secondo **MIT License**, Copyright (c) 2026 M.A.W. 1968.
