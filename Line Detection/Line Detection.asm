;Program compiled by Great Cow BASIC (0.99.01 2022-01-27 (Windows 64 bit) : Build 1073) for Microchip MPASM
;Need help? See the GCBASIC forums at http://sourceforge.net/projects/gcbasic/forums,
;check the documentation or email w_cholmondeley at users dot sourceforge dot net.

;********************************************************************************

;Set up the assembler options (Chip type, clock source, other bits and pieces)
 LIST p=16F18875, r=DEC
#include <P16F18875.inc>
 __CONFIG _CONFIG1, _FCMEN_ON & _CLKOUTEN_OFF & _RSTOSC_HFINT32 & _FEXTOSC_OFF
 __CONFIG _CONFIG2, _MCLRE_OFF
 __CONFIG _CONFIG3, _WDTE_OFF
 __CONFIG _CONFIG4, _LVP_OFF & _WRT_OFF
 __CONFIG _CONFIG5, _CPD_OFF & _CP_OFF

;********************************************************************************

;Set aside memory locations for variables
DIRECTION                        EQU 32

;********************************************************************************

;Vectors
	ORG	0
	pagesel	BASPROGRAMSTART
	goto	BASPROGRAMSTART
	ORG	4
	retfie

;********************************************************************************

;Start of program memory page 0
	ORG	5
BASPROGRAMSTART
;Call initialisation routines
	call	INITSYS

;Start of the main program
;Motors
;#define LME PortC.0
;#define LMB PortC.1
;Dir LME OUT
	bcf	TRISC,0
;Dir LMB OUT
	bcf	TRISC,1
;#define RME PortC.2
;#define RMB PortC.3
;Dir RME OUT
	bcf	TRISC,2
;Dir RMB OUT
	bcf	TRISC,3
;Line Detection
;#define PHOTOTRANS PortD.4
;Dir PHOTOTRANS IN
	bsf	TRISD,4
START
;if PHOTOTRANS ON then
	btfss	PORTD,4
	goto	ELSE1_1
;motors(0)
	clrf	DIRECTION
	call	MOTORS
;else
	goto	ENDIF1
ELSE1_1
;motors(1)
	movlw	1
	movwf	DIRECTION
	call	MOTORS
;end if
ENDIF1
;goto start
	goto	START
;end
	goto	BASPROGRAMEND
BASPROGRAMEND
	sleep
	goto	BASPROGRAMEND

;********************************************************************************

;Source: system.h (156)
INITSYS
;asm showdebug This code block sets the internal oscillator to ChipMHz
;asm showdebug Default settings for microcontrollers with _OSCCON1_
;Default OSCCON1 typically, NOSC HFINTOSC; NDIV 1 - Common as this simply sets the HFINTOSC
;OSCCON1 = 0x60
	movlw	96
	banksel	OSCCON1
	movwf	OSCCON1
;Default value typically, CSWHOLD may proceed; SOSCPWR Low power
;OSCCON3 = 0x00
	clrf	OSCCON3
;Default value typically, MFOEN disabled; LFOEN disabled; ADOEN disabled; SOSCEN disabled; EXTOEN disabled; HFOEN disabled
;OSCEN = 0x00
	clrf	OSCEN
;Default value
;OSCTUNE = 0x00
	clrf	OSCTUNE
;asm showdebug The MCU is a chip family ChipFamily
;asm showdebug OSCCON type is 102
;Set OSCFRQ values for MCUs with OSCSTAT... the 16F18855 MCU family
;OSCFRQ = 0b00000110
	movlw	6
	movwf	OSCFRQ
;asm showdebug _Complete_the_chip_setup_of_BSR,ADCs,ANSEL_and_other_key_setup_registers_or_register_bits
;Ensure all ports are set for digital I/O and, turn off A/D
;SET ADFM OFF
	banksel	ADCON0
	bcf	ADCON0,ADFRM0
;Switch off A/D Var(ADCON0)
;SET ADCON0.ADON OFF
	bcf	ADCON0,ADON
;ANSELA = 0
	banksel	ANSELA
	clrf	ANSELA
;ANSELB = 0
	clrf	ANSELB
;ANSELC = 0
	clrf	ANSELC
;ANSELD = 0
	clrf	ANSELD
;ANSELE = 0
	clrf	ANSELE
;Set comparator register bits for many MCUs with register CM2CON0
;C2ON = 0
	banksel	CM2CON0
	bcf	CM2CON0,C2ON
;C1ON = 0
	bcf	CM1CON0,C1ON
;
;'Turn off all ports
;PORTA = 0
	banksel	PORTA
	clrf	PORTA
;PORTB = 0
	clrf	PORTB
;PORTC = 0
	clrf	PORTC
;PORTD = 0
	clrf	PORTD
;PORTE = 0
	clrf	PORTE
	return

;********************************************************************************

;Source: Line Detection.gcb (18)
MOTORS
;if direction = 1 then
	decf	DIRECTION,W
	btfss	STATUS, Z
	goto	ELSE2_1
;set LME OFF
	bcf	LATC,0
;set LMB ON
	bsf	LATC,1
;set RME OFF
	bcf	LATC,2
;set RMB ON
	bsf	LATC,3
;else
	goto	ENDIF2
ELSE2_1
;set LME ON
	bsf	LATC,0
;set LMB OFF
	bcf	LATC,1
;set RME ON
	bsf	LATC,2
;set RMB OFF
	bcf	LATC,3
;end if
ENDIF2
	return

;********************************************************************************

;Start of program memory page 1
	ORG	2048
;Start of program memory page 2
	ORG	4096
;Start of program memory page 3
	ORG	6144

 END
