; Dati demo PETSCII (tests/build.py). ASCII, MIT.
Title1
        BYTE $41,$52,$41,$5A,$49,$2D,$4E,$41
        BYTE $43,$43,$41,$43,$48,$45,$20,$2F
        BYTE $20,$4D,$4F,$53,$20,$36,$35,$30
        BYTE $32,$2D,$36,$35,$31,$30,$0D,$42
        BYTE $49,$4E,$41,$52,$49,$4F,$20,$2D
        BYTE $3E,$20,$44,$45,$43,$49,$4D,$41
        BYTE $4C,$45,$20,$2F,$20,$4B,$45,$52
        BYTE $4E,$41,$4C,$20,$24,$46,$46,$44
        BYTE $32,$0D,$0D,$00
Title2
        BYTE $41,$52,$41,$5A,$49,$2D,$4E,$41
        BYTE $43,$43,$41,$43,$48,$45,$20,$2F
        BYTE $20,$4D,$55,$4C,$54,$49,$50,$52
        BYTE $45,$43,$49,$53,$49,$4F,$4E,$45
        BYTE $0D,$53,$54,$45,$53,$53,$41,$20
        BYTE $52,$4F,$55,$54,$49,$4E,$45,$2C
        BYTE $20,$46,$49,$4E,$4F,$20,$41,$20
        BYTE $33,$32,$20,$42,$59,$54,$45,$0D
        BYTE $0D,$00
Prompt1
        BYTE $0D,$53,$50,$41,$5A,$49,$4F,$3A
        BYTE $20,$49,$4E,$54,$45,$52,$49,$20
        BYTE $41,$20,$36,$34,$2C,$20,$31,$32
        BYTE $38,$20,$45,$20,$32,$35,$36,$20
        BYTE $42,$49,$54,$00
Prompt2
        BYTE $0D,$53,$50,$41,$5A,$49,$4F,$3A
        BYTE $20,$52,$49,$54,$4F,$52,$4E,$4F
        BYTE $20,$41,$4C,$20,$42,$41,$53,$49
        BYTE $43,$00
ErrorText
        BYTE $45,$52,$52,$4F,$52,$45,$3A,$20
        BYTE $4C,$55,$4E,$47,$48,$45,$5A,$5A
        BYTE $41,$20,$4E,$4F,$4E,$20,$56,$41
        BYTE $4C,$49,$44,$41,$00
Name0
        BYTE $5A,$45,$52,$4F,$3A,$20,$00
Value0
        BYTE $00
Name1
        BYTE $55,$4E,$4F,$3A,$20,$00
Value1
        BYTE $01
Name2
        BYTE $4E,$4F,$56,$45,$3A,$20,$00
Value2
        BYTE $09
Name3
        BYTE $44,$49,$45,$43,$49,$3A,$20,$00
Value3
        BYTE $0A
Name4
        BYTE $32,$35,$35,$3A,$20,$00
Value4
        BYTE $FF
Name5
        BYTE $32,$35,$36,$3A,$20,$00
Value5
        BYTE $00,$01
Name6
        BYTE $4D,$41,$58,$20,$31,$36,$20,$42
        BYTE $49,$54,$3A,$20,$00
Value6
        BYTE $FF,$FF
Name7
        BYTE $4D,$41,$58,$20,$33,$32,$20,$42
        BYTE $49,$54,$3A,$20,$00
Value7
        BYTE $FF,$FF,$FF,$FF
Name8
        BYTE $4D,$41,$58,$20,$36,$34,$20,$42
        BYTE $49,$54,$3A,$0D,$00
Value8
        BYTE $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
Name9
        BYTE $0D,$4D,$41,$58,$20,$31,$32,$38
        BYTE $20,$42,$49,$54,$3A,$0D,$00
Value9
        BYTE $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        BYTE $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
Name10
        BYTE $0D,$4D,$41,$58,$20,$32,$35,$36
        BYTE $20,$42,$49,$54,$3A,$0D,$00
Value10
        BYTE $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        BYTE $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        BYTE $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        BYTE $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
NameLo
        BYTE <Name0,<Name1,<Name2,<Name3
        BYTE <Name4,<Name5,<Name6,<Name7
        BYTE <Name8,<Name9,<Name10
NameHi
        BYTE >Name0,>Name1,>Name2,>Name3
        BYTE >Name4,>Name5,>Name6,>Name7
        BYTE >Name8,>Name9,>Name10
ValueLo
        BYTE <Value0,<Value1,<Value2,<Value3
        BYTE <Value4,<Value5,<Value6,<Value7
        BYTE <Value8,<Value9,<Value10
ValueHi
        BYTE >Value0,>Value1,>Value2,>Value3
        BYTE >Value4,>Value5,>Value6,>Value7
        BYTE >Value8,>Value9,>Value10
ValueLen
        BYTE 1,1,1,1,1,2,2,4,8,16,32
