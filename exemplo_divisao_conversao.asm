; Definições de endereços de memória
DIVIDENDO_LOW    EQU 30h  ; Byte baixo do dividendo
DIVIDENDO_HIGH   EQU 31h  ; Byte alto do dividendo
DIVISOR_LOW      EQU 32h  ; Byte baixo do divisor
DIVISOR_HIGH     EQU 33h  ; Byte alto do divisor
RESULTADO_LOW    EQU 34h  ; Byte baixo do resultado
RESULTADO_HIGH   EQU 35h  ; Byte alto do resultado
CONTADOR         EQU 36h  ; Contador para deslocamentos
TEMP_DIV_LOW     EQU 37h  ; Cópia temporária do byte baixo do dividendo
TEMP_DIV_HIGH    EQU 38h  ; Cópia temporária do byte alto do dividendo
TEMP_RESULT_LOW  EQU 39h  ; Byte baixo temporário do resultado
TEMP_RESULT_HIGH EQU 3Ah  ; Byte alto temporário do resultado
DECIMAL_MILHAR   EQU 40h  ; Valor Decimal do Resultado (MILHAR)
DECIMAL_CENTENA  EQU 41h  ; Valor Decimal do Resultado (CENTENA)
DECIMAL_DEZENA   EQU 42h  ; Valor Decimal do Resultado (DEZENA)
DECIMAL_UNIDADE  EQU 43h  ; Valor Decimal do Resultado (UNIDADE)

ORG 0000h
    LJMP MAIN

ORG 0030h
MAIN:
    ; Configurar dividendo 50000 (1FFE)
    MOV DIVIDENDO_LOW, #1Fh   ; Byte baixo do dividendo (3E8)
    MOV DIVIDENDO_HIGH, #FEh   ; Byte alto do dividendo (3E8)
    
    ; Configurar divisor 200 (2000)
    MOV DIVISOR_LOW, #00h      ; Byte baixo do divisor (0A)
    MOV DIVISOR_HIGH, #20h     ; Byte alto do divisor (0A)
    
    ; Chamar a rotina de divisão
    LCALL div16_16
    
    ; Depois da divisão, o resultado estará em RESULTADO_LOW e RESULTADO_HIGH
    ; O resultado esperado é 250 (FA hex)
    
    ; Converter o resultado hexadecimal para decimal
    LCALL TO_DECIMAL
    
    ; Aqui poderia adicionar código para verificar ou mostrar o resultado
    ; Para fins de depuração, você pode usar um breakpoint aqui
    
HALT:
    SJMP HALT        ; Loop infinito para encerrar o programa

; Incluir a rotina de divisão
ORG 0100h
div16_16:
    CLR C                      ; Limpa o carry inicialmente
    MOV TEMP_RESULT_LOW, #00h  ; Limpa a variável de resultado temporário inicialmente
    MOV TEMP_RESULT_HIGH, #00h ; Limpa a variável de resultado temporário inicialmente
    MOV CONTADOR, #00h         ; Limpa o contador, pois contará o número de bits deslocados à esquerda

div1:
    INC CONTADOR               ; Incrementa o contador para cada deslocamento à esquerda
    MOV A, DIVISOR_LOW         ; Move o byte baixo do divisor atual para o acumulador
    RLC A                      ; Desloca o byte baixo à esquerda, rotaciona através do carry
    MOV DIVISOR_LOW, A         ; Salva o byte baixo do divisor atualizado
    MOV A, DIVISOR_HIGH        ; Move o byte alto do divisor atual para o acumulador
    RLC A                      ; Desloca o byte alto à esquerda, rotacionando o carry do byte baixo
    MOV DIVISOR_HIGH, A        ; Salva o byte alto do divisor atualizado
    JNC div1                   ; Repete até que a flag de carry seja definida a partir do byte alto

