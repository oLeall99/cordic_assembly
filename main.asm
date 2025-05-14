; Implementação do Algoritmo CORDIC
; Para calcular seno e cosseno de um ângulo qualquer
; Entrada: ANGLE0, ANGLE1 (ângulo em formato Q3.13)
; Saída: SEN0, SEN1 (resultado do seno), COS0, COS1 (resultado do cosseno)

; Alocação de memória
COS0   EQU    30h ; COS LSB (byte menos significativo)
COS1   EQU    31h ; COS MSB (byte mais significativo)
SEN0   EQU    40h ; SEN LSB (byte menos significativo)
SEN1   EQU    41h ; SEN MSB (byte mais significativo)
ANGLE0 EQU    20h ; ANGLE LSB (byte menos significativo do ângulo)
ANGLE1 EQU    21h ; ANGLE MSB (byte mais significativo do ângulo)
XTMP0  EQU    3Ah ; X temporário LSB
XTMP1  EQU    3Bh ; X temporário MSB
YTMP0  EQU    4Ah ; Y temporário LSB
YTMP1  EQU    4Bh ; Y temporário MSB
X0     EQU    3Dh ; X atual LSB
X1     EQU    3Eh ; X atual MSB
Y0     EQU    4Dh ; Y atual LSB
Y1     EQU    4Eh ; Y atual MSB
Z0     EQU    2Dh ; Z atual (ângulo ajustado) LSB
Z1     EQU    2Eh ; Z atual (ângulo ajustado) MSB
E0     EQU    6Eh ; Valor atual da tabela arctg(k) LSB
E1     EQU    6Fh ; Valor atual da tabela arctg(k) MSB
COS_FINAL0 EQU 32h ; Resultado final de COS LSB (byte menos significativo)
COS_FINAL1 EQU 33h ; Resultado final de COS MSB (byte mais significativo)
SEN_FINAL0 EQU 42h ; Resultado final de SEN LSB (byte menos significativo)
SEN_FINAL1 EQU 43h ; Resultado final de SEN MSB (byte mais significativo)
K      EQU    1Fh ; Índice da iteração atual

; Constantes
PI2_LSB  EQU  42H   ; π/2 em formato Q3.13 LSB
PI2_MSB  EQU  32H   ; π/2 em formato Q3.13 MSB

ORG 0000H
LJMP START

; Strings armazenadas na ROM
ORG 0020h
STR_COS:
    DB "COS "
    DB 00h        ; Marca null no fim da String
STR_SEN:
    DB "SEN "
    DB 00h        ; Marca null no fim da String

; Tabela de arctangentes para CORDIC (formato Q3.13)
ORG 0030H
E_00: 
    DB 22H, 19H     ; atan(2^0)  = 0,7853981633974483
    DB 0D6H, 0EH    ; atan(2^-1) = 0,4636476090008061
    DB 0D7H, 07H    ; atan(2^-2) = 0,24497866312686414
    DB 0FBH, 03H    ; atan(2^-3) = 0,12435499454676144
    DB 0FFH, 01H    ; atan(2^-4) = 0,06241880999595735
    DB 00H, 01H     ; atan(2^-5) = 0,031239833430268277
    DB 80H, 00H     ; atan(2^-6) = 0,015623728620476831
    DB 40H, 00H     ; atan(2^-7) = 0,007812341060101111
    DB 20H, 00H     ; atan(2^-8) = 0,0039062301319669718
    DB 10H, 00H     ; atan(2^-9) = 0,0019531225164788188
    DB 08H, 00H     ; atan(2^-10) = 0,0009765621895593195
    DB 04H, 00H     ; atan(2^-11) = 0,0004882812111948983
    DB 02H, 00H     ; atan(2^-12) = 0,00024414062014936177
    DB 01H, 00H     ; atan(2^-13) = 0,00012207031189367021

