; Implementação do Algoritmo CORDIC para EdSim51
; Calcula seno e cosseno de um ângulo usando algoritmo CORDIC
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
K      EQU    50h ; Índice da iteração atual

; Constantes
PI2_LSB  EQU  42H   ; π/2 em formato Q3.13 LSB
PI2_MSB  EQU  32H   ; π/2 em formato Q3.13 MSB

ORG 0000H
LJMP START

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
    ; Inicializa valores de teste 
    MOV ANGLE0, #8CH    ; Example angle (approximately 45 degrees)
    MOV ANGLE1, #09H
    
    ; Inicializa X = 0x136F (X1:X0), Y = 0x0000
    ; Isso representa o vetor inicial [1, 0] escalado pelo fator K = 0.607253
    MOV X0, #6FH        ; X LSB (0x6F)
    MOV X1, #13H        ; X MSB (0x13) - Aproximadamente 1.0 em Q3.13
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
    ; Add PI/2 to Z
    MOV A, Z0
    ADD A, #PI2_LSB
    MOV Z0, A
    MOV A, Z1
    ADDC A, #PI2_MSB
    MOV Z1, A
    AJMP CORDIC_ALGO

CORDIC_ALGO: 
    MOV DPTR, #E_00    ; Initialize DPTR with arctangent table
    MOV R1, #0         ; Iteration counter
    MOV K, #0          ; Initialize rotation index

CORDIC_LOOP:
    ; Store K temporarily in R0
    MOV R0, K

    ; Save current X and Y values
    MOV XTMP0, X0
    MOV XTMP1, X1
    MOV YTMP0, Y0
    MOV YTMP1, Y1

    ; Load arctangent constants from table
    MOV A, #0
    MOVC A, @A+DPTR
    MOV E0, A
    MOV A, #1
    MOVC A, @A+DPTR
    MOV E1, A
    INC DPTR
    INC DPTR

    ; Prepare R3 with sign bits of X, Y, Z
    MOV R3, #0
    
    ; Get X sign bit
    MOV A, X1
    ANL A, #80H
    RL A
    ORL A, R3
    MOV R3, A

    ; Get Y sign bit
    MOV A, Y1
    ANL A, #80H
    RL A
    RL A
    ORL A, R3
    MOV R3, A

    ; Get Z sign bit
    MOV A, Z1
    ANL A, #80H
    RL A
    RL A
    RL A
    ORL A, R3
    MOV R3, A

    ; Increment R3 for DJNZ usage
    INC R3

    ; Check if Z is negative
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

; Case selection based on X, Y, Z signs in R3
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

    ; Increment K and iteration counter
    INC K
    INC R1

    ; Check if we've completed 14 iterations
    MOV A, R1
    CJNE A, #0EH, NEXT_ITER
    LJMP CORDIC_END    ; Use long jump to reach end

NEXT_ITER:
    LJMP CORDIC_LOOP   ; Use long jump to continue loop

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
    ; Check if result needs to be negated based on quadrant
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
    ; Store final results
    MOV COS0, X0
    MOV COS1, X1
    MOV SEN0, Y0
    MOV SEN1, Y1

LOOP_HALT:
    SJMP LOOP_HALT     ; Infinite loop to hold results

END