div2:
    ; Desloca o divisor à direita
    MOV A, DIVISOR_HIGH        ; Move o byte alto do divisor para o acumulador
    RRC A                      ; Rotaciona o byte alto do divisor à direita e para o carry
    MOV DIVISOR_HIGH, A        ; Salva o valor atualizado do byte alto do divisor
    MOV A, DIVISOR_LOW         ; Move o byte baixo do divisor para o acumulador
    RRC A                      ; Rotaciona o byte baixo do divisor à direita, com o carry do byte alto
    MOV DIVISOR_LOW, A         ; Salva o valor atualizado do byte baixo do divisor
    
    CLR C                      ; Limpa o carry, não precisamos mais dele
    
    ; Salva cópias temporárias do dividendo
    MOV TEMP_DIV_HIGH, DIVIDENDO_HIGH  ; Faz uma cópia segura do byte alto do dividendo
    MOV TEMP_DIV_LOW, DIVIDENDO_LOW    ; Faz uma cópia segura do byte baixo do dividendo
    
    ; Tenta a subtração
    MOV A, DIVIDENDO_LOW       ; Move o byte baixo do dividendo para o acumulador
    SUBB A, DIVISOR_LOW        ; Dividendo - divisor deslocado = bit do resultado (0 ou 1)
    MOV DIVIDENDO_LOW, A       ; Salva o dividendo atualizado 
    MOV A, DIVIDENDO_HIGH      ; Move o byte alto do dividendo para o acumulador
    SUBB A, DIVISOR_HIGH       ; Subtrai o byte alto do divisor (subtração de 16 bits)
    MOV DIVIDENDO_HIGH, A      ; Salva o byte alto atualizado
    
    JNC div3                   ; Se a flag de carry NÃO estiver definida, o resultado é 1
    
    ; Caso contrário, o resultado é 0, restaura o dividendo original
    MOV DIVIDENDO_HIGH, TEMP_DIV_HIGH
    MOV DIVIDENDO_LOW, TEMP_DIV_LOW

div3:
    CPL C                      ; Inverte o carry, para que possa ser diretamente copiado no resultado
    MOV A, TEMP_RESULT_LOW     
    RLC A                      ; Desloca a flag de carry para o resultado temporário
    MOV TEMP_RESULT_LOW, A     
    MOV A, TEMP_RESULT_HIGH
    RLC A
    MOV TEMP_RESULT_HIGH, A
    
    DJNZ CONTADOR, div2        ; Agora conta para trás e repete até que o contador seja zero
    
    ; Move o resultado final para os endereços de resultado
    MOV A, TEMP_RESULT_HIGH
    MOV RESULTADO_HIGH, A
    MOV A, TEMP_RESULT_LOW
    MOV RESULTADO_LOW, A
    
    RET

TO_DECIMAL:
        ; Limpa as variaveis:
        MOV DECIMAL_MILHAR, #0
        MOV DECIMAL_CENTENA, #0
        MOV DECIMAL_DEZENA, #0
        MOV DECIMAL_UNIDADE, #0

        ; Cópia do numero a ser convertido para decimal
        MOV R0, RESULTADO_LOW    ; LSB
        MOV R1, RESULTADO_HIGH   ; MSB

CONVERT_LOOP:
        ; Verifica se o número é zero
        MOV A, R0
        ORL A, R1
        JZ DECIMAL_DONE         ; Se o número já é zero, termina a conversão

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
        INC DECIMAL_MILHAR   ; Incrementa milhares
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
        INC DECIMAL_CENTENA  ; Incrementa centenas
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
        INC DECIMAL_DEZENA   ; Incrementa dezenas
        SJMP CONVERT_LOOP

CHECK_1:
        ; O que sobrou são as unidades
        MOV A, R0              ; O resto está em R0
        ADD A, DECIMAL_UNIDADE ; Adiciona às unidades existentes
        MOV DECIMAL_UNIDADE, A
        
        ; Zera o número original pois já processamos tudo
        MOV R0, #0
        MOV R1, #0
        SJMP CONVERT_LOOP

DECIMAL_DONE:
        RET                    ; Retorna após a conversão

FIM:
        SJMP $