ORG 0100H
START:
    ; Limpa todas as variáveis antes de começar
    MOV COS0, #00H
    MOV COS1, #00H
    MOV SEN0, #00H
    MOV SEN1, #00H
    MOV XTMP0, #00H
    MOV XTMP1, #00H
    MOV YTMP0, #00H
    MOV YTMP1, #00H
    MOV X0, #00H
    MOV X1, #00H
    MOV Y0, #00H
    MOV Y1, #00H
    MOV Z0, #00H
    MOV Z1, #00H
    MOV E0, #00H
    MOV E1, #00H
    MOV K, #00H
    MOV R2, #00H
    MOV R3, #00H

    ; Configura o ângulo de teste para 0x098C
    MOV ANGLE0, #8Ch
    MOV ANGLE1, #09h
    
    ; Inicializa X = 0x136F (X1:X0), Y = 0x0000
    MOV X0, #6FH        ; X LSB (0x6F)
    MOV X1, #13H        ; X MSB (0x13)
    MOV Y0, #00H        ; Y LSB
    MOV Y1, #00H        ; Y MSB
    
    ; Fator de escala K = 0.607253 já está incluído no valor inicial de X
    MOV R2, #0          ; Indicador de quadrante

    ; Normaliza o ângulo para [-π/2, π/2]
    CLR C               ; Limpa carry para subtração
    MOV A, ANGLE0       
    SUBB A, #PI2_LSB    
    MOV Z0, A           
    MOV A, ANGLE1       
    SUBB A, #PI2_MSB    
    MOV Z1, A           

    JC ADD_PI_DIV_2     ; Se ângulo < π/2, ajusta

    ; Se o ângulo está entre π/2 e π
    MOV R2, #2          ; Define quadrante 2

    MOV A, Z0
    SUBB A, #PI2_LSB
    MOV Z0, A
    MOV A, Z1
    SUBB A, #PI2_MSB
    MOV Z1, A
    JC TWOS            ; Se estiver no quadrante 2

    ; Se o ângulo está entre π e 3π/2
    MOV R2, #3         ; Define quadrante 3

    MOV A, Z0
    SUBB A, #PI2_LSB
    MOV Z0, A
    MOV A, Z1
    SUBB A, #PI2_MSB
    MOV Z1, A
    JC ADD_PI_DIV_2    ; Se estiver no quadrante 3

    ; Se o ângulo está entre 3π/2 e 2π
    MOV R2, #1         ; Define quadrante 4

    MOV A, Z0
    SUBB A, #PI2_LSB
    MOV Z0, A
    MOV A, Z1
    SUBB A, #PI2_MSB
    MOV Z1, A

TWOS:
    ; Two's complement of Z
    MOV A, Z0
    CPL A
    ADD A, #1
    MOV Z0, A
    MOV A, Z1
    CPL A
    ADDC A, #0
    MOV Z1, A
    AJMP CORDIC_ALGO

ADD_PI_DIV_2:
    ; Adiciona PI/2 to Z
    MOV A, Z0
    ADD A, #PI2_LSB
    MOV Z0, A
    MOV A, Z1
    ADDC A, #PI2_MSB
    MOV Z1, A
    AJMP CORDIC_ALGO

CORDIC_ALGO: 
    MOV DPTR, #E_00    ; Inicializa o DPTR com o endereço da tabela de arctg (E_00)
    MOV R1, #0         ; Contador de iterações
    MOV K, #0          ; Inicializa o indice de rotacao

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

    ; Prepara R# com sinal de X, Y, Z
    MOV R3, #0
    
    ; Pega o bit de sinal de X
    MOV A, X1
    ANL A, #80H
    RL A
    ORL A, R3
    MOV R3, A

    ; Pega o bit de sinal de Y
    MOV A, Y1
    ANL A, #80H
    RL A
    RL A
    ORL A, R3
    MOV R3, A

    ; Pega o bit de sinal de Z
    MOV A, Z1
    ANL A, #80H
    RL A
    RL A
    RL A
    ORL A, R3
    MOV R3, A

    ; Incremenenta 0 R3
    INC R3

    ; Verifica se o Z é negativo
    MOV A, #80H
    ANL A, Z1
    JNZ ADD_Z

    ; Negate E for subtraction
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

