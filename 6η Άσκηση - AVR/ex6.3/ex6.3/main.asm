;
; 6.3.asm
;
; Created: 27/11/2017 6:32:01 μμ
; Author : Γιάνννης & Νίκος

.INCLUDE "m16def.inc"

; ---- Αρχή τμήματος δεδομένων.
.DSEG
_tmp_: .byte 2
; ---- Τέλος τμήματος δεδομένων.

.CSEG

;Δημιουργία Στοίβας.
  ldi r24,LOW(RAMEND)
  out SPL,r24
  ldi r25,HIGH(RAMEND)
  out SPH,r25

;Θέση της PORTB ως έξοδος.
	ser r24
  out DDRB , r24

;Αρχικοποίηση του DDRC για την ανάγνωση του πληκτρολογίου.
  ldi r24,(1 << PC7) | (1 << PC6) | (1 << PC5) | (1 << PC4)
  out DDRC,r24
;Αρχική κλήση για την αρχικοποίηση της _tmp_ .
  call scan_keypad_rising_edge

start:
  ldi r24 ,10          		        ; Θέτουμε 10ms καθυστέρηση για αποφυγή σπινθιρισμών.
	rcall scan_keypad_rising_edge   ; Διάβασμα του πληκτρολογίου.
	rcall keypad_to_ascii			; Μετατροπή σε ASCII.
  cpi r24 ,0                        ; Αν δεν πατήθηκε τίποτα
  breq start                        ; ξαναγυρνάει στο start
  mov r25 ,r24                      ; Αποθήκευση 1ου ψηφίου στον r25

  push r25
SndB:
  ldi r24 ,10
 rcall scan_keypad_rising_edge	    ; Διάβασμα του πληκτρολογίου.
	rcall keypad_to_ascii			; Μετατροπή σε ASCII.
  cpi r24 ,0                        ; Αν δεν πατήθηκε τίποτα
  breq SndB                         ; ξαναγυρνάει στο SndB
  pop r25
  cpi r25 ,'1'                      ; Έλεγχος αν το πρώτο πλήκτρο που πατήθηκε είναι το '1'
  brne  WRONG                       ; και  αν όχι ...
  cpi r24 ,'2'                      ; Έλεχγος αν το δεύτερο πλήκτρο που πατήθηκε είναι το '2'
  brne WRONG                        ; και  αν όχι ...
  rcall on_4s                       ; Εφόσον πατήθηκε το ζεύγος '12', καλείται η on_4s
  rjmp start                        ; και επιστροφή (διαρκής επανάληψη)

WRONG:
  rcall blink_4s
  rjmp start

;Καλούμενες υπορουτίνες

keypad_to_ascii:
  movw r26 ,r24
	ldi r24 ,'*'
	sbrc r26 ,0
	ret
	ldi r24 ,'0'
	sbrc r26 ,1
	ret
	ldi r24 ,'#'
	sbrc r26 ,2
	ret
	ldi r24 ,'D'
	sbrc r26 ,3
	ret
	ldi r24 ,'7'
	sbrc r26 ,4
	ret
	ldi r24 ,'8'
	sbrc r26 ,5
	ret
	ldi r24 ,'9'
	sbrc r26 ,6
	ret
	ldi r24 ,'C'
	sbrc r26 ,7
	ret
	ldi r24 ,'4'
	sbrc r27 ,0
	ret
	ldi r24 ,'5'
	sbrc r27 ,1
	ret
	ldi r24 ,'6'
	sbrc r27 ,2
	ret
	ldi r24 ,'B'
	sbrc r27 ,3
	ret
	ldi r24 ,'1'
	sbrc r27 ,4
	ret
	ldi r24 ,'2'
	sbrc r27 ,5
	ret
	ldi r24 ,'3'
	sbrc r27 ,6
	ret
	ldi r24 ,'A'
	sbrc r27 ,7
	ret
	clr r24
	ret

scan_keypad_rising_edge:
  mov r22 ,r24         ; αποθήκευσε το χρόνο σπινθηρισμού στον r22
  rcall scan_keypad    ; έλεγξε το πληκτρολόγιο για πιεσμένους διακόπτες
  push r24             ; και αποθήκευσε το αποτέλεσμα
  push r25
  mov r24 ,r22         ; καθυστέρησε r22 ms (τυπικές τιμές 10-20 msec που καθορίζεται από τον
  ldi r25 ,0           ; κατασκευαστή του πληκτρολογίου – χρονοδιάρκεια σπινθηρισμών)
  rcall wait_msec
  rcall scan_keypad    ; έλεγξε το πληκτρολόγιο ξανά και
  pop r23              ; απόρριψε όσα πλήκτρα εμφανίζουν
  pop r22              ; σπινθηρισμό
  and r24 ,r22
  and r25 ,r23
  ldi r26 ,low(_tmp_)  ; φόρτωσε την κατάσταση των διακοπτών στην
  ldi r27 ,high(_tmp_) ; προηγούμενη κλήση της ρουτίνας στους r27:r26
  ld r23 ,X+
  ld r22 ,X
  st X ,r24            ; αποθήκευσε στη RAM τη νέα κατάσταση
  st -X ,r25           ; των διακοπτών
  com r23
  com r22              ; βρες τους διακόπτες που έχουν «μόλις» πατηθεί
  and r24 ,r22
  and r25 ,r23
  ret


