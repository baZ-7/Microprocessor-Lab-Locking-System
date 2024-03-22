#include <xc.inc>
    
global	SetPasscode_Screen, EnterPasscode_Screen, SetFingerprint_Screen, Fingerprint_Screen
global	Incorrect_Screen, Unlocked_Screen, Welcome_Screen, Alarm_Screen, Timeout_Screen
global	Display_Setup
extrn	LCD_Clear, LCD_delay_ms, LCD_Write_Message, LCD_Line2, LCD_Send_Byte_D, LCD_Write_Hex
extrn	LCD_Cursor_Off, LCD_Cursor_On, counter_cursor
extrn	buzzer_incorrect, buzzer_unlock, buzzer_press, buzzer_alarm

psect	udata_acs   ;reserve data space in access ram
counter:    ds 1    ;reserve one byte for a counter variable
    
psect	udata_bank4 ;reserve data anywhere in RAM (here at 0x400)
SetPasscode:	ds  0x0F ;reserve 16 bytes for message data
EnterPasscode:	ds  0x0F 
SetFingerprint:	ds  0x0F
Fingerprint:	ds  0x0F
Incorrect:	ds  0x0F
Unlocked:	ds  0x0F
Instruction:	ds  0x0F
Welcome:	ds  0x0F
Timeout:	ds  0x0F
Alarm:		ds  0x0F
    
psect	data    
	; ******* Table, data in programme memory, and its length *****

SetPasscodeTable:
	db	'S','e','t',' ','P','a','s','s','c','o','d','e',0x0a
	SetPasscodeTable_l   EQU    13
	align	2

EnterPasscodeTable:
	db	'E','n','t','e','r',' ','P','a','s','s','c','o','d','e',0x0a
	EnterPasscodeTable_l  EQU    15
	align	2

SetFingerprintTable:
	db	'S','e','t',' ','F','i','n','g','e','r','p','r','i','n','t',0x0a
	SetFingerprintTable_l  EQU  16
	align	2

FingerprintTable:
	db	'F','i','n','g','e','r','p','r','i','n','t',0x0a
	FingerprintTable_l   EQU    12	; length of data
	align	2
	
IncorrectTable:
	db	'I','n','c','o','r','r','e','c','t',' ',':','[',0x0a
	IncorrectTable_l    EQU	    13
	align	2
	
UnlockedTable:
	db	'U','n','l','o','c','k','e','d',0x0a
	UnlockedTable_l	    EQU	    9
	align	2

InstructionTable:
	db	'E','-','L','o','c','k',' ',' ','C','-','R','e','s','e','t',0x0a
	InstructionTable_l  EQU	    16
	align	2
	
WelcomeTable:
	db	' ',' ',' ',' ','W','e','l','c','o','m','e','!',0x0a
	WelcomeTable_l	EQU	13
	align	2
	
TimeoutTable:
	db	' ',' ',' ',' ','T','i','m','e','o','u','t',':',0x0a
	TimeoutTable_l	EQU	13
	align	2
	
AlarmTable:
	db	' ',' ',' ',' ',' ','A','L','A','R','M','!',0x0a
	AlarmTable_l	EQU	12
	align	2
	
psect	display_code, class=CODE

Display_Setup:
	bcf	CFGS	; point to Flash program memory  
	bsf	EEPGD 	; access Flash program memory
	;move all the PM tables into bank. Only needs to be done once on setup
SetPasscode_Setup:    
	lfsr    0, SetPasscode	; Load FSR0 with address in RAM	
	movlw   low highword(SetPasscodeTable)	; address of data in PM
	movwf   TBLPTRU, A		; load upper bits to TBLPTRU
	movlw   high(SetPasscodeTable)	; address of data in PM
	movwf   TBLPTRH, A		; load high byte to TBLPTRH
	movlw   low(SetPasscodeTable)	; address of data in PM
	movwf   TBLPTRL, A		; load low byte to TBLPTRL
	movlw   SetPasscodeTable_l		; bytes to read
	movwf   counter, A		; our counter register
SetPasscode_Loop: 	
	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	SetPasscode_Loop		; keep going until finished

