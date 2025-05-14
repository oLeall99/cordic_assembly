; Divisão de Q3.13 por 0x2000 (8192) e conversão para decimal puro (ex: 999)
; Entrada: valor Q3.13 em 30h (MSB) e 31h (LSB)
; Saída: resultado decimal em 32h (MSB) e 33h (LSB)

ORG 0000h
LJMP main

ORG 0030h
main:
    ; Exemplo: 0x1FFE (8190) em Q3.13
    MOV 30h, #1Fh    ; MSB
    MOV 31h, #FEh    ; LSB

    ; Copiar para temporários
    MOV 34h, 30h     ; MSB
    MOV 35h, 31h     ; LSB

    ; Multiplicar por 1000 (0x03E8)
    ; Usar algoritmo de multiplicação manual (16x16 -> 32 bits)
    MOV 36h, #0E8h   ; 1000 LSB
    MOV 37h, #03h    ; 1000 MSB
    CLR A
    MOV 38h, A       ; Resultado 0 (byte 0 - LSB)
    MOV 39h, A       ; Resultado 1
    MOV 3Ah, A       ; Resultado 2
    MOV 3Bh, A       ; Resultado 3 (MSB)

    ; Multiplicação:  (34h,35h) * (37h,36h) -> (3Bh,3Ah,39h,38h)
    ; Multiplica LSB
    MOV A, 35h
    MOV B, 36h
    MUL AB
    MOV 38h, A       ; LSB
    MOV 39h, B
    ; Multiplica cruzado
    MOV A, 35h
    MOV B, 37h
    MUL AB
    ADD A, 39h
    MOV 39h, A
    MOV A, B
    ADDC A, 3Ah
    MOV 3Ah, A
    MOV A, 34h
    MOV B, 36h
    MUL AB
    ADD A, 39h
    MOV 39h, A
    MOV A, B
    ADDC A, 3Ah
    MOV 3Ah, A
    ; Multiplica MSB
    MOV A, 34h
    MOV B, 37h
    MUL AB
    ADD A, 3Ah
    MOV 3Ah, A
    MOV A, B
    ADDC A, 3Bh
    MOV 3Bh, A

    ; Agora (3Bh,3Ah,39h,38h) tem o produto (entrada * 1000)
    ; Vamos dividir por 8192 (0x2000) deslocando 13 bits para a direita
    ; O resultado será truncado.
    ; Resultado em 32h (MSB) e 33h (LSB)
    ; Result_LSB (33h) = ((39h >> 5) & 0x07) | (((3Ah & 0x1F) << 3) & 0xF8)
    ; Result_MSB (32h) = ((3Ah >> 5) & 0x07) | (((3Bh & 0x1F) << 3) & 0xF8)

    ; Calcular Result_LSB (33h)
    MOV A, 39h      ; A = B1 (39h do produto)
    MOV R0, A       ; Salva B1 em R0 temporariamente
    CLR C
    RR A            ; B1 >> 1
    RR A            ; B1 >> 2
    RR A            ; B1 >> 3
    RR A            ; B1 >> 4
    RR A            ; A = (B1 >> 5). Bits 0,1,2 de A são 39h[5,6,7]
    ANL A, #07h     ; Isola os 3 bits: A = (39h >> 5) & 0x07
    MOV R1, A       ; R1 = (39h >> 5) & 0x07

    MOV A, 3Ah      ; A = B2 (3Ah do produto)
    ANL A, #1Fh     ; A = (3Ah & 0x1F) (pega os 5 bits inferiores de 3Ah: 3Ah[4:0])
    CLR C           ; Limpa o carry antes de rotacionar para a esquerda
    RL A            ; (3Ah[4:0]) << 1
    RL A            ; (3Ah[4:0]) << 2
    RL A            ; A = (3Ah[4:0]) << 3. Bits 3-7 de A são 3Ah[0-4] deslocados
    ANL A, #0F8h    ; Isola os 5 bits superiores: A = ((3Ah & 0x1F) << 3) & 0xF8
    
    ORL A, R1       ; A = (((3Ah & 0x1F) << 3) & 0xF8) | ((39h >> 5) & 0x07)
    MOV 33h, A      ; Armazena Result_LSB

    ; Calcular Result_MSB (32h)
    MOV A, 3Ah      ; A = B2 (3Ah do produto)
    CLR C
    RR A            ; B2 >> 1
    RR A            ; B2 >> 2
    RR A            ; B2 >> 3
    RR A            ; B2 >> 4
    RR A            ; A = (B2 >> 5)
    ANL A, #07h     ; Isola os 3 bits: A = (3Ah >> 5) & 0x07
    MOV R0, A       ; R0 = (3Ah >> 5) & 0x07

    MOV A, 3Bh      ; A = B3 (3Bh do produto)
    ANL A, #1Fh     ; A = (3Bh & 0x1F)
    CLR C
    RL A            ; (3Bh & 0x1F) << 1
    RL A            ; (3Bh & 0x1F) << 2
    RL A            ; A = (3Bh & 0x1F) << 3
    ANL A, #0F8h    ; Isola os 5 bits superiores: A = ((3Bh & 0x1F) << 3) & 0xF8
    
    ORL A, R0       ; A = (((3Bh & 0x1F) << 3) & 0xF8) | ((3Ah >> 5) & 0x07)
    MOV 32h, A      ; Armazena Result_MSB

    SJMP $           ; Loop infinito
END
