/*
 * chasiki.asm
 *
 *  Created: 25.03.2021 20:50:24
 *   Author: HP
 */ 
.include "m328Pdef.inc"

.equ edmin = 2
.equ dmin = 1
.equ edhour = 3
.equ dhour = 4
.equ second = 0
.equ set_flag = 5
.equ set_hour = 6

.equ SHIFT_NUMBER = 6
.equ SHIFT_TAYM = 9
.equ SHIFT_TAYM_DSEC= 10
.equ SHIFT_TAYM_EDSEC = 11
.equ SHIFT_TAYM_EDMIN = 12
.equ SHIFT_TAYM_DMIN = 13

.equ light_on = 0;]
.equ light_off = 1;]
.equ stop = 2;]
.equ start = 3;]           flag
.equ INT1_AKT = 4;]
.equ INT2_AKT = 5;]
.equ INT3_AKT = 6;]
.equ INT4_AKT = 7;]

.equ eddata = 0
.equ ddata = 1
.equ week = 2
.equ edmonth = 3
.equ dmonth = 4
.equ edyear = 5
.equ dyear = 6

;flag1:

.equ SETTING_MIN = 0
.equ SETTING_HOUR =1

 .def temp = r16
 .def data = r17
 .def cloc = r20; регистр счета для индикации
 .def flag = r19; регистр для отслеживания состояния
 .def flag1 = r18

 .dseg
 RAS: .byte 16
 cloc_taym: .byte 3
 BUFER1: .byte 4
 BUFER2: .byte 4
 BUFER3: .byte 4
 DATA_BUF: .byte 7
 .cseg
.org $000
rjmp reset

.org 0x0006 
jmp PCINT0_int
.org 0x0012 
jmp TIM2_OVF
;.org 0x0016 
;jmp TIM1_COMPA
.org 0x001C 
jmp TIM0_COMPA

	NUMBER: .db 0b11010111, 0b00010100, 0b11001101, 0b01011101, 0b00011110, 0b01011011, 0b11011011, 0b00010101, 0b11011111, 0b01011111, 0b00000000
	ADRES: .dw TAYM, budil, CALEND, SETTING

 Reset:
 	ldi TEMP, HIGH (RAMEND)
	OUT SPH, TEMP
	ldi TEMP, LOW (RAMEND)
	OUT SPL, TEMP

	;инициализация таймера0 для индикации
	ldi temp, (1<<WGM01)
	out TCCR0A, temp
	ldi temp, (1<<CS02)
	out TCCR0B, temp
	ldi temp, (1<<OCIE0A)
	sts TIMSK0, temp
	ldi temp, 25
	out OCR0A, temp

	cbi PORTB, PB5
	sbi ddrb, PB5
	;sbi DDRB, PB4
	;sbi PORTB, PB4

	sbi portb, pb0
	sbi portb, pb1
	sbi portb, pb2
	sbi portb, pb3

	;настройка прерываний кнопки
	ldi temp, (1<<PCINT1)|(1<<PCINT2)|(1<<PCINT3)|(1<<PCINT0)
	sts PCMSK0, temp
	ldi temp, (1<<PCIE0)
	sts PCICR, temp

	ser temp
	OUT DDRD, TEMP
	OUT DDRC, TEMP

;	cycle_pic:;
;	in temp, portc
;	com temp
;	out portc, temp
;	ldi r22, 200
;	ldi r21, 5
;	delay_3:
;	ldi r22,200
;	delay_4:
;	dec r22
;	brne delay_4
;	dec r21
;	brne delay_3
;	jmp cycle_pic
	
	ldi temp, 0
	mov r4, temp
	sts RAS+edhour, temp
	ldi temp, 2
	sts RAS+dhour, temp
	ldi temp, 5
	sts RAS+dmin, temp
	ldi temp, 4
	sts RAS+edmin, temp

;		delay:
	ser r20
	delay2:
	ser r21
	delay3:
	ser r22
	delay4:
	dec r22
	brne delay4
	dec r21
	brne delay3
	dec r20
	brne delay2
;	dec r23
	;brne delay

	cli
	;инициализация таймера для часов
	ldi temp, (1<<CS22)|(1<<CS20)
	sts TCCR2B, temp
	clr temp
	sts TCNT2, temp
	ldi temp, (1<<AS2)
	sts ASSR, temp
	ldi temp, (1<<TCNT2)|(1<<OCIE2A)
	sts TIMSK2, TEMP


	;настройка спящего режима
;	ldi temp, (1<<SM1)|(1<<SM0);|(1<<SE)
;	out SMCR, temp
;	ldi temp, 0b10101111
;	sts PRR, temp