; Seleciona o caso de acordo com os sinais de X, Y e Z em R3 
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

    ; Incrementa o K no contador de iteracao
    INC K
    INC R1

    ; Verifica se fez as 14 iterações
    MOV A, R1
    CJNE A, #0EH, NEXT_ITER
    LJMP CORDIC_END    ; Usa o long jump para chegar no end

NEXT_ITER:
    LJMP CORDIC_LOOP   ; usa o long jump para reiniciar o loop

; Subroutines
ABS_X:
    CLR C
    MOV A, XTMP0
    CPL A
    ADD A, #1
    MOV XTMP0, A
    MOV A, XTMP1
    CPL A
    ADDC A, #0
    MOV XTMP1, A
    RET

ABS_Y:
    CLR C
    MOV A, YTMP0
    CPL A
    ADD A, #1
    MOV YTMP0, A
    MOV A, YTMP1
    CPL A
    ADDC A, #0
    MOV YTMP1, A
    RET

SHIFT_XY:
    MOV A, R0
    JZ END_SHIFT_XY
    DEC R0

    ; Shift XTMP right
    CLR C
    MOV A, XTMP1
    RRC A
    MOV XTMP1, A
    MOV A, XTMP0
    RRC A
    MOV XTMP0, A

    ; Shift YTMP right
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

CORDIC_END:
    ; Verifica se o resultado precisa ser negativo de acordo com o quadrante
    MOV A, #3
    ANL A, R2
    JZ THE_END

    MOV A, #2
    ANL A, R2
    JZ TWOS_Y_FINAL

TWOS_X_FINAL:
    MOV A, X0
    CPL A
    ADD A, #1
    MOV X0, A
    MOV A, X1
    CPL A
    ADDC A, #0
    MOV X1, A

TWOS_Y_FINAL:
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
    ; Salva os resultados finais
    MOV COS0, X0
    MOV COS1, X1
    MOV SEN0, Y0
    MOV SEN1, Y1
    
    ; Inicializa o LCD e mostra os resultados
    ACALL CALL_CONVERT
    ACALL DISPLAY_RESULTS   ; Chama a rotina para mostrar resultados no LCD

LOOP_HALT:
    SJMP LOOP_HALT     ; Loop infinito

CALL_CONVERT:
    ACALL CONVERT_COS
    ACALL CONVERT_SEN
    RET


; Divisão de Q3.13 por 0x2000 (8192) e conversão para decimal puro (ex: 999)
; Entrada: valor Q3.13 em COS_FINAL1 (MSB) e COS_FINAL0 (LSB)
; Saída: resultado decimal em 32h (MSB) e 33h (LSB)

