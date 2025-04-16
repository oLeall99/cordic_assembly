ORG 0000H   ; Início do programa

; === INÍCIO DAS VARIÁVEIS NA RAM INTERNA ===
; Mapeando diretamente nos endereços da RAM interna do 8051 (128 bytes)

; X e Y (valores 16-bit)
X0      EQU 30H
X1      EQU 31H
Y0      EQU 32H
Y1      EQU 33H

; Z (valor de entrada e controle angular)
Z0      EQU 34H
Z1      EQU 35H

; ε_k temporário
E0      EQU 36H
E1      EQU 37H

; Temporários para X e Y durante shift
XTMP0   EQU 38H
XTMP1   EQU 39H
YTMP0   EQU 3AH
YTMP1   EQU 3BH

; Contador de iterações (k)
K       EQU 3CH

; Ponteiro da tabela (em DPTR)
; Será usado no MOVC A,@A+DPTR

; === INÍCIO DA TABELA EM ROM ===
ORG 0100H
ATAN_TABLE:
; Valores Q1.15 de arctan(2^-k), little endian (LSB primeiro)
; k = 0 até 13
DB 078H,064H  ; 0.785398163 = 0x6478
DB 048H,03BH  ; 0.463647609 = 0x3B48
DB 05BH,01FH  ; 0.244978663 = 0x1F5B
DB 0EAH,0FH   ; 0.124354995 = 0x0FEA
DB 0FDH,07H   ; 0.062418810 = 0x07FD
DB 0FFH,03H   ; 0.031239833 = 0x03FF
DB 0FFH,01H   ; 0.015623729 = 0x01FF
DB 0FFH,00H   ; 0.007812341 = 0x00FF
DB 07FH,00H   ; 0.003906230 = 0x007F
DB 040H,00H   ; 0.001953123 = 0x0040
DB 020H,00H   ; 0.000976562 = 0x0020
DB 010H,00H   ; 0.000488281 = 0x0010
DB 008H,00H   ; 0.000244141 = 0x0008
DB 004H,00H   ; 0.000122070 = 0x0004