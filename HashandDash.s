#include <xc.inc>
    
global	Storage_Setup, Hash_Passcode, Hash_Matching, Passcode_Check, Passcode_SetCheckbit, Passcode_ClearCheckbit, passcode_checkbit
global	ps_value, salt_byte
extrn	entry 

psect	udata_acs   ; reserve data space in access ram
conversion_byte: ds 1	    ; reserve 1 byte
ps_byte1: ds    1	    ; reserve 1 byte
ps_byte2: ds    1	    ; reserve 1 byte
ps_byteH: ds    1	    ; reserve 1 byte
ps_byteL: ds    1	    ; reserve 1 byte
ps_value: ds	1	    ; reserve 1 byte
salt_byte: ds	1	    ; reserve 1 byte for salt
RES0: ds	1	    ; reserve 1 byte for storing the values of the multiplication
RES1: ds	1	    ; reserve 1 byte
RES2: ds	1	    ; reserve 1 byte
RES3: ds	1	    ; reserve 1 byte
DATA_EE_ADDRH: ds   1	;high byte for data memory address to access
DATA_EE_ADDRL: ds   1	;low byte for data memory address to access
EE_DATA: ds	1	    ; reserve 1 byte
passcode_checkbit: ds 1	    ; reserve 1 byte
    
psect	hashing_code, class=CODE

Storage_Setup:
    bcf	RTCCFG, 2, A ;enable RTCC output 
    bsf	RTCCFG, 7, A ;enable RTCC module for system timer reading
    ;default passcode checkbit to be 0
    movlw   0x00
    movwf   passcode_checkbit, A
    movlw   0xFF
    return

Passcode_Check:
    movlw   0x0			;passcode checkbit stored into address 008 in eeprom
    movwf   DATA_EE_ADDRH, A
    movlw   0x08
    movwf   DATA_EE_ADDRL, A
    call    EEPROM_read		;reading the checkbit
    movwf   passcode_checkbit, A
    return

Passcode_SetCheckbit:
    movlw   0x0
    movwf   DATA_EE_ADDRH, A
    movlw   0x08
    movwf   DATA_EE_ADDRL, A
    movlw   0x00
    movwf   EE_DATA, A		;writing the checkbit
    call    EEPROM_write
    return
   
Passcode_ClearCheckbit:
    movlw   0x0
    movwf   DATA_EE_ADDRH, A
    movlw   0x08
    movwf   DATA_EE_ADDRL, A
    movlw   0xff		;clearing!
    movwf   EE_DATA, A		;writing the checkbit
    call    EEPROM_write
    return

Hash_Passcode:
    
    ;a salt byte is added to the 16-bit binary number to create a 24-bit number
    movlw   0x0			   ;storing the salt byte into EEPROM
    movwf   DATA_EE_ADDRH, A
    movlw   0x03
    movwf   DATA_EE_ADDRL, A
    call    pseudorandom_number	;generate 8-bit number
    movwf   EE_DATA, A		;writing the checkbit
    call    EEPROM_write
    
    ;a pseudorandom 8-bit number is generated
    movlw   0x0			    ;storing the ps_value into EEPROM
    movwf   DATA_EE_ADDRH, A
    movlw   0x04
    movwf   DATA_EE_ADDRL, A
    call    pseudorandom_number	;generate 8-bit number
    movwf   EE_DATA, A		;writing the checkbit
    call    EEPROM_write
    
    ;4 ascii values passcode input convert into 16-bit binary number
    call    Hash
    
    ;perform 24bitx8bit multiplication
    call    mult24x8

    ;the output 'hashed' value would be the least significant byte RES0 
    movff   RES0, EE_DATA, A ;into address 005
    movlw   0x0
    movwf   DATA_EE_ADDRH, A
    movlw   0x05
    movwf   DATA_EE_ADDRL, A
    call    EEPROM_write	;put the hashed value into EEPROM storage
    ;and second least significant byte RES01
    movff   RES1, EE_DATA, A ;into address 006
    movlw   0x0
    movwf   DATA_EE_ADDRH, A
    movlw   0x06
    movwf   DATA_EE_ADDRL, A
    call    EEPROM_write	;put the hashed value into EEPROM storage
    return

