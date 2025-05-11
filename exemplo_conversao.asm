        ORG 00H

        ; Número 0x1FFE = 8190
        MOV 70h, #0FEh       ; LSB original
        MOV 71h, #1Fh        ; MSB original

        ; Zera os dígitos
        MOV 72h, #0          ; milhares
        MOV 73h, #0          ; centenas
        MOV 74h, #0          ; dezenas
        MOV 75h, #0          ; unidades

        ; Cópia do número para trabalhar
        MOV R0, 70h          ; LSB
        MOV R1, 71h          ; MSB

CONVERT_LOOP:
        ; Verifica se o número é zero
        MOV A, R0
        ORL A, R1
        JZ FIM

        ; Subtrai 1000 (03E8h) se possível
        MOV A, R0
        CLR C
        SUBB A, #0E8h
        MOV B, A
        MOV A, R1
        SUBB A, #03h
        JC CHECK_100         ; Se < 1000, tenta centenas
        
        ; Atualiza o número
        MOV R0, B
        MOV R1, A
        INC 72h              ; Incrementa milhares
        SJMP CONVERT_LOOP

CHECK_100:
        ; Subtrai 100 (64h) se possível
        MOV A, R0
        CLR C
        SUBB A, #64h
        MOV B, A
        MOV A, R1
        SUBB A, #00h
        JC CHECK_10          ; Se < 100, tenta dezenas
        
        ; Atualiza o número
        MOV R0, B
        MOV R1, A
        INC 73h              ; Incrementa centenas
        SJMP CONVERT_LOOP

CHECK_10:
        ; Subtrai 10 (0Ah) se possível
        MOV A, R0
        CLR C
        SUBB A, #0Ah
        MOV B, A
        MOV A, R1
        SUBB A, #00h
        JC CHECK_1           ; Se < 10, trata unidades
        
        ; Atualiza o número
        MOV R0, B
        MOV R1, A
        INC 74h              ; Incrementa dezenas
        SJMP CONVERT_LOOP

CHECK_1:
        ; O que sobrou são as unidades
        MOV A, R0            ; O resto está em R0
        ADD A, 75h           ; Adiciona às unidades existentes
        MOV 75h, A
        
        ; Zera o número original pois já processamos tudo
        MOV R0, #0
        MOV R1, #0
        SJMP CONVERT_LOOP

FIM:
        SJMP $
        END
