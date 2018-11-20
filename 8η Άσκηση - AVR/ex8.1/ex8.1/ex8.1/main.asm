;
; ex8.1.asm
;
; Created: 18-Dec-17 3:02:00 PM
; Author : Nicolas & Johnnny
;

; Εισαγωγή βοηθητικών βιβλιοθηκών.
.INCLUDE "wait.asm"
.INCLUDE "one_wire.asm"
.def temp = r18

    ;Δημιουργία της Στοίβας.
    ldi r24,LOW(RAMEND)
    out SPL,r24
    ldi r25,HIGH(RAMEND)
    out SPH,r25

start:
    rcall read_temp
    ldi r24, low(1000)
    ldi r25, high(1000)
    rcall wait_msec
    rjmp start

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
    mov r25,r24
    pop r24                         ; Στο τέλος έχουμε r25:r24 = high:low

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
