;
; ex8.1.asm
;
; Created: 18-Dec-17 3:02:00 PM
; Author : Nicolas & Johnnny
;


; ---- Αρχή τμήματος δεδομένων
.DSEG
	_tmp_: .byte 2
; ---- Τέλος τμήματος δεδομένων


.CSEG

; Εισαγωγή βοηθητικών βιβλιοθηκών.
.INCLUDE "wait.asm"
.INCLUDE "one_wire.asm"
.INCLUDE "screen.asm"
.INCLUDE "hex_keyboard.asm"

.def temp = r18
.def first = r19

    ; Αρχικοποίηση μεταβλητής _tmp_ .
    ldi temp, 0
    ldi r26, low(_tmp_)
    ldi r27, high(_tmp_)
    st X+, temp
    st X, temp

    ; Αρχικοποίηση της PORTC για το πληκτρολόγιο.
    ldi temp, 0xf0
    out DDRC, temp

    ;Δημιουργία της Στοίβας.
    ldi r24,LOW(RAMEND)
    out SPL,r24
    ldi r25,HIGH(RAMEND)
    out SPH,r25

    ; Αρχικοποίηση της PORTC για το πληκτρολόγιο.
	ldi temp, 0xf0
	out DDRC, temp

    ;Αρχικοποίηση της PORTD για την οθόνη LCD.
	ldi temp, 0xff
	out DDRD, temp

    ;Αρχικοποίηση οθόνης.
	rcall lcd_init

; Εκτύπωση θερμοκρασίας από τον αισθητήρα.
; Για ενεργοποίηση uncomment από εδώ
; ---------------------------------------------------------------------------- ;
; start:
;     rcall read_temp
;     rcall print_temp
;     ldi r24, low(1000)
;     ldi r25, high(1000)
;     rcall wait_msec
;     rjmp start
; ---------------------------------------------------------------------------- ;
; εως εδώ.


; Εκτύπωση θερμοκρασίας από το πληκτρολόγιο.
; Για ενεργοποίηση uncomment από εδώ
; ---------------------------------------------------------------------------- ;
start:
    ldi temp, 4
    ldi r20,0
    ldi r21,0

	rcall read_byte
	mov r21, r24
	swap r21
	rcall read_byte
	or r21, r24
	rcall read_byte
	mov r20, r24
	rcall read_byte
	or r20, r24

	mov r24,r20
	mov r25,r21
    rcall print_temp
    ldi r24, low(1000)
    ldi r25, high(1000)
    rcall wait_msec
    rjmp start
; ---------------------------------------------------------------------------- ;
; εως εδώ.

read_byte:
	ldi r24, 10
	rcall scan_keypad_rising_edge
	rcall keypad_to_hex
	cpi r24, 0
	breq read_byte
	ret

; Ρουτίνα που επιστρέφει την μετρούμενη θερμοκρασία στο ζεύγος r25:r24
; σε δυαδική μορφή συμπληρώματος ως προς 1. Αν εμφανιστεί οποιοδήποτε σφάλμα,
; επιστρέφουμε την τιμή 8000.
read_temp:
    rcall one_wire_reset            ; Αρχικοποίηση συσκευής.
    sbrs r24, 0                     ; Αν δε βρεθεί συσκευή (r24=0),
    rjmp no_device                  ; επιστρέφουμε με τιμή 8000.

    ldi r24, 0xCC                   ; Αγνοούμε τον έλεγχο για πολλές συσκευές.
    rcall one_wire_transmit_byte
    ldi r24, 0x44                   ; Ζητάμε να ξεκινήσει η μέτρηση της
    rcall one_wire_transmit_byte    ; θερμοκρασίας.

