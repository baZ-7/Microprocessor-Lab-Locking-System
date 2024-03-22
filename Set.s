;#include <xc.inc>
;    
;global	SetPasscode, SetFingerprint
;extrn	LCD_Clear, LCD_delay_ms, LCD_Write_Message, LCD_Line2, LCD_Send_Byte_D
;extrn	LCD_Cursor_Off, LCD_Cursor_On
;
;psect	udata_acs   ; reserve data space in access ram
;counter:    ds 1    ; reserve one byte for a counter variable
;    
;psect	udata_bank5 ; reserve data anywhere in RAM (here at 0x400)
;myArray1:   ds	0x80 ; reserve 128 bytes for message data
;psect	udata_bank6
;myArray2:   ds	0x80
;    
;psect	data    
;	; ******* Table, data in programme memory, and its length *****
;FingerprintTable:
;	db	'S','e','t',' ','F','i','n','g','e','r','p','r','i','n','t',0x0a
;	FingerprintTable_1  EQU	    16
;	align	2
;
;PasscodeTable:
;	db	'S','e','t',' ','P','a','s','s','c','o','d','e',0x0a
;					; message, plus carriage return
;	PasscodeTable_1   EQU	13	; length of data
;	align	2
;	
;psect	set_code, class=CODE
;
;SetFingerprint:
;	call    LCD_Clear
;	bcf	CFGS	; point to Flash program memory  
;	bsf	EEPGD 	; access Flash program memory
;	
;;Display 'Set Fingerprint' message
;start1: 
;	lfsr	0, myArray1	; Load FSR0 with address in RAM	
;	movlw	low highword(FingerprintTable)	; address of data in PM
;	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
;	movlw	high(FingerprintTable)	; address of data in PM
;	movwf	TBLPTRH, A		; load high byte to TBLPTRH
;	movlw	low(FingerprintTable)	; address of data in PM
;	movwf	TBLPTRL, A		; load low byte to TBLPTRL
;	movlw	FingerprintTable_1	; bytes to read
;	movwf 	counter, A		; our counter register
;	
;loop1: 	
;	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
;	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
;	decfsz	counter, A		; count down to zero
;	bra	loop1		; keep going until finished
;    
;	movlw	FingerprintTable_1	; output message to LCD
;	addlw	0xff		; don't send the final carriage return to LCD
;	lfsr	2, myArray1
;	call	LCD_Write_Message
;	
;	call	LCD_Cursor_Off
;
;	return
;
;SetPasscode:
;	call    LCD_Clear
;	bcf	CFGS	; point to Flash program memory  
;	bsf	EEPGD 	; access Flash program memory
;;Display 'Set Passcode' message
;start2: 
;	call    LCD_Clear
;	lfsr	0, myArray2	; Load FSR0 with address in RAM	
;	movlw	low highword(PasscodeTable)	; address of data in PM
;	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
;	movlw	high(PasscodeTable)	; address of data in PM
;	movwf	TBLPTRH, A		; load high byte to TBLPTRH
;	movlw	low(PasscodeTable)	; address of data in PM
;	movwf	TBLPTRL, A		; load low byte to TBLPTRL
;	movlw	PasscodeTable_1		; bytes to read
;	movwf 	counter, A		; our counter register
;	
;loop2: 	
;	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
;	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
;	decfsz	counter, A		; count down to zero
;	bra	loop2		; keep going until finished
;    
;	movlw	PasscodeTable_1	; output message to LCD
;	addlw	0xff		; don't send the final carriage return to LCD
;	lfsr	2, myArray2
;	call	LCD_Write_Message
;
;	call	LCD_Line2
;	movlw	0x5F		;write four underscores
;	call	LCD_Send_Byte_D
;	movlw	0x5F		;write four underscores
;	call    LCD_Send_Byte_D
;	movlw	0x5F		;write four underscores
;	call    LCD_Send_Byte_D
;	movlw	0x5F		;write four underscores
;	call	LCD_Send_Byte_D
;	call	LCD_Line2
;	
;	call	LCD_Cursor_On
;	
;	return