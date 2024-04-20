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
DELAYTEMP                        EQU 112
DELAYTEMP2                       EQU 113
DIRECTION                        EQU 32
LCDBYTE                          EQU 33
LCDCOLUMN                        EQU 34
LCDLINE                          EQU 35
LCD_STATE                        EQU 36
PRINTLEN                         EQU 37
STRINGPOINTER                    EQU 38
SYSBYTETEMPA                     EQU 117
SYSBYTETEMPB                     EQU 121
SYSBYTETEMPX                     EQU 112
SYSLCDTEMP                       EQU 39
SYSPRINTDATAHANDLER              EQU 40
SYSPRINTDATAHANDLER_H            EQU 41
SYSPRINTTEMP                     EQU 42
SYSREPEATTEMP1                   EQU 43
SYSSTRINGA                       EQU 119
SYSSTRINGA_H                     EQU 120
SYSTEMP1                         EQU 44
SYSTEMP2                         EQU 45
SYSWAITTEMP10US                  EQU 117
SYSWAITTEMPMS                    EQU 114
SYSWAITTEMPMS_H                  EQU 115
SYSWAITTEMPUS                    EQU 117
SYSWAITTEMPUS_H                  EQU 118

;********************************************************************************

;Alias variables
AFSR0 EQU 4
AFSR0_H EQU 5

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
	call	INITLCD

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
;#define PHOTOTRANS PortD.1
;Dir PHOTOTRANS IN
	bsf	TRISD,1
;----------------------------------------------------
;LCD Connection Settings
;#define LCD_LINES 2
;#define LCD_IO 4
;#define LCD_DB4 PortD.4
;#define LCD_DB5 PortD.5
;#define LCD_DB6 PortD.6
;#define LCD_DB7 PortD.7
;#define LCD_RS PORTC.4
;#define LCD_RW PORTC.5
;#define LCD_Enable PORTC.6
;Dir LCD_RS out
	bcf	TRISC,4
;Dir LCD_RW out
	bcf	TRISC,5
;Dir LCD_Enable out
	bcf	TRISC,6
;Dir LCD_DB4 out
	bcf	TRISD,4
;Dir LCD_DB5 in
	bsf	TRISD,5
;Dir LCD_DB6 out
	bcf	TRISD,6
;Dir LCD_DB7 in
	bsf	TRISD,7
;----------------------------------------------------
;Do
SysDoLoop_S1
;lcdDisplay()
	call	LCDDISPLAY
;if PHOTOTRANS ON then
	btfss	PORTD,1
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
;Loop
	goto	SysDoLoop_S1
SysDoLoop_E1
;end
;loop
BASPROGRAMEND
	sleep
	goto	BASPROGRAMEND

;********************************************************************************

;Source: lcd.h (955)
CHECKBUSYFLAG
;Sub that waits until LCD controller busy flag goes low (ready)
;Only used by LCD_IO 4,8 and only when LCD_NO_RW is NOT Defined
;Called by sub LCDNOrmalWriteByte
;LCD_RSTemp = LCD_RS
	bcf	SYSLCDTEMP,2
	btfsc	PORTC,4
	bsf	SYSLCDTEMP,2
;DIR SCRIPT_LCD_BF  IN
	bsf	TRISD,7
;SET LCD_RS OFF
	bcf	LATC,4
;SET LCD_RW ON
	bsf	LATC,5
;Do
SysDoLoop_S2
;Set LCD_Enable ON
	bsf	LATC,6
;wait 1 us
	movlw	2
	movwf	DELAYTEMP
DelayUS14
	decfsz	DELAYTEMP,F
	goto	DelayUS14
	nop
;SysLCDTemp.7 = SCRIPT_LCD_BF
	bcf	SYSLCDTEMP,7
	btfsc	PORTD,7
	bsf	SYSLCDTEMP,7
;Set LCD_Enable OFF
	bcf	LATC,6
;Wait 1 us
	movlw	2
	movwf	DELAYTEMP
DelayUS15
	decfsz	DELAYTEMP,F
	goto	DelayUS15
	nop
;PulseOut LCD_Enable, 1 us
;Macro Source: stdbasic.h (186)
;Set Pin On
	bsf	LATC,6
;WaitL1 Time
	movlw	2
	movwf	DELAYTEMP
DelayUS16
	decfsz	DELAYTEMP,F
	goto	DelayUS16
;Set Pin Off
	bcf	LATC,6
;Wait 1 us
	movlw	2
	movwf	DELAYTEMP
