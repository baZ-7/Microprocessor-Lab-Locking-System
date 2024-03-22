#include <xc.inc>
    
global  KeyPad_Setup, KeyPad_Read, KeyPad_output, check_bit, entry;, Passcode
extrn	LCD_Send_Byte_D, LCD_Clear, LCD_delay_x4us
extrn	SetPasscode_Screen, EnterPasscode_Screen, Unlocked_Screen, Incorrect_Screen, Timeout_Screen, Alarm_Screen
extrn	LCD_Cursor_Off, LCD_Cursor_On
extrn	buzzer_press, buzzer_incorrect, buzzer_unlock
extrn	Hash_Passcode, Hash_Matching, Passcode_SetCheckbit, Passcode_ClearCheckbit

psect	udata_acs	;reserve data space in access ram 
KeyPad_col: ds 1
KeyPad_row: ds 1
KeyPad_total: ds 1	;8-bit binary keypad output
KeyPad_Prev: ds 1	;previous 8-bit output
KeyPad_output: ds  1	;reserve 1 byte for ascii output
KeyPad_counter: ds 1	;count number of characters being inputed
check_bit: ds 1		;bits to check for status 
			;first bit 0 for set mode, 1 for enter mode
			;second bit 0 for locked, 1 for unlocked
compare_bit: ds 1	;for comparing C and E
compare_bit_odd: ds 1	;same but reversed
incorrect_counter: ds 1 ;counting incorrect attempts
timeout_counter: ds 1	;counting number of timeouts
entry: ds 4		;4 bytes for ascii entry
;Passcode: ds 4		;4 bytes for stored passcode
test_byte: ds 1		;1 byte for testing

psect	keypad_code, class=CODE	

KeyPad_Setup:
    movlb   0x0f
    bsf	    REPU	;enable, set pull-ups
    movlb   0x00
    clrf    LATE, A	;PORT E for the keypad
    movlw   0xff
    movwf   KeyPad_Prev, A
    movlw   0x00
    movwf   KeyPad_counter, A
    lfsr    1, entry
    movlw   0x00
    movwf   check_bit, A ;initialize check bits as zeros (set mode, locked)
    movlw   0x00
    movwf   compare_bit, A
    movlw   0x01
    movwf   compare_bit_odd, A
    movlw   0x00
    movwf   incorrect_counter, A
    movlw   0x00
    movwf   timeout_counter, A
    clrf    LATD, A
    movlw   0x00
    movwf   TRISD, A ;set port d to output for status LEDs
    movff   check_bit, PORTD, A
    return

KeyPad_Read:
    movlw   0x0f	;portE 0-3 inputs
    movwf   TRISE, A
    movlw   0x05	;delay for 20 us
    call    LCD_delay_x4us 
    
    movff   PORTE, KeyPad_col	;move column values
   
    btfsc   PORTE, 4, A	    ;debouncing routine
    return		;if column is invalid, return
    btfsc   PORTE, 5, A
    return
    btfsc   PORTE, 6, A
    return
    btfsc   PORTE, 7, A
    return
   
    movlw   0xf0	;portE 4-7 inputs
    movwf   TRISE, A
    movlw   0x05	;delay for 20 us
    call    LCD_delay_x4us 
    
    movff   PORTE, KeyPad_row	;move row values
    
    btfsc   PORTE, 0, A	    ;debouncing routine
    return
    btfsc   PORTE, 1, A
    return
    btfsc   PORTE, 2, A
    return
    btfsc   PORTE, 3, A
    return
    
    movf    KeyPad_row, W, A
    iorwf   KeyPad_col, W, A
    movwf   KeyPad_total, A	;gather 8-bit number from keypad output

KeyPad_Compare:
    movf    KeyPad_total, W, A
    cpfseq  KeyPad_Prev, A	;compare with prev keypad value
    bra     KeyPad_Extract	;if not same go to extract
    return

KeyPad_Extract:
    movff   KeyPad_total, KeyPad_Prev	;put value into previous for comparisons
    call    _1_test    ;loaded keypad_output with ascii
    movlw   '='		;symbol for no input
    cpfseq  KeyPad_output, A ;check for no input
    bra	    Mode_Check
    return

Mode_Check:
    btfsc   check_bit, 1, A ;check if unlocked
    goto    unlocked_mode
    btfss   check_bit, 0, A ;check if set mode
    goto    set_mode
    goto    enter_mode

