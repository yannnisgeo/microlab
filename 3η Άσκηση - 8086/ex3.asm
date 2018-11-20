INCLUDE macros.asm			; Some basic helper macros.

STACK_SEG SEGMENT STACK
	DW 50 DUP(?)
STACK_SEG ENDS

DATA_SEG SEGMENT
	TABLE DB 14 DUP(?)		; 14 byte table.
	quit_msg DB "QUIT$"
	NEW_LINE DB 0AH,0DH,'$'
DATA_SEG ENDS

CODE_SEG SEGMENT
	ASSUME CS:CODE_SEG,SS:STACK_SEG,DS:DATA_SEG

; ; Returns only when an allowed character is pressed.
; ; Ignored the rest withouht printing.
READ_STD PROC NEAR
NOTREADY:
	READ_B
	CMP AL,'='				; If '=' was pressed
	JE RSTFIN
	CMP AL,0DH				; returns immediately.
	JE RSTFIN
	CMP AL,' '				; If ' ' was pressed
	JNE NUMBER
	PRINT AL				; we print it
	JMP RSTFIN				; and return.
NUMBER:
	CMP AL,'0'				; Check if number.
	JL NOTREADY				; if lower than'0', read next.
	CMP AL,'9'				; If greater than '9',
	JG CALPH				; Check if capital letter.
	PRINT AL				; if not, number in [0,9], print,
	JMP RSTFIN				; return.
CALPH:
	CMP AL,'A'				; Same for 'A'-'Z'.
	JL NOTREADY
	CMP AL,'Z'
	JG SALPH
	PRINT AL
	JMP RSTFIN
SALPH:
	CMP AL,'a'				; Same for 'a'-'z'.
	JL NOTREADY
	CMP AL,'z'
	JG NOTREADY				; Not allowed char, wait to read next.
	PRINT AL
RSTFIN:
	RET
READ_STD ENDP

; ; Prints from TABLE the characters in BL-BH.
TYPE_IF PROC NEAR
	MOV SI,0				; Set destination counter.
REPET:
	CMP SI,CX				; Check if all CX input characters have been read.
	JZ FINTI				; If yes, return.
	MOV AL,[BP+SI]
	CMP AL,BL				; Check if char is
	JL NBCH					; lower than BL
	CMP AL,BH				; or greater than BH.
	JG NBCH					; If yes, skip printing.
	PRINT AL
NBCH:
	INC SI					; Increase counter...
	JMP REPET				; and repeat.
FINTI:
	RET
TYPE_IF ENDP

; ; Printing of two greater numbers (in order of precedence).
TWOBIG PROC NEAR
	MOV DL,-1				; Second greatest number in DL.
	MOV DH,-1				; Greatest in DH (not ASCII).
	MOV SI,0				; Reset destination counter.
	MOV AH,0				; Reset precedence counter (Values 0:DH - 1:DL).
REPAT:
	CMP SI,CX				; Check if all CX chars have been read.
	JZ FINAL				; if yes, go to final printing.
	MOV AL,[BP+SI]
	CMP AL,'0'				; Check if number.
	JL NBGH
	CMP AL,'9'
	JG NBGH					; If not, move to next.
	SUB AL,48				; If yes, transform it from ASCII to number (deASCIIfication).
	CMP AL,DH				; Compare it with Greatest (DH).
	JL SECCH				; If not greater, compare it with Second Greatest (DL).
	MOV DL,DH				; If yes, move Greatest in Second Greatest.
	MOV DH,AL				; And this in Greatest.
	MOV AH,0       			; Also, set DL as prior (Newer = Bigger).
	JMP NBGH				; Move to next character.
SECCH:
	CMP AL,DL				; Compare with Segond Greatest.
	JL NBGH					; If lower, move to next character,
	MOV DL,AL				; If not, replace.
	MOV AH,1				; and set DH as prior (Newer = Smaller)
NBGH:
	INC SI					; Increase counter
	JMP REPAT				; move to next character of table TABLE.
FINAL:
	CMP DH,0				; Check if any number was pressed (if not, DH=-1).
	JL ENDTWO				; If not, print nothing.
	CMP AH,1	 			; Check if Second Greatest (small) is new (if yes, it obviously exists)
	JE NEW_SMALL
	CMP DL,0				; Check if small exists.
	JL SKIP_SMALL			; If not, only one number was pressed.
	ADD DL,48				; If yes, it exists.
	PRINT DL
SKIP_SMALL:
	ADD DH,48				; ASCIIfication and printing in precedence order.
	PRINT DH
	JMP ENDTWO
NEW_SMALL:
	ADD DH,48				; ASCIIfication and printing in precedence order.
	PRINT DH
	ADD DL,48
	PRINT DL
ENDTWO:
	RET
TWOBIG ENDP


MAIN PROC FAR
	MOV AX,DATA_SEG
	MOV DS,AX
	MOV ES,AX
	MOV BP,OFFSET TABLE		; Address of input TABLE is saved in base register BP

; MAIN PROGRAM
; Reads as many as 14 latin characters, numbers or spaces
; and then prints them in groups, as requested.
; The two biggest numbers are printed in the last line.
; Terminates if '=' is pressed.
START:

; Input reading and saving on the TABLE.
	MOV DI,0					; Initialize DI, destination counter.
READING:
	CALL READ_STD				; Reading one of the allowed characters.
	CMP AL,'='					; If '=', quit.
	JE QUIT
	CMP AL,0DH					; If Enter
	JE DISPLAY					; move to Display.
	CMP DI,14					; If counter = 14
	JZ READING					; then returns and doesn't save anything more
	MOV [BP+DI],AL				; else, the characteris saved in it's slot
	INC DI						; and the counter is increaded by 1.
	JMP READING					; Constant repeating until Enter (or '=') is pressed.

; Display input in requested form.
DISPLAY:
	PRINT_STR NEW_LINE
	MOV CX,DI					; Save the current size of input in CX. (From DI)

; TYPE_IF prints from input, only the characters in the beadth BL-BH.
	MOV BL,'0'					; The values 'a', 'z' are put in BL and BH respectively,
	MOV BH,'9'					;	so that only numbers between 0 and 9 are printed.
	CALL TYPE_IF				; Through TYPE_IF.
	PRINT ' '					; Space between groups.
	MOV BL,'A'					; Equally for capital letters.
	MOV BH,'Z'
	CALL TYPE_IF
	PRINT ' '
	MOV BL,'a'					; Equally for small letters.
	MOV BH,'z'
	CALL TYPE_IF

	PRINT_STR NEW_LINE
	CALL TWOBIG					; TWOBIG prints the two Greatest input numbers.

	PRINT_STR NEW_LINE
	JMP START					; constant repetition.

QUIT:
	PRINT_STR NEW_LINE
	PRINT_STR quit_msg
	EXIT
MAIN ENDP

CODE_SEG ENDS
	END MAIN