DelayUS17
	decfsz	DELAYTEMP,F
	goto	DelayUS17
	nop
;Loop While SysLCDTemp.7 <> 0
	btfsc	SYSLCDTEMP,7
	goto	SysDoLoop_S2
SysDoLoop_E2
;LCD_RS = LCD_RSTemp
	bcf	LATC,4
	btfsc	SYSLCDTEMP,2
	bsf	LATC,4
	return

;********************************************************************************

;Source: lcd.h (364)
CLS
;Sub to clear the LCD
;SET LCD_RS OFF
	bcf	LATC,4
;Clear screen
;LCDWriteByte (0b00000001)
	movlw	1
	movwf	LCDBYTE
	call	LCDNORMALWRITEBYTE
;Wait 4 ms
	movlw	4
	movwf	SysWaitTempMS
	clrf	SysWaitTempMS_H
	call	Delay_MS
;Move to start of visible DDRAM
;LCDWriteByte(0x80)
	movlw	128
	movwf	LCDBYTE
	call	LCDNORMALWRITEBYTE
;Wait 50 us
	movlw	133
	movwf	DELAYTEMP
DelayUS1
	decfsz	DELAYTEMP,F
	goto	DelayUS1
	return

;********************************************************************************

Delay_10US
D10US_START
	movlw	25
	movwf	DELAYTEMP
DelayUS0
	decfsz	DELAYTEMP,F
	goto	DelayUS0
	nop
	decfsz	SysWaitTemp10US, F
	goto	D10US_START
	return

;********************************************************************************

Delay_MS
	incf	SysWaitTempMS_H, F
DMS_START
	movlw	14
	movwf	DELAYTEMP2
DMS_OUTER
	movlw	189
	movwf	DELAYTEMP
DMS_INNER
	decfsz	DELAYTEMP, F
	goto	DMS_INNER
	decfsz	DELAYTEMP2, F
	goto	DMS_OUTER
	decfsz	SysWaitTempMS, F
	goto	DMS_START
	decfsz	SysWaitTempMS_H, F
	goto	DMS_START
	return

;********************************************************************************

;Source: lcd.h (437)
INITLCD
;asm showdebug  `LCD_IO selected is ` LCD_IO
;asm showdebug  `LCD_Speed is SLOW`
;asm showdebug  `OPTIMAL is set to ` OPTIMAL
;asm showdebug  `LCD_Speed is set to ` LCD_Speed
;Wait 50 ms
	movlw	50
	movwf	SysWaitTempMS
	clrf	SysWaitTempMS_H
	call	Delay_MS
;Dir LCD_RW OUT
	bcf	TRISC,5
;Set LCD_RW OFF
	bcf	LATC,5
;Dir LCD_DB4 OUT
	bcf	TRISD,4
;Dir LCD_DB5 OUT
	bcf	TRISD,5
;Dir LCD_DB6 OUT
	bcf	TRISD,6
;Dir LCD_DB7 OUT
	bcf	TRISD,7
;Dir LCD_RS OUT
	bcf	TRISC,4
;Dir LCD_Enable OUT
	bcf	TRISC,6
;Set LCD_RS OFF
	bcf	LATC,4
;Set LCD_Enable OFF
	bcf	LATC,6
;Wakeup (0x30 - b'0011xxxx' )
;Set LCD_DB7 OFF
	bcf	LATD,7
;Set LCD_DB6 OFF
	bcf	LATD,6
;Set LCD_DB5 ON
	bsf	LATD,5
;Set LCD_DB4 ON
	bsf	LATD,4
;Wait 2 us
	movlw	5
	movwf	DELAYTEMP
DelayUS2
	decfsz	DELAYTEMP,F
	goto	DelayUS2
;PulseOut LCD_Enable, 2 us
;Macro Source: stdbasic.h (186)
;Set Pin On
	bsf	LATC,6
;WaitL1 Time
	movlw	5
	movwf	DELAYTEMP
DelayUS3
	decfsz	DELAYTEMP,F
	goto	DelayUS3
;Set Pin Off
	bcf	LATC,6
;Wait 10 ms
	movlw	10
	movwf	SysWaitTempMS
	clrf	SysWaitTempMS_H
	call	Delay_MS
;Repeat 3
	movlw	3
	movwf	SysRepeatTemp1
SysRepeatLoop1
;PulseOut LCD_Enable, 2 us
;Macro Source: stdbasic.h (186)
;Set Pin On
	bsf	LATC,6