CONVERT_COS:
    MOV COS_FINAL1, COS1    ; MSB
    MOV COS_FINAL0, COS0    ; LSB

    ; Copiar para temporários
    MOV 6Ah, COS_FINAL1     ; MSB
    MOV 6Bh, COS_FINAL0     ; LSB

    ; Multiplicar por 1000 (0x03E8)
    ; Usar algoritmo de multiplicação manual (16x16 -> 32 bits)
    MOV 7Bh, #0E8h   ; 1000 LSB
    MOV 7Ah, #03h    ; 1000 MSB
    CLR A
    MOV 4Bh, A       ; Resultado 0 (byte 0 - LSB)
    MOV 4Ah, A       ; Resultado 1
    MOV 5Bh, A       ; Resultado 2
    MOV 5Ah, A       ; Resultado 3 (MSB)

    ; Multiplicação:  (6Ah,6Bh) * (7Ah,7Bh) -> (5Ah,5Bh,4Ah,4Bh)
    ; Multiplica LSB
    MOV A, 6Bh
    MOV B, 7Bh
    MUL AB
    MOV 4Bh, A       ; LSB
    MOV 4Ah, B
    ; Multiplica cruzado
    MOV A, 6Bh
    MOV B, 7Ah
    MUL AB
    ADD A, 4Ah
    MOV 4Ah, A
    MOV A, B
    ADDC A, 5Bh
    MOV 5Bh, A
    MOV A, 6Ah
    MOV B, 7Bh
    MUL AB
    ADD A, 4Ah
    MOV 4Ah, A
    MOV A, B
    ADDC A, 5Bh
    MOV 5Bh, A
    ; Multiplica MSB
    MOV A, 6Ah
    MOV B, 7Ah
    MUL AB
    ADD A, 5Bh
    MOV 5Bh, A
    MOV A, B
    ADDC A, 5Ah
    MOV 5Ah, A

    ; Calcular Result_LSB (33h)
    MOV A, 4Ah      ; A = B1 (4Ah do produto)
    MOV R0, A       ; Salva B1 em R0 temporariamente
    CLR C
    RR A            ; B1 >> 1
    RR A            ; B1 >> 2
    RR A            ; B1 >> 3
    RR A            ; B1 >> 4
    RR A            ; A = (B1 >> 5). Bits 0,1,2 de A são 4Ah[5,6,7]
    ANL A, #07h     ; Isola os 3 bits: A = (4Ah >> 5) & 0x07
    MOV R1, A       ; R1 = (4Ah >> 5) & 0x07

    MOV A, 5Bh      ; A = B2 (5Bh do produto)
    ANL A, #1Fh     ; A = (5Bh & 0x1F) (pega os 5 bits inferiores de 5Bh: 5Bh[4:0])
    CLR C           ; Limpa o carry antes de rotacionar para a esquerda
    RL A            ; (5Bh[4:0]) << 1
    RL A            ; (5Bh[4:0]) << 2
    RL A            ; A = (5Bh[4:0]) << 3. Bits 3-7 de A são 5Bh[0-4] deslocados
    ANL A, #0F8h    ; Isola os 5 bits superiores: A = ((5Bh & 0x1F) << 3) & 0xF8
    
    ORL A, R1       ; A = (((5Bh & 0x1F) << 3) & 0xF8) | ((4Ah >> 5) & 0x07)
    MOV 33h, A      ; Armazena Result_LSB

    ; Calcular Result_MSB (32h)
    MOV A, 5Bh      ; A = B2 (5Bh do produto)
    CLR C
    RR A            ; B2 >> 1
    RR A            ; B2 >> 2
    RR A            ; B2 >> 3
    RR A            ; B2 >> 4
    RR A            ; A = (B2 >> 5)
    ANL A, #07h     ; Isola os 3 bits: A = (5Bh >> 5) & 0x07
    MOV R0, A       ; R0 = (5Bh >> 5) & 0x07

    MOV A, 5Ah      ; A = B3 (5Ah do produto)
    ANL A, #1Fh     ; A = (5Ah & 0x1F)
    CLR C
    RL A            ; (5Ah & 0x1F) << 1
    RL A            ; (5Ah & 0x1F) << 2
    RL A            ; A = (5Ah & 0x1F) << 3
    ANL A, #0F8h    ; Isola os 5 bits superiores: A = ((5Ah & 0x1F) << 3) & 0xF8
    
    ORL A, R0       ; A = (((5Ah & 0x1F) << 3) & 0xF8) | ((5Bh >> 5) & 0x07)
    MOV 32h, A      ; Armazena Result_MSB