unlocked_mode:
    call    C_check
    cpfseq  compare_bit, A ;skip if not C
    bra	    unlocked_c
    call    E_check
    cpfseq  compare_bit, A ;skip if not E
    bra	    unlocked_e
    return  ;some other input -> no action

unlocked_c:
    call    resetcp
    call    Passcode_ClearCheckbit
    bcf	    check_bit, 0, A ;set mode
    bcf	    check_bit, 1, A ;locked
    movff   check_bit, PORTD, A
    call    buzzer_press
    call    SetPasscode_Screen
    return

unlocked_e:
    call    resetcp
    bsf	    check_bit, 0, A ;entry mode
    bcf	    check_bit, 1, A ;locked
    movff   check_bit, PORTD, A
    call    buzzer_press
    call    EnterPasscode_Screen
    return

set_mode:
    call    C_check
    cpfseq  compare_bit, A ;skip if not C
    bra	    set_c
    call    E_check
    cpfseq  compare_bit, A ;skip if not E
    bra	    set_e
    call    counter_check ;ret 0x00 if counter is <4
    cpfseq  compare_bit, A ;skip if counter <4
    return
    bra	    set_other

set_c:
    call    resetcp
    call    buzzer_press
    call    SetPasscode_Screen
    return

set_e:
    call    counter_check
    cpfseq  compare_bit_odd, A ;skip if counter >=4
    bra	    set_other
    ;put entry into passcode
    call    Hash_Passcode
    call    Passcode_SetCheckbit
;    lfsr    1, entry 
;    lfsr    2, Passcode
;    movff   POSTINC1, POSTINC2
;    movff   POSTINC1, POSTINC2
;    movff   POSTINC1, POSTINC2
;    movff   POSTINC1, POSTINC2
    call    reset_entry ;clear value in entry so passcode cannot be read
    call    resetcp
    bsf	    check_bit, 0, A ;entry mode
    movff   check_bit, PORTD
    call    buzzer_press
    call    EnterPasscode_Screen
    return
    
set_other:
    movf    KeyPad_output, W, A ; put ascii in w
    movwf   POSTINC1, A ;put ascii in entry
    call    LCD_Send_Byte_D ; sending character to LCD
    incf    KeyPad_counter, A ;increment counter by 1 i.e. there is a input
    call    counter_check
    cpfseq  compare_bit, A ;skip if counter <4
    call    LCD_Cursor_Off ;turn cursor off if counter is now 4
    call    buzzer_press
    return
    
enter_mode:
    call    C_check
    cpfseq  compare_bit, A ;skip if not C
    bra	    enter_c
    call    E_check
    cpfseq  compare_bit, A ;skip if not E
    bra	    enter_e
    call    counter_check
    cpfseq  compare_bit, A ;skip if counter <4
    return
    bra	    enter_other

enter_c:
    call    resetcp
    call    buzzer_press
    call    EnterPasscode_Screen
    return

enter_e:
    call    counter_check
    cpfseq  compare_bit_odd, A ;skip if counter >=4
    bra	    enter_other
    ;check entry vs passcode
;    lfsr    1, entry
;    lfsr    2, Passcode
;    movf    POSTINC1, W, A
;    cpfseq  POSTINC2, A
;    bra	    IncorrectPasscode
;    movf    POSTINC1, W, A
;    cpfseq  POSTINC2, A
;    bra	    IncorrectPasscode
;    movf    POSTINC1, W, A
;    cpfseq  POSTINC2, A
;    bra	    IncorrectPasscode
;    movf    POSTINC1, W, A
;    cpfseq  POSTINC2, A
;    bra	    IncorrectPasscode
    call    Hash_Matching
    movwf   test_byte, A
    tstfsz  test_byte, A
    bra	    IncorrectPasscode ;output 1 for incorrect passcode
    
    bsf	    check_bit, 1, A ;correct passcode, unlocked!
    movff   check_bit, PORTD
    clrf    incorrect_counter, A    ;clear counters
    clrf    timeout_counter, A
    call    reset_entry
    call    buzzer_unlock
    call    Unlocked_Screen
    return
    
enter_other:
    movf    KeyPad_output, W, A ; put ascii in w
    movwf   POSTINC1, A ;put ascii in entry
    call    LCD_Send_Byte_D ; sending character to LCD
    incf    KeyPad_counter, A ;increment counter by 1 i.e. there is a input
    call    counter_check
    cpfseq  compare_bit, A ;skip if counter <4
    call    LCD_Cursor_Off ;turn cursor off if counter is now 4
    call    buzzer_press
    return