check_finished:
    rcall one_wire_receive_bit      ; Ελέγχουμε αν έχει τελειώσει η μετατροπή
    sbrs r24, 0                     ; της θερμοκρασίας (r24=1), αλλιώς
    rjmp check_finished             ; περιμένουμε.

    rcall one_wire_reset            ; Αρχικοποιούμε και πάλι τη συσκευή, γιατί
                                    ; μετά τη μέτρηση επανέρχεται σε κατάσταση
                                    ; χαμηλής κατανάλωσης ισχύος.
    sbrs r24, 0                     ; Αν αποσυνδέθηκε επιστρέφουμε με τιμή 8000.
    rjmp no_device

    ldi r24, 0xCC                   ; Αγνοούμε τον έλεγχο για πολλές συσκευές.
    rcall one_wire_transmit_byte
    ldi r24, 0xBE                   ; Ζητάμε να γίνει ανάγνωση.
    rcall one_wire_transmit_byte


    rcall one_wire_receive_byte     ; Διαβάζουμε τα 2 bytes της θερμοκρασίας.
    push r24
    rcall one_wire_receive_byte
    mov r25, r24                    ; Στο τέλος έχουμε r25:r24 = high:low
    pop r24

    sbrs r25,0
    rjmp done
    dec r24                         ; Μετατροπή από συμπλήρωμα ως προς 2 σε
                                    ; συμπλήρωμα ως προς 1.
done:
    ser temp
    out DDRA, temp
    out PORTA, r24                  ; Εκτύπωση αποτελέσματος στην PORTA.
    ret                             ; Επιστροφή της θερμοκρασίας στους r25:r24.

no_device:                          ; Επιστροφή με r25:r24 = 8000 σε περίπτωση
    ldi r25, high(8000)             ; σφάλματος.
    ldi r24, low(8000)
    ret


print_error:
    ldi r24, 0x01			        ; Καθαρισμός της οθόνης.
    rcall lcd_command
    ldi r24, low(1530)
    ldi r25, high(1530)
    rcall wait_usec
    ldi r24, 'N'			         ; Τύπωμα "NO Device".
    rcall lcd_data
    ldi r24, 'O'
    rcall lcd_data
    ldi r24, ' '
    rcall lcd_data
    ldi r24, 'D'
    rcall lcd_data
    ldi r24, 'e'
    rcall lcd_data
    ldi r24, 'v'
    rcall lcd_data
    ldi r24, 'i'
    rcall lcd_data
    ldi r24, 'c'
    rcall lcd_data
    ldi r24, 'e'
    rcall lcd_data
    ret

print_temp:
    mov temp, r24
    lsr r24                         ; Αγνοούμε το δεκαδικό ψηφίο.
    push r24
    push r25

    ldi r24, 0x01			        ; Καθαρισμός της οθόνης.
    rcall lcd_command
    ldi r24, low(1530)
    ldi r25, high(1530)
    rcall wait_usec

    pop r25                         ; Επαναφορά του r25
    ldi r24, '+'                    ; και εκτύπωση προσήμου
    sbrc r25, 0
    ldi r24, '-'
    rcall lcd_data
    sbrc r25, 0                     ; Αν ο αριθμός είναι αρνητικός (r25=0xff),
    com temp                        ; τότε υπολογίζουμε το συμπλήρωμά του.

    ldi first, 0
    ldi r24, 0

    cpi temp,100
    brlo decades
    ldi first, 1
    ldi r24, '1'
    rcall lcd_data
    subi temp,100

    ldi r24,0
decades:
    cpi temp,10
    brlo print_dec
    inc r24
    subi temp,10
    rjmp decades
print_dec:
    cpi r24,0
    sbrs first,0
    breq digit
    subi r24,-48                    ; ASCIIοποίηση δεκάδων.
    rcall lcd_data
digit:
    mov r24, temp
    subi r24,-48                    ; ASCIIοποίηση μονάδων
    rcall lcd_data

    ldi r24, 0xb2                   ; Εκτύπωση o
    rcall lcd_data
    ldi r24, 'C'
    rcall lcd_data
    ret
