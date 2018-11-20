; Read a hexadecimal digit in AL. Ignore everything but 'Q'.
READHEX PROC NEAR
AGAINREADHEX:
    READ_B
    CMP AL,'Q'
    JE ENDREADHEX
    CMP AL,'0'
    JL AGAINREADHEX
    CMP AL,'9'
    JG READHEXLETTER
    SUB AL,'0'
    JMP ENDREADHEX
READHEXLETTER:
    CMP AL,'A'
    JL AGAINREADHEX
    CMP AL,'F'
    JG AGAINREADHEX
    SUB AL,55
ENDREADHEX:
    RET
READHEX ENDP

; A converter procedure. It executes (AX)/(BX), stores the result in CL and the
; remainder in AX.
CONVERT PROC NEAR
CONVAGAIN:
    CMP AX,BX
    JC CONVDONE
    SUB AX,BX
    INC CX
    JMP CONVAGAIN
CONVDONE:
    RET
CONVERT ENDP

; Convert HEX in AX to DEC. Accurate for up to 16-bit HEX numbers.
HEXTODEC PROC NEAR
    PUSH BX
    PUSH CX
    MOV CX,0

    MOV BX,1000
    CALL CONVERT
    SHL CX,4

    MOV BX,100
    CALL CONVERT
    SHL CX,4

    MOV BX,10
    CALL CONVERT
    SHL CX,4

    ADD CX,AX
    MOV AX,CX
    POP CX
    POP BX
    RET
HEXTODEC ENDP

; Convert DEC in AX to HEX. Accurate for up to 16-bit DEC numbers.
DECTOHEX PROC NEAR
    PUSH BX
    PUSH CX
    MOV CL,4
    MOV BX,0
DECTOHEXAGAIN:
    PUSH AX
    PUSH CX
    MOV CL,12
    SHR AX,CL
    POP CX
    AND AX,000FH
    PUSH CX
    ADD BX,BX           ; (BX) = 2*N
    MOV CX,BX           ; (CX) = 2*N
    ADD BX,BX           ; (BX) = 4*N
    ADD BX,BX           ; (BX) = 8*N
    ADD BX,CX           ; (BX) = 10*N
    POP CX
    ADD BX,AX
    POP AX
    PUSH CX
    MOV CL,4
    SHL AX,CL
    POP CX
    DEC CL
    JNZ DECTOHEXAGAIN

    MOV AX,BX
    POP CX
    POP BX
    RET
DECTOHEX ENDP

; A procedure that prints a single HEX digit.
PRINT_HEX PROC NEAR
    PUSH AX
	CMP AL,10
	JC DECD
	ADD AL,55
	PRINT AL
	JMP PRHXRET
DECD:
	ADD AL,48
	PRINT AL
PRHXRET:
    POP AX
	RET
PRINT_HEX ENDP

; Print 4 digits contained in AX. Ignore leading zeros.
PRINT_RESULT_HEX PROC NEAR
	PUSH BX
	PUSH CX
	PUSH AX

	MOV CL,4       ; Set CL to 4, for efficient ROR.
	MOV CH,4       ; Digits to be printed, default is 4.

	MOV BX,AX      ; Store the input in BX.
	ROR BX,CL      ; Move first digit to the 4 LSB bits in BH.
	MOV AH,0       ; Initialize non-zero flag to 0.
LOOPPRH:
	MOV AL,BH
	AND AL,0FH     ; Isolate current digit.
	CMP AH,0       ; Check if a non-zero digit has been printed.
	JNZ TYPEANYRH  ; If so, print unconditionally.
	CMP AL,0       ; Else. check if current is zero.
	JZ NEXTDRH     ; If so, proceed without printing.
	MOV AH,1       ; Else, set AH flag.
TYPEANYRH:
	CALL PRINT_HEX ; If we got here, we print the hex digit contained in AL.
NEXTDRH:
	ROL BX,CL      ; Shift BX to get the next digit.
	DEC CH         ; Decrease digit counter,
	JNZ LOOPPRH    ; and repeat until 4 digits are printed.

	CMP AH,0       ; If the non-zero flag is never set,
	JNZ P4RETRH
	PRINT '0'      ; print zero.
P4RETRH:
    POP AX
	POP CX
	POP BX
	RET
PRINT_RESULT_HEX ENDP

; Print 3 OCT digits from AX.
PRINT_RESULT_OCT PROC NEAR
	PUSH BX
	PUSH CX
	PUSH AX

	MOV CL,3		; Set CL for efficient shifting.
	MOV CH,3		; Store the number of digits to be printed.

	MOV BX,AX      ; Store the input in BX.
	ROL BX,2       ; Move the first digit in the 4 LSB bits of BH.
	MOV AH,0       ; Initialize non-zero flag to 0.
LOOPPRO:
	MOV AL,BH
	AND AL,07H     ; Isolate current digit.
    CMP AH,0       ; Check if a non-zero digit has been printed.
	JNZ TYPEANYRO  ; If so, print unconditionally.
	CMP AL,0       ; Else. check if current is zero.
	JZ NEXTDRO     ; If so, proceed without printing.
	MOV AH,1       ; Else, set AH flag.
TYPEANYRO:
	CALL PRINT_HEX ; If we got here, we print the hex digit contained in AL.
NEXTDRO:
    ROL BX,CL      ; Shift BX to get the next digit.
    DEC CH         ; Decrease digit counter,
    JNZ LOOPPRO    ; and repeat until 3 digits are printed.

	CMP AH,0       ; If the non-zero flag is never set,
	JNZ P4RETRO
	PRINT '0'      ; print zero.
P4RETRO:
    POP AX
	POP CX
	POP BX
	RET
PRINT_RESULT_OCT ENDP