IncorrectPasscode:
    call    resetcp
    call    Incorrect_Screen
    incf    incorrect_counter, A ;counter for incorrect attempts
    movlw   0x03
    cpfslt  incorrect_counter, A ;timeout if three or more incorrect attempts	    
    call    Timeout
    call    EnterPasscode_Screen
    return

Timeout:
    incf    timeout_counter, A
    movlw   0x03
    cpfslt  timeout_counter, A ;alarm if 3 or more timeouts ;skip if f less than w
    bra	    Alarm
    call    Timeout_Screen
    return
Alarm:
    call    Alarm_Screen    ;play the alarm
    return
    
;testing the keypad total 8-bit number to get the corresponding ascii
_1_test:
    movlw   01110111B
    cpfseq  KeyPad_total, A
    bra	    _2_test
    movlw   '1'
    movwf   KeyPad_output, A
    return
_2_test:
    movlw   10110111B
    cpfseq  KeyPad_total, A
    bra	    _3_test
    movlw   '2'
    movwf   KeyPad_output, A
    return
_3_test:
    movlw   11010111B
    cpfseq  KeyPad_total, A
    bra	    F_test
    movlw   '3'
    movwf   KeyPad_output, A
    return
F_test:
    movlw   11100111B
    cpfseq  KeyPad_total, A
    bra	    _4_test
    movlw   'F'
    movwf   KeyPad_output, A
    return
_4_test:
    movlw   01111011B
    cpfseq  KeyPad_total, A
    bra	    _5_test
    movlw   '4'
    movwf   KeyPad_output, A
    return
_5_test:
    movlw   10111011B
    cpfseq  KeyPad_total, A
    bra	    _6_test
    movlw   '5'
    movwf   KeyPad_output, A
    return
_6_test:
    movlw   11011011B
    cpfseq  KeyPad_total, A
    bra	    E_test
    movlw   '6'
    movwf   KeyPad_output, A
    return
E_test:
    movlw   11101011B
    cpfseq  KeyPad_total, A
    bra	    _7_test
    movlw   'E'
    movwf   KeyPad_output, A
    return
_7_test:
    movlw   01111101B
    cpfseq  KeyPad_total, A
    bra	    _8_test
    movlw   '7'
    movwf   KeyPad_output, A
    return
_8_test:
    movlw   10111101B
    cpfseq  KeyPad_total, A
    bra	    _9_test
    movlw   '8'
    movwf   KeyPad_output, A
    return
_9_test:
    movlw   11011101B
    cpfseq  KeyPad_total, A
    bra	    D_test
    movlw   '9'
    movwf   KeyPad_output, A
    return
D_test:
    movlw   11101101B
    cpfseq  KeyPad_total, A
    bra	    A_test
    movlw   'D'
    movwf   KeyPad_output, A
    return
A_test:
    movlw   01111110B
    cpfseq  KeyPad_total, A
    bra	    _0_test
    movlw   'A'
    movwf   KeyPad_output, A
    return
_0_test:
    movlw   10111110B
    cpfseq  KeyPad_total, A
    bra	    B_test
    movlw   '0'
    movwf   KeyPad_output, A
    return
B_test:
    movlw   11011110B
    cpfseq  KeyPad_total, A
    bra	    C_test
    movlw   'B'
    movwf   KeyPad_output, A
    return
C_test:
    movlw   11101110B
    cpfseq  KeyPad_total, A
    bra	    no_input_test
    movlw   'C'
    movwf   KeyPad_output, A
    return
no_input_test:
    movlw   11111111B
    cpfseq  KeyPad_total, A
    movwf   KeyPad_Prev, A
    movlw   '='
    movwf   KeyPad_output, A
    return
    
C_check:
    movlw   'C'
    cpfseq  KeyPad_output, A
    retlw   0x00
    retlw   0x01    ;return 1 if output is 'C'

E_check:
    movlw   'E'
    cpfseq  KeyPad_output, A
    retlw   0x00
    retlw   0x01    ;return 1 if output is 'E'

counter_check:
    movlw   0x03
    cpfsgt  KeyPad_counter, A ;skip if counter is 4 (or more)
    retlw   0x00
    retlw   0x01 ;return 0x01 if counter is 4 (or more)

resetcp:    ;reset counter and entry pointer
    movlw   0x00
    movwf   KeyPad_counter, A
    lfsr    1, entry
    return
    
reset_entry:	;reset entry values
    lfsr    1, entry
    movlw   0x00
    movwf   POSTINC1, A
    movwf   POSTINC1, A
    movwf   POSTINC1, A
    movwf   POSTINC1, A
    return