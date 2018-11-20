; Print a single character.
PRINT MACRO CHAR
	PUSH DX
	PUSH AX
	MOV DL,CHAR
	MOV AH,2
	INT 21H
	POP AX
	POP DX
ENDM

; Print a string.
PRINT_STR MACRO MESSAGE
	PUSH DX
	PUSH AX
	MOV DX, OFFSET MESSAGE
	MOV AH,9
	INT 21H
	POP AX
	POP DX
ENDM

; Read and print input character.
READ MACRO
	MOV AH,1
	INT 21H
ENDM

; Read input character without printing.
READ_B MACRO
	MOV AH,8
	INT 21H
ENDM

; Exit to OS.
EXIT MACRO
	MOV AX,4C00H
	INT 21H
ENDM

; Isolate #(POS) nibble of AX in AL.
SINGLE MACRO POS
	SHR AX,POS
	SHR AX,POS
	SHR AX,POS
	SHR AX,POS
	AND AX,0FH
ENDM