EnterPasscode_Setup:
	lfsr	0, EnterPasscode	; Load FSR0 with address in RAM	
	movlw	low highword(EnterPasscodeTable)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(EnterPasscodeTable)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(EnterPasscodeTable)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	EnterPasscodeTable_l	; bytes to read
	movwf 	counter, A		; our counter register
EnterPasscode_Loop: 	
	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	EnterPasscode_Loop		; keep going until finished

SetFingerprint_Setup:
	lfsr	0, SetFingerprint	; Load FSR0 with address in RAM	
	movlw	low highword(SetFingerprintTable)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(SetFingerprintTable)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(SetFingerprintTable)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	SetFingerprintTable_l	; bytes to read
	movwf 	counter, A		; our counter register
SetFingerprint_Loop: 	
	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	SetFingerprint_Loop		; keep going until finished

Fingerprint_Setup:
	lfsr	0, Fingerprint	; Load FSR0 with address in RAM	
	movlw	low highword(FingerprintTable)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(FingerprintTable)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(FingerprintTable)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	FingerprintTable_l	; bytes to read
	movwf 	counter, A		; our counter register
Fingerprint_Loop: 	
	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	Fingerprint_Loop		; keep going until finished

Incorrect_Setup:
	lfsr	0, Incorrect	; Load FSR0 with address in RAM	
	movlw	low highword(IncorrectTable)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(IncorrectTable)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(IncorrectTable)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	IncorrectTable_l	; bytes to read
	movwf 	counter, A		; our counter register
Incorrect_Loop: 	
	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	Incorrect_Loop		; keep going until finished

Unlocked_Setup:
	lfsr	0, Unlocked	; Load FSR0 with address in RAM	
	movlw	low highword(UnlockedTable)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(UnlockedTable)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(UnlockedTable)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	UnlockedTable_l	; bytes to read
	movwf 	counter, A		; our counter register
Unlocked_Loop: 	
	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	Unlocked_Loop		; keep going until finished

Instruction_Setup:
	lfsr	0, Instruction	; Load FSR0 with address in RAM	
	movlw	low highword(InstructionTable)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(InstructionTable)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(InstructionTable)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	InstructionTable_l	; bytes to read
	movwf 	counter, A		; our counter register
Instruction_Loop: 	
	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	Instruction_Loop		; keep going until finished

Welcome_Setup:
	lfsr	0, Welcome	; Load FSR0 with address in RAM	
	movlw	low highword(WelcomeTable)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(WelcomeTable)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(WelcomeTable)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	WelcomeTable_l	; bytes to read
	movwf 	counter, A		; our counter register
Welcome_Loop: 	
	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	Welcome_Loop		; keep going until finished

Timeout_Setup:
	lfsr	0, Timeout	; Load FSR0 with address in RAM	
	movlw	low highword(TimeoutTable)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(TimeoutTable)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(TimeoutTable)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	TimeoutTable_l	; bytes to read
	movwf 	counter, A		; our counter register
Timeout_Loop: 	
	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	Timeout_Loop		; keep going until finished

Alarm_Setup:
	lfsr	0, Alarm	; Load FSR0 with address in RAM	
	movlw	low highword(AlarmTable)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(AlarmTable)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(AlarmTable)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	AlarmTable_l	; bytes to read
	movwf 	counter, A		; our counter register
Alarm_Loop:
	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	Alarm_Loop		; keep going until finished

	return

;Functions to call when you want to display a certain screen. all preceeded by LCD_Clear
SetPasscode_Screen:
	call    LCD_Clear
	movlw	SetPasscodeTable_l	; output message to LCD
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, SetPasscode
	call	LCD_Write_Message   ;write to LCD

	call	LCD_Line2
	movlw	0x5F		;write four underscores
	call	LCD_Send_Byte_D
	movlw	0x5F		;write four underscores
	call    LCD_Send_Byte_D
	movlw	0x5F		;write four underscores
	call    LCD_Send_Byte_D
	movlw	0x5F		;write four underscores
	call	LCD_Send_Byte_D
	call	LCD_Line2
	call	LCD_Cursor_On
	
	movlw	0xff		; delay
	call	LCD_delay_ms
	return

