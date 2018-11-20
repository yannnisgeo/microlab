INCLUDE macros.asm			; Some basic helper macros.

STACK_SEG SEGMENT STACK
	DW 50 DUP(?)
STACK_SEG ENDS

DATA_SEG SEGMENT
	input_msg DB "GIVE 2 DECIMAL DIGITS: $"
	output_msg DB "OCTAL= $"
	quit_msg DB "QUIT$"
	NEW_LINE DB 0AH,0DH,'$'
DATA_SEG ENDS

CODE_SEG SEGMENT
	ASSUME CS:CODE_SEG,SS:STACK_SEG,DS:DATA_SEG

INCLUDE helpers.asm			; Some helper procedures.

READSOME PROC NEAR

AGAINREADSOME:				; A procedure to read decimal digits, Q, +, -, =.
    READ_B
    CMP AL,'='
    JE ENDREADSOME
	CMP AL,'+'
    JE ENDREADSOME
	CMP AL,'-'
    JE ENDREADSOME
    CMP AL,'Q'
    JE ENDREADSOME
    CMP AL,'0'
    JL AGAINREADSOME
    CMP AL,'9'
    JG AGAINREADSOME
    SUB AL,'0'
ENDREADSOME:
    RET

READSOME ENDP

MAIN PROC FAR
	MOV AX,DATA_SEG
	MOV DS,AX
	MOV ES,AX

	MOV CL,4				; We set CL for efficient SHR.

START:
	MOV BX,0				; Store the 2 numbers in BX,DX.
	MOV DX,0
	MOV CH,0				; (CH) = digits read

FIRST:
	CALL READSOME			; Read a single character.
	CMP AL,'Q'				; If it's 'Q', we quit.
	JE QUIT
	CMP AL,'='
	JE FIRST
	CMP AL,'+'				; If it's '+', then...
	JNE CONT1
	CMP CH,0				; check if at least one digit has been read.
	JG ADDTHEM				; If so add it with the next number.
	JMP FIRST				; Else ignore the input.
CONT1:
	CMP AL,'-'				; Likewise for '-'.
	JNE CONT2
	CMP CH,0
	JG SUBTHEM
	JMP FIRST
CONT2:
	AND AX,0FH				; If we get there, a new decimal digit was entered.
	CALL PRINT_HEX			; We print it.
	SHL DX,CL				; Then we adjust DX accordingly.
	ADD DX,AX
	INC CH
	CMP CH,3				; Check if more than 3 decimals have been read.
	JL FIRST				; If not, allow reading more.

OPERATION:					; We have read 3 decimal digits and we are only
	CALL READSOME			; expecting an operation symbol.
	CMP AL,'Q'
	JE QUIT
	CMP AL,'+'				; Check if '+' was pressed...
	JE ADDTHEM				; and jump accordingly.
	CMP AL,'-'				; Likewise for '-'.
	JE SUBTHEM
	JMP OPERATION

ADDTHEM:
	PRINT AL				; Print the operation symbol,
	MOV AX,0				; set the (AX) flag to 0...
	JMP DONE				; and move on.
SUBTHEM:
	PRINT AL
	MOV AX,1
DONE:
	PUSH AX					; Store the operation flag in the stack.

	MOV CH,0
SECOND:
	CALL READSOME			; Read a single character.
	CMP AL,'Q'				; If it's 'Q', we quit.
	JE QUIT
	CMP AL,'+'
	JE SECOND
	CMP AL,'-'
	JE SECOND
	CMP AL,'='				; If '=' was pressed, then...
	JNE CONT3
	CMP CH,0				; check if at least one digit has been read.
	JE SECOND				; If not, ignore the input.
	JMP EQUALSENTERED		; Else display the output.

CONT3:
	AND AX,0FH				; If we get there, a new decimal digit was entered.
	CALL PRINT_HEX			; We print it.
	SHL BX,CL				; Then we adjust DX accordingly.
	ADD BX,AX
	INC CH
	CMP CH,3				; ...check if more than 2 decimals have been read.
	JL SECOND				; If not, allow to read more.

EQUALS:						; We have read 3 decimal digits and we are only
	CALL READSOME			; expecting the '=' symbol to print the output.
	CMP AL,'Q'
	JE QUIT
	CMP AL,'='
	JNE EQUALS
EQUALSENTERED:				; Once '=' is properly entered,
	PRINT '='				; print it.
	MOV AX,BX				; Convert both numbers to HEX.
	CALL DECTOHEX
	MOV BX,AX
	MOV AX,DX
	CALL DECTOHEX
	MOV DX,AX

	MOV CH,0				; Initialize the sign flag.
	POP AX					; Restore AX to check the operation flag.
	CMP AL,0
	JE SKIP
	NEG BX					; If '-' was pressed, we set (BX) = -(BX)
SKIP:
	ADD DX,BX				; (DX) = (DX) + (BX)
	MOV AX,DX				; Store the result in AX.
	CMP AX,0FFFFh			; Check for its sign.
	JG SKIP2
	MOV CH,1				; If it's negative, set the sign flag...
	PRINT '-'				; and print '-'.
	NEG AX					; Negate the result, for proper printing.
SKIP2:
	CALL PRINT_RESULT_HEX	; Print the result in HEX.

	PRINT '='
	CMP CH,1				; Check if the sign flag is set.
	JNE SKIP3
	PRINT '-'				; If so, print '-' again.
SKIP3:
	CALL HEXTODEC			; Convert AX to decimal.
	CALL PRINT_RESULT_HEX	; Print it.
	PRINT_STR NEW_LINE		; Print a new line...

	JMP START				; and start from scratch.

QUIT:
	PRINT_STR NEW_LINE		; Print a new line,
	PRINT_STR quit_msg		; an exit message...
	EXIT					; and return control to the OS.
MAIN ENDP

CODE_SEG ENDS
	END MAIN