clr flag
;cbr flag, light_off
	
	CICLE:
	sei
	jmp CICLE

DELAY_INT:
	ldi r20, 10
	delay22:
	ser r21
	delay43:
	ser r22
	delay44:
	dec r22
	brne delay44
	dec r21
	brne delay43
	dec r20
	brne delay22
	ret



PCINT0_int:
;call DELAY_INT
clr temp
sts PCICR, temp
	ldi temp, (1<<OCIE0A);
	sts TIMSK0, temp;

	clr flag
	mov r4, flag
	in temp, pinb
COM TEMP
andi temp, 0b00001111
cpse temp, flag
jmp NOT_EXIT_INT
	EXIT_INT:
clr flag
sts TIMSK0, flag;
out portc, flag
	ldi temp, (1<<PCIE0)
	sts PCICR, temp
	clr temp
sts TIMSK1, temp
	jmp CICLE

NOT_EXIT_INT:
nop
clr flag
sts PCICR, flag
cli
ldi temp, (1<<WGM12)
sts TCCR1A, temp
ldi temp, (1<<CS11);|(1<<CS11)
sts TCCR1B, temp
ldi temp, 0Xa1
sts OCR1AL, temp
ldi temp, 0x0
sts OCR1AH, temp
ldi temp, 1<<OCIE1A
sts TIMSK1, temp


CICL:
sbi TIFR1 , OCF1A
	sei
	PAUS_10:
		SBIS  TIFR1 , OCF1A
		jmp PAUS_10
		nop
		cli
in temp, pinb
COM TEMP
andi temp, 0b00001111
cpi temp, 0b00
breq EXIT_INT

sbic pinb, pb3
jmp cicl;brne cicl;

cli
CYCL:
clr flag
in temp, pinb
COM TEMP
andi temp, 0b00001111
cpse temp, flag
jmp cycl


clr flag
sts RAS+shift_number +2, flag
cli
ldi temp, 10
sts RAS+SHIFT_NUMBER+1, temp
sts RAS+SHIFT_NUMBER+3, temp
sts RAS+SHIFT_NUMBER+4, temp
ldi temp, SHIFT_NUMBER
mov r4, temp;r4 - прибавление к адресу вывода


;jmp CICLE

;TIM1_COMPA:

	PAUS_1:
	sbi TIFR1 , OCF1A
	sei
	PAUS_11:
		SBIS  TIFR1 , OCF1A
		jmp PAUS_11
		nop
		cli
		
;		clr temp
;		sts TCNT1H, temp;
;		sts TCNT1L, temp
lds flag, RAS+SHIFT_NUMBER+2
	SBIS PINB, pb1
	inc flag
	nop
	cpi flag, 4
	brsh OBNULEN
	NOT_OB:
	sts RAS+SHIFT_NUMBER+2, flag
	
	SBIC pinb, pb2
	jmp paus_1
	nop

	lsl flag

	ldi ZL, low(ADRES*2)
	ldi ZH, high(adres*2)

	clr temp
	clc
	add Zl, flag
	adc ZH, temp

	lpm flag1, Z+
	lpm flag, Z
	MOVW ZH:ZL, flag1:flag

	ijmp
	
	OBNULEN:
	ldi flag, 255
	jmp NOT_OB

	DECREMENT:
	lds temp, RAS+SHIFT_TAYM_EDSEC
	dec temp
	sts RAS+SHIFT_TAYM_EDSEC, temp
	cpi temp, 255
	brne EXIT_DEC
	ldi temp, 9
	sts RAS+SHIFT_TAYM_EDSEC, temp
	lds temp, RAS+SHIFT_TAYM_DSEC
	dec temp
	sts RAS+SHIFT_TAYM_DSEC, temp
	cpi temp, 255
	brne EXIT_DEC
	ldi temp, 5
	sts RAS+SHIFT_TAYM_DSEC, temp

	lds temp, RAS+SHIFT_TAYM_EDmin
	dec temp
	sts RAS+SHIFT_TAYM_EDmin, temp
	cpi temp, 255
	brne EXIT_DEC
	ldi temp, 9
	sts RAS+SHIFT_TAYM_EDMIN, temp
	lds temp, RAS+SHIFT_TAYM_DMIN
	dec temp
	sts RAS+SHIFT_TAYM_DMIN, temp
	cpi temp, 255
	brne EXIT_DEC
	ldi temp, 5
	sts RAS+SHIFT_TAYM_DMIN, temp

TIM2_OVF:
	push data
	push temp

	

	mov temp, r5
	cpi temp, 100
	breq DECREMENT
