INCLUDE macros.asm			; Some basic helper macros.

STACK_SEG SEGMENT STACK
	DW 50 DUP(?)
STACK_SEG ENDS

DATA_SEG SEGMENT
	input_msg DB "GIVE 3 HEX DIGITS: $"
	output_msg DB "Decimal: $"
	quit_msg DB "QUIT$"
	NEW_LINE DB 0AH,0DH,'$'
DATA_SEG ENDS

CODE_SEG SEGMENT
	ASSUME CS:CODE_SEG,SS:STACK_SEG,DS:DATA_SEG

INCLUDE helpers.asm			; Some helper procedures.

READSOME PROC NEAR
AGAINREADSOME:
    READ_B
    CMP AL,'0'
    JL AGAINREADSOME
    CMP AL,'9'
    JG READSOMELETTER
    SUB AL,'0'
    JMP ENDREADSOME
READSOMELETTER:
    CMP AL,'A'
    JL AGAINREADSOME
    CMP AL,'F'
    JG AGAINREADSOME
    SUB AL,55
ENDREADSOME:
    RET
READSOME ENDP

PRINT_FRACTIONAL PROC NEAR	; A procedure that produces the desired output.
	PUSH AX					; We store AX,DX
	PUSH DX
	MOV AX,DX				; DX contains the number we just read, but HEXTODEC
	SHR AX,4				; requires it is stored in AX. We must also isolate
	CALL HEXTODEC			; H1H0.
	MOV DX,AX				; Backup the converted number in DX.

	MOV CL,3				; (CL) = (digits to be printed)
LOPO1:
	CMP CL,0
	JE FIN1
	DEC CL
	SINGLE CL				; A helper macro that singles out the digit at the
	CALL PRINT_HEX			; position defined by CL.
	MOV AX,DX				; Restore full number and repeat!
	JMP LOPO1
FIN1:
	PRINT '.'				; Print the dot.

	POP DX					; Restore DX to contain the original HEX number.
	MOV BX,DX				; Move it to BX...
	AND BX,0FH				; and trim H1H0.
	MOV AX,625				; 625 = 1/16*10000
	MUL BX					; (DX AX) = 625*(H-1)

	CALL HEXTODEC			; Convert the number to decimal.
	MOV DX,AX				; Back it up in DX.
	MOV CL,4				; Now print 4 digits.
LOPO2:
	CMP CL,0
	JE FIN2
	DEC CL
	SINGLE CL
	CALL PRINT_HEX
	MOV AX,DX
	JMP LOPO2
FIN2:
	PRINT_STR NEW_LINE		; Print a new line,
	POP AX					; restore AX...
	RET						; and return.

PRINT_FRACTIONAL ENDP

MAIN PROC FAR
	MOV AX,DATA_SEG
	MOV DS,AX
	MOV ES,AX

START:
	PRINT_STR input_msg
	MOV BL,3				; Read 3 hex digits.
	MOV CL,4				; Preload CL with 4, to shift bits efficiently.

	MOV DX,0
MORE:
	CMP BL,1				; Once we read two HEX digits, we print the dot.
	JNE SKIP
	PRINT '.'
SKIP:
	CALL READSOME			; Helper procedure that reads a HEX from keyboard,
	CALL PRINT_HEX			; ignoring any irrelevant input. We then print it.
	SHL DX,CL				; Shift the accumulated number to position
	AND AX,0FH				; Clean up the HEX digits in (AH)
	ADD DX,AX				; And add the resulted number to the accumulator DX.
	DEC BL					; One less digit to read! :)
	JNZ MORE

	PRINT_STR NEW_LINE

	CMP DX,0E12H			; If our group name (E12) is entered, we quit.
	JZ QUIT

	PRINT_STR output_msg
	CALL PRINT_FRACTIONAL	; A procedure that expects the desired number in DX
							; and prints in proper format.
	JMP START

QUIT:
	PRINT_STR quit_msg		; Print an exit message...
	EXIT					; and return control to the OS.
MAIN ENDP

CODE_SEG ENDS
	END MAIN
