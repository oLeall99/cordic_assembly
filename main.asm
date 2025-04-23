COS0   EQU    30h ; COS LSB
COS1   EQU    31h ; COS MSB
SEN0   EQU    40h ; SEN LSB
SEN1   EQU    41h ; SEN MSB
ANGLE0 EQU    20h ; ANGLE LSB
ANGLE1 EQU    21h ; ANGLE MSB
XTMP0  EQU    3Ah ; Valores Temporarios para X LSB
XTMP1  EQU    3Bh ; Valores Temporarios para X MSB
YTMP0  EQU    4Ah ; Valores Temporarios para Y LSB
YTMP1  EQU    4Bh ; Valores Temporarios para Y MSB
X0     EQU    3Dh ; Valor X atual LSB
X1     EQU    3Eh ; Valor X atual MSB
Y0     EQU    4Dh ; Valor Y atual LSB
Y1     EQU    4Eh ; Valor Y atual MSB
Z0     EQU    2Dh ; Valor Z (angulo ajustado) LSB
Z1     EQU    2Eh ; Valor Z (angulo ajustado) MSB
E0     EQU    6Eh ; Valor da tabela arctg(k) atual LSB
E1     EQU    6Fh ; Valor da tabela arctg(k) atual MSB
K      EQU    50h ; Indice da iteracao atual 

E_00: 
    DB 22H, 19H, 0D6H, 0EH, 0D7H, 07H, 0FBH, 03H
    DB 0FFH, 01H, 00H, 01H, 80H, 00H, 40H, 00H
    DB 20H, 00H, 10H, 00H, 08H, 00H, 04H, 00H
    DB 02H, 00H, 01H, 00H

ORG 0x0000

; constantes
   PI2_LSB  EQU  042h   ; π/2 em Q3.13 LSB
   PI2_MSB  EQU  032h   ; π/2 em Q3.13 MSB


START:
    ; Inicializa valores de teste 
	MOV ANGLE0, #8CH
	MOV ANGLE1, #09H
    
    ; Inicializa X = 0x136F (X1:X0), Y = 0x0000
    MOV X0, #0BAH         ; X LSB
    MOV X1, #04DH         ; X MSB
    MOV Y0, #00H         ; Y LSB
    MOV Y1, #00H         ; Y MSB
    MOV R2, #00H         ; indicador de sinal
    MOV XTMP0, #00H
    MOV XTMP1, #00H
    MOV YTMP0, #00H
    MOV YTMP1, #00H
    MOV Z0, #00H
    MOV Z1, #00H
    MOV E0, #00H
    MOV E1, #00H
    MOV K, #00H

    CLR C                ; Limpa o carry (borrow) para a subtracao com SUBB

    ; Subtrai PI / 2 ( PI / 2 = 0x3244) do angulo armazenado em ANGLE0 e ANGLE1
    MOV A, ANGLE0        ; Coloca o byte menos significativo do angulo em A 
    SUBB A, #PI2_LSB     ; Subtrai o LSB de PI/2
    MOV Z0, A            ; Salva o resultado no Z0
    MOV A, ANGLE1        ; Coloca o byte mais significativo do angulo em A 
    SUBB A, #PI2_MSB     ; Subtrai o MSB de PI/2 com carry
    MOV Z1, A            ; Salva o resultado no Z1

    JC ADD_PI_DIV_2      ; Se houve borrow (JC = Jump if Carry), entao angulo < PI / 2

    ; Se o angulo estiver entre PI/2 e PI:
    MOV  R2, #2        ; Seno positivo, cossento negativo

    MOV A, Z0
    SUBB A, #PI2_LSB     ; Subtrai LSB de PI / 2
    MOV Z0, A

    MOV A, Z1
    SUBB A, #PI2_MSB     ; Subtrai MSB de PI / 2
    MOV Z1, A
    JC TWOS              ; Se houver carry, está no 2º quadrante (PI/2 a PI)

    ; Caso Contrário, continua
    MOV R2, #3           ; Seno negativo, cosseno negativo

    MOV A, Z0
    SUBB A, #PI2_LSB     ; Subtrai LSB de PI / 2
    MOV Z0, A

    MOV A, Z1
    SUBB A, #PI2_MSB     ; Subtrai MSB de PI / 2
    MOV Z1, A
    JC ADD_PI_DIV_2      ; Se houve carry, está no 3º quadrante (PI a 3PI / 2)

    ; Ultimo caso: angulo esta entre 3PI / 2 e 2PI
    MOV R2, #1          ; Seno negativo, cosseno positivo

    MOV A, Z0
    SUBB A, #PI2_LSB    ; Subtrai LSB de PI / 2
    MOV Z0, A

    MOV A, Z1
    SUBB A, #PI2_MSB    ; Subtrai MSB de PI / 2
    MOV Z1, A