;	ldi temp, 100
;	mov r5, temp
		EXIT_DEC:
	mov temp, r3
	com temp
	ori temp, 0b11011111
	mov r3, temp
	ldi temp, 60
	lds data, ras+second
	inc data
	sts RAS+second, DATA
	cpse data, temp
	rjmp TIM2_END
	CLR DATA
	sts RAS+second, DATA


	ldi temp, 10
	lds data, RAS+edmin
	inc data
	sts RAS+edmin, DATA
	cpse data, temp
	rjmp TIM2_END
	CLR DATA
	sts RAS+edmin, DATA

	
	ldi temp, 6
	lds data, RAS+dmin
	inc data
	sts RAS+dmin, DATA
	cpse data, temp
	rjmp TIM2_END
	CLR DATA
	sts RAS+dmin, DATA
	
	ldi temp, 4
	lds data, RAS+edhour
	inc data
	sts RAS+edhour, DATA
	CP data, temp
	BREQ TIM2_END_ALL
	ERROR:
	ldi temp, 10
	lds data, RAS+edhour
	sts RAS+edhour, DATA
	cpse data, temp
	rjmp TIM2_END
	CLR DATA
	sts RAS+edhour, DATA

	lds data, RAS+dhour
	cpi data, 10
	breq TIM_CLEAR
	inc data
	sts RAS+dhour, DATA



	TIM2_END:
	pop temp
	pop data
	
;	sleep
	reti

	TIM_CLEAR:
	ldi data, 1
	sts RAS+dhour, DATA
	pop temp
	pop data
	reti

	TIM2_END_ALL:
	lds data, RAS+dhour
	LDI TEMP, 2
	CP DATA, TEMP
	BREQ OBNUL
	jmp ERROR
	OBNUL:
	CLR DATA
	sts RAS+edhour, data
	ldi data, 10
	sts RAS+dhour, DATA
	call COUNTER
	pop temp
	pop data
;	sleep
	reti

	




TIM0_COMPA:
	sbis portb, pb5
	jmp not_onen
	nop
	in temp, portc
	andi temp, 0b00010000
	cpi temp, 0
	breq ldi_one
	cbi portc, pc4
	jmp not_onen
	ldi_one:
	sbi portc, pc4
	not_onen:
	inc cloc;
	push cloc
	ldi temp, 0b1
	dec cloc
	brne INTER_SDVIG
	rjmp NOT_INTER
	INTER_SDVIG:
	lsl temp
	dec cloc
	brne INTER_SDVIG
	NOT_INTER:
	ser data
	out PORTD, data
	in cloc, portc
	andi cloc, 0b00010000
	or temp, cloc
	OUT PORTC, TEMP
	pop cloc
	cli

	ldi YL, low(ras)
	add YL, cloc
	add YL, r4
	ldi YH, high(ras)
	clr temp
	adc YH, temp
	ld data, Y
	cpi cloc, 4
	brsh NOT_3
	jmp not_not
	NOT_3:
	clr cloc

	NOT_NOT:
	ldi zl, low((NUMBER)*2)
	add zl, data
	ldi zh, high((number)*2)
	clr temp
	adc zh, temp
	lpm temp, z

	in data, PINC
	lsl data
	lsl data
	lsl data
	com data
	or data, r3

	com temp
	and temp, data
	out PORTD, temp


	reti




TAYM:
cli
cbi PORTB, PB5

lds temp, BUFER1
	sts RAS+SHIFT_TAYM_EDSEC, temp
	lds temp, BUFER1+1
	sts RAS+SHIFT_TAYM_DSEC, temp
	lds temp, BUFER1+2
	sts RAS+SHIFT_TAYM_EDMIN, temp
	lds temp, BUFER1+3
	sts RAS+SHIFT_TAYM_DMIN, temp

clr flag
	mov r5, flag
CYCL1:
in temp, pinb
COM TEMP
andi temp, 0b00001111
cpse temp, flag
jmp cycl1
clr temp
	sts TCNT1H, temp;
	sts TCNT1L, temp
ldi temp, SHIFT_TAYM
mov r4, temp;r4 - прибавление к адресу вывода
clr flag

CICL_TAYM:
sbi TIFR1 , OCF1A
sei
	PAUS_TAYM_1:
		SBIS  TIFR1 , OCF1A
		jmp PAUS_TAYM_1
		nop
		cli
	
	;clr temp
;	sts TCNT1H, temp;
;		sts TCNT1L, temp
	SBIS PINB, pb1
	call inc_flag
	nop
return_inc:
	SBIS PINB, pb3
	call FLAG_DEC
	nop
return_dec:
	SBIC pinb, pb2
	jmp CICL_TAYM
	cli
