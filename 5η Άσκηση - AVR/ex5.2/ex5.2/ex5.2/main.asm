;
; ex5.2.asm
;
; Created: 20/11/2017 10:03:15 μμ
; Author : Γιάννης & Nίκος
;


.def counter=r16			; περιέχει το τρέχον περιεχόμενο του μετρητή
.def answer=r17				; περιέχει το πλήθος των διακοπτών της θύρας A που είναι ON
.def temp=r18

.org 0x0
	rjmp reset
.org 0x2
	rjmp ISR0				; διάνυσμα διακοπής INTR0

reset:
	; Αρχικοποίηση της στοίβας.
	LDI temp, HIGH(RAMEND)	; Το άνω byte του τέλους της μνήμης
	OUT SPH, temp			; τίθεται στον stack pointer (high)
	LDI temp, LOW(RAMEND)	; κι όμοια το κάτω byte.
	OUT SPL, temp

	; Επίτρεψη INT0.
	ldi temp,( 1 << ISC01) | ( 1 << ISC00)
	out MCUCR, temp			; Ορίζεται η διακοπή με σήμα θετικής ακμής.
	ldi temp, ( 1 << INT0)
	out GICR, temp			; Επιτρέπεται η διακοπή.
	sei						; Επίτρεψη διακοπών.

	; Οι B,C τίθενται έξοδοι.
	ser temp
	out DDRB, temp
	out DDRC, temp
	; Η A τίθεται είσοδος.
	clr temp
	out DDRA,temp
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

;; Όταν καλείται ανάβει τόσα led της θύρας C όσα switch της A
;; είναι ON (αρχίζοντας από το LSB).
ISR0:
; Σώσιμο καταχωρητών.
	push r24
	push r25
	push counter
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

	ldi answer,0			; Στον answer θα σχηματιστεί η απάντηση.
	ldi counter,8			; O counter χρησιμοποιείται εδώ ως μετρητής των bits.
	in temp, PINA
stillcnt:
	rol temp				; Ολίσθηση μέσω κρατουμένου.
	brcc nextdig			; Αν το Carry είναι 0 πάει στο nextdig.
	lsl answer				; Αλλιώς ολισθαίνει αριστερά τον answer
	inc answer				; και προσθέται ακόμη μία μονάδα.
nextdig:
	dec counter				; Μειώνει το μετρητή
	brne stillcnt			; κι επαναλαμβάνει συνολικά 8 φορές (μία για κάθε bit).

	out PORTC, answer		; Απεικόνιση της εξόδου στη θύρα C.
; Επαναφορά των καταχωρητών και επιστροφή.
	pop temp
	out SREG, temp
	pop temp
	pop counter
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
