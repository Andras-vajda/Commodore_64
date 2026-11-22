; Confronto sperimentale: Horner binario con addizioni BCD del MOS 6502.
; ASCII, commenti italiani, licenza MIT come il programma principale.
; Non e' una sostituzione della routine dell'articolo.
; Ingresso A=n (1..32), X/Y=indirizzo LE. Uscita BCDText, X=cifre, C=0.
; Sorgente disgiunta dai buffer, $FB/$FC e stack. Puntatore ripristinato.
; SED richiede protezione del contesto: IRQ mascherati durante il nucleo,
; I ripristinato, D=0 in uscita. Nessuna simulazione degli NMI nel test.
        * = $8000
ConvertBCD
        PHP
        CLD
        CMP #1
        BCC BCDBad
        CMP #33
        BCS BCDBad
        STA BCDInputLen
        STX BCDArgLo
        STY BCDArgHi
        LDA $FB
        STA BCDSave
        LDA $FC
        STA BCDSave+1
        LDA BCDArgLo
        STA $FB
        LDA BCDArgHi
        STA $FC
        LDY #0
BCDCopy
        LDA ($FB),Y
        STA BCDBin,Y
        INY
        CPY BCDInputLen
        BNE BCDCopy
        LDA BCDSave
        STA $FB
        LDA BCDSave+1
        STA $FC
        LDX BCDInputLen
        LDA BCDLengths,X
        STA BCDLen
        TAX
        LDA #0
        STA BCDCount
BCDZero
        DEX
        STA BCDBuffer,X
        BNE BCDZero
        LDA BCDInputLen
        SEC
        SBC #1
        STA BCDInputIndex
        SEI
        SED
        JMP BCDByte
BCDBad
        PLP
        CLD
        LDA #0
        STA BCDText
        LDX #0
        SEC
        RTS
BCDByte
        LDX BCDInputIndex
        LDA BCDBin,X
        STA BCDCurrent
        LDA #8
        STA BCDBits
BCDBit
        ASL BCDCurrent
        LDX #0
        LDY BCDLen
BCDDouble
        LDA BCDBuffer,X
        ADC BCDBuffer,X
        STA BCDBuffer,X
        INX
        DEY
        BNE BCDDouble
        DEC BCDBits
        BNE BCDBit
        DEC BCDInputIndex
        BPL BCDByte
        CLD
        PLP
        CLD
        LDX BCDLen
        DEX
BCDToText
        LDA BCDBuffer,X
        LSR A
        LSR A
        LSR A
        LSR A
        JSR BCDEmit
        LDA BCDBuffer,X
        AND #15
        JSR BCDEmit
        DEX
        BPL BCDToText
        LDY BCDCount
        BNE BCDEnd
        LDA #48
        STA BCDText
        INY
BCDEnd
        LDA #0
        STA BCDText,Y
        TYA
        TAX
        CLC
        RTS
BCDEmit
        LDY BCDCount
        BNE BCDStore
        CMP #0
        BEQ BCDEmitEnd
BCDStore
        ORA #48
        STA BCDText,Y
        INC BCDCount
BCDEmitEnd
        RTS
BCDInputLen   BYTE 0
BCDArgLo      BYTE 0
BCDArgHi      BYTE 0
BCDSave       BYTES 2,0
BCDLen        BYTE 0
BCDCount      BYTE 0
BCDInputIndex BYTE 0
BCDCurrent   BYTE 0
BCDBits      BYTE 0
BCDBin       BYTES 32,0
BCDBuffer    BYTES 39,0
BCDText      BYTES 79,0
; Capienza: ceil(cifre(256^n-1)/2), n=0..32.
BCDLengths
        BYTE 0,2,3,4,5,7,8,9,10,11,13,14,15,16,17,19,20
        BYTE 21,22,23,25,26,27,28,29,31,32,33,34,35,37,38,39