;WaitL1 Time
	movlw	5
	movwf	DELAYTEMP
DelayUS4
	decfsz	DELAYTEMP,F
	goto	DelayUS4
;Set Pin Off
	bcf	LATC,6
;Wait 1 ms
	movlw	1
	movwf	SysWaitTempMS
	clrf	SysWaitTempMS_H
	call	Delay_MS
;End Repeat
	decfsz	SysRepeatTemp1,F
	goto	SysRepeatLoop1
SysRepeatLoopEnd1
;Set 4 bit mode (0x20 - b'0010xxxx')
;Set LCD_DB7 OFF
	bcf	LATD,7
;Set LCD_DB6 OFF
	bcf	LATD,6
;Set LCD_DB5 ON
	bsf	LATD,5
;Set LCD_DB4 OFF
	bcf	LATD,4
;Wait 2 us
	movlw	5
	movwf	DELAYTEMP
DelayUS5
	decfsz	DELAYTEMP,F
	goto	DelayUS5
;PulseOut LCD_Enable, 2 us
;Macro Source: stdbasic.h (186)
;Set Pin On
	bsf	LATC,6
;WaitL1 Time
	movlw	5
	movwf	DELAYTEMP
DelayUS6
	decfsz	DELAYTEMP,F
	goto	DelayUS6
;Set Pin Off
	bcf	LATC,6
;Wait 100 us
	movlw	1
	movwf	DELAYTEMP2
DelayUSO7
	clrf	DELAYTEMP
DelayUS7
	decfsz	DELAYTEMP,F
	goto	DelayUS7
	decfsz	DELAYTEMP2,F
	goto	DelayUSO7
	movlw	9
	movwf	DELAYTEMP
DelayUS8
	decfsz	DELAYTEMP,F
	goto	DelayUS8
;===== now in 4 bit mode =====
;LCDWriteByte 0x28    '(b'00101000')  '0x28 set 2 line mode
	movlw	40
	movwf	LCDBYTE
	call	LCDNORMALWRITEBYTE
;LCDWriteByte 0x06    '(b'00000110')  'Set cursor movement
	movlw	6
	movwf	LCDBYTE
	call	LCDNORMALWRITEBYTE
;LCDWriteByte 0x0C    '(b'00001100')  'Turn off cursor
	movlw	12
	movwf	LCDBYTE
	call	LCDNORMALWRITEBYTE
;Cls  'Clear the display
	call	CLS
;LCD_State = 12
	movlw	12
	movwf	LCD_STATE
	return

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

;Source: LCD Display.gcb (39)
LCDDISPLAY
;CLS
	call	CLS
;print ("GCBASIC 2024")
	movlw	low StringTable1
	movwf	SysPRINTDATAHandler
	movlw	(high StringTable1) | 128
	movwf	SysPRINTDATAHandler_H
	call	PRINT108
;locate 1, 2
	movlw	1
	movwf	LCDLINE
	movlw	2
	movwf	LCDCOLUMN
	call	LOCATE
;Print ("GCBASIC 2024")
	movlw	low StringTable1
	movwf	SysPRINTDATAHandler
	movlw	(high StringTable1) | 128
	movwf	SysPRINTDATAHandler_H
	goto	PRINT108

;********************************************************************************

;Source: lcd.h (1006)
LCDNORMALWRITEBYTE
;Sub to write a byte to the LCD
;CheckBusyFlag         'WaitForReady
	call	CHECKBUSYFLAG
;set LCD_RW OFF
	bcf	LATC,5
;Dim Temp as Byte
;Pins must be outputs if returning from WaitForReady, or after LCDReadByte or GET subs
;DIR LCD_DB4 OUT
	bcf	TRISD,4
;DIR LCD_DB5 OUT
	bcf	TRISD,5
;DIR LCD_DB6 OUT
	bcf	TRISD,6
;DIR LCD_DB7 OUT
	bcf	TRISD,7
;Write upper nibble to output pins
;set LCD_DB4 OFF
;set LCD_DB5 OFF
;set LCD_DB6 OFF
;set LCD_DB7 OFF
;if LCDByte.7 ON THEN SET LCD_DB7 ON
;if LCDByte.6 ON THEN SET LCD_DB6 ON
;if LCDByte.5 ON THEN SET LCD_DB5 ON
;if LCDByte.4 ON THEN SET LCD_DB4 ON
;LCD_DB7 = LCDByte.7
	bcf	LATD,7
	btfsc	LCDBYTE,7
	bsf	LATD,7
