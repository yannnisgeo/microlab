;
; ex7.2.asm
;
; Created: 03/12/2017 7:20:24 μμ
; Author : Γιάννης & Νίκος
;


.def input=r16
.def inputold=r17
.def temp=r18
.def counter=r19

	;Αρχικοποίηση της στοίβας.
	LDI temp, HIGH(RAMEND)	;Το άνω byte του τέλους της μνήμης
	OUT SPH, temp			;τίθεται στον stack pointer (high)
	LDI temp, LOW(RAMEND)	;κι όμοια το κάτω byte.
	OUT SPL, temp

	;Αρχικοποίηση της PORTΑ για την είσοδο.
	ldi temp, 0x00
	out DDRA, temp
	;Αρχικοποίηση της PORTD για την οθόνη LCD.
	ldi temp, 0xff
	out DDRD, temp
;Αρχικοποίηση οθόνης.
	rcall lcd_init

	ldi inputold, 0xff


;;; ΑΡΧΗ ΚΥΡΙΟΥ ΠΡΟΓΡΑΜΜΑΤΟΣ ;;;
start:
	in input, PINA
	cp input, inputold		; Αν δεν έχει αλλάξει το input
	breq start						; Άραξε
	mov inputold, input

	;Καθαρισμός της οθόνης.
	ldi r24 ,0x01
	rcall lcd_command
	ldi r24 ,low(1530)
	ldi r25 ,high(1530)
	rcall wait_usec

	;Τύπωμα των 8 ψηφίων του PINA.
	push input
	ldi counter, 8
show_loop:
	ldi r24,'0'				;Αρχικά τοποθετείται το '0' στον r24.
	rol input
	brcc not_one			;Αν το Carry είναι 1
	ldi r24,'1'				;τοποθετείται το '1' στον r24.
not_one:
	rcall lcd_data		;Τύπωμα του ψηφίου.
	dec counter
	brne show_loop		;Επανάληψη 8 φορές (μία για κάθε ψηφίο).
	pop input

	ldi r24,'='				;Τύπωμα του '='.
	rcall lcd_data

	ldi r24, '+'			;Το r24 αρχικοποιείται σε '+'.
	sbrc input, 7
	ldi r24, '-'			;Το r24 γίνεται '-' αν είναι 1 το MSB της εισόδου.
	rcall lcd_data		;Εμφάνιση του προσήμου

	sbrc input, 7			;Αν η είσοδος ήταν αρνητική,
	com input					;παίρνουμε το συμπλήρωμα ως προς 1 (εντολή COM).
;;Παρατηρούμε ότι 00000000=+0 και 11111111=-0 (αφού το 2ο θα αντιστραφεί με COM
;; αλλά θα έχει περαστεί από πριν αρνητικό πρόσιμο), οπότε λήφθηκε υπόψην η
;; διπλή αναπαράσταση του 0.

;Ο input πλέον περιέχει την απόλυτη τιμή της εισόδου.
	ldi temp,0x00			;Ο temp θα γίνει 0xff αν τυπωθούν εκατοντάδες.
	cpi input, 100
	brlo decades
	subi input, 100
	ldi temp, 0xff		;Αποθηκεύεται στον temp ότι τυπώθηκαν εκατοντάδες.
	ldi r24, '1'			;Αν είναι μεγαλύτερο του 100,
	rcall lcd_data		;τυπώνει '1'.
decades:
	ldi r24, 0			;Στον r24 θα σχηματιστούν οι δεκάδες.
decades_loop:
	cpi input, 10
	brlo decades_pr		;Αν είναι μικρότερο από 10, πάει στο monades.
	inc r24				;Αλλιώς αυξάνει τον r24 κατά 1
	subi input, 10		;και μειώνει την είσοδο κατά 10.
	rjmp decades_loop	;Επαναλαμβάνει μέχρι να ληφθούν όλες οι δεκάδες.
decades_pr:
	cpi r24, 0			;Ελέγχει αν οι δεκάδες είναι 0.
	brne decades_trpr	;Αν όχι, απλά τις τυπώνει.
	cpi temp,0x00		;Αν ναι, ελέγχει αν έχουν τυπωθεί εκατοντάδες
	breq monades		;κι αν όχι πάει κατ' ευθείαν στις μονάδες.
decades_trpr:
	ldi temp, 0x30
	add r24, temp		;Ascii-οποίηση των δεκάδων
	rcall lcd_data		;και τύπωμα τους.
monades:
	ldi r24, 0x30
	add r24, input		;Στον input έχουν απομείνει οι μονάδες,
	rcall lcd_data		;οπότε και τυπώνονται σε ASCII.

	rjmp start			;Διαρκής επανάληψη.
;;; ΤΕΛΟΣ ΚΥΡΙΟΥ ΠΡΟΓΡΑΜΜΑΤΟΣ ;;;

