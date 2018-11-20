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

AGAINREADSOME:				; A procedure to read decimal digits, 'Q' and ENTER.
    READ_B
    CMP AL,0DH
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

	MOV DX,0				; DX stores the decimal number represented by the
	MOV CL,4				; last two digits. We set CL for efficient SHR.

START:
	PRINT_STR input_msg
	MOV CH,0				; (CH) = digits read
READING:
	CALL READSOME			; Read a single character.
	CMP AL,'Q'				; If it's 'Q', we quit.
	JE QUIT
	CMP AL,0DH				; If it's ENTER,
	JNE SKIP
	CMP CH,2				; ...check if more than 2 decimals have been read.
	JL READING				; If not, ignore the ENTER.
	JMP PRINTOCT			; Else, calculate the output and print it.
SKIP:
	CMP CH,2				; Store min(2,digits read) in CH.
	JE SKIPINC
	INC CH
SKIPINC:					; We reach this part if we have a decimal digit.
	CALL PRINT_HEX			; We print it.
	SHL DX,CL				; Then we adjust DX accordingly.
	ADD DX,AX
	AND DX,255

	JMP READING				; Keep on reading digits.

PRINTOCT:					; Print the converted number.
	PRINT_STR NEW_LINE		; Formatting...
	PRINT_STR output_msg
	MOV AX,DX				; Move DX to AX.
	CALL DECTOHEX			; Convert it to HEX (for personal ease).
	CALL PRINT_RESULT_OCT	; Print it in Octal.
	PRINT_STR NEW_LINE
	JMP START				; Return to start.

QUIT:
	PRINT_STR NEW_LINE		; Print a new line,
	PRINT_STR quit_msg		; an exit message...
	EXIT					; and return control to the OS.
MAIN ENDP

CODE_SEG ENDS
	END MAIN