scan_keypad:
  ldi r24 ,0x01        ; έλεγξε την πρώτη γραμμή του πληκτρολογίου
  rcall scan_row
  swap r24	     	     ; αποθήκευσε το αποτέλεσμα
  mov r27 ,r24         ; στα 4 msb του r27
  ldi r24 ,0x02	       ; έλεγξε τη δεύτερη γραμμή του πληκτρολογίου
  rcall scan_row
  add r27 ,r24         ; αποθήκευσε το αποτέλεσμα στα 4 lsb του r27
  ldi r24 ,0x03        ; έλεγξε την τρίτη γραμμή του πληκτρολογίου
  rcall scan_row
  swap r24             ; αποθήκευσε το αποτέλεσμα
  mov r26 ,r24         ; στα 4 msb του r26
  ldi r24 ,0x04        ; έλεγξε την τέταρτη γραμμή του πληκτρολογίου
  rcall scan_row
  add r26 ,r24         ; αποθήκευσε το αποτέλεσμα στα 4 lsb του r26
  movw r24 ,r26        ; μετάφερε το αποτέλεσμα στους καταχωρητές r25:r24
  ret


scan_row:
  ldi r25 ,0x08        ; αρχικοποίηση με ‘0000 1000’
back_:
  lsl r25              ; αριστερή ολίσθηση του ‘1’ τόσες θέσεις
  dec r24              ; όσος είναι ο αριθμός της γραμμής
  brne back_
  out PORTC ,r25       ; η αντίστοιχη γραμμή τίθεται στο λογικό ‘1’
  nop
  nop			             ; καθυστέρηση για να προλάβει να γίνει η αλλαγή κατάστασης
  in r24 ,PINC         ; επιστρέφουν οι θέσεις (στήλες) των διακοπτών που είναι πιεσμένοι
  andi r24 ,0x0f       ; απομονώνονται τα 4 LSB όπου τα ‘1’ δείχνουν που είναι πατημένοι
  ret                  ; οι διακόπτες.


wait_msec:
	push r24             ; 2 κύκλοι (0.250 μsec)
	push r25             ; 2 κύκλοι
	ldi r24 , low(998)   ; φόρτωσε τον καταχ. r25:r24 με 998 (1 κύκλος - 0.125 μsec)
  ldi r25 , high(998)  ; 1 κύκλος (0.125 μsec)
  rcall wait_usec      ; 3 κύκλοι (0.375 μsec), προκαλεί συνολικά καθυστέρηση 998.375 μsec
  pop r25              ; 2 κύκλοι (0.250 μsec)
  pop r24              ; 2 κύκλοι
  sbiw r24 , 1         ; 2 κύκλοι
  brne wait_msec       ; 1 ή 2 κύκλοι (0.125 ή 0.250 μsec)
  ret                  ; 4 κύκλοι (0.500 μsec)

wait_usec:
	sbiw r24 ,1		      ; 2 κύκλοι (0.250 μsec)
	nop				          ; 1 κύκλος (0.125 μsec)
	nop				          ; 1 κύκλος (0.125 μsec)
	nop				          ; 1 κύκλος (0.125 μsec)
	nop				          ; 1 κύκλος (0.125 μsec)
	brne wait_usec	    ; 1 ή 2 κύκλοι (0.125 ή 0.250 μsec)
	ret				          ; 4 κύκλοι (0.500 μsec)

;Ανάβει τα leds της PORTB για 4 sec.
on_4s:
	ser r26
	out PORTB , r26		  ; Άναμμα των LEDs της PORTB.
	ldi r24 , low(4000)
    ldi r25 , high(4000)
	rcall wait_msec     ; Καθυστέρηση 4sec.
	clr r26
	out PORTB , r26     ; Σβήσιμο των LEDs της PORTB
	ret 				        ; κι επιστροφή.

;Αναβοσβήνει τα leds της PORTB για 4 sec, με συχνότητα 0.25 sec.
blink_4s:
  ser r26             ; r26: έξοδος  (αρχικά άναμμα)
  ldi r27, 16         ; r27: counter (4/0.25=16)
repat:
  out PORTB, r26      ; Άναμμα ή σβήσιμο των LEDs της PORTB.
  ldi r24 , low(250)
  ldi r25 , high(250)
  rcall wait_msec     ; Καθυστέρηση 0.25 sec.
  com r26             ; Εναλλαγή bits εξόδου (Άναμμα/Σβήσιμο)
  dec r27             ; Μείωση counter
  cpi r27, 0          ; Όσο ο counter δεν ειναι 0
  brne repat          ; επανάλαβε
  clr r26
  out PORTB, r26       ; σβήσιμο για σιγουριά
  ret
