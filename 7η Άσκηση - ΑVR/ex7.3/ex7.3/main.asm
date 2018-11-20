;
; ex7.3.asm
;
; Created: 04/12/2017 2:39:40 μμ
; Author : Γιάνννης & Νίκος
;


.def counter=r16
.def min_counter=r17
.def input=r18
.def temp=r19

reset:
	;Αρχικοποίηση της στοίβας.
	LDI temp, HIGH(RAMEND)	;Το άνω byte του τέλους της μνήμης
	OUT SPH, temp						;τίθεται στον stack pointer (high)
	LDI temp, LOW(RAMEND)		;κι όμοια το κάτω byte.
	OUT SPL, temp

	;Αρχικοποίηση της PORTB για την είσοδο.
	ldi temp, 0x00
	out DDRA, temp
	;Αρχικοποίηση της PORTD για την οθόνη LCD.
	ldi temp, 0xff
	out DDRD, temp
	;Αρχικοποίηση οθόνης.
	rcall lcd_init

	clr counter							; Αρχικοποίηση 	counters
	clr min_counter

;;; ΑΡΧΗ ΚΥΡΙΟΥ ΠΡΟΓΡΑΜΜΑΤΟΣ ;;;
start:
;;;Λεπτά
    cpi min_counter, 0x3c 				; σύγκριση με 60 *ΠΡΙΝ* την απεικόνιση,
    brne just_print									; αφού inc-> στο προηγούμενο loop. Αν <60, συνέχισε,
    clr min_counter						; αλλιώς μηδένισε τον min_counter (αφού πέρασε 1 ΄ώρα)
just_print:
	rcall printer
wait_1_sec:
	ldi r24,low(1000)				; Ξεκινάει τη μέτρηση του δευτερολέπτου,
	ldi r25,high(1000)			; ελέγχοντας ταυτόχρονα,
	rcall check_wait_msec		; αν είναι πατημένο το PB0.
	rjmp start							;Διαρκής επανάληψη για χρονομέτρηση.
;;; ΤΕΛΟΣ ΚΥΡΙΟΥ ΠΡΟΓΡΑΜΜΑΤΟΣ ;;;


;;;ΑΡΧΗ ΜΗ ΕΤΟΙΜΑΤΖΙΔΙΚΩΝ ΡΟΥΤΙΝΩΝ ;;;
printer:
	rcall lcd_init
  mov input, min_counter
  rcall prnt_time					; Τύπωμα λεπτών
  ldi r24, ' '
  rcall lcd_data
  ldi r24, 'M'
  rcall lcd_data
  ldi r24, 'I'
  rcall lcd_data
  ldi r24, 'N'
  rcall lcd_data
	ldi r24, ':'
	rcall lcd_data
;;;Δευτερόλεπτα
	mov input, counter
	rcall prnt_time				; Τύπωμα δευτερολέπτων.
	inc counter 					; Αύξηση του μετρητή δευτερολέπτων μετά την απεικόνιση.
	cpi counter, 0x3c 		; Σύγκριση με 60 *ΜΕΤΑ* την απεικόνιση (Αφού inc->μετά).
	brlo cont_sec 				; Aν μικρότερο, απλά συνέχισε.
	clr counter 					; Αλλιώς, μηδένισε τον counter,
	inc min_counter				; και αύξησε τον min_counter (αφού πέρασε 1 λεπτό).
cont_sec:
  ldi r24, ' '
  rcall lcd_data
  ldi r24, 'S'
  rcall lcd_data
  ldi r24, 'E'
  rcall lcd_data
  ldi r24, 'C'
  rcall lcd_data
 	ret

prnt_time: 			    ; μετατρέπει την τιμή του input σε bcd και την τυπώνει
	ldi r24, 0			  ; Στον r24 θα σχηματιστούν οι δεκάδες.
	ldi temp, 0x30
decades_loop:
	cpi input, 10
	brlo print_all   		; Αν είναι μικρότερο από 10, πάει στο print_all.
	inc r24				; Αλλιώς αυξάνει τον r24 κατά 1,
	subi input, 10		; και μειώνει την είσοδο κατά 10.
	rjmp decades_loop	; Επαναλαμβάνει μέχρι να ληφθούν όλες οι δεκάδες.
