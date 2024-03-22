#include <xc.inc>

extrn	LCD_Setup, LCD_delay_ms
extrn	Welcome_Screen, SetPasscode_Screen, EnterPasscode_Screen
extrn	KeyPad_Setup, KeyPad_Read, check_bit
extrn	buzzer_setup
extrn	Storage_Setup, Passcode_Check, passcode_checkbit
extrn	Display_Setup

    
psect	code, abs	
rst: 	org 0x0
 	goto	setup

	; ******* Programme Setup Code ***********************
setup:	
	call	Display_Setup
	call	LCD_Setup
	call	KeyPad_Setup
	call	Storage_Setup
	call	buzzer_setup
	call	Passcode_Check
	tstfsz	passcode_checkbit, A	;if starting up with passcode
	goto	start
	goto	start_with_passcode
	
	; ******* Main programme ****************************************

start:
	
	call    Welcome_Screen ;welcome message and loading screen
	call    SetPasscode_Screen
	goto	keypadloop
	
start_with_passcode:
	bsf	check_bit, 0, A	;go to enter mode
	bcf	check_bit, 1, A	;make sure it is locked
	movff	check_bit, PORTD
	call	EnterPasscode_Screen
	goto	keypadloop

keypadloop: ;main loop
	call	KeyPad_Read
	movlw   0x0F		; delay
	call	LCD_delay_ms
	bra	keypadloop