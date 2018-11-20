/*
 * ex6.2.c
 *
 * Created: 28/11/2017 3:18:53 μμ
 * Author : Γιάνννης & Νίκος
 */ 

#include <avr/io.h>

int main(void)
{
	volatile unsigned char input;
	unsigned char answer;

	DDRA = 0x00;		//είσοδος A
	DDRC = 0xff;		//έξοδος C

	while (1)
	{
		/* Διάβασμα εισόδου. */
		input = PINA;
		/* FO=answer(5)=(ABC+CD+DE)' */
		if (((input & 0b00000111) == 0b00000111) || ((input & 0b00001100) == 0b00001100) || ((input & 0b00011000) == 0b00011000)) answer = 0b00000000; else answer = 0b00100000;
		/* F1=answer(6)=ABC+D'E' */
		if (((input & 0b00000111) == 0b00000111) || ((input & 0b00011000) == 0b00000000)) answer |= 0b01000000;
		/* F2=answer(7)=F0+F1 */
		if (answer & 0b01100000) answer |= 0b10000000;
		/* Εμφάνιση εξόδου. */
		PORTC = answer;
	}
}


