#include <xc.inc>
    
global	buzzer_setup, buzzer_press, buzzer_incorrect, buzzer_unlock, buzzer_alarm
extrn	LCD_delay_ms, LCD_delay_x4us

psect	udata_acs   ;reserve data in access ram
buzzer_counter_short: ds 1 ;counter for short pulse
buzzer_counter_mid: ds 1
buzzer_counter_long: ds 1 ;counter for long pulse
counter: ds 1 ;counter variable for alarm
	
psect	buzzer_code, class=CODE

buzzer_setup:
    movlw   0x30
    movwf   buzzer_counter_short, A
    movlw   0x47
    movwf   buzzer_counter_mid, A
    movlw   0x60
    movwf   buzzer_counter_long, A
    return

buzzer_press: ;beep
buzzer_loop_press:
    bsf	    PORTD, 7, A
    call    delay_mid ;medium pitch
    bcf	    PORTD, 7, A
    call    delay_mid
    decfsz  buzzer_counter_short, F, A ;short pulse
    bra	    buzzer_loop_press
    call    reset_counters
    return

buzzer_incorrect: ;bee-boop
buzzer_loop_incorrect1:
    bsf	    PORTD, 7, A
    call    delay_mid ;medium pitch
    bcf	    PORTD, 7, A
    call    delay_mid
    decfsz  buzzer_counter_short, F, A ;short pulse
    bra	    buzzer_loop_incorrect1
buzzer_loop_incorrect2:
    bsf	    PORTD, 7, A
    call    delay_low ;low pitch
    bcf	    PORTD, 7, A
    call    delay_low
    decfsz  buzzer_counter_long, F, A ;long pulse
    bra	    buzzer_loop_incorrect2
    call    reset_counters
    return

buzzer_unlock: ;bee-boo-beep
unlock_loop_mid:
    bsf	    PORTD, 7, A
    call    delay_mid ;medium pitch
    bcf	    PORTD, 7, A
    call    delay_mid
    decfsz  buzzer_counter_long, F, A ;long pulse
    bra	    unlock_loop_mid
unlock_loop_low:
    bsf	    PORTD, 7, A
    call    delay_low ;low pitch
    bcf	    PORTD, 7, A
    call    delay_low
    decfsz  buzzer_counter_mid, F, A ;medium pulse
    bra	    unlock_loop_low
unlock_loop_high:
    bsf	    PORTD, 7, A
    call    delay_high ;high pitch
    bcf	    PORTD, 7, A
    call    delay_high
    decfsz  buzzer_counter_long, F, A ;long pulse
    bra	    unlock_loop_high
    call    reset_counters
    return

buzzer_alarm:
    movlw   0x04
    movwf   counter, A
alarm_loop_high:
    bsf	    PORTD, 7, A
    call    delay_high ;high pitch
    bcf	    PORTD, 7, A
    call    delay_high
    decfsz  buzzer_counter_mid, F, A ;med pulse
    bra	    alarm_loop_high
alarm_loop_mid:
    bsf	    PORTD, 7, A
    call    delay_mid ;medium pitch
    bcf	    PORTD, 7, A
    call    delay_mid
    decfsz  buzzer_counter_short, F, A ;short pulse
    bra	    alarm_loop_mid
    call    reset_counters
    
    decfsz  counter, A
    bra	    alarm_loop_high
    return
    
delay_mid: ;mid pitch delay
    movlw   0x01
    call    LCD_delay_ms
    return
    
delay_low: ;low pitch delay
    movlw   0x01
    call    LCD_delay_ms
    movlw   0x3E
    call    LCD_delay_x4us
    return
    
delay_high: ;high pitch delay
    movlw   0xA6
    call    LCD_delay_x4us
    return

reset_counters:
    movlw   0x30
    movwf   buzzer_counter_short, A
    movlw   0x47
    movwf   buzzer_counter_mid, A
    movlw   0x60
    movwf   buzzer_counter_long, A
    return