ldi temp, SHIFT_TAYM
mov r4, temp;r4 - прибавление к адресу вывода
	
CYCL2:
clr flag
in temp, pinb
COM TEMP
andi temp, 0b00001111
cpse temp, flag
jmp cycl2
clr temp
	sts TCNT1H, temp;
	sts TCNT1L, temp
PAUS_TAYM_22:
	sbi TIFR1 , OCF1A
	sei
	PAUS_TAYM_2:
		SBIS  TIFR1 , OCF1A
		jmp PAUS_TAYM_2
		nop
		cli
	SBIS PINB, pb1
	call inc_flag_min
	nop
	return_inc_min:
	SBIS PINB, pb3
;	jmp FLAG_DEC_min
	nop
	return_dec_min:
	SBIC pinb, pb2
	jmp PAUS_TAYM_22

	lds temp, RAS+SHIFT_TAYM_EDSEC
	sts BUFER1, temp
	lds temp, RAS+SHIFT_TAYM_DSEC
	sts BUFER1+1, temp
	lds temp, RAS+SHIFT_TAYM_EDMIN
	sts BUFER1+2, temp
	lds temp, RAS+SHIFT_TAYM_DMIN
	sts BUFER1+3, temp
	

clr temp
	sts TCNT1H, temp;
	sts TCNT1L, temp

	ldi temp, 100
	mov r5, temp
CICL_TIME:
	sbi TIFR1 , OCF1A
	sei
	PAUS_TAYM_3:
		SBIS  TIFR1 , OCF1A
		jmp PAUS_TAYM_3
		nop
		cli
	lds temp, RAS+SHIFT_TAYM_DMIN
	lds FLAG, RAS+SHIFT_TAYM_EDMIN
	add temp, flag
	lds FLAG, RAS+SHIFT_TAYM_DSEC 
	adc temp, flag
	lds FLAG, RAS+SHIFT_TAYM_EDSEC
	adc temp, flag
	cpi temp, 0
	brne CICL_TIME	
	cli
	sbi PORTB, PB5
		CYCL_DELAY:
clr flag
in temp, pinb
COM TEMP
andi temp, 0b00001111
cpse temp, flag
jmp cycl_DELAY
		NEXT:
		clr flag	
	mov r4, flag
	mov r5, flag
		CICL_RET:
	sbi TIFR1 , OCF1A
	sei
	PAUS_TAYM_4:
		SBIS  TIFR1 , OCF1A
		jmp PAUS_TAYM_4
		nop
		cli
		sbis pinb, pb3
		jmp TAYM
		sbis pinb, pb1
		jmp BUF1_RAS
		;sbis pinb, pb1
	;	jmp BUF2_RAS
		sbic pinb, pb2
		jmp CICL_RET
		nop

	cli
	cbi PORTB, PB5
	clr flag
	sts TIMSK0, flag;
	sts TIMSK1, flag
	out portc, flag
	ldi temp, (1<<PCIE0)
	sts PCICR, temp
	jmp CICLE
	

;	CYCL_DELAY:
;clr flag
;in temp, pinb
;C;OM TEMP
;andi temp, 0b00001111
;cpse temp, flag
;jmp cycl_DELAY
;ret

inc_flag:
	lds temp, RAS+SHIFT_TAYM_EDSEC
	inc temp
	sts RAS+SHIFT_TAYM_EDSEC, temp
	cpi temp, 10
	brsh INC_FLAG_DSEG
	ret
INC_FLAG_DSEG:
	clr temp
	sts RAS+SHIFT_TAYM_EDSEC, temp
	lds temp, RAS+SHIFT_TAYM_DSEC
	inc temp
	sts RAS+SHIFT_TAYM_DSEC, temp
	cpi temp, 6
	brsh CLEAR_FLAG_SEC
	ret
CLEAR_FLAG_SEC:
	clr temp
	sts RAS+SHIFT_TAYM_DSEC, temp
	ret

FLAG_DEC:
	lds temp, RAS+SHIFT_TAYM_EDSEC
	dec temp
	cpi temp, 255
	breq DEC_FLAG_DSEC
	sts RAS+SHIFT_TAYM_EDSEC, temp
	ret
DEC_FLAG_DSEC:
	ldi temp, 9
	sts RAS+SHIFT_TAYM_EDSEC, temp
	lds temp, RAS+SHIFT_TAYM_DSEC
	dec temp
	cpi temp, 255
	breq CLEAR_FLAG_SEC_DEC
	sts RAS+SHIFT_TAYM_DSEC, temp
	ret
CLEAR_FLAG_SEC_DEC:
	ldi temp, 5
	sts RAS+SHIFT_TAYM_DSEC, temp
	ret