print_all:
	add r24, temp		  ; Ascii-οποίηση των δεκάδων
	rcall lcd_data		; και τύπωμα τους.
	add input,temp
	mov r24, input		; Στον input έχουν απομείνει οι μονάδες,
	rcall lcd_data		; οπότε και τυπώνονται σε ASCII.
  ret

;; Προκαλεί καθυστέρηση r25:r24 msec, καλώντας την check_wait_2usec.
check_wait_msec:
	push r24									; 2 κύκλοι (0.250 μsec)
	push r25									; 2 κύκλοι
	ldi r24 , low(499)				; φόρτωσε τον καταχ. r25:r24 με 998 (1 κύκλος - 0.125 μsec)
	ldi r25 , high(499)				; 1 κύκλος (0.125 μsec)
	rcall check_wait_2usec		; 3 κύκλοι (0.375 μsec), προκαλεί συνολικά καθυστέρηση 998.375 μsec
	pop r25										; 2 κύκλοι (0.250 μsec)
	pop r24										; 2 κύκλοι
	sbiw r24 , 1							; 2 κύκλοι
	brne check_wait_msec			; 1 ή 2 κύκλοι (0.125 ή 0.250 μsec)
	ret												; 4 κύκλοι (0.500 μsec)
;; Η check_wait_msec έχει ίδια κατασκευή με την απλή wait_msec, με όρισμα όμως,
;; το μισό της απλής wait_msec. Θα δούμε γιατί.

;; Η check_wait_2usec προκαλεί καθυστέρηση, ελέγχοντας για πάτημα των PB7 & PB0.
;; Αν πατηθεί το PB7 φεύγει για το reset.
;; Αν αφεθεί το PB0, μένει στην check_wait_2usec.
;; ΣΗΜΕΙΩΣΗ: η εντολή rjmp έχει μήκος μίας λέξης, οπότε όταν σκιπάρεται
;;           και στις 2 περιπτώσεις, παρόλο που η ίδια θα έκανε 2 κύκλους,
;;           το sbrc θα μετρήσει 2 κύκλους.
;; Σύνολο 1+2+2=5 κύκλοι προστέθηκαν στο βρόγχο. Έχουμε 1 παραπάνω,οπότε δεν
;; μπορούμε να αντικαταστήσουμε απλά τις nop με τις εντολές για έλεγχο.
;; Θα εργαστούμε ως εξής: Θα διπλασιάσουμε το σύνολο των κύκλων, από 8 σε 16
;; (προσθέτοντας άλλες 3 nop (σύνολο 7 τώρα) πέρα από τις εντολές ελέγχου)
;; και θα ρυθμίσουμε την check_wait_msec που θα κατασκευάσουμε ώστε να τρέχει
;; την check_wait_2usec τις μισές φορές σε σχέση με τη η ρουτίνα που δίδεται
;; από τη θεωρία.
check_wait_2usec:
	in temp, PINB					; Διάβασμα της θύρας B.  		 1 κύκλος (0.125 μsec)
	sbrs temp , 7					; Έλεγχος αν είναι πατημένο το PB7. 	(0.250 μsec)
	rjmp cont_c
	mov temp,counter
	add temp,min_counter
	cpi temp,0
	breq check_wait_2usec
	clr counter
	clr min_counter
	rcall printer
	rjmp check_wait_2usec
cont_c:
	sbrs temp , 0					; Έλεγχος αν είναι πατημένο το PB0.   (0.250 μsec)
	rjmp check_wait_2usec	; Αν όχι, επανάληψη, (2 κύκλοι αν είναι πaτημένο).
	sbiw r24 , 1					; 2 κύκλοι (0.250 μsec)
	nop
	nop
	nop
	nop
	nop                   ; Προσθέτουμε 3 nop.
	nop										; Άρα σύνολο 8+5+3=16 κύκλοι στον βρόγχο.
	nop										; Και 15 όταν το brne γίνει false (τελευταία επαναλ.)
	brne check_wait_2usec	; 1 ή 2 κύκλοι (0.125 ή 0.250 μsec)
	ret										; 4 κύκλοι (0.500 μsec)