TWOS:
    MOV A, Z0            ; Pega o LSB de Z
    CPL A                ; Complementa os bits
    ADD A, #1            ; Soma 1 -> complemnto de dois
    MOV Z0, A            ; Salva de volta no Z0

    MOV A, Z1            ; Pega o MSB de Z
    CPL A                ; Complementa os bits
    ADDC A, #0           ; Soma com carry da operação anterior
    MOV Z1, A            ; Salva no Z1

    AJMP CORDIC_ALGO


ADD_PI_DIV_2:
    MOV A, Z0         ; Carrega o LSB de Z
    ADD A, #PI2_LSB       ; Soma o LSB de PI/2
    MOV Z0, A         ; Salva de volta em Z0

    MOV A, Z1         ; Carrega o MSB de Z
    ADDC A, #PI2_MSB     ; Soma com carry o MSB de PI/2
    MOV Z1, A         ; Salva de volta em Z1

    AJMP    CORDIC_ALGO

CORDIC_ALGO: 
    MOV DPTR, #E_00   ; Inicializa o DPTR com o endereço da tabela de arctg (E_00)
    MOV R1, #0        ; Contador de iterações
    MOV K, #0         ; Inicializa o indice de rotacao


CORDIC_LOOP:
    ; Armazena temporariamente K em R0
    MOV R0, K

    ; Salva os valores temporarios de X e Y
    MOV XTMP0, X0
    MOV XTMP1, X1
    MOV YTMP0, Y0
    MOV YTMP1, Y1

    ; Carrega constantes arctg(k) da tabela E_00
    MOV A, #0
    MOVC A, @A+DPTR
    MOV E0, A
    MOV A, #1
    MOVC A, @A+DPTR
    MOV E1, A
    INC DPTR
    INC DPTR

    ; Prepara R3 com sinal de X, Y, Z (bit mais significativo)
    MOV R3, #0
    
    MOV A, X1
    ANL A, #80H         ; Pega bit de sinal de X
    RL A 
    ORL A, R3
    MOV R3, A

    MOV A, Y1
    ANL A, #80H         ; Pega bit de sinal de Y
    RL A
    RL A
    ORL A, R3
    MOV R3, A

    MOV A, Z1
    ANL A, #80H         ; Pega bit de sinal de Z
    RL A
    RL A
    RL A 
    ORL A, R3
    MOV R3, A

    ; Incrementa o R3 para uso com DJNZ
    INC R3

    ; Verifica se Z é negativo (bit 7 setado)
    MOV A, #80H
    ANL A, Z1
    JNZ ADD_Z  ; Se Z negativo, pula inversao de e

    ; Inverte E para realizar a subtracao
    MOV A, E0
    CPL A
    ADD A, #1
    MOV E0, A

    MOV A, E1
    CPL A
    ADDC A, #0
    MOV E1, A


ADD_Z:
    ; Z = Z + E
    MOV A, E0
    ADD A, Z0
    MOV Z0, A

    MOV A, E1
    ADDC A, Z1
    MOV Z1, A

; ==========================================================
; === Selecao de caso baseado no sinal de X, Y e Z no R# ===
; ==========================================================

CASE1: 
    DJNZ R3, CASE2
    ACALL SHIFT_XY
    ACALL TWOS_Y_SHFTED
    AJMP ADD_XY

CASE2:
    DJNZ R3, CASE3
    ACALL ABS_X
    ACALL SHIFT_XY
    ACALL TWOS_X_SHFTED
    ACALL TWOS_Y_SHFTED
    AJMP ADD_XY

CASE3:
    DJNZ R3, CASE4
    ACALL ABS_Y
    ACALL SHIFT_XY
    AJMP ADD_XY