inc_flag_min:
	lds temp, RAS+SHIFT_TAYM_EDMIN
	inc temp
	sts RAS+SHIFT_TAYM_EDMIN, temp
	cpi temp, 10
	brsh INC_FLAG_DMIN
	RET
INC_FLAG_DMIN:
	clr temp
	sts RAS+SHIFT_TAYM_EDMIN, temp
	lds temp, RAS+SHIFT_TAYM_DMIN
	inc temp
	sts RAS+SHIFT_TAYM_DMIN, temp
	cpi temp, 6
	brsh CLEAR_FLAG_MIN
	RET
CLEAR_FLAG_MIN:
	clr temp
	sts RAS+SHIFT_TAYM_DMIN, temp
	RET

FLAG_DEC_min:
	lds temp, RAS+SHIFT_TAYM_EDMIN
	dec temp
	cpi temp, 255
	breq DEC_FLAG_DMIN
	sts RAS+SHIFT_TAYM_EDMIN, temp
	ret
DEC_FLAG_DMIN:
	ldi temp, 9
	sts RAS+SHIFT_TAYM_EDMIN, temp
	lds temp, RAS+SHIFT_TAYM_DMIN
	dec temp
	cpi temp, 255
	breq CLEAR_FLAG_MIN_DEC 
	sts RAS+SHIFT_TAYM_DMIN, temp
	ret
CLEAR_FLAG_MIN_DEC:
	ldi temp, 5
	sts RAS+SHIFT_TAYM_DMIN, temp
	ret


BUF1_RAS:
			cbi PORTB, PB5

	lds temp, BUFER2
	sts RAS+SHIFT_TAYM_EDSEC, temp
	lds temp, BUFER2+1
	sts RAS+SHIFT_TAYM_DSEC, temp
	lds temp, BUFER2+2
	sts RAS+SHIFT_TAYM_EDMIN, temp
	lds temp, BUFER2+3
	sts RAS+SHIFT_TAYM_DMIN, temp

clr flag
	mov r5, flag
CYCL17:
in temp, pinb
COM TEMP
andi temp, 0b00001111
cpse temp, flag
jmp cycl17
clr temp
	sts TCNT1H, temp;
	sts TCNT1L, temp
ldi temp, SHIFT_TAYM
mov r4, temp;r4 - прибавление к адресу вывода
clr flag

CICL_TAYM7:
sbi TIFR1 , OCF1A
sei
	PAUS_TAYM_17:
		SBIS  TIFR1 , OCF1A
		jmp PAUS_TAYM_17
		nop
		cli
	
	;clr temp
;	sts TCNT1H, temp;
;		sts TCNT1L, temp
	SBIS PINB, pb1
	call inc_flag
	nop
;;return_inc:
	SBIS PINB, pb3
	call FLAG_DEC
	nop
;return_dec:
	SBIC pinb, pb2
	jmp CICL_TAYM7
	cli
ldi temp, SHIFT_TAYM
mov r4, temp;r4 - прибавление к адресу вывода
	
CYCL27:
clr flag
in temp, pinb
COM TEMP
andi temp, 0b00001111
cpse temp, flag
jmp cycl27
clr temp
	sts TCNT1H, temp;
	sts TCNT1L, temp
PAUS_TAYM_227:
	sbi TIFR1 , OCF1A
	sei
	PAUS_TAYM_27:
		SBIS  TIFR1 , OCF1A
		jmp PAUS_TAYM_27
		nop
		cli
	SBIS PINB, pb1
	call inc_flag_min
	nop
;	return_inc_min:
	SBIS PINB, pb3
;	jmp FLAG_DEC_min
	nop
;	return_dec_min:
	SBIC pinb, pb2
	jmp PAUS_TAYM_227

	lds temp, RAS+SHIFT_TAYM_EDSEC
	sts BUFER2, temp
	lds temp, RAS+SHIFT_TAYM_DSEC
	sts BUFER2+1, temp
	lds temp, RAS+SHIFT_TAYM_EDMIN
	sts BUFER2+2, temp
	lds temp, RAS+SHIFT_TAYM_DMIN
	sts BUFER2+3, temp
	

clr temp
	sts TCNT1H, temp;
	sts TCNT1L, temp

	ldi temp, 100
	mov r5, temp
