.include "m328pdef.inc"
.include "delayMacro.inc"

.cseg

.def A = r16
.def AH = r17
.def B = r24


.org 0x00
	; I/O Pins Configuration
	SBI DDRB, 0			; Set PB0 pin for Output to BUZZER
	CBI PORTB, 0			; Clear PORTB register

	LDI B, ~(1 << PD7)  ; Set PD7 for PIR Input
	out DDRD, B
	
	; ADC Configuration for LDR
	LDI A,0b11000111	; [ADEN ADSC ADATE ADIF ADIE ADIE ADPS2 ADPS1 ADPS0]
	STS ADCSRA,A
	
	LDI A, 0b01100000	; [REFS1 REFS0 ADLAR – MUX3 MUX2 MUX1 MUX0]
	STS ADMUX, A			; Select ADC0 (PC0) pin
	SBI PORTC, PC0		; Enable Pull-up Resistor

MAIN_LOOP:
	LDS A, ADCSRA		; Start Analog to Digital Conversion
	ORI A, (1 << ADSC)
	STS ADCSRA, A

wait:
	LDS A, ADCSRA		; wait for conversion to complete
	SBRC A, ADSC
rjmp wait
	LDS A,ADCL			; Must Read ADCL before ADCH
	LDS AH,ADCH
	CPI AH,200			; compare LDR reading with our desired threshold
	brsh NIGHT			; jump if same or higher (AH >= 200)
	CBI PORTB,0			; BUZZER OFF  As it is DAYTIME
rjmp MAIN_LOOP

NIGHT:
	IN B, PIND			; Read value from PIR pin (PD7)
    ANDI B, (1 << PD7)	; Mask other bits (PD7 is 7th bit)
	CPI B,0
	brhc BUZZER_ON
rjmp MAIN_LOOP

BUZZER_ON:
		SBI PORTB,0
		delay 500
		CBI PORTB,0
rjmp MAIN_LOOP