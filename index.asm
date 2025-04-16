ORG 0000H   ; Início do programa

; === VARIÁVEIS ===
COS0    EQU 30H    ; Cos(?) LSB
COS1    EQU 31H    ; Cos(?) MSB
SEN0    EQU 40H    ; Sen(?) LSB
SEN1    EQU 41H    ; Sen(?) MSB

X0_TMP  EQU 32H
X1_TMP  EQU 33H
Y0_TMP  EQU 42H
Y1_TMP  EQU 43H
Z0      EQU 50H
Z1      EQU 51H
E0      EQU 38H
E1      EQU 39H
XTMP0   EQU 3AH
XTMP1   EQU 3BH
YTMP0   EQU 4AH
YTMP1   EQU 4BH
K       EQU 3EH

START:
    ; === Entrada: Z = ?/4 ? 0.7854 rad = 0x6477 (Q1.15) ===
	MOV Z0, #077H
	MOV Z1, #064H
    ; === Inicialização ===
    MOV X0_TMP, #0FH       ; X = K ? 0.607 * 32768 ? 0x4D0F
    MOV X1_TMP, #4DH
    MOV Y0_TMP, #00H
    MOV Y1_TMP, #00H
    MOV K, #00H

CORDIC_LOOP:
    ; Acessar ?_k da tabela
    MOV DPTR, #0100H
    MOV A, K
    RL A     ; K * 2 (2 bytes por entrada)
    MOVC A, @A+DPTR
    MOV E0, A
    INC DPTR
    MOVC A, @A+DPTR
    MOV E1, A

    ; Verifica sinal de Z1 (bit 7)
     MOV A, Z1
    JNB ACC.7, D_POS

D_NEG:
    ; Z = Z + ?
    MOV A, Z0
    ADD A, E0
    MOV Z0, A
    MOV A, Z1
    ADDC A, E1
    MOV Z1, A

    ; Copia Y para YTMP
    MOV A, Y1_TMP
    MOV YTMP1, A
    MOV A, Y0_TMP
    MOV YTMP0, A

    ; YTMP >> K
    MOV R0, K
SHIFT_Y:
    JZ SHIFT_DONE_Y
    CLR C
    MOV A, YTMP1
    RRC A
    MOV YTMP1, A
    MOV A, YTMP0
    RRC A
    MOV YTMP0, A
    DJNZ R0, SHIFT_Y
SHIFT_DONE_Y:

    ; X = X + YTMP
    MOV A, X0_TMP
    ADD A, YTMP0
    MOV X0_TMP, A
    MOV A, X1_TMP
    ADDC A, YTMP1
    MOV X1_TMP, A

    SJMP NEXT_ITER  ; <- Pula D_POS

D_POS:
    ; Z = Z - ?
    MOV A, Z0
    CLR C
    SUBB A, E0
    MOV Z0, A
    MOV A, Z1
    SUBB A, E1
    MOV Z1, A

    ; Copia X para XTMP
    MOV A, X1_TMP
    MOV XTMP1, A
    MOV A, X0_TMP
    MOV XTMP0, A

    ; XTMP >> K
    MOV R0, K
SHIFT_X:
    JZ SHIFT_DONE_X
    CLR C
    MOV A, XTMP1
    RRC A
    MOV XTMP1, A
    MOV A, XTMP0
    RRC A
    MOV XTMP0, A
    DJNZ R0, SHIFT_X
SHIFT_DONE_X:

    ; Y = Y + XTMP
    MOV A, Y0_TMP
    ADD A, XTMP0
    MOV Y0_TMP, A
    MOV A, Y1_TMP
    ADDC A, XTMP1
    MOV Y1_TMP, A


NEXT_ITER:
    INC K
    MOV A, K
    CJNE A, #0EH, CORDIC_LOOP

    ; === Armazena resultados ===
    MOV A, X0_TMP
    MOV COS0, A
    MOV A, X1_TMP
    MOV COS1, A

    MOV A, Y0_TMP
    MOV SEN0, A
    MOV A, Y1_TMP
    MOV SEN1, A

    SJMP $  ; Loop infinito para parar execução

; === TABELA DE ATAN(2^-k), Q1.15, little endian ===
ORG 0100H
ATAN_TABLE:
    DB 078H,064H  ; atan(2^-0)
    DB 048H,03BH  ; atan(2^-1)
    DB 05BH,01FH
    DB 0EAH,0FH
    DB 0FDH,07H
    DB 0FFH,03H
    DB 0FFH,01H
    DB 0FFH,00H
    DB 07FH,00H
    DB 040H,00H
    DB 020H,00H
    DB 010H,00H
    DB 008H,00H
    DB 004H,00H