CICL_TIME7:
	sbi TIFR1 , OCF1A
	sei
	PAUS_TAYM_37:
		SBIS  TIFR1 , OCF1A
		jmp PAUS_TAYM_37
		nop
		cli
	lds temp, RAS+SHIFT_TAYM_DMIN
	lds FLAG, RAS+SHIFT_TAYM_EDMIN
	add temp, flag
	lds FLAG, RAS+SHIFT_TAYM_DSEC 
	adc temp, flag
	lds FLAG, RAS+SHIFT_TAYM_EDSEC
	adc temp, flag
	cpi temp, 0
	brne CICL_TIME7	
	cli
	sbi PORTB, PB5
		CYCL_DELAY7:
clr flag
in temp, pinb
COM TEMP
andi temp, 0b00001111
cpse temp, flag
		jmp cycl_DELAY7
	nop 
	jmp NEXT


BUDIL:


nop
ldi temp, 6
sts RAS+SHIFT_NUMBER, temp
sts RAS+SHIFT_NUMBER+1, temp
sts RAS+SHIFT_NUMBER+2, temp
sts RAS+SHIFT_NUMBER+3, temp

ldi temp, (1<<PCIE0)
sts PCICR, temp
		clr temp
sts TIMSK1, temp
	sei
	jmp CICLE

CALEND:
cli
cbi PORTB, PB5

lds temp, DATA_BUF+EDDATA
	sts RAS+SHIFT_TAYM_EDSEC, temp
	lds temp, DATA_BUF+DDATA
	sts RAS+SHIFT_TAYM_DSEC, temp
	lds temp, DATA_BUF+EDMONTH
	sts RAS+SHIFT_TAYM_EDMIN, temp
	lds temp, DATA_BUF+DMONTH
	sts RAS+SHIFT_TAYM_DMIN, temp

clr flag
	mov r5, flag
CYCL_CAL:
in temp, pinb
COM TEMP
andi temp, 0b00001111
cpse temp, flag
jmp cycl_CAL
clr temp
	sts TCNT1H, temp;
	sts TCNT1L, temp
ldi temp, SHIFT_TAYM
mov r4, temp;r4 - прибавление к адресу вывода

CICL_CALC11:
sbi TIFR1 , OCF1A
sei
	PAUS_CAL1:
		SBIS  TIFR1 , OCF1A
		jmp PAUS_CAL1
		nop
		cli
	SBIC pinb, pb2
	jmp CICL_CALC11



	lds temp, DATA_BUF+WEEK
	sts RAS+SHIFT_TAYM_EDSEC, temp
	ldi temp, 10
	sts RAS+SHIFT_TAYM_DSEC, temp
	sts RAS+SHIFT_TAYM_EDMIN, temp
	sts RAS+SHIFT_TAYM_DMIN, temp

CYCL_CAL2:
in temp, pinb
COM TEMP
andi temp, 0b00001111
cpse temp, flag
jmp cycl_CAL2
clr temp
	sts TCNT1H, temp;
	sts TCNT1L, temp
ldi temp, SHIFT_TAYM
mov r4, temp;r4 - прибавление к адресу вывода

CICL_CALC12:
sbi TIFR1 , OCF1A
sei
	PAUS_CAL12:
		SBIS  TIFR1 , OCF1A
		jmp PAUS_CAL12
		nop
		cli
	SBIC pinb, pb2
	jmp CICL_CALC12



ldi temp, (1<<PCIE0)
sts PCICR, temp
clr temp
sts TIMSK1, temp
sts timsk0, temp
sei
	jmp CICLE

SETTING:

cli
cbi PORTB, PB5

lds temp, RAS+EDMIN
	sts RAS+SHIFT_TAYM_EDSEC, temp
	lds temp, RAS+DMIN
	sts RAS+SHIFT_TAYM_DSEC, temp
	lds temp, RAS+EDHOUR
	sts RAS+SHIFT_TAYM_EDMIN, temp
	lds temp, RAS+DHOUR
	sts RAS+SHIFT_TAYM_DMIN, temp

clr flag
mov r5, flag
CYCL18:
in temp, pinb
COM TEMP
andi temp, 0b00001111
cpse temp, flag
jmp cycl18
clr temp
	sts TCNT1H, temp;
	sts TCNT1L, temp
ldi temp, SHIFT_TAYM
mov r4, temp;r4 - прибавление к адресу вывода
clr flag

CICL_TAYM8:
sbi TIFR1 , OCF1A
sei
	PAUS_TAYM_18:
		SBIS  TIFR1 , OCF1A
		jmp PAUS_TAYM_18
		nop
		cli
	
	;clr temp
;	sts TCNT1H, temp;
;		sts TCNT1L, temp
	SBIS PINB, pb1
	call inc_flag
	nop
	SBIS PINB, pb3
	call FLAG_DEC
	nop
	SBIC pinb, pb2
	jmp CICL_TAYM8
	cli