Hash_Matching:
    ;4 ascii values passcode input convert into 16-bit binary number
    call    Hash

    ;perform 24bitx8bit multiplication
    call    mult24x8
    
    ;matching the 005 stored value with the current RES0
    movlw   0x0		    ;look at address 005
    movwf   DATA_EE_ADDRH, A
    movlw   0x05
    movwf   DATA_EE_ADDRL, A
    call    EEPROM_read	;put stored hashed value into W
    cpfseq  RES0, A	;skip line if matching
    bra	    hash_wrong	;if not matching
    

    ;matching the 006 stored value with the current RES1
    movlw   0x0		    ;look at address 006
    movwf   DATA_EE_ADDRH, A
    movlw   0x06
    movwf   DATA_EE_ADDRL, A
    call    EEPROM_read	;put stored hashed value into W
    cpfseq  RES1, A	;skip line if matching
    bra	    hash_wrong	;if not matching
    
    
    retlw   0x00    ;output 0 for matching passcode 
    
hash_wrong: 
    retlw   0x01    ;output 1 for incorrect passcode
     

Hash:
    ;getting the salt byte and ps_value out of EEPROM
    movlw   0x0		    ;look at address 003
    movwf   DATA_EE_ADDRH, A
    movlw   0x03
    movwf   DATA_EE_ADDRL, A
    call    EEPROM_read	;put stored hashed value into W
    movwf   salt_byte
    
    movlw   0x0		    ;look at address 004
    movwf   DATA_EE_ADDRH, A
    movlw   0x04
    movwf   DATA_EE_ADDRL, A
    call    EEPROM_read	;put stored hashed value into W
    movwf   ps_value
    
    lfsr  2, entry	;go to location of first passcode ascii
    movff   POSTINC2, conversion_byte, A
    call    ASCIIto4bit
    movff   conversion_byte, ps_byteL, A ;loading 4-bit binary to ps_byteL
    movff   POSTINC2, conversion_byte, A ;go to location of second passcode ascii
    call    ASCIIto4bit
    rlncf    conversion_byte, F, A  ;shift the bits 4 to the left
    rlncf    conversion_byte, F, A
    rlncf    conversion_byte, F, A
    rlncf    conversion_byte, W, A
    iorwf   ps_byteL, F, A	    ;loading second 4-bit segment to ps_byteL 
    movff   POSTINC2, conversion_byte, A ;go to location of third passcode ascii
    call    ASCIIto4bit
    movff   conversion_byte, ps_byteH, A ;loading 4-bit binary to ps_byteL
    movff   POSTINC2, conversion_byte, A ;go to location of second passcode ascii
    call    ASCIIto4bit
    rlncf    conversion_byte, F, A  ;shift the bits 4 to the left
    rlncf    conversion_byte, F, A
    rlncf    conversion_byte, F, A
    rlncf    conversion_byte, W, A
    iorwf   ps_byteH, F, A	    ;loading second 4-bit segment to ps_byteH
    lfsr  2, entry
    return
    
pseudorandom_number:
    bcf	RTCCFG, 0, A ;point RTCVALL to the seconds module
    bcf	RTCCFG, 1, A
    movff   RTCVALL, ps_byte1, A ;moving from 'seconds' register
    bcf	    ps_byte1, 4, A	;keeping only the 4 binary values representing a number 0-9
    bcf	    ps_byte1, 5, A
    bcf	    ps_byte1, 6, A
    bcf	    ps_byte1, 7, A
    movff   RTCVALL, ps_byte2, A ;moving from 'seconds' register
    bcf	    ps_byte2, 4, A	;keeping only the 4 binary values representing a number 0-9
    bcf	    ps_byte2, 5, A
    bcf	    ps_byte2, 6, A
    bcf	    ps_byte2, 7, A
    rlcf    ps_byte2, F, A  ;shift the bits 4 to the left
    rlcf    ps_byte2, F, A
    rlcf    ps_byte2, F, A
    rlcf    ps_byte2, W, A
    iorwf   ps_byte1, W, A
    return
 
EEPROM_read:
    movff   DATA_EE_ADDRH, EEADRH, A
    movff   DATA_EE_ADDRL, EEADR, A
    BCF EECON1, 7, A ; Point to DATA memory EEPGD
    BCF EECON1, 6, A ; Access EEPROM CFGS
    BSF EECON1, 0, A ; EEPROM Read RD
    NOP
    MOVF EEDATA, W, A ; W = EEDATA
    return