;LCD_DB6 = LCDByte.6
	bcf	LATD,6
	btfsc	LCDBYTE,6
	bsf	LATD,6
;LCD_DB5 = LCDByte.5
	bcf	LATD,5
	btfsc	LCDBYTE,5
	bsf	LATD,5
;LCD_DB4 = LCDByte.4
	bcf	LATD,4
	btfsc	LCDBYTE,4
	bsf	LATD,4
;Wait 1 us
	movlw	2
	movwf	DELAYTEMP
DelayUS9
	decfsz	DELAYTEMP,F
	goto	DelayUS9
	nop
;PulseOut LCD_enable, 1 us
;Macro Source: stdbasic.h (186)
;Set Pin On
	bsf	LATC,6
;WaitL1 Time
	movlw	2
	movwf	DELAYTEMP
DelayUS10
	decfsz	DELAYTEMP,F
	goto	DelayUS10
;Set Pin Off
	bcf	LATC,6
;All data pins low
;set LCD_DB4 OFF
;set LCD_DB5 OFF
;set LCD_DB6 OFF
;set LCD_DB7 OFF
	bcf	LATD,7
;
;'Write lower nibble to output pins
;if LCDByte.3 ON THEN SET LCD_DB7 ON
	btfsc	LCDBYTE,3
	bsf	LATD,7
;if LCDByte.2 ON THEN SET LCD_DB6 ON
;if LCDByte.1 ON THEN SET LCD_DB5 ON
;if LCDByte.0 ON THEN SET LCD_DB4 ON
;LCD_DB7 = LCDByte.3
;LCD_DB6 = LCDByte.2
	bcf	LATD,6
	btfsc	LCDBYTE,2
	bsf	LATD,6
;LCD_DB5 = LCDByte.1
	bcf	LATD,5
	btfsc	LCDBYTE,1
	bsf	LATD,5
;LCD_DB4 = LCDByte.0
	bcf	LATD,4
	btfsc	LCDBYTE,0
	bsf	LATD,4
;Wait 1 us
	movlw	2
	movwf	DELAYTEMP
DelayUS11
	decfsz	DELAYTEMP,F
	goto	DelayUS11
	nop
;PulseOut LCD_enable, 1 us
;Macro Source: stdbasic.h (186)
;Set Pin On
	bsf	LATC,6
;WaitL1 Time
	movlw	2
	movwf	DELAYTEMP
DelayUS12
	decfsz	DELAYTEMP,F
	goto	DelayUS12
;Set Pin Off
	bcf	LATC,6
;Set data pins low again
;SET LCD_DB7 OFF
;SET LCD_DB6 OFF
;SET LCD_DB5 OFF
;SET LCD_DB4 OFF
;Wait SCRIPT_LCD_POSTWRITEDELAY
	movlw	226
	movwf	DELAYTEMP
DelayUS13
	decfsz	DELAYTEMP,F
	goto	DelayUS13
	nop
;If Register Select is low
;IF LCD_RS = 0 then
	btfsc	PORTC,4
	goto	ENDIF7
;IF LCDByte < 16 then
	movlw	16
	subwf	LCDBYTE,W
	btfsc	STATUS, C
	goto	ENDIF8
;if LCDByte > 7 then
	movf	LCDBYTE,W
	sublw	7
	btfsc	STATUS, C
	goto	ENDIF9
;LCD_State = LCDByte
	movf	LCDBYTE,W
	movwf	LCD_STATE
;end if
ENDIF9
;END IF
ENDIF8
;END IF
ENDIF7
	return

;********************************************************************************

;Source: lcd.h (350)
LOCATE
;Sub to locate the cursor
;Where LCDColumn is 0 to screen width-1, LCDLine is 0 to screen height-1
;Set LCD_RS Off
	bcf	LATC,4
;If LCDLine > 1 Then
	movf	LCDLINE,W
	sublw	1
	btfsc	STATUS, C
	goto	ENDIF3
;LCDLine = LCDLine - 2
	movlw	2
	subwf	LCDLINE,F
;LCDColumn = LCDColumn + LCD_WIDTH
	movlw	20
	addwf	LCDCOLUMN,F
;End If
ENDIF3
;LCDWriteByte(0x80 or 0x40 * LCDLine + LCDColumn)
	movf	LCDLINE,W
	movwf	SysBYTETempA
	movlw	64
	movwf	SysBYTETempB
	call	SYSMULTSUB
	movf	LCDCOLUMN,W
	addwf	SysBYTETempX,W
	movwf	SysTemp1
	movlw	128
	iorwf	SysTemp1,W
	movwf	LCDBYTE
	call	LCDNORMALWRITEBYTE
