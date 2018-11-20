;
; 6.1.asm
;
; Created: 26/11/2017 7:42:39 μμ
; Author : Γιάνννης & Νίκος
;


;Δημιουργία της Στοίβας.
  ldi r24,LOW(RAMEND)
  out SPL,r24
  ldi r25,HIGH(RAMEND)
  out SPH,r25

;Θέση των PORTA, PORTC ως εισόδους.
 clr r24
 out DDRA , r24
 out DDRC , r24
;Θέση της PORTB ως έξοδο.
 ser r24
 out DDRB , r24

;Αρχικοποίηση καταχωρητή r26 που θα χρησιμοποιηθεί στην έξοδο.

start:
	clr r26
	in r24 , PINA      ; Διάβασμα της θύρας Α.


;GATE 04 (XNOR)
	mov r25 , r24
	lsl r25            ; Προετοιμασία για σύγκριση PB7 - PB6.
	push r24
	push r25
	andi r24 , 0x80		 ; Απομόνωση των PA7 και PA6.
	andi r25 , 0x80
	add r24 , r25			 ; Αν τα bit 7 των καταχωρητών είναι ίδια (NXOR) (1+1=0 ή 0+0=0)
	sbrs r24 , 7
	ori r26 , 0x08     ; τότε θέτουμε στο Led εξόδου PB3 λογικό 1.

	pop r25
	pop r24		  			 ; Επαναφορά καταχωρητών για περαιτέρω επεξεργασία.


;GATE 03 (NOR)
	lsl r24
	lsl r24  					 ; Shift left μέχρι να έρθει στο MSB του r24 το PA5.
	lsl r25
	lsl r25					   ; Shift left μέχρι να έρθει στο MSB του r25 το ΡΑ4.
	push r24
	push r25
  andi r24 , 0x80		 ; Απομόνωση των PA5 και PA4.
	andi r25 , 0x80
	or r24 , r25
	com r24            ; Υλοποίηση της NOR me OR και αντιστροφή bit (COM).
	sbrc r24 , 7			 ; Αν βγει 1 από την NOR,
	ori r26 , 0x04	   ; τότε θέτουμε στο led εξόδου PB2 λογικό 1.

	pop r25
	pop r24					   ; Επαναφορά καταχωρητών για περαιτέρω επεξεργασία.


;GATE 02 (OR)
	lsl r24
	lsl r24					   ; Shift left μέχρι να έρθει στο MSB του r24 το PA3.
	lsl r25
	lsl r25					   ; Shift left μέχρι να έρθει στο MSB του r25 το ΡΑ2.
	push r24
	push r25
	andi r24 , 0x80		 ; Απομόνωση των PA3 και PA2.
	andi r25 , 0x80
	or r24 , r25
	sbrc r24 , 7			 ; Αν βγει 1 από την OR,
	ori r26 , 0x02     ; τότε θέτουμε στο led εξόδου PB1 λογικό 1.
	mov r27 , r26
	andi r27 , 0x02    ; Αποθηκεύουμε στο 2o bit του r27 για την GATE 05.

	pop r25
	pop r24					   ; Επαναφορά καταχωρητών για περαιτέρω επεξεργασία.


;GATE 01 (XOR)
	lsl r24
	lsl r24					   ; Shift left μέχρι να έρθει στο MSB του r24 το PA1.
	lsl r25
	lsl r25	  				 ; Shift left μέχρι να έρθει στο MSB του r25 το ΡΑ0.
	push r24
	push r25
	andi r24 , 0x80		 ; Απομόνωση των PA1 και PA0.
	andi r25 , 0x80
	add r24 , r25			 ; Αν τα bit 7 των κάταχωρητών είναι διαφορετικά (XOR) (1+0=1 ή 0+1=1),
	sbrc r24 , 7		   ; τότε αποθηκεύουμε το αποτέλεσμα στο
	ori r27 , 0x01     ; 1ο bit του r27 για την GATE 05.

	pop r25
	pop r24


;GATE 05 (AND)
	mov r24 , r27      ; Χρησιμοποιώ τον r24 ως temp για να υλοποιήσω την AND.
	lsr r24            ; Ολισθαίνουμε το bit 1 στη θέση του bit 0, ώστε να τα συγκρίνουμε.
	and r24 , r27
	sbrc r24 , 0       ; Αν το bit 0 είναι 1,
	ori r26 , 0x01	   ; τότε θέτουμε το bit 0 εξόδου λογικό 1.


;Έλεγχος διακοπτών PC0-7
	in r27 , PINC
	eor r26 , r27		   ; Αντιστρέφονται τόσα bits εξόδου του B όσα έχουν 1 στον C.
 	out PORTB , r26


	rjmp start				 ; Διαρκής Επανάληψη.