;;; ΑΡΧΗ ΡΟΥΤΙΝΩΝ ΟΘΟΝΗΣ ;;;
write_2_nibbles:
	push r24				; στέλνει τα 4 MSB
	in r25 ,PIND			; διαβάζονται τα 4 LSB και τα ξαναστέλνουμε
	andi r25 ,0x0f			; για να μην χαλάσουμε την όποια προηγούμενη κατάσταση
	andi r24 ,0xf0			; απομονώνονται τα 4 MSB και
	add r24 ,r25			; συνδυάζονται με τα προϋπάρχοντα 4 LSB
	out PORTD ,r24			; και δίνονται στην έξοδο
	sbi PORTD ,PD3			; δημιουργείται παλμός Εnable στον ακροδέκτη PD3
	cbi PORTD ,PD3			; PD3=1 και μετά PD3=0
	pop r24					; στέλνει τα 4 LSB. Ανακτάται το byte.
	swap r24				; εναλλάσσονται τα 4 MSB με τα 4 LSB
	andi r24 ,0xf0			; που με την σειρά τους αποστέλλονται
	add r24 ,r25
	out PORTD ,r24
	sbi PORTD ,PD3			; Νέος παλμός Εnable
	cbi PORTD ,PD3
	ret

lcd_data:
	sbi PORTD ,PD2			; επιλογή του καταχωρήτη δεδομένων (PD2=1)
	rcall write_2_nibbles	; αποστολή του byte
	ldi r24 ,43				; αναμονή 43μsec μέχρι να ολοκληρωθεί η λήψη
	ldi r25 ,0				; των δεδομένων από τον ελεγκτή της lcd
	rcall wait_usec
	ret

lcd_command:
	cbi PORTD ,PD2			; επιλογή του καταχωρητή εντολών (PD2=0)
	rcall write_2_nibbles	; αποστολή της εντολής και αναμονή 39μsec
	ldi r24 ,39				; για την ολοκλήρωση της εκτέλεσης της από τον ελεγκτή της lcd.
	ldi r25 ,0				; ΣΗΜ.: υπάρχουν δύο εντολές, οι clear display και return home,
	rcall wait_usec			; που απαιτούν σημαντικά μεγαλύτερο χρονικό διάστημα.
	ret

lcd_init:
	ldi r24 ,40				; Όταν ο ελεγκτής της lcd τροφοδοτείται με
	ldi r25 ,0				; ρεύμα εκτελεί την δική του αρχικοποίηση.
	rcall wait_msec			; Αναμονή 40 msec μέχρι αυτή να ολοκληρωθεί.
	ldi r24 ,0x30			; εντολή μετάβασης σε 8 bit mode
	out PORTD ,r24			; επειδή δεν μπορούμε να είμαστε βέβαιοι
	sbi PORTD ,PD3			; για τη διαμόρφωση εισόδου του ελεγκτή
	cbi PORTD ,PD3			; της οθόνης, η εντολή αποστέλλεται δύο φορές
	ldi r24 ,39
	ldi r25 ,0				; εάν ο ελεγκτής της οθόνης βρίσκεται σε 8-bit mode
	rcall wait_usec			; δεν θα συμβεί τίποτα, αλλά αν ο ελεγκτής έχει διαμόρφωση
							; εισόδου 4 bit θα μεταβεί σε διαμόρφωση 8 bit
	ldi r24 ,0x30
	out PORTD ,r24
	sbi PORTD ,PD3
	cbi PORTD ,PD3
	ldi r24 ,39
	ldi r25 ,0
	rcall wait_usec
	ldi r24 ,0x20			; αλλαγή σε 4-bit mode
	out PORTD ,r24
	sbi PORTD ,PD3
	cbi PORTD ,PD3
	ldi r24 ,39
	ldi r25 ,0
	rcall wait_usec
	ldi r24 ,0x28			; επιλογή χαρακτήρων μεγέθους 5x8 κουκίδων
	rcall lcd_command		; και εμφάνιση δύο γραμμών στην οθόνη
	ldi r24 ,0x0c			; ενεργοποίηση της οθόνης, απόκρυψη του κέρσορα
	rcall lcd_command
	ldi r24 ,0x01			; καθαρισμός της οθόνης
	rcall lcd_command
	ldi r24 ,low(1530)
	ldi r25 ,high(1530)
	rcall wait_usec
	ldi r24 ,0x06			; ενεργοποίηση αυτόματης αύξησης κατά 1 της διεύθυνσης
	rcall lcd_command		; που είναι αποθηκευμένη στον μετρητή διευθύνσεων και
							; απενεργοποίηση της ολίσθησης ολόκληρης της οθόνης
	ret
;;; ΤΕΛΟΣ ΡΟΥΤΙΝΩΝ ΟΘΟΝΗΣ ;;;

;;; ΑΡΧΗ ΡΟΥΤΙΝΩΝ ΧΡΟΝΟΚΑΘΥΣΤΕΡΗΣΗΣ ;;;
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
;;; ΤΕΛΟΣ ΡΟΥΤΙΝΩΝ ΧΡΟΝΟΚΑΘΥΣΤΕΡΗΣΗΣ ;;;