CONVERT_SEN:
    MOV SEN_FINAL1, SEN1   ; MSB
    MOV SEN_FINAL0, SEN0   ; LSB

    ; Copiar para temporários
    MOV 6Ah, SEN_FINAL1     ; MSB
    MOV 6Bh, SEN_FINAL0     ; LSB

    ; Multiplicar por 1000 (0x03E8)
    ; Usar algoritmo de multiplicação manual (16x16 -> 42 bits)
    MOV 7Bh, #0E8h   ; 1000 LSB
    MOV 7Ah, #03h    ; 1000 MSB
    CLR A
    MOV 4Bh, A       ; Resultado 0 (byte 0 - LSB)
    MOV 4Ah, A       ; Resultado 1
    MOV 5Bh, A       ; Resultado 2
    MOV 5Ah, A       ; Resultado 3 (MSB)

    ; Multiplicação:  (6Ah,6Bh) * (7Ah,7Bh) -> (5Ah,5Bh,4Ah,4Bh)
    ; Multiplica LSB
    MOV A, 6Bh
    MOV B, 7Bh
    MUL AB
    MOV 4Bh, A       ; LSB
    MOV 4Ah, B
    ; Multiplica cruzado
    MOV A, 6Bh
    MOV B, 7Ah
    MUL AB
    ADD A, 4Ah
    MOV 4Ah, A
    MOV A, B
    ADDC A, 5Bh
    MOV 5Bh, A
    MOV A, 6Ah
    MOV B, 7Bh
    MUL AB
    ADD A, 4Ah
    MOV 4Ah, A
    MOV A, B
    ADDC A, 5Bh
    MOV 5Bh, A
    ; Multiplica MSB
    MOV A, 6Ah
    MOV B, 7Ah
    MUL AB
    ADD A, 5Bh
    MOV 5Bh, A
    MOV A, B
    ADDC A, 5Ah
    MOV 5Ah, A

    ; Calcular Result_LSB (43h)
    MOV A, 4Ah      ; A = B1 (4Ah do produto)
    MOV R0, A       ; Salva B1 em R0 temporariamente
    CLR C
    RR A            ; B1 >> 1
    RR A            ; B1 >> 2
    RR A            ; B1 >> 3
    RR A            ; B1 >> 4
    RR A            ; A = (B1 >> 5). Bits 0,1,2 de A são 4Ah[5,6,7]
    ANL A, #07h     ; Isola os 3 bits: A = (4Ah >> 5) & 0x07
    MOV R1, A       ; R1 = (4Ah >> 5) & 0x07

    MOV A, 5Bh      ; A = B2 (5Bh do produto)
    ANL A, #1Fh     ; A = (5Bh & 0x1F) (pega os 5 bits inferiores de 5Bh: 5Bh[4:0])
    CLR C           ; Limpa o carry antes de rotacionar para a esquerda
    RL A            ; (5Bh[4:0]) << 1
    RL A            ; (5Bh[4:0]) << 2
    RL A            ; A = (5Bh[4:0]) << 3. Bits 3-7 de A são 5Bh[0-4] deslocados
    ANL A, #0F8h    ; Isola os 5 bits superiores: A = ((5Bh & 0x1F) << 3) & 0xF8
    
    ORL A, R1       ; A = (((5Bh & 0x1F) << 3) & 0xF8) | ((4Ah >> 5) & 0x07)
    MOV 43h, A      ; Armazena Result_LSB

    ; Calcular Result_MSB (42h)
    MOV A, 5Bh      ; A = B2 (5Bh do produto)
    CLR C
    RR A            ; B2 >> 1
    RR A            ; B2 >> 2
    RR A            ; B2 >> 3
    RR A            ; B2 >> 4
    RR A            ; A = (B2 >> 5)
    ANL A, #07h     ; Isola os 3 bits: A = (5Bh >> 5) & 0x07
    MOV R0, A       ; R0 = (5Bh >> 5) & 0x07

    MOV A, 5Ah      ; A = B3 (5Ah do produto)
    ANL A, #1Fh     ; A = (5Ah & 0x1F)
    CLR C
    RL A            ; (5Ah & 0x1F) << 1
    RL A            ; (5Ah & 0x1F) << 2
    RL A            ; A = (5Ah & 0x1F) << 3
    ANL A, #0F8h    ; Isola os 5 bits superiores: A = ((5Ah & 0x1F) << 3) & 0xF8
    
    ORL A, R0       ; A = (((5Ah & 0x1F) << 3) & 0xF8) | ((5Bh >> 5) & 0x07)
    MOV 42h, A      ; Armazena Result_MSB

; Rotina para exibir os resultados no LCD
DISPLAY_RESULTS:
    ; Incluir código do LCD do exemplo_lcd2.asm
    ; --- Mapeamento de Hardware (8051) ---
    RS      EQU     P1.3    ;Reg Select ligado em P1.3
    EN      EQU     P1.2    ;Enable ligado em P1.2

    ; Inicializa o LCD
    ACALL LCD_INIT
    
    ; Posiciona na primeira linha
    MOV A, #00h           ; Primeira posição da primeira linha
    ACALL POSICIONA_CURSOR
    
    ; Exibe "COS "
    MOV DPTR, #STR_COS
    ACALL ESCREVE_STRING_ROM
    
    ; Converte e exibe o valor do cosseno
    ACALL EXIBE_VALOR_COS
    
    ; Posiciona na segunda linha
    MOV A, #40h           ; Primeira posição da segunda linha
    ACALL POSICIONA_CURSOR
    
    ; Exibe "SEN "
    MOV DPTR, #STR_SEN
    ACALL ESCREVE_STRING_ROM
    
    ; Converte e exibe o valor do seno
    ACALL EXIBE_VALOR_SEN
    
    RET