ldi temp, SHIFT_TAYM
mov r4, temp;r4 - прибавление к адресу вывода
	
CYCL28:
clr flag
in temp, pinb
COM TEMP
andi temp, 0b00001111
cpse temp, flag
jmp CYCL28
clr temp
	sts TCNT1H, temp;
	sts TCNT1L, temp
PAUS_TAYM_228:
	sbi TIFR1 , OCF1A
	sei
	PAUS_TAYM_28:
		SBIS  TIFR1 , OCF1A
		jmp PAUS_TAYM_28
		nop
		cli
	SBIS PINB, pb1
	call INC_HOUR
	nop
///	SBIS PINB, pb3
///	jmp DEC_HOUR
//	nop
	SBIC pinb, pb2
	jmp PAUS_TAYM_228
	NOP
	CYCL_DELAY8:
clr flag
in temp, pinb
COM TEMP
andi temp, 0b00001111
cpse temp, flag
jmp cycl_DELAY8
	lds temp, RAS+SHIFT_TAYM_EDSEC
	sts RAS+EDMIN, temp
	lds temp, RAS+SHIFT_TAYM_DSEC
	sts RAS+DMIN, temp
	lds temp, RAS+SHIFT_TAYM_EDMIN
	sts RAS+EDHOUR, temp
	lds temp, RAS+SHIFT_TAYM_DMIN
	sts RAS+DHOUR, temp

	lds temp, DATA_BUF+EDDATA
	sts RAS+SHIFT_TAYM_EDSEC, temp
	lds temp, DATA_BUF+DDATA
	sts RAS+SHIFT_TAYM_DSEC, temp
	lds temp, DATA_BUF+EDMONTH
	sts RAS+SHIFT_TAYM_EDMIN, temp
	lds temp, DATA_BUF+DMONTH
	sts RAS+SHIFT_TAYM_DMIN, temp



							clr flag
mov r5, flag
CYCL19:
in temp, pinb
COM TEMP
andi temp, 0b00001111
cpse temp, flag
jmp cycl19
clr temp
	sts TCNT1H, temp;
	sts TCNT1L, temp
ldi temp, SHIFT_TAYM
mov r4, temp;r4 - прибавление к адресу вывода
clr flag

CICL_TAYM9:
sbi TIFR1 , OCF1A
sei
	PAUS_TAYM_19:
		SBIS  TIFR1 , OCF1A
		jmp PAUS_TAYM_19
		nop
		cli
	
	;clr temp
;	sts TCNT1H, temp;
;		sts TCNT1L, temp
	SBIS PINB, pb1
	call inc_flag
	nop
	SBIS PINB, pb3
	call FLAG_DEC
	nop
	SBIC pinb, pb2
	jmp CICL_TAYM9
	cli
ldi temp, SHIFT_TAYM
mov r4, temp;r4 - прибавление к адресу вывода
	
CYCL29:
clr flag
in temp, pinb
COM TEMP
andi temp, 0b00001111
cpse temp, flag
jmp CYCL29
clr temp
	sts TCNT1H, temp;
	sts TCNT1L, temp
PAUS_TAYM_229:
	sbi TIFR1 , OCF1A
	sei
	PAUS_TAYM_29:
		SBIS  TIFR1 , OCF1A
		jmp PAUS_TAYM_29
		nop
		cli
	SBIS PINB, pb1
	call INC_HOUR
	nop
///	SBIS PINB, pb3
///	jmp DEC_HOUR
//	nop
	SBIC pinb, pb2
	jmp PAUS_TAYM_229
	NOP
	CYCL_DELAY9:
clr flag
in temp, pinb
COM TEMP
andi temp, 0b00001111
cpse temp, flag
					jmp cycl_DELAY9

	lds temp, RAS+SHIFT_TAYM_EDSEC
	sts DATA_BUF+EDDATA, temp
	lds temp,RAS+SHIFT_TAYM_DSEC
	sts  DATA_BUF+DDATA, temp
	lds temp,RAS+SHIFT_TAYM_EDMIN 
	sts DATA_BUF+EDMONTH, temp
	lds temp,RAS+SHIFT_TAYM_DMIN 
	sts DATA_BUF+DMONTH, temp


		lds temp, DATA_BUF+WEEK
	sts RAS+SHIFT_TAYM_EDSEC, temp
	ldi temp, 10
	sts RAS+SHIFT_TAYM_DSEC, temp
	sts RAS+SHIFT_TAYM_EDMIN, temp
	sts RAS+SHIFT_TAYM_DMIN, temp

	CYCL30:
clr flag
in temp, pinb
COM TEMP
andi temp, 0b00001111
cpse temp, flag
jmp CYCL30
clr temp
	sts TCNT1H, temp;
	sts TCNT1L, temp
