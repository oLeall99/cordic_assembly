           ORG 0000H
           LJMP INICIO

           ORG 0100H
INICIO:
           MOV A,#0FFH
VOLTA:
           CALL TECLADO
           SJMP VOLTA     

TECLADO:
				MOV R0, #0 ; clear R0 - the first key is key0

				; scan row0
				SETB P0.3 ; set row3
				CLR P0.0 ; clear row0
				CALL colScan ; call column-scan subroutine

          ; scan row1
				SETB P0.0 ; set row0
				CLR P0.1 ; clear row1
				CALL colScan ; call column-scan subroutine

				; scan row2
				SETB P0.1 ; set row1
				CLR P0.2 ; clear row2
          CALL colScan ; call column-scan subroutine

				; scan row3
				SETB P0.2 ; set row2
				CLR P0.3 ; clear row3
				CALL colScan ; call column-scan subroutine
				CJNE R0,#0CH,SAI
          MOV A,#0FFH
SAI:
				RET
          
          colScan:
				JNB P0.4, gotKey ; if col0 is cleared - key found
				INC R0 ; otherwise move to next key
				JNB P0.5, gotKey ; if col1 is cleared - key found
				INC R0 ; otherwise move to next key
				JNB P0.6, gotKey ; if col2 is cleared - key found
				INC R0 ; otherwise move to next key
				RET ; return from subroutine - key not found
gotKey:
				MOV A,R0
				RET  