; Rotina para converter e exibir o valor do cosseno
EXIBE_VALOR_COS:
    ; Verificar se o valor é negativo (bit mais significativo = 1)
    MOV A, 32h
    JNB ACC.7, COS_POSITIVO
    
    ; Se for negativo, exibir "-"
    MOV A, #'-'
    ACALL SEND_CHARACTER
    
    ; Converter para positivo (complemento de 2)
    MOV A, 33h        ; LSB
    CPL A
    ADD A, #01h
    MOV 33h, A
    MOV A, 32h        ; MSB
    CPL A
    ADDC A, #00h
    ANL A, #7Fh       ; Limpa o bit de sinal
    MOV 32h, A
    
COS_POSITIVO:
    ; Sempre mostramos o valor como 0.xxx
    MOV A, #'0'
    ACALL SEND_CHARACTER
    
    ; Exibir ponto decimal
    MOV A, #'.'
    ACALL SEND_CHARACTER
    
    ; Tratamento correto para 16 bits (MSB:LSB = 32h:33h)
    ; Extrair dígitos para formato 0.xxx
    
    ; Criamos um valor composto em R6:R7
    MOV R6, 32h    ; MSB em R6
    MOV R7, 33h    ; LSB em R7
    
    ; Divisão por 100 - usando algoritmo de divisão para 16 bits
    ; Resultado em R3 (centenas), R6:R7 terá o resto
    MOV R3, #0     ; Inicializa contador de centenas
    
DIV_COS_100:
    ; Verifica se o valor é >= 100
    CLR C
    MOV A, R7      ; LSB
    SUBB A, #100
    MOV R0, A      ; Guarda LSB temporário
    MOV A, R6      ; MSB
    SUBB A, #0     ; Subtrai carry
    JC FIM_DIV_COS_100  ; Se < 100, terminou
    
    ; Valor >= 100, subtrai 100 e incrementa contador
    MOV R6, A      ; Atualiza MSB
    MOV A, R0
    MOV R7, A     ; Atualiza LSB
    INC R3         ; Incrementa contador de centenas
    SJMP DIV_COS_100
    
FIM_DIV_COS_100:
    ; R3 tem as centenas, R6:R7 tem o resto
    ; Agora dividimos o resto por 10 para pegar as dezenas
    MOV R4, #0     ; Inicializa contador de dezenas
    
DIV_COS_10:
    ; Verifica se o valor é >= 10
    CLR C
    MOV A, R7      ; LSB
    SUBB A, #10
    MOV R0, A      ; Guarda LSB temporário
    MOV A, R6      ; MSB
    SUBB A, #0     ; Subtrai carry
    JC FIM_DIV_COS_10  ; Se < 10, terminou
    
    ; Valor >= 10, subtrai 10 e incrementa contador
    MOV R6, A      ; Atualiza MSB
    MOV A, R0
    MOV R7, A     ; Atualiza LSB
    INC R4         ; Incrementa contador de dezenas
    SJMP DIV_COS_10
    
FIM_DIV_COS_10:
    ; R4 tem as dezenas, R7 tem as unidades (R6 deve ser zero)
    ; Exibe os 3 dígitos
    
    ; Exibe centenas
    MOV A, R3
    ADD A, #'0'    ; Converte para ASCII
    ACALL SEND_CHARACTER
    
    ; Exibe dezenas
    MOV A, R4
    ADD A, #'0'    ; Converte para ASCII
    ACALL SEND_CHARACTER
    
    ; Exibe unidades
    MOV A, R7
    ADD A, #'0'    ; Converte para ASCII
    ACALL SEND_CHARACTER
    
    RET