PAUS_TAYM_230:
	sbi TIFR1 , OCF1A
	sei
	PAUS_TAYM_30:
		SBIS  TIFR1 , OCF1A
		jmp PAUS_TAYM_30
		nop
		cli
	lds temp, DATA_BUF+WEEK
	SBIS PINB, pb1
	inc temp
	nop
	cpi temp, 8
	brsh CLEAR_WEEK
	sts DATA_BUF+WEEK, temp
	RETURN_WEEK:
	sts RAS+SHIFT_TAYM_EDSEC, temp
	SBIC pinb, pb2
	jmp PAUS_TAYM_230
	
ldi temp, (1<<PCIE0)
sts PCICR, temp
clr temp
sts TIMSK1, temp
sts TIMSK0, temp
sei
	jmp CICLE

	CLEAR_WEEK:
	clr temp
	sts DATA_BUF+WEEK, temp
	jmp RETURN_WEEK
	
	COUNTER:
	lds temp, DATA_BUF+WEEK
	inc temp
	sts DATA_BUF+WEEK, temp
	cpi temp, 8
	brlo NOT_SUNDAY
	ldi temp, 1
	sts DATA_BUF+WEEK, temp
	NOT_SUNDAY:
	lds temp, DATA_BUF+EDDATA
	inc temp
	sts DATA_BUF+EDDATA, temp
	cpi temp, 10
	brlo NOT_CAP
	clr temp
	sts DATA_BUF+EDDATA, temp
	lds temp, DATA_BUF+DDATA
	inc temp
	sts DATA_BUF+DDATA, temp
	NOT_CAP:
	ldi flag, 10
	mul temp, flag
	mov temp, r0
	lds flag, DATA_BUF+EDDATA
	add temp, flag
	cpi temp, 32
	brsh WEEK_END
	cpi temp, 31
	brne APRIL

	lds flag, DATA_BUF+DMONTH
	lds temp, DATA_BUF+EDMONTH
	cpi flag, 1
	brne NOT_ONE
	ldi flag, 10
	add temp, flag
	NOT_ONE:
	cpi temp, 4
	breq WEEK_END
	cpi temp, 6
	breq WEEK_END
	cpi temp, 9
	breq WEEK_END
	cpi temp, 11
	breq WEEK_END

	APRIL:
	cpi temp, 30
	breq WEEK_END
	cpi temp, 29
	breq EXIT_COUNTER

	lds flag, DATA_BUF+DMONTH
	lds data, DATA_BUF+EDMONTH
	cpi flag, 1
	brne NOT_ONE1
	ldi flag, 10
	add data, flag
	NOT_ONE1:
	cpi data, 2
	brne EXIT_COUNTER
	WEEK_END:
	ldi temp, 1
	sts DATA_BUF+EDDATA, temp
	clr temp
	sts DATA_BUF+DDATA, temp
	lds data, DATA_BUF+EDMONTH
	inc data
	sts DATA_BUF+EDMONTH, data
	cpi data, 10
	brlo END_YEAR
	ldi temp, 1
	sts DATA_BUF+DMONTH, temp
	EXIT_COUNTER:
	ret



	END_YEAR:
	lds flag, DATA_BUF+DMONTH
	lds temp, DATA_BUF+EDMONTH
	cpi flag, 1
	brne NOT_ONE2
	ldi flag, 10
	add temp, flag
	NOT_ONE2:
	cpi temp, 13
	brlo EXIT_COUNTER
	clr temp
	sts DATA_BUF+DMONTH, temp
	ldi temp, 1
	sts DATA_BUF+EDMONTH, temp
	jmp EXIT_COUNTER

INC_HOUR:
	lds temp, RAS+SHIFT_TAYM_EDMIN
	inc temp
	sts RAS+SHIFT_TAYM_EDMIN, temp
	cpi temp, 10
	breq CLEAR_HOUR_INC
	lds flag, RAS+SHIFT_TAYM_DMIN
	ldi data, 10
	mul flag, data
	mov flag, r0
	add temp, flag
	cpi temp, 24
	brsh CLEAR_H
	ret
CLEAR_HOUR_INC:
	clr temp
	sts RAS+SHIFT_TAYM_EDMIN, temp
	lds temp, RAS+SHIFT_TAYM_DMIN
	inc temp
	sts RAS+SHIFT_TAYM_DMIN, temp
	ret
	CLEAR_H:
	clr temp
	sts RAS+SHIFT_TAYM_DMIN, temp
	sts RAS+SHIFT_TAYM_EDMIN, temp
	ret