;wait 5 10us
	movlw	5
	movwf	SysWaitTemp10US
	goto	Delay_10US

;********************************************************************************

;Source: LCD Display.gcb (48)
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

;Overloaded signature: STRING:, Source: lcd.h (785)
PRINT108
;Sub to print a string variable on the LCD
;PrintLen = PrintData(0)
	movf	SysPRINTDATAHandler,W
	movwf	AFSR0
	movf	SysPRINTDATAHandler_H,W
	movwf	AFSR0_H
	movf	INDF0,W
	movwf	PRINTLEN
;If PrintLen = 0 Then Exit Sub
	movf	PRINTLEN,F
	btfsc	STATUS, Z
	return
;Set LCD_RS On
	bsf	LATC,4
;Write Data
;For SysPrintTemp = 1 To PrintLen
	movlw	1
	movwf	SYSPRINTTEMP
SysForLoop1
;LCDWriteByte PrintData(SysPrintTemp)
	movf	SYSPRINTTEMP,W
	addwf	SysPRINTDATAHandler,W
	movwf	AFSR0
	movlw	0
	addwfc	SysPRINTDATAHandler_H,W
	movwf	AFSR0_H
	movf	INDF0,W
	movwf	LCDBYTE
	call	LCDNORMALWRITEBYTE
;Next
;#4p Positive value Step Handler in For-next statement
	movf	SYSPRINTTEMP,W
	subwf	PRINTLEN,W
	movwf	SysTemp1
	movwf	SysBYTETempA
	clrf	SysBYTETempB
	call	SYSCOMPEQUAL
	comf	SysByteTempX,F
	btfss	SysByteTempX,0
	goto	ENDIF5
;Set LoopVar to LoopVar + StepValue where StepValue is a positive value
	incf	SYSPRINTTEMP,F
	goto	SysForLoop1
;END IF
ENDIF5
SysForLoopEnd1
	return

;********************************************************************************

;Source: system.h (2997)
SYSCOMPEQUAL
;Dim SysByteTempA, SysByteTempB, SysByteTempX as byte
;clrf SysByteTempX
	clrf	SYSBYTETEMPX
;movf SysByteTempA, W
	movf	SYSBYTETEMPA, W
;subwf SysByteTempB, W
	subwf	SYSBYTETEMPB, W
;btfsc STATUS, Z
	btfsc	STATUS, Z
;comf SysByteTempX,F
	comf	SYSBYTETEMPX,F
	return

;********************************************************************************

;Source: system.h (2437)
SYSMULTSUB
;dim SysByteTempA as byte
;dim SysByteTempB as byte
;dim SysByteTempX as byte
;clrf SysByteTempX
	clrf	SYSBYTETEMPX
MUL8LOOP
;movf SysByteTempA, W
	movf	SYSBYTETEMPA, W
;btfsc SysByteTempB, 0
	btfsc	SYSBYTETEMPB, 0
;addwf SysByteTempX, F
	addwf	SYSBYTETEMPX, F
;bcf STATUS, C
	bcf	STATUS, C
;rrf SysByteTempB, F
	rrf	SYSBYTETEMPB, F
;bcf STATUS, C
	bcf	STATUS, C
;rlf SysByteTempA, F
	rlf	SYSBYTETEMPA, F
;movf SysByteTempB, F
	movf	SYSBYTETEMPB, F
;btfss STATUS, Z
	btfss	STATUS, Z
;goto MUL8LOOP
	goto	MUL8LOOP
	return

;********************************************************************************

SysStringTables
	movf	SysStringA_H,W
	movwf	PCLATH
	movf	SysStringA,W
	incf	SysStringA,F
	btfsc	STATUS,Z
	incf	SysStringA_H,F
	movwf	PCL

StringTable1
	retlw	12
	retlw	71	;G
	retlw	67	;C
	retlw	66	;B
	retlw	65	;A
	retlw	83	;S
	retlw	73	;I
	retlw	67	;C
	retlw	32	; 
	retlw	50	;2
	retlw	48	;0
	retlw	50	;2
	retlw	52	;4


;********************************************************************************

;Start of program memory page 1
	ORG	2048
;Start of program memory page 2
	ORG	4096
;Start of program memory page 3
	ORG	6144

 END