CASE4:
    DJNZ R3, CASE5
    ACALL ABS_X
    ACALL ABS_Y
    ACALL SHIFT_XY
    ACALL TWOS_X_SHFTED
    AJMP ADD_XY

CASE5:
    DJNZ R3, CASE6
    ACALL SHIFT_XY
    ACALL TWOS_X_SHFTED
    AJMP ADD_XY

CASE6:
    DJNZ R3, CASE7
    ACALL ABS_X
    ACALL SHIFT_XY
    AJMP ADD_XY

CASE7:
    DJNZ R3, CASE8
    ACALL ABS_Y
    ACALL SHIFT_XY
    ACALL TWOS_X_SHFTED
    ACALL TWOS_Y_SHFTED
    AJMP ADD_XY

CASE8:
    ACALL ABS_X
    ACALL ABS_Y
    ACALL SHIFT_XY
    ACALL TWOS_Y_SHFTED

ADD_XY:
    ; X = X + YTMP
    MOV A, YTMP0
    ADD A, X0
    MOV X0, A

    MOV A, YTMP1
    ADDC A, X1
    MOV X1, A

    ; Y = Y + XTMP
    MOV A, XTMP0
    ADD A, Y0
    MOV Y0, A

    MOV A, XTMP1
    ADDC A, Y1
    MOV Y1, A

    ; Incrementa k E R1
    INC K
    INC R1

    ; Se R1 < 14 (0EH), continua no loop
    CJNE R1, #0EH, LONG_JUMP

    ; Caso Contrário, encerra
    AJMP CORDIC_END

LONG_JUMP:
    AJMP CORDIC_LOOP

CORDIC_END:
    ; Verifica se a resposta precisa ser negada
    MOV A, #3     ; Deixa os sinais positivos se R2 = 0
    ANL A, R2
    JZ THE_END

    MOV A, #2     ; Pula negacao do cosseno se R2 = 1
    ANL A, R2
    JZ TWOS_Y

TWOS_X:
    MOV A, X0
    CPL A
    ADD A, #1
    MOV X0, A

    MOV A, X1
    CPL A
    ADDC A, #0
    MOV X1, A

TWOS_Y:
    MOV A, #1
    ANL A, R2
    JZ THE_END

    MOV A, Y0
    CPL A
    ADD A, #1
    MOV Y0, A

    MOV A, Y1
    CPL A
    ADDC A, #0
    MOV Y1, A

THE_END:
    AJMP THE_REAL_END

; |-----------------------------|
; |---> Subrotinas              |           
; |-----------------------------|

ABS_X:
    CLR C
    MOV A, XTMP0
    SUBB A, #1
    MOV XTMP0, A
    MOV A, XTMP1
    SUBB A, #0
    MOV XTMP1, A
    RET

; ---

ABS_Y:
    CLR C
    MOV A, YTMP0
    SUBB A, #1
    MOV YTMP0, A
    MOV A, YTMP1
    SUBB A, #0
    MOV YTMP1, A
    RET

; --- 

SHIFT_XY:
    MOV A, R0
    JZ END_SHIFT_XY      ; Se R0 = 0, termina
    DEC R0               ; Decrementa contador de shift

    ; shift XTMP 
    CLR C
    MOV A, XTMP1
    RRC A
    MOV XTMP1, A

    MOV A, XTMP0
    RRC A
    MOV XTMP0, A 
    
    ; shift YTMP
    CLR C
    MOV A, YTMP1
    RRC A
    MOV YTMP1, A 

    MOV A, YTMP0
    RRC A 
    MOV YTMP0, A

    AJMP SHIFT_XY

END_SHIFT_XY:
    RET

; ---

TWOS_X_SHFTED:
    MOV A, XTMP0
    CPL A 
    ADD A, #1
    MOV XTMP0, A

    MOV A, XTMP1
    CPL A 
    ADDC A, #0
    MOV XTMP1, A 
    RET

; ---

TWOS_Y_SHFTED:
    MOV A, YTMP0
    CPL A 
    ADD A, #1
    MOV YTMP0, A

    MOV A, YTMP1
    CPL A 
    ADDC A, #0
    MOV YTMP1, A 
    RET

; ---
THE_REAL_END:
    MOV COS0, X0
    MOV COS1, X1
    MOV SEN0, Y0
    MOV SEN1, Y1

LOOP_HALT:
    SJMP LOOP_HALT