EnterPasscode_Screen:
	call    LCD_Clear    
	movlw	EnterPasscodeTable_l	; output message to LCD
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, EnterPasscode
	call	LCD_Write_Message

	call	LCD_Line2
	movlw	0x5F		;write four underscores
	call	LCD_Send_Byte_D
	movlw	0x5F		;write four underscores
	call    LCD_Send_Byte_D
	movlw	0x5F		;write four underscores
	call    LCD_Send_Byte_D
	movlw	0x5F		;write four underscores
	call	LCD_Send_Byte_D
	call	LCD_Line2
	call	LCD_Cursor_On
	
	movlw	0xff		; delay
	call	LCD_delay_ms
	return

SetFingerprint_Screen:
	call    LCD_Clear
	movlw	SetFingerprintTable_l	; output message to LCD
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, SetFingerprint
	call	LCD_Write_Message
	call	LCD_Cursor_Off

	movlw	0xff		; delay
	call	LCD_delay_ms
	return

Fingerprint_Screen:
	call    LCD_Clear
	movlw	FingerprintTable_l	; output message to LCD
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, Fingerprint
	call	LCD_Write_Message
	call	LCD_Cursor_Off
	
	movlw	0xff		; delay
	call	LCD_delay_ms
	return
	
Incorrect_Screen:
	call    LCD_Clear
	movlw	IncorrectTable_l	; output message to LCD
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, Incorrect
	call	LCD_Write_Message
	call	LCD_Cursor_Off
	
	movlw	0xff		; delay
	call	LCD_delay_ms
	call	buzzer_incorrect
	call	delay1s
	return

Unlocked_Screen:
	call    LCD_Clear
	movlw	UnlockedTable_l	; output message to LCD
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, Unlocked
	call	LCD_Write_Message
	call	LCD_Line2
Instruction_Screen:
	movlw	InstructionTable_l	; output message to LCD
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, Instruction
	call	LCD_Write_Message
	call	LCD_Cursor_Off
	
	movlw	0xff		; delay
	call	LCD_delay_ms
	call	delay1s
	return

Welcome_Screen:
	call    LCD_Clear
	call	LCD_Cursor_Off
	movlw	WelcomeTable_l	; output message to LCD
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, Welcome
	call	LCD_Write_Message
	
	call	buzzer_unlock
	call	LCD_Line2
Loading_Screen:
	movlw	0x10
	movwf	counter, A
Loading_Loop:
	call	delay350    ;350 ms delay
	movlw	00111110B
	call	LCD_Send_Byte_D
	decfsz	counter, A
	bra	Loading_Loop
	
	movlw	0xff		; delay
	call	LCD_delay_ms
	call	buzzer_press
	return
	
Timeout_Screen:
	call    LCD_Clear
	call	LCD_Cursor_Off
	movlw	TimeoutTable_l	; output message to LCD
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, Timeout
	call	LCD_Write_Message
	call	LCD_Line2
Timeout_Counter:
	movlw	0x09	;timeout for 10 seconds
	movwf	counter, A
Timeout_Counter_Loop:
	call	counter_cursor
	movf	counter, W, A
	call	LCD_Write_Hex
	call	delay1s
	decfsz	counter, A
	bra	Timeout_Counter_Loop
	call	buzzer_press
	return
	
Alarm_Screen:
	call    LCD_Clear
	movlw	AlarmTable_l	; output message to LCD
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, Alarm
	call	LCD_Write_Message
	call	LCD_Cursor_Off
	call	LCD_Line2
Alarm_Counter:
	movlw	0x09	;alarm for 10 seconds
	movwf	counter, A
Alarm_Counter_Loop:
	call	counter_cursor
	movf	counter, W, A
	call	LCD_Write_Hex
	call	buzzer_alarm	;play alarm sound for 1 second
	decfsz	counter, A
	bra	Alarm_Counter_Loop
	return
	
delay350:
	movlw	0xaf
	call	LCD_delay_ms
	movlw	0xaf
	call	LCD_delay_ms
	return
	
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