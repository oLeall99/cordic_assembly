; Constantes 
; 1000 -> Q3.13 = 0x03E8
MIL_MSB EQU 7EH
MIL_LSB EQU 7FH

MUL16:
    MOV MIL_MSB, #03H 
    MOV MIL_LSB, #E8H
    ; Multiplica R0:R1 * MIL_MSB:MIL_LSB (16 bits × 16 bits)

    ; Zera R4–R7
    clr a
    mov R4, a
    mov R5, a
    mov R6, a
    mov R7, a

    ; low1 * low2
    mov a, MIL_LSB
    mov b, R2
    mul ab
    mov R4, a        ; LSB
    mov R5, b        ; próximo byte

    ; low1 * high2
    mov a, MIL_LSB
    mov b, R3
    mul ab
    add a, R5
    mov R5, a
    mov a, b
    addc a, R6
    mov R6, a
    clr c
    mov a, R7
    addc a, #00
    mov R7, a

    ; high1 * low2
    mov a, MIL_MSB
    mov b, R2
    mul ab
    add a, R5
    mov R5, a
    mov a, b
    addc a, R6
    mov R6, a
    clr c
    mov a, R7
    addc a, #00
    mov R7, a

    ; high1 * high2
    mov a, MIL_MSB
    mov b, R3
    mul ab
    add a, R6
    mov R6, a
    mov a, b
    addc a, R7
    mov R7, a

    ; -------------------------------
    ; Push resultado na stack (R7 → R4)
    ; -------------------------------
    mov 0x20, R4
    mov 0x21, R5
    mov 0x22, R6
    mov 0x23, R7

    push 0x23
    push 0x22
    push 0x21
    push 0x20

    ret

; valor esperado:
; 03E7