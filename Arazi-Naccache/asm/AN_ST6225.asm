; ======================================================================
; Arazi-Naccache: binario -> decimale ASCII per MCU ST6220 / ST6225
; Sintassi: ST AST6 (ST62 Macro Assembler). Sorgente puro ASCII.
; Copyright (c) 2026 M.A.W. 1968. Codice distribuito con licenza MIT.
;
; Risorse:
;   RAM utente : 45 byte (084h..0B0h; 0B1h..0BFh liberi; I/O da 0C0h)
;   ROM        : ~330 byte (tutte le JR verificate entro [-13, +12])
;   Stack HW   : 2 livelli max (inclusa CALL ConvertNumber; 6 su ST622x)
;
; Convenzione ST62:
;   SUB/CP -> C=1 su borrow (A < op); ADD -> C=1 su carry.
;   JRR/JRS caricano il bit testato in C, senza alterare A ne' Z.
;   CLR A (pseudo-istruzione AST6 -> SUB A, A) imposta A=0, Z=1, C=0.
; ======================================================================

        .vers   "ST6225"

; --- Registri CPU mappati in RAM (se non gia' in st6225.inc) ---
X       .def    080h
Y       .def    081h
V       .def    082h
W       .def    083h
A       .def    0FFh

; --- Costanti di configurazione ---
MaxBytes    .def    8               ; Fino a 64 bit (20 cifre max)
MaxText     .def    21              ; 20 cifre + terminatore NUL

; --- Mappa RAM lineare ST622x (084h..0B0h, 45 byte totali) ---
InputLen    .def    084h            ; Lunghezza ingresso in byte (1..8)
WorkLen     .def    085h            ; InputLen + 1 (include byte di guardia)
DigitCount  .def    086h            ; Contatore cifre prodotte
Digit       .def    087h            ; Resto corrente (0..9)
SmallTemp   .def    088h            ; Appoggio riduzione mod 255 / mod 5
SmallLow    .def    089h            ; Nibble basso in Remainder10
Work        .def    08Ah            ; Buffer n+1 byte (08Ah..092h)
Temp        .def    093h            ; Buffer n+1 byte (093h..09Bh)
DecimalText .def    09Ch            ; Stringa ASCII invertita in loco (09Ch..0B0h)

; ----------------------------------------------------------------------
; ConvertNumber: converte Work[0..InputLen-1] (LE) in DecimalText (ASCII).
; Ingresso: InputLen in [1..MaxBytes], dividendo copiato in Work.
; Uscita:   C=0, DigitCount = numero cifre, DecimalText terminato da NUL;
;           C=1, DigitCount = 0, stringa vuota se InputLen non valido.
; Alterati: A, X, Y, V, W, Work, Temp.
; ----------------------------------------------------------------------
ConvertNumber:
        LD      A, InputLen
        JRNZ    ConvLenNZ           ; (+2)
        JP      ConvertBad          ; 0 non valido
ConvLenNZ:
        CPI     A, MaxBytes+1       ; C=1 sse A < MaxBytes+1
        JRC     ConvLenOK           ; (+2)
        JP      ConvertBad          ; > MaxBytes non valido
ConvLenOK:
        ; Azzera byte di guardia Work[InputLen] e imposta WorkLen = InputLen+1
        ADDI    A, Work             ; A contiene ancora InputLen
        LD      X, A                ; X = &Work[InputLen]
        CLR     A                   ; A = 0, C = 0
        LD      (X), A              ; Byte di guardia = 0
        LD      A, InputLen
        ADDI    A, 1
        LD      WorkLen, A
        CLR     A
        LD      DigitCount, A

ConvertDigit:
        CALL    Remainder10         ; A = Work mod 10 (0..9)
        LD      Digit, A
        ADDI    A, 48               ; ASCII '0'..'9'
        LD      V, A
        LD      A, DigitCount
        ADDI    A, DecimalText
        LD      X, A                ; X = &DecimalText[DigitCount]
        LD      A, V
        LD      (X), A              ; Accumula cifre dalla meno significativa
        INC     DigitCount

        ; --- Quotient10 in linea (evita un livello sullo stack HW) ---
        ; 1) M = Work - Digit
        LDI     X, Work
        LD      A, WorkLen
        LD      Y, A
        LD      A, (X)
        SUB     A, Digit
        LD      (X), A
        JRNC    SubDigitDone        ; (+8) nessun borrow da propagare
SubDigitLoop:
        INC     X
        DEC     Y
        JRZ     SubDigitDone        ; (+5)
        LD      A, (X)
        SUBI    A, 1
        LD      (X), A
        JRC     SubDigitLoop        ; (-8) propaga finche' c'e' borrow
SubDigitDone:

        ; 2) M / 2
        CALL    DivideTwo

        ; 3) 51 * (M/2) = 17 * 3 * (M/2) = (16 + 1) * (2 + 1) * (M/2)
        CALL    CopyWork            ; Temp = X
        CALL    ShiftWork           ; Work = 2X
        CALL    AddTemp             ; Work = 3X
        CALL    CopyWork            ; Temp = 3X
        CALL    ShiftWork           ; 6X
        CALL    ShiftWork           ; 12X
        CALL    ShiftWork           ; 24X
        CALL    ShiftWork           ; 48X
        CALL    AddTemp             ; Work = 51X

        ; 4) Divisione esatta in loco per 255
        CALL    Div255Exact

        CALL    IsWorkZero          ; Z=1 sse Work == 0
        JRZ     ConvertDone         ; (+2)
        JP      ConvertDigit

ConvertDone:
        ; Terminatore NUL a DecimalText[DigitCount] e inversione in loco
        LD      A, DigitCount
        ADDI    A, DecimalText
        LD      X, A                ; X = &DecimalText[DigitCount]
        CLR     A
        LD      (X), A              ; DecimalText[DigitCount] = 0
        DEC     X                   ; X -> ultima cifra scritta
        LDI     Y, DecimalText      ; Y -> prima cifra scritta

ConvertRevLoop:
        LD      A, Y
        CP      A, X                ; C=1 sse Y < X (indirizzi in 09Ch..0AFh)
        JRNC    ConvertRevDone      ; (+1