; Rotina para converter e exibir o valor do seno
EXIBE_VALOR_SEN:
    ; Verificar se o valor é negativo (bit mais significativo = 1)
    MOV A, 42h
    JNB ACC.7, SEN_POSITIVO
    
    ; Se for negativo, exibir "-"
    MOV A, #'-'
    ACALL SEND_CHARACTER
    
    ; Converter para positivo (complemento de 2)
    MOV A, 43h        ; LSB
    CPL A
    ADD A, #01h
    MOV 43h, A
    MOV A, 42h        ; MSB
    CPL A
    ADDC A, #00h
    ANL A, #7Fh       ; Limpa o bit de sinal
    MOV 42h, A
    
SEN_POSITIVO:
    ; Sempre mostramos o valor como 0.xxx
    MOV A, #'0'
    ACALL SEND_CHARACTER
    
    ; Exibir ponto decimal
    MOV A, #'.'
    ACALL SEND_CHARACTER
    
    ; Tratamento correto para 16 bits (MSB:LSB = 42h:43h)
    ; Extrair dígitos para formato 0.xxx
    
    ; Criamos um valor composto em R6:R7
    MOV R6, 42h    ; MSB em R6
    MOV R7, 43h    ; LSB em R7
    
    ; Divisão por 100 - usando algoritmo de divisão para 16 bits
    ; Resultado em R3 (centenas), R6:R7 terá o resto
    MOV R3, #0     ; Inicializa contador de centenas
    
DIV_SEN_100:
    ; Verifica se o valor é >= 100
    CLR C
    MOV A, R7      ; LSB
    SUBB A, #100
    MOV R0, A      ; Guarda LSB temporário
    MOV A, R6      ; MSB
    SUBB A, #0     ; Subtrai carry
    JC FIM_DIV_SEN_100  ; Se < 100, terminou
    
    ; Valor >= 100, subtrai 100 e incrementa contador
    MOV R6, A      ; Atualiza MSB
    MOV A, R0
    MOV R7, A     ; Atualiza LSB
    INC R3         ; Incrementa contador de centenas
    SJMP DIV_SEN_100
    
FIM_DIV_SEN_100:
    ; R3 tem as centenas, R6:R7 tem o resto
    ; Agora dividimos o resto por 10 para pegar as dezenas
    MOV R4, #0     ; Inicializa contador de dezenas
    
DIV_SEN_10:
    ; Verifica se o valor é >= 10
    CLR C
    MOV A, R7      ; LSB
    SUBB A, #10
    MOV R0, A      ; Guarda LSB temporário
    MOV A, R6      ; MSB
    SUBB A, #0     ; Subtrai carry
    JC FIM_DIV_SEN_10  ; Se < 10, terminou
    
    ; Valor >= 10, subtrai 10 e incrementa contador
    MOV R6, A      ; Atualiza MSB
    MOV A, R0
    MOV R7, A     ; Atualiza LSB
    INC R4         ; Incrementa contador de dezenas
    SJMP DIV_SEN_10
    
FIM_DIV_SEN_10:
    ; R4 tem as dezenas, R7 tem as unidades (R6 deve ser zero)
    ; Exibe os 3 dígitos
    
    ; Exibe centenas
    MOV A, R3
    ADD A, #'0'    ; Converte para ASCII
    ACALL SEND_CHARACTER
    
    ; Exibe dezenas
    MOV A, R4
    ADD A, #'0'    ; Converte para ASCII
    ACALL SEND_CHARACTER
    
    ; Exibe unidades
    MOV A, R7
    ADD A, #'0'    ; Converte para ASCII
    ACALL SEND_CHARACTER
    
    RET

