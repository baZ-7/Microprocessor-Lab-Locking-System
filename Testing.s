#include <xc.inc>

global	delay1s, Screens, reset_, enter
extrn	EnterPasscode_Screen, Fingerprint_Screen, Incorrect_Screen, Unlocked_Screen, Welcome_Screen
extrn	SetPasscode, keypadloop, check_bit, KeyPad_counter
extrn	entry, Passcode
extrn	LCD_delay_ms

psect	udata_acs   ; reserve data space in access ram
counter:    ds 1    ; reserve one byte for a counter variable   

psect	testing_code, class=CODE
    

    
reset_:
    clrf    KeyPad_counter, A
    call    SetPasscode ;set passcode
    call    keypadloop
    ;call    ConfirmPasscode ;confirmation
    ;call    keypadloop
    ;set fingerprint
    bra	    enter

enter:
    clrf    KeyPad_counter, A
    call    EnterPasscode_Screen;detect any input -> jump to enter passcode
    call    keypadloop
    ;enter fingerprint
    ;check if the passcode entered is correct
    lfsr    1, entry
    lfsr    2, Passcode
    movf    POSTINC1, W, A
    cpfseq  POSTINC2, A
    bra	    IncorrectPasscode
    movf    POSTINC1, W, A
    cpfseq  POSTINC2, A
    bra	    IncorrectPasscode
    movf    POSTINC1, W, A
    cpfseq  POSTINC2, A
    bra	    IncorrectPasscode
    movf    POSTINC1, W, A
    cpfseq  POSTINC2, A
    bra	    IncorrectPasscode
    lfsr    1, entry		;move pointer back to start
    
    bsf	    check_bit, 3, A  ;set unlock bit to unlocked
    call    Unlocked_Screen
    movlw   0x04
    movwf   KeyPad_counter, A ;to by pass the output characters
    goto    keypadloop
    
    ;jump to reset or unlock
IncorrectPasscode:
    call    Incorrect_Screen
    call    delay1s
    bra	    enter
    
testing:   
	movlw	0x05
	movwf	counter, A
Screens:
	call	EnterPasscode_Screen
	call	delay1s
	call	Fingerprint_Screen
	call	delay1s
	call	Incorrect_Screen
	call	delay1s
	call	Unlocked_Screen
	call	delay1s
	bra	Screens
	
	
	
delay1s:
	movlw	0xFF
	call	LCD_delay_ms
	movlw	0xFF
	call	LCD_delay_ms
	movlw	0xFF
	call	LCD_delay_ms
	movlw	0xFF
	call	LCD_delay_ms
	return

