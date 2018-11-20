;
; ex5.1.asm
;
; Created: 19/11/2017 2:07:26 μμ
; Author : Γιάννης & Νίκος
;


.def counter=r16			; Περιέχει το τρέχον περιεχόμενο του μετρητή
.def intrcounter=r17		; Μετρητής του πλήθους των διακοπών INT1
.def temp=r18

.org 0x0
	rjmp reset
.org 0x4					; Διάνυσμα διακοπής INT1
	rjmp ISR1

reset:
	; Αρχικοποίηση της στοίβας.
	LDI temp, HIGH(RAMEND)	; Το άνω byte του τέλους της μνήμης
	OUT SPH, temp			; τίθεται στον stack pointer (high)
	LDI temp, LOW(RAMEND)	; κι όμοια το κάτω byte.
	OUT SPL, temp

	; Επίτρεψη INT1.
	ldi temp, (1 << ISC10) | (1 << ISC11)
	out MCUCR, temp			; Ορίζεται η διακοπή με σήμα θετικής ακμής.
	ldi temp, (1 << INT1)
	out GICR, temp			; Επιτρέπεται η διακοπή ΙΝΤ1.
	sei						; Επίτρεψη διακοπών.

	; Οι A,B τίθενται έξοδοι.
	ser temp
	out DDRA, temp
	out DDRB, temp
	; Η D τίθεται είσοδος.
	clr temp
	out DDRD,temp
	; Αρχικοποίηση counter.
	clr counter

;; Κυρίως πρόγραμμα, απεικονίζει έναν 8-bit μετρητή στη θύρα B.
loop:
	out PORTB, counter		; Δείχνει το τρέχον περιεχόμενο του μετρητή,
	ldi r24, low(200)
	ldi r25, high(200)
	rcall wait_msec			; περιμένει 0.2 sec,
	inc counter				; τον αυξάνει
	rjmp loop				; και επαναλαμβάνει.


;; Όταν καλείται απεικονίζει στην θύρα A το πλήθος των διακοπών INT1,
;; αν το PD7 είναι ON.
ISR1:
	; Σώσιμο των καταχωρητών.
	push r24
	push r25
	push temp
	in temp, SREG
	push temp

; Έλεγχος για αναπηδήσεις ώστε να μετρηθεί μία φορά η ρουτίνα.
check:
	ldi temp, (1 << INTF1)
	out GIFR, temp			; Μηδενισμός του INTF1.
	ldi r24, low(5)
	ldi r25, high(5)
	rcall wait_msec			; Αναμονή για 5 msec.
	in temp, GIFR
	sbrc temp,7				; Αν το INTF1 είναι 0 πάει στις κυρίως εντολές,
	rjmp check				; αλλιώς επαναλαμβάνει.

	inc intrcounter			; Αυξάνει το πλήθος των διακοπών κατά 1.

	in temp, PIND			; Διάβασμα της θύρας D.
	sbrc temp,7				; Αν το PD7 είναι 0, δεν εκτελείται η επόμενη εντολή.
	out PORTA,intrcounter	; Αλλιώς απεικονίζεται στη θύρα Α, το πλήθος των διακοπών.

is1ret:
; Επαναφορά των καταχωρητών και επιστροφή.
	pop temp
	out SREG, temp
	pop temp
	pop r25
	pop r24
	reti

;; Προκαλεί καθυστέρηση r25:r24 msec.
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

;; Προκαλεί καθυστέρηση r25:r24 μsec.
wait_usec:
	sbiw r24 ,1				; 2 κύκλοι (0.250 μsec)
	nop						; 1 κύκλος (0.125 μsec)
	nop						; 1 κύκλος (0.125 μsec)
	nop						; 1 κύκλος (0.125 μsec)
	nop						; 1 κύκλος (0.125 μsec)
	brne wait_usec			; 1 ή 2 κύκλοι (0.125 ή 0.250 μsec)
	ret						; 4 κύκλοι (0.500 μsec)
