;
; ex4.2.asm
;
; Created: 7/11/2017 12:26:41 πμ
; Author : Γιάννης
;


;;Αρχικοποίηση της στοίβας.
	LDI r16, HIGH(RAMEND)	;Το άνω byte του τέλους της μνήμης
	OUT SPH,r16				;τίθεται στον stack pointer (high)
	LDI r16, LOW(RAMEND)	;κι όμοια το κάτω byte.
	OUT SPL,r16
	
	ser r26 
	out DDRB, r26		;H PORTB τίθεται έξοδος.
	clr r26
	out DDRA,r26		;Η PORTA τίθεται είσοδος.
flash: 
;Άναμμα της PORTA.
	rcall on
	in r26, pina		;Διάβασμα της PORTA.
	swap r26			;Μεταφορά των PA4-PA7 στα PA0-PA3.
	rcall delay			;Καθυστέρηση ανάλογα με την τιμή των PA4-PA7.
;Σβήσιμο της PORTA.
	rcall off			
	in r26, pina		;Τα PA0-PA3 καθορίζουν τη διάρκεια του σβησίματος
	rcall delay			;τα οποία διαβάζει η delay (4 LSB του r26).
	rjmp flash

;;Προκαλεί καθυστέρηση (x+1)*200 msec όπου x τα 4 LSB του r26.
delay:
	andi r26,0x0f		;Απομόνωση των 4 LSB του r26.
	inc r26				;r26 <- r26 + 1.
	ldi r27,200			;r27 <- 200
	mul r26,r27			;r1:r0 <- r27*r26 = 200 * (x+1).
	movw r24,r0			;r25:r24 <- r1:r0.
	rcall wait_msec		;Καθυστέρηση 200(x+1) msec.
	ret					;Επιστροφή.

;;Ανάβει την πόρτα B.
on: ser r26 
	out PORTB , r26
	ret 

;;Σβήνει την πόρτα B.
off: clr r26 
	out PORTB , r26
	ret 

;;Προκαλεί καθυστέρηση r25:r24 msec.
wait_msec:
	push r24				; 2 κύκλοι (0.250 μsec)
	push r25				; 2 κύκλοι
	ldi r24 , low(998)		; φόρτωσε τον καταχ. r25:r24 με 998 (1 κύκλος - 0.125 μsec)
	ldi r25 , high(998)		; 1 κύκλος (0.125 μsec)
	rcall wait_usec			; 3 κύκλοι (0.375 μsec), προκαλεί συνολικά καθυστέρηση 998.375 μsec
	pop r25					; 2 κύκλοι (0.250 μsec)
	pop r24					; 2 κύκλοι
	sbiw r24 , 1			; 2 κύκλοι
	brne wait_msec			; 1 ή 2 κύκλοι (0.125 ή 0.250 μsec)
	ret						; 4 κύκλοι (0.500 μsec)

;;Προκαλεί καθυστέρηση r25:r24 μsec.
wait_usec:
	sbiw r24 ,1				; 2 κύκλοι (0.250 μsec)
	nop						; 1 κύκλος (0.125 μsec)
	nop						; 1 κύκλος (0.125 μsec)
	nop						; 1 κύκλος (0.125 μsec)
	nop						; 1 κύκλος (0.125 μsec)
	brne wait_usec			; 1 ή 2 κύκλοι (0.125 ή 0.250 μsec)
	ret						; 4 κύκλοι (0.500 μsec)