EEPROM_write:
    movff   DATA_EE_ADDRH, EEADRH, A
    movff   DATA_EE_ADDRL, EEADR, A
    MOVFF EE_DATA, EEDATA, A ; Data Memory Value to write
    BCF EECON1, 7, A ; Point to DATA memory EEPGD
    BCF EECON1, 6, A ; Access EEPROM CFGS
    BSF EECON1, 2, A ; Enable writes WREN
    BCF INTCON, 7, A ; Disable Interrupts GIE
    MOVLW 0x55 ;
    MOVWF EECON2, A ; Write 55h
    MOVLW 0xAA ;
    MOVWF EECON2, A ; Write 0AAh
    BSF EECON1, 1, A ; Set WR bit to begin write WR
    BTFSC EECON1, 1, A ; Wait for write to complete 
    GOTO $-2
    BSF INTCON, 7, A ; Enable Interrupts GIE
    ; User code execution 
    BCF EECON1, 2, A ; Disable writes on write complete (EEIF set) WREN
    clrf EEDATA, A
    return
 
mult24x8:
	MOVF ps_byteL, W, A
	MULWF ps_value, A ; ARG1L * ARG2H->
	; PRODH:PRODL
	MOVFF PRODH, RES1 ;
	MOVFF PRODL, RES0 ;
	;
	MOVF salt_byte, W, A
	MULWF ps_value, A ; ARG1H * ARG2L->
	; PRODH:PRODL
	MOVFF PRODH, RES3 ;
	MOVFF PRODL, RES2 ;
	;
	MOVF ps_byteH, W, A
	MULWF ps_value, A ; ARG1M * ARG2L->
	; PRODH:PRODL
	MOVFF PRODL, WREG ;
	ADDWF RES1, F, A
	MOVFF PRODH, WREG ;
	ADDWFC RES2, F, A ; Add cross
	CLRF WREG, A ;
	ADDWFC RES3, F, A ;
	
	;clearing the salt byte and ps_value
	clrf	salt_byte, A
	clrf	ps_value, A
	return

ASCIIto4bit:	;converting ASCII values to 4-bit binary representation
    movlw   '0'
    cpfseq  conversion_byte, A
    bra	    check_1
    movlw   00000000B
    movwf   conversion_byte, A
    return
check_1:
    movlw   '1'
    cpfseq  conversion_byte, A
    bra	    check_2
    movlw   00000001B
    movwf   conversion_byte, A
    return
check_2:
    movlw   '2'
    cpfseq  conversion_byte, A
    bra	    check_3
    movlw   00000010B
    movwf   conversion_byte, A
    return
check_3:
    movlw   '3'
    cpfseq  conversion_byte, A
    bra	    check_4
    movlw   00000011B
    movwf   conversion_byte, A  
    return
check_4:
    movlw   '4'
    cpfseq  conversion_byte, A
    bra	    check_5
    movlw   00000100B
    movwf   conversion_byte, A
    return
check_5:
    movlw   '5'
    cpfseq  conversion_byte, A
    bra	    check_6
    movlw   00000101B
    movwf   conversion_byte, A
    return
check_6:
    movlw   '6'
    cpfseq  conversion_byte, A
    bra	    check_7
    movlw   00000110B
    movwf   conversion_byte, A  
    return
check_7:
    movlw   '7'
    cpfseq  conversion_byte, A
    bra	    check_8
    movlw   00000111B
    movwf   conversion_byte, A 
    return
check_8:
    movlw   '8'
    cpfseq  conversion_byte, A
    bra	    check_9
    movlw   00001000B
    movwf   conversion_byte, A  
    return
check_9:
    movlw   '9'
    cpfseq  conversion_byte, A
    bra	    check_A
    movlw   00001001B
    movwf   conversion_byte, A 
    return
check_A:
    movlw   'A'
    cpfseq  conversion_byte, A
    bra	    check_B
    movlw   00001010B
    movwf   conversion_byte, A 
    return
check_B:			    ;skip check C as 'C' reserved for clear!
    movlw   'B'
    cpfseq  conversion_byte, A
    bra	    check_D
    movlw   00001011B
    movwf   conversion_byte, A  
    return
check_D:
    movlw   'D'
    cpfseq  conversion_byte, A
    bra	    check_E
    movlw   00001100B
    movwf   conversion_byte, A
    return
check_E:
    movlw   'E'
    cpfseq  conversion_byte, A
    bra	    check_F
    movlw   00001101B
    movwf   conversion_byte, A 
    return
check_F:
    movlw   'F'
    cpfseq  conversion_byte, A
    return
    movlw   00001110B
    movwf   conversion_byte, A
    return