; --- Rotinas do LCD (baseadas no exemplo_lcd2.asm) ---
; Inicializa o LCD
LCD_INIT:
    CLR RS      ; clear RS - indicates that instructions are being sent to the module

    ; function set  
    CLR P1.7        ; |
    CLR P1.6        ; |
    SETB P1.5       ; |
    CLR P1.4        ; | high nibble set

    SETB EN     ; |
    CLR EN      ; | negative edge on E

    CALL DELAY      ; wait for BF to clear   
                    ; function set sent for first time - tells module to go into 4-bit mode

    SETB EN     ; |
    CLR EN      ; | negative edge on E

    SETB P1.7       ; low nibble set (only P1.7 needed to be changed)

    SETB EN     ; |
    CLR EN      ; | negative edge on E

    CALL DELAY      ; wait for BF to clear

    ; entry mode set
    ; set to increment with no shift
    CLR P1.7        ; |
    CLR P1.6        ; |
    CLR P1.5        ; |
    CLR P1.4        ; | high nibble set

    SETB EN     ; |
    CLR EN      ; | negative edge on E

    SETB P1.6       ; |
    SETB P1.5       ; |low nibble set

    SETB EN     ; |
    CLR EN      ; | negative edge on E

    CALL DELAY      ; wait for BF to clear

    ; display on/off control
    ; the display is turned on, the cursor is turned on and blinking is turned on
    CLR P1.7        ; |
    CLR P1.6        ; |
    CLR P1.5        ; |
    CLR P1.4        ; | high nibble set

    SETB EN     ; |
    CLR EN      ; | negative edge on E

    SETB P1.7       ; |
    SETB P1.6       ; |
    SETB P1.5       ; |
    SETB P1.4       ; | low nibble set

    SETB EN     ; |
    CLR EN      ; | negative edge on E

    CALL DELAY      ; wait for BF to clear
    RET

; Envia um caractere para o LCD
SEND_CHARACTER:
    SETB RS         ; setb RS - indicates that data is being sent to module
    MOV C, ACC.7        ; |
    MOV P1.7, C         ; |
    MOV C, ACC.6        ; |
    MOV P1.6, C         ; |
    MOV C, ACC.5        ; |
    MOV P1.5, C         ; |
    MOV C, ACC.4        ; |
    MOV P1.4, C         ; | high nibble set

    SETB EN         ; |
    CLR EN          ; | negative edge on E

    MOV C, ACC.3        ; |
    MOV P1.7, C         ; |
    MOV C, ACC.2        ; |
    MOV P1.6, C         ; |
    MOV C, ACC.1        ; |
    MOV P1.5, C         ; |
    MOV C, ACC.0        ; |
    MOV P1.4, C         ; | low nibble set

    SETB EN         ; |
    CLR EN          ; | negative edge on E

    CALL DELAY          ; wait for BF to clear
    RET

; Posiciona o cursor na posição especificada
POSICIONA_CURSOR:
    CLR RS          ; clear RS - indicates that instruction is being sent to module
    SETB P1.7           ; |
    MOV C, ACC.6        ; |
    MOV P1.6, C         ; |
    MOV C, ACC.5        ; |
    MOV P1.5, C         ; |
    MOV C, ACC.4        ; |
    MOV P1.4, C         ; | high nibble set

    SETB EN         ; |
    CLR EN          ; | negative edge on E

    MOV C, ACC.3        ; |
    MOV P1.7, C         ; |
    MOV C, ACC.2        ; |
    MOV P1.6, C         ; |
    MOV C, ACC.1        ; |
    MOV P1.5, C         ; |
    MOV C, ACC.0        ; |
    MOV P1.4, C         ; | low nibble set

    SETB EN         ; |
    CLR EN          ; | negative edge on E

    CALL DELAY          ; wait for BF to clear
    RET

; Rotina de atraso para o LCD
DELAY:
    MOV R0, #50
    DJNZ R0, $
    RET

; Escreve uma string armazenada na ROM
ESCREVE_STRING_ROM:
    MOV R1, #00h
    ; Inicia a escrita da String no Display LCD
LOOP_ESCREVE:
    MOV A, R1
    MOVC A, @A+DPTR     ; Lê da memória de programa
    JZ FIM_ESCREVE      ; Se A for 0, então o fim dos dados foi alcançado - sai do loop
    ACALL SEND_CHARACTER ; Envia dados em A para o módulo LCD
    INC R1              ; Aponta para o próximo dado
    MOV A, R1
    JMP LOOP_ESCREVE    ; Repete
FIM_ESCREVE:
    RET