;; Συνολικά η ρουτίνα θα προκαλεί καθυστέρηση
;; [16*0.125*(998-1)]+[15*0.125+0.5]  = 1996.375μs για είσοδο 998, άρα
;; [16*0.125*(499-1)]+[15*0.125+0.5] =   998.375μs για ε΄ισοδο 998/2=499.




;;;TΕΛΟΣ ΜΗ ΕΤΟΙΜΑΤΖΙΔΙΚΩΝ ΡΟΥΤΙΝΩΝ ;;;


;;; ΑΡΧΗ ΡΟΥΤΙΝΩΝ ΟΘΟΝΗΣ ;;;
write_2_nibbles:
	push r24				    ; στέλνει τα 4 MSB
	in r25 ,PIND			  ; διαβάζονται τα 4 LSB και τα ξαναστέλνουμε
	andi r25 ,0x0f			; για να μην χαλάσουμε την όποια προηγούμενη κατάσταση
	andi r24 ,0xf0			; απομονώνονται τα 4 MSB και
	add r24 ,r25		   	; συνδυάζονται με τα προϋπάρχοντα 4 LSB
	out PORTD ,r24			; και δίνονται στην έξοδο
	sbi PORTD ,PD3			; δημιουργείται παλμός Εnable στον ακροδέκτη PD3
	cbi PORTD ,PD3			; PD3=1 και μετά PD3=0
	pop r24					    ; στέλνει τα 4 LSB. Ανακτάται το byte.
	swap r24			  	  ; εναλλάσσονται τα 4 MSB με τα 4 LSB
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
	ldi r24 ,0x28				; επιλογή χαρακτήρων μεγέθους 5x8 κουκίδων
	rcall lcd_command		; και εμφάνιση δύο γραμμών στην οθόνη
	ldi r24 ,0x0c				; ενεργοποίηση της οθόνης, απόκρυψη του κέρσορα
	rcall lcd_command
	ldi r24 ,0x01				; καθαρισμός της οθόνης
	rcall lcd_command
	ldi r24 ,low(1530)
	ldi r25 ,high(1530)
	rcall wait_usec
	ldi r24 ,0x06				; ενεργοποίηση αυτόματης αύξησης κατά 1 της διεύθυνσης
	rcall lcd_command		; που είναι αποθηκευμένη στον μετρητή διευθύνσεων και
											; απενεργοποίηση της ολίσθησης ολόκληρης της οθόνης
	ret
;;; ΤΕΛΟΣ ΡΟΥΤΙΝΩΝ ΟΘΟΝΗΣ ;;;

;;; ΑΡΧΗ ΡΟΥΤΙΝΩΝ ΧΡΟΝΟΚΑΘΥΣΤΕΡΗΣΗΣ ;;;
;;Προκαλεί καθυστέρηση r25:r24 msec.
wait_msec:
	push r24						; 2 κύκλοι (0.250 μsec)
	push r25						; 2 κύκλοι
	ldi r24 , low(998)	; φόρτωσε τον καταχ. r25:r24 με 998 (1 κύκλος - 0.125 μsec)
	ldi r25 , high(998)	; 1 κύκλος (0.125 μsec)
	rcall wait_usec				; 3 κύκλοι (0.375 μsec), προκαλεί συνολικά καθυστέρηση 998.375 μsec
	pop r25							; 2 κύκλοι (0.250 μsec)
	pop r24							; 2 κύκλοι
	sbiw r24 , 1				; 2 κύκλοι
	brne wait_msec			; 1 ή 2 κύκλοι (0.125 ή 0.250 μsec)
	ret									; 4 κύκλοι (0.500 μsec)

;;Προκαλεί καθυστέρηση r25:r24 μsec.
wait_usec:
	sbiw r24 , 1			; 2 κύκλοι (0.250 μsec)
	nop								; 1 κύκλος (0.125 μsec)
	nop								; 1 κύκλος (0.125 μsec)
	nop								; 1 κύκλος (0.125 μsec)
	nop								; 1 κύκλος (0.125 μsec)
	brne wait_usec		; 1 ή 2 κύκλοι (0.125 ή 0.250 μsec)
	ret								; 4 κύκλοι (0.500 μsec)
;;; ΤΕΛΟΣ ΡΟΥΤΙΝΩΝ ΧΡΟΝΟΚΑΘΥΣΤΕΡΗΣΗΣ ;;;
