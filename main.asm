COS0   EQU    30h ; COS LSB
COS1   EQU    31h ; COS MSB
SEN0   EQU    40h ; SEN LSB
SEN1   EQU    41h ; SEN MSB
ANGLE0 EQU    20h ; ANGLE LSB
ANGLE1 EQU    21h ; ANGLE MSB
XTMP0  EQU    3Ah
XTMP1  EQU    3Bh
YTMP0  EQU    4Ah
YTMP1  EQU    4Bh
X0     EQU    3Dh
X1     EQU    3Eh
Y0     EQU    4Dh
Y1     EQU    4Eh
Z0     EQU    2Dh
Z1     EQU    2Eh
E0     EQU    6Eh
E1     EQU    6Fh
K       EQU    50h

E_00: 
    DB 22H, 19H, 0D6H, 0EH, 0D7H, 07H, 0FBH, 03H
    DB 0FFH, 01H, 00H, 01H, 80H, 00H, 40H, 00H
    DB 20H, 00H, 10H, 00H, 08H, 00H, 04H, 00H
    DB 02H, 00H, 01H, 00H

ORG 0x0000


START:

    ; Inicializa X = 0x136F (X1:X0), Y = 0x0000
    MOV X0, #6FH         ; X LSB
    MOV X1, #13H         ; X MSB
    MOV Y0, #00H         ; Y LSB
    MOV Y1, #00H         ; Y MSB

    MOV R2, #00H         ; Inicializa o indicador de sinal

    CLR C                ; Limpa o carry (borrow) para a subtracao com SUBB

    ; Subtrai PI / 2 ( PI / 2 = 0x3244) do angulo armazenado em ANGLE0 e ANGLE1
    MOV A, ANGLE0        ; Coloca o byte menos significativo do angulo em A 
    SUBB A, #44H         ; Subtrai o LSB de PI/2
    MOV Z0, A            ; Salva o resultado no Z0

    MOV A, ANGLE1        ; Coloca o byte mais significativo do angulo em A 
    SUBB A, #32H         ; Subtrai o MSB de PI/2 com carry
    MOV Z1, A            ; Salva o resultado no Z1

    JC ADD_PI_DIV_2      ; Se houve borrow (JC = Jump if Carry), entao angulo < PI / 2

    ; Se o angulo estiver entre PI/2 e PI:
    MOV  R2, #02H        ; Seno positivo, cossento negativo

    MOV A, Z0
    SUBB A, #44H         ; Subtrai LSB de PI / 2
    MOV Z0, A

    MOV A, Z1
    SUBB A, #32H         ; Subtrai MSB de PI / 2
    MOV Z1, A
    JC TWOS              ; Se houver carry, está no 2º quadrante (PI/2 a PI)

    ; Caso Contrário, continua
    MOV R2, #3           ; Seno negativo, cosseno negativo

    MOV A, Z0
    SUBB A, #44H         ; Subtrai LSB de PI / 2
    MOV Z0, A

    MOV A, Z1
    SUBB A, #32H         ; Subtrai MSB de PI / 2
    MOV Z1, A
    JC ADD_PI_DIV_2      ; Se houve carry, está no 3º quadrante (PI a 3PI / 2)

    ; Ultimo caso: angulo esta entre 3PI / 2 e 2PI
    MOV R2, #1          ; Seno negativo, cosseno positivo

    MOV A, Z0
    SUBB A, #44H         ; Subtrai LSB de PI / 2
    MOV Z0, A

    MOV A, Z1
    SUBB A, #32H         ; Subtrai MSB de PI / 2
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
    ADD A, #44H       ; Soma o LSB de PI/2
    MOV Z0, A         ; Salva de volta em Z0

    MOV A, Z1         ; Carrega o MSB de Z
    ADDC A, #32H      ; Soma com carry o MSB de PI/2
    MOV Z1, A         ; Salva de volta em Z1

    RET               ; Retorna (caso for subrotina), ou continue o fluxo


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
    INC DPTR

    MOV A, #0
    MOVC A, @A+DPTR
    MOV E1, A
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

    