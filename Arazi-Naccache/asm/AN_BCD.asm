; ==================================================
; Arazi-Naccache: binario -> decimale, MOS 6502/6510
; Commodore 64, CBM prg Studio. Solo NMOS document.
; Copyright (c) 2026 M.A.W. 1968. Licenza MIT.
; Caricamento: LOAD "ANBCD",8,1   Avvio: SYS 49152
; ==================================================
        * = $C000

PrintChr = $FFD2      ; KERNAL CHROUT: char in A.
ClrChn   = $FFCC      ; Ripristina canali std.
GetIn    = $FFE4      ; Tastiera non bloccante.
Source   = $FB        ; Ptr temp; ripristinato.
MaxBytes = 32         ; 1..32 byte (fino 256 bit).
MaxText  = 3*MaxBytes ; Limite cifre + NUL.


; --------------------------------------------------
; Dimostratore su due pagine.
; SPAZIO passa alla seconda, poi torna al BASIC.
; --------------------------------------------------
Start   CLD
        JSR ClrChn
        LDA #147
        JSR PrintChr
        LDA #0
        STA DemoPage
        STA DemoCase
        LDX #<Title1
        LDY #>Title1
        JSR PrintString
DemoLoop
        LDX DemoCase
        CPX #8
        BNE DemoNext
        LDA DemoPage
        BNE DemoNext
        LDX #<Prompt1
        LDY #>Prompt1
        JSR PrintString
Page1Ready
        JSR WaitSpace
        INC DemoPage
        LDA #147
        JSR PrintChr
        LDX #<Title2
        LDY #>Title2
        JSR PrintString
DemoNext
        LDX DemoCase
        CPX #11
        BEQ DemoDone
        LDA NameLo,X
        LDY NameHi,X
        TAX
        JSR PrintString
        LDX DemoCase
        LDA ValueLo,X
        STA ArgLo
        LDA ValueHi,X
        STA ArgHi
        LDA ValueLen,X
        LDX ArgLo
        LDY ArgHi
        JSR PrintNumber
        BCC DemoGood
        LDX #<ErrorText
        LDY #>ErrorText
        JSR PrintString
DemoGood
        LDA #13
        JSR PrintChr
        INC DemoCase
        JMP DemoLoop
DemoDone
        LDX #<Prompt2
        LDY #>Prompt2
        JSR PrintString
Page2Ready
        JSR WaitSpace
        LDA #13
        JSR PrintChr
        RTS

WaitSpace
        JSR GetIn
        CMP #32
        BNE WaitSpace
        RTS

; --------------------------------------------------
; PrintNumber: A=n, X/Y=lo/hi sorgente (formato LE).
; Stampa senza CR sul canale KERNAL corrente; Start
; seleziona lo schermo. C=0: n valido; C=1: n non
; valido, nessuna stampa (non segnala errori I/O).
; --------------------------------------------------
PrintNumber
        JSR ConvertNumber
        BCS PrintNumberEnd
        LDA #0
        STA PrintIndex
PrintNumberLoop
        LDX PrintIndex
        LDA DecimalText,X
        BEQ PrintNumberOK
        JSR PrintChr
        INC PrintIndex
        JMP PrintNumberLoop
PrintNumberOK
        CLC
PrintNumberEnd
        RTS

; --------------------------------------------------
; ConvertNumber: A=n (1..MaxBytes), X/Y=lo/hi src.
; Uscita: DecimalText ASCII/PETSCII terminato da 0,
;   X=numero di cifre, C=0. Se n non valido: C=1,
;   X=0, stringa vuota. Altera A,X,Y,flag; D=0.
; Preserva sorgente e $FB/$FC. Buffer statici (non
; rientrante): sorgente disgiunta da RAM di lavoro,
; $FB/$FC, stack attivo e aree alterate dal KERNAL;
; deve essere leggibile nella configurazione attiva.
; --------------------------------------------------
ConvertNumber
        CLD
        CMP #1
        BCC ConvertBad
        CMP #MaxBytes+1
        BCS ConvertBad
        STA InputLen
        STX ArgLo
        STY ArgHi
        LDA Source
        STA SaveSource
        LDA Source+1
        STA SaveSource+1
        LDA ArgLo
        STA Source
        LDA ArgHi
        STA Source+1
        LDA #0
        STA DigitCount
        LDY #0
ConvertCopy
        LDA (Source),Y
        STA Work,Y
        INY
        CPY InputLen
        BNE ConvertCopy
        LDA #0
        STA Work,Y    ; Byte di guardia (x51).
        INY
        STY WorkLen
        LDA SaveSource
        STA Source
        LDA SaveSource+1
        STA Source+1
ConvertDigit
        JSR Remainder10
        STA Digit
        CLC
        ADC #48
        LDX DigitCount
        STA ReverseText,X
        INC DigitCount
        JSR Quotient10
        JSR IsWorkZero
        BNE ConvertDigit
        LDX DigitCount
        DEX
        LDY #0
ConvertReverse
        LDA ReverseText,X
        STA DecimalText,Y
        INY
        DEX
        BPL ConvertReverse
        LDA #0
        STA DecimalText,Y
        LDX DigitCount
        CLC
        RTS
ConvertBad
        LDA #0
        STA DecimalText
        STA DigitCount
        LDX #0
        SEC
        RTS

; --------------------------------------------------
; Resto mod 10: riduzione mod 255, mod 5, parita'.
; Il riporto circolare codifica 0 anche come 255;
; poiche' 5 divide 255, non si crea ambiguita'.
; --------------------------------------------------
Remainder10
        LDA #0
        LDX #0
        LDY WorkLen
RemainderBytes
        CLC
        ADC Work,X
        ADC #0        ; Riporto circ. (no ovf).
        INX
        DEY
        BNE RemainderBytes
        STA SmallTemp
        AND #15
        STA SmallLow
        LDA SmallTemp
        LSR A
        LSR A
        LSR A
        LSR A
        CLC
        ADC SmallLow  ; 16=1 (mod 5): sum<=30.
RemainderFive
        CMP #5
        BCC RemainderParity
        SBC #5        ; CMP ha posto C=1.
        JMP RemainderFive
RemainderParity
        STA SmallLow  ; N mod 5 (tra 0 e 4).
        EOR Work
        AND #1
        BEQ RemainderKeep
        LDA SmallLow
        CLC
        ADC #5
        RTS
RemainderKeep
        LDA SmallLow
        RTS

; --------------------------------------------------
; Quotient10: Work <- (Work - Digit) / 10.
; Identita': M/10 = 51*(M/2)/255, con 10 | M.
; Un byte di guardia basta: 51*(M/2) < 26*256^n.
; --------------------------------------------------
Quotient10
        SEC
        LDA Work
        SBC Digit
        STA Work
        LDX InputLen
        LDY #1
SubtractDigit
        LDA Work,Y
        SBC #0
        STA Work,Y
        INY
        DEX           ; Non altera C (prestito).
        BNE SubtractDigit
        LDX WorkLen
        DEX
        CLC
DivideTwo
        ROR Work,X
        DEX
        BPL DivideTwo
        JSR CopyWork
        JSR ShiftWork ; 2X.
        JSR AddTemp   ; 3X.
        JSR CopyWork
        JSR ShiftWork
        JSR ShiftWork
        JSR ShiftWork
        JSR ShiftWork ; 16*(3X).
        JSR AddTemp   ; 17*(3X) = 51X.
        JSR Div255Exact
        RTS

CopyWork
        LDX #0
        LDY WorkLen
CopyWorkLoop
        LDA Work,X
        STA Temp,X
        INX
        DEY
        BNE CopyWorkLoop
        RTS

ShiftWork
        CLC
        LDX #0
        LDY WorkLen
ShiftWorkLoop
        ROL Work,X
        INX
        DEY
        BNE ShiftWorkLoop
        RTS

AddTemp
        CLC
        LDX #0
        LDY WorkLen
AddTempLoop
        LDA Work,X
        ADC Temp,X
        STA Work,X
        INX
        DEY
        BNE AddTempLoop
        RTS

; --------------------------------------------------
; Arazi-Naccache /255: complemento e somma fusi.
; PRE:  D=0; WorkLen=1..33; Work mult. di 255 >= 0.
; POST: Work = quoziente esatto, in loco (LE).
; A = cifra prec. del quoziente; C = 1 - prestito.
; INX, DEY, BNE, STA non alterano C (no CMP/CPX).
; --------------------------------------------------
Div255Exact
        LDA #0
        SEC
        LDX #0
        LDY WorkLen
Div255Loop
        SBC Work,X
        STA Work,X
        INX
        DEY
        BNE Div255Loop
        RTS

; Versione didattica in due passate (collaudo):
; calcola -Work mod 256^WorkLen, poi somme prefisse.
Div255Reference
        SEC
        LDX #0
        LDY WorkLen
Div255Complement
        LDA #0
        SBC Work,X
        STA Work,X
        INX
        DEY
        BNE Div255Complement
        CLC
        LDA #0
        LDX #0
        LDY WorkLen
Div255Prefix
        ADC Work,X
        STA Work,X
        INX
        DEY
        BNE Div255Prefix
        RTS

IsWorkZero
        LDA #0
        LDX WorkLen
        DEX
IsWorkZeroLoop
        ORA Work,X
        DEX
        BPL IsWorkZeroLoop
        CMP #0        ; Ricostruisce Z dopo DEX.
        RTS

; Stampa di servizio: X/Y ptr PETSCII term. da 0.
; Salva $FB/$FC; indice indipendente dal KERNAL.
PrintString
        STX ArgLo
        STY ArgHi
        LDA Source
        PHA
        LDA Source+1
        PHA
        LDA ArgLo
        STA Source
        LDA ArgHi
        STA Source+1
        LDA #0
        STA PrintIndex
PrintStringLoop
        LDY PrintIndex
        LDA (Source),Y
        BEQ PrintStringDone
        JSR PrintChr
        INC PrintIndex
        JMP PrintStringLoop
PrintStringDone
        PLA
        STA Source+1
        PLA
        STA Source
        RTS

; --------------------------------------------------
; Memoria di lavoro (nessuna chiamata BASIC/KERNAL
; da parte delle routine aritmetiche).
; --------------------------------------------------
InputLen       BYTE 0
WorkLen        BYTE 0
DigitCount     BYTE 0
Digit          BYTE 0
SmallTemp      BYTE 0
SmallLow       BYTE 0
ArgLo          BYTE 0
ArgHi          BYTE 0
SaveSource     BYTE 0,0
PrintIndex     BYTE 0
DemoCase       BYTE 0
DemoPage       BYTE 0
Work           DCB MaxBytes+1, 0
Temp           DCB MaxBytes+1, 0
ReverseText    DCB MaxText, 0
DecimalText    DCB MaxText+1, 0

; --------------------------------------------------
; Testi PETSCII espliciti (editor irrilevante).
; Tabelle e messaggi verificati da tests/build.py.
; --------------------------------------------------
        IncAsm "AN_data.asm"
; --------------------------------------------------
; EOF: AN_BCD.asm
; --------------------------------------------------
