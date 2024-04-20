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
ADREADPORT                       EQU 32
DELAYTEMP                        EQU 112
DELAYTEMP2                       EQU 113
DIGITALWALLFRONT                 EQU 33
DIGITALWALLLEFT                  EQU 34
DIRECTION                        EQU 35
LCDBYTE                          EQU 36
LCDCOLUMN                        EQU 37
LCDLINE                          EQU 38
LCDVALUE                         EQU 39
LCDVALUETEMP                     EQU 40
LCD_STATE                        EQU 41
PRINTLEN                         EQU 42
READAD                           EQU 43
STRINGPOINTER                    EQU 44
SYSBYTETEMPA                     EQU 117
SYSBYTETEMPB                     EQU 121
SYSBYTETEMPX                     EQU 112
SYSCALCTEMPX                     EQU 112
SYSDIVLOOP                       EQU 116
SYSDIVMULTA                      EQU 119
SYSDIVMULTA_H                    EQU 120
SYSDIVMULTB                      EQU 123
SYSDIVMULTB_H                    EQU 124
SYSDIVMULTX                      EQU 114
SYSDIVMULTX_H                    EQU 115
SYSLCDTEMP                       EQU 45
SYSPRINTDATAHANDLER              EQU 46
SYSPRINTDATAHANDLER_H            EQU 47
SYSPRINTTEMP                     EQU 48
SYSREPEATTEMP1                   EQU 49
SYSSTRINGA                       EQU 119
SYSSTRINGA_H                     EQU 120
SYSTEMP1                         EQU 50
SYSTEMP1_H                       EQU 51
SYSTEMP2                         EQU 52
SYSTEMP2_H                       EQU 53
SYSWAITTEMP10US                  EQU 117
SYSWAITTEMPMS                    EQU 114
SYSWAITTEMPMS_H                  EQU 115
SYSWAITTEMPUS                    EQU 117
SYSWAITTEMPUS_H                  EQU 118
SYSWORDTEMPA                     EQU 117
SYSWORDTEMPA_H                   EQU 118
SYSWORDTEMPB                     EQU 121
SYSWORDTEMPB_H                   EQU 122
SYSWORDTEMPX                     EQU 112
SYSWORDTEMPX_H                   EQU 113
WALLFRONTVOLTAGE                 EQU 54
WALLLEFTVOLTAGE                  EQU 55

;********************************************************************************

;Alias variables
AFSR0 EQU 4
AFSR0_H EQU 5
SYSREADADBYTE EQU 43

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
;Wall Detection
;#define WallLeft porta.2
;#define WallFront porta.1
;Dir WallLeft in
	bsf	TRISA,2
;Dir WallFront in
	bsf	TRISA,1
;Dim WallFrontVoltage as Byte
;Dim WallLeftVoltage as Byte
;Dim DigitalWallFront as Byte
;Dim DigitalWallLeft as Byte
;Do Forever
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

;Source: Wall Detection.gcb (50)
LCDDISPLAY
;CLS
	call	CLS
;WallFrontVoltage = READAD(AN1)
	movlw	1
	movwf	ADREADPORT
	call	FN_READAD6
	movf	SYSREADADBYTE,W
	movwf	WALLFRONTVOLTAGE
;WallLeftVoltage = READAD(AN2)
	movlw	2
	movwf	ADREADPORT
	call	FN_READAD6
	movf	SYSREADADBYTE,W
	movwf	WALLLEFTVOLTAGE
;DigitalWallFront = ((6787/(WallFrontVoltage-3))-4)/5
	movlw	3
	subwf	WALLFRONTVOLTAGE,W
	movwf	SysTemp1
	movlw	131
	movwf	SysWORDTempA
	movlw	26
	movwf	SysWORDTempA_H
	movf	SysTemp1,W
	movwf	SysWORDTempB
	clrf	SysWORDTempB_H
	call	SYSDIVSUB16
	movf	SysWORDTempA,W
	movwf	SysTemp2
	movf	SysWORDTempA_H,W
	movwf	SysTemp2_H
	movlw	4
	subwf	SysTemp2,W
	movwf	SysTemp1
	movlw	0
	subwfb	SysTemp2_H,W
	movwf	SysTemp1_H
	movf	SysTemp1,W
	movwf	SysWORDTempA
	movf	SysTemp1_H,W
	movwf	SysWORDTempA_H
	movlw	5
	movwf	SysWORDTempB
	clrf	SysWORDTempB_H
	call	SYSDIVSUB16
	movf	SysWORDTempA,W
	movwf	DIGITALWALLFRONT
;DigitalWallLeft = ((6787/(WallLeftVoltage-3))-4)/5
	movlw	3
	subwf	WALLLEFTVOLTAGE,W
	movwf	SysTemp1
	movlw	131
	movwf	SysWORDTempA
	movlw	26
	movwf	SysWORDTempA_H
	movf	SysTemp1,W
	movwf	SysWORDTempB
	clrf	SysWORDTempB_H
	call	SYSDIVSUB16
	movf	SysWORDTempA,W
	movwf	SysTemp2
	movf	SysWORDTempA_H,W
	movwf	SysTemp2_H
	movlw	4
	subwf	SysTemp2,W
	movwf	SysTemp1
	movlw	0
	subwfb	SysTemp2_H,W
	movwf	SysTemp1_H
	movf	SysTemp1,W
	movwf	SysWORDTempA
	movf	SysTemp1_H,W
	movwf	SysWORDTempA_H
	movlw	5
	movwf	SysWORDTempB
	clrf	SysWORDTempB_H
	call	SYSDIVSUB16
	movf	SysWORDTempA,W
	movwf	DIGITALWALLLEFT
;Locate 0,0
	clrf	LCDLINE
	clrf	LCDCOLUMN
	call	LOCATE
;Print "LEFT: "
	movlw	low StringTable1
	movwf	SysPRINTDATAHandler
	movlw	(high StringTable1) | 128
	movwf	SysPRINTDATAHandler_H
	call	PRINT108
;Print DigitalWallLeft
	movf	DIGITALWALLLEFT,W
	movwf	LCDVALUE
	call	PRINT109
;Locate 1,0
	movlw	1
	movwf	LCDLINE
	clrf	LCDCOLUMN
	call	LOCATE
;Print "FRONT: "
	movlw	low StringTable2
	movwf	SysPRINTDATAHandler
	movlw	(high StringTable2) | 128
	movwf	SysPRINTDATAHandler_H
	call	PRINT108
;Print DigitalWallFront
	movf	DIGITALWALLFRONT,W
	movwf	LCDVALUE
	call	PRINT109
;wait 500 ms
	movlw	244
	movwf	SysWaitTempMS
	movlw	1
	movwf	SysWaitTempMS_H
	goto	Delay_MS

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
	goto	ENDIF10
;IF LCDByte < 16 then
	movlw	16
	subwf	LCDBYTE,W
	btfsc	STATUS, C
	goto	ENDIF11
;if LCDByte > 7 then
	movf	LCDBYTE,W
	sublw	7
	btfsc	STATUS, C
	goto	ENDIF12
;LCD_State = LCDByte
	movf	LCDBYTE,W
	movwf	LCD_STATE
;end if
ENDIF12
;END IF
ENDIF11
;END IF
ENDIF10
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
	goto	ENDIF4
;LCDLine = LCDLine - 2
	movlw	2
	subwf	LCDLINE,F
;LCDColumn = LCDColumn + LCD_WIDTH
	movlw	20
	addwf	LCDCOLUMN,F
;End If
ENDIF4
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

;Source: Wall Detection.gcb (68)
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
	goto	ENDIF6
;Set LoopVar to LoopVar + StepValue where StepValue is a positive value
	incf	SYSPRINTTEMP,F
	goto	SysForLoop1
;END IF
ENDIF6
SysForLoopEnd1
	return

;********************************************************************************

;Overloaded signature: BYTE:, Source: lcd.h (800)
PRINT109
;Sub to print a byte variable on the LCD
;LCDValueTemp = 0
	clrf	LCDVALUETEMP
;Set LCD_RS On
	bsf	LATC,4
;IF LCDValue >= 100 Then
	movlw	100
	subwf	LCDVALUE,W
	btfss	STATUS, C
	goto	ENDIF7
;LCDValueTemp = LCDValue / 100
	movf	LCDVALUE,W
	movwf	SysBYTETempA
	movlw	100
	movwf	SysBYTETempB
	call	SYSDIVSUB
	movf	SysBYTETempA,W
	movwf	LCDVALUETEMP
;LCDValue = SysCalcTempX
	movf	SYSCALCTEMPX,W
	movwf	LCDVALUE
;LCDWriteByte(LCDValueTemp + 48)
	movlw	48
	addwf	LCDVALUETEMP,W
	movwf	LCDBYTE
	call	LCDNORMALWRITEBYTE
;End If
ENDIF7
;If LCDValueTemp > 0 Or LCDValue >= 10 Then
	movf	LCDVALUETEMP,W
	movwf	SysBYTETempB
	clrf	SysBYTETempA
	call	SYSCOMPLESSTHAN
	movf	SysByteTempX,W
	movwf	SysTemp1
	movf	LCDVALUE,W
	movwf	SysBYTETempA
	movlw	10
	movwf	SysBYTETempB
	call	SYSCOMPLESSTHAN
	comf	SysByteTempX,F
	movf	SysTemp1,W
	iorwf	SysByteTempX,W
	movwf	SysTemp2
	btfss	SysTemp2,0
	goto	ENDIF8
;LCDValueTemp = LCDValue / 10
	movf	LCDVALUE,W
	movwf	SysBYTETempA
	movlw	10
	movwf	SysBYTETempB
	call	SYSDIVSUB
	movf	SysBYTETempA,W
	movwf	LCDVALUETEMP
;LCDValue = SysCalcTempX
	movf	SYSCALCTEMPX,W
	movwf	LCDVALUE
;LCDWriteByte(LCDValueTemp + 48)
	movlw	48
	addwf	LCDVALUETEMP,W
	movwf	LCDBYTE
	call	LCDNORMALWRITEBYTE
;End If
ENDIF8
;LCDWriteByte (LCDValue + 48)
	movlw	48
	addwf	LCDVALUE,W
	movwf	LCDBYTE
	goto	LCDNORMALWRITEBYTE

;********************************************************************************

;Overloaded signature: BYTE:, Source: a-d.h (1748)
FN_READAD6
;ADFM should configured to ensure LEFT justified
;SET ADFM OFF
	banksel	ADCON0
	bcf	ADCON0,ADFRM0
;for 16F1885x and possibly future others
;ADPCH = ADReadPort
	banksel	ADREADPORT
	movf	ADREADPORT,W
	banksel	ADPCH
	movwf	ADPCH
;***************************************
;Perform conversion
;LLReadAD 1
;Macro Source: a-d.h (373)
;***  'Special section for 16F1688x Chips ***
;'Configure ANSELA/B/C/D
;Select Case ADReadPort 'Configure ANSELA/B/C/D @DebugADC_H
;Case 0: Set ANSELA.0 On
SysSelect1Case1
	banksel	ADREADPORT
	movf	ADREADPORT,F
	btfss	STATUS, Z
	goto	SysSelect1Case2
	banksel	ANSELA
	bsf	ANSELA,0
;Case 1: Set ANSELA.1 On
	goto	SysSelectEnd1
SysSelect1Case2
	decf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case3
	banksel	ANSELA
	bsf	ANSELA,1
;Case 2: Set ANSELA.2 On
	goto	SysSelectEnd1
SysSelect1Case3
	movlw	2
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case4
	banksel	ANSELA
	bsf	ANSELA,2
;Case 3: Set ANSELA.3 On
	goto	SysSelectEnd1
SysSelect1Case4
	movlw	3
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case5
	banksel	ANSELA
	bsf	ANSELA,3
;Case 4: Set ANSELA.4 ON
	goto	SysSelectEnd1
SysSelect1Case5
	movlw	4
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case6
	banksel	ANSELA
	bsf	ANSELA,4
;Case 5: Set ANSELA.5 On
	goto	SysSelectEnd1
SysSelect1Case6
	movlw	5
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case7
	banksel	ANSELA
	bsf	ANSELA,5
;Case 6: Set ANSELA.6 On
	goto	SysSelectEnd1
SysSelect1Case7
	movlw	6
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case8
	banksel	ANSELA
	bsf	ANSELA,6
;Case 7: Set ANSELA.7 On
	goto	SysSelectEnd1
SysSelect1Case8
	movlw	7
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case9
	banksel	ANSELA
	bsf	ANSELA,7
;Case 8: Set ANSELB.0 On
	goto	SysSelectEnd1
SysSelect1Case9
	movlw	8
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case10
	banksel	ANSELB
	bsf	ANSELB,0
;Case 9: Set ANSELB.1 On
	goto	SysSelectEnd1
SysSelect1Case10
	movlw	9
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case11
	banksel	ANSELB
	bsf	ANSELB,1
;Case 10: Set ANSELB.2 On
	goto	SysSelectEnd1
SysSelect1Case11
	movlw	10
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case12
	banksel	ANSELB
	bsf	ANSELB,2
;Case 11: Set ANSELB.3 On
	goto	SysSelectEnd1
SysSelect1Case12
	movlw	11
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case13
	banksel	ANSELB
	bsf	ANSELB,3
;Case 12: Set ANSELB.4 On
	goto	SysSelectEnd1
SysSelect1Case13
	movlw	12
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case14
	banksel	ANSELB
	bsf	ANSELB,4
;Case 13: Set ANSELB.5 On
	goto	SysSelectEnd1
SysSelect1Case14
	movlw	13
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case15
	banksel	ANSELB
	bsf	ANSELB,5
;Case 14: Set ANSELB.6 On
	goto	SysSelectEnd1
SysSelect1Case15
	movlw	14
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case16
	banksel	ANSELB
	bsf	ANSELB,6
;Case 15: Set ANSELB.7 On
	goto	SysSelectEnd1
SysSelect1Case16
	movlw	15
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case17
	banksel	ANSELB
	bsf	ANSELB,7
;Case 16: Set ANSELC.0 On
	goto	SysSelectEnd1
SysSelect1Case17
	movlw	16
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case18
	banksel	ANSELC
	bsf	ANSELC,0
;Case 17: Set ANSELC.1 On
	goto	SysSelectEnd1
SysSelect1Case18
	movlw	17
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case19
	banksel	ANSELC
	bsf	ANSELC,1
;Case 18: Set ANSELC.2 On
	goto	SysSelectEnd1
SysSelect1Case19
	movlw	18
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case20
	banksel	ANSELC
	bsf	ANSELC,2
;Case 19: Set ANSELC.3 On
	goto	SysSelectEnd1
SysSelect1Case20
	movlw	19
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case21
	banksel	ANSELC
	bsf	ANSELC,3
;Case 20: Set ANSELC.4 On
	goto	SysSelectEnd1
SysSelect1Case21
	movlw	20
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case22
	banksel	ANSELC
	bsf	ANSELC,4
;Case 21: Set ANSELC.5 On
	goto	SysSelectEnd1
SysSelect1Case22
	movlw	21
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case23
	banksel	ANSELC
	bsf	ANSELC,5
;Case 22: Set ANSELC.6 On
	goto	SysSelectEnd1
SysSelect1Case23
	movlw	22
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case24
	banksel	ANSELC
	bsf	ANSELC,6
;Case 23: Set ANSELC.7 On
	goto	SysSelectEnd1
SysSelect1Case24
	movlw	23
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case25
	banksel	ANSELC
	bsf	ANSELC,7
;Case 24: Set ANSELD.0 On
	goto	SysSelectEnd1
SysSelect1Case25
	movlw	24
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case26
	banksel	ANSELD
	bsf	ANSELD,0
;Case 25: Set ANSELD.1 On
	goto	SysSelectEnd1
SysSelect1Case26
	movlw	25
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case27
	banksel	ANSELD
	bsf	ANSELD,1
;Case 26: Set ANSELD.2 On
	goto	SysSelectEnd1
SysSelect1Case27
	movlw	26
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case28
	banksel	ANSELD
	bsf	ANSELD,2
;Case 27: Set ANSELD.3 On
	goto	SysSelectEnd1
SysSelect1Case28
	movlw	27
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case29
	banksel	ANSELD
	bsf	ANSELD,3
;Case 28: Set ANSELD.4 On
	goto	SysSelectEnd1
SysSelect1Case29
	movlw	28
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case30
	banksel	ANSELD
	bsf	ANSELD,4
;Case 29: Set ANSELD.5 On
	goto	SysSelectEnd1
SysSelect1Case30
	movlw	29
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case31
	banksel	ANSELD
	bsf	ANSELD,5
;Case 30: Set ANSELD.6 On
	goto	SysSelectEnd1
SysSelect1Case31
	movlw	30
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case32
	banksel	ANSELD
	bsf	ANSELD,6
;Case 31: Set ANSELD.7 On
	goto	SysSelectEnd1
SysSelect1Case32
	movlw	31
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case33
	banksel	ANSELD
	bsf	ANSELD,7
;Case 32: Set ANSELE.0 On
	goto	SysSelectEnd1
SysSelect1Case33
	movlw	32
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case34
	banksel	ANSELE
	bsf	ANSELE,0
;Case 33: Set ANSELE.1 On
	goto	SysSelectEnd1
SysSelect1Case34
	movlw	33
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelect1Case35
	banksel	ANSELE
	bsf	ANSELE,1
;Case 34: Set ANSELE.2 On
	goto	SysSelectEnd1
SysSelect1Case35
	movlw	34
	subwf	ADREADPORT,W
	btfss	STATUS, Z
	goto	SysSelectEnd1
	banksel	ANSELE
	bsf	ANSELE,2
;End Select  '*** ANSEL Bits should now be set ***
SysSelectEnd1
;*** ANSEL Bits are now set ***
;Set voltage reference
;ADREF = 0  'Default = 0 /Vref+ = Vdd/ Vref-  = Vss
;Configure AD clock defaults
;Set ADCS off 'Clock source = FOSC/ADCLK
	banksel	ADCON0
	bcf	ADCON0,ADCS
;ADCLK = 1 ' default to FOSC/2
	movlw	1
	movwf	ADCLK
;Conversion Clock Speed
;SET ADCS OFF  'ADCON0.4
	bcf	ADCON0,ADCS
;ADCLK = 15    'FOSC/16
	movlw	15
	movwf	ADCLK
;Result formatting
;if ADLeftadjust = 0 then  '10-bit
;Set ADCON.2 off     '8-bit
;Set ADFM OFF
	bcf	ADCON0,ADFRM0
;Set ADFM0 OFF
	bcf	ADCON0,ADFM0
;End if
;Select Channel
;ADPCH = ADReadPort  'Configure AD read Channel
	banksel	ADREADPORT
	movf	ADREADPORT,W
	banksel	ADPCH
	movwf	ADPCH
;Enable A/D
;SET ADON ON
	bsf	ADCON0,ADON
;Acquisition Delay
;Wait AD_Delay
	movlw	2
	movwf	SysWaitTemp10US
	banksel	STATUS
	call	Delay_10US
;Read A/D @1
;SET GO_NOT_DONE ON
	banksel	ADCON0
	bsf	ADCON0,GO_NOT_DONE
;nop
	nop
;Wait While GO_NOT_DONE ON
SysWaitLoop1
	btfsc	ADCON0,GO_NOT_DONE
	goto	SysWaitLoop1
;Switch off A/D
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
;ReadAD = ADRESH
	banksel	ADRESH
	movf	ADRESH,W
	banksel	READAD
	movwf	READAD
;SET ADFM OFF
	banksel	ADCON0
	bcf	ADCON0,ADFRM0
	banksel	STATUS
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

;Source: system.h (3023)
SYSCOMPEQUAL16
;dim SysWordTempA as word
;dim SysWordTempB as word
;dim SysByteTempX as byte
;clrf SysByteTempX
	clrf	SYSBYTETEMPX
;Test low, exit if false
;movf SysWordTempA, W
	movf	SYSWORDTEMPA, W
;subwf SysWordTempB, W
	subwf	SYSWORDTEMPB, W
;btfss STATUS, Z
	btfss	STATUS, Z
;return
	return
;Test high, exit if false
;movf SysWordTempA_H, W
	movf	SYSWORDTEMPA_H, W
;subwf SysWordTempB_H, W
	subwf	SYSWORDTEMPB_H, W
;btfss STATUS, Z
	btfss	STATUS, Z
;return
	return
;comf SysByteTempX,F
	comf	SYSBYTETEMPX,F
	return

;********************************************************************************

;Source: system.h (3302)
SYSCOMPLESSTHAN
;Dim SysByteTempA, SysByteTempB, SysByteTempX as byte
;clrf SysByteTempX
	clrf	SYSBYTETEMPX
;bsf STATUS, C
	bsf	STATUS, C
;movf SysByteTempB, W
	movf	SYSBYTETEMPB, W
;subwf SysByteTempA, W
	subwf	SYSBYTETEMPA, W
;btfss STATUS, C
	btfss	STATUS, C
;comf SysByteTempX,F
	comf	SYSBYTETEMPX,F
	return

;********************************************************************************

;Source: system.h (2712)
SYSDIVSUB
;dim SysByteTempA as byte
;dim SysByteTempB as byte
;dim SysByteTempX as byte
;Check for div/0
;movf SysByteTempB, F
	movf	SYSBYTETEMPB, F
;btfsc STATUS, Z
	btfsc	STATUS, Z
;return
	return
;Main calc routine
;SysByteTempX = 0
	clrf	SYSBYTETEMPX
;SysDivLoop = 8
	movlw	8
	movwf	SYSDIVLOOP
SYSDIV8START
;bcf STATUS, C
	bcf	STATUS, C
;rlf SysByteTempA, F
	rlf	SYSBYTETEMPA, F
;rlf SysByteTempX, F
	rlf	SYSBYTETEMPX, F
;movf SysByteTempB, W
	movf	SYSBYTETEMPB, W
;subwf SysByteTempX, F
	subwf	SYSBYTETEMPX, F
;bsf SysByteTempA, 0
	bsf	SYSBYTETEMPA, 0
;btfsc STATUS, C
	btfsc	STATUS, C
;goto Div8NotNeg
	goto	DIV8NOTNEG
;bcf SysByteTempA, 0
	bcf	SYSBYTETEMPA, 0
;movf SysByteTempB, W
	movf	SYSBYTETEMPB, W
;addwf SysByteTempX, F
	addwf	SYSBYTETEMPX, F
DIV8NOTNEG
;decfsz SysDivLoop, F
	decfsz	SYSDIVLOOP, F
;goto SysDiv8Start
	goto	SYSDIV8START
	return

;********************************************************************************

;Source: system.h (2780)
SYSDIVSUB16
;dim SysWordTempA as word
;dim SysWordTempB as word
;dim SysWordTempX as word
;dim SysDivMultA as word
;dim SysDivMultB as word
;dim SysDivMultX as word
;SysDivMultA = SysWordTempA
	movf	SYSWORDTEMPA,W
	movwf	SYSDIVMULTA
	movf	SYSWORDTEMPA_H,W
	movwf	SYSDIVMULTA_H
;SysDivMultB = SysWordTempB
	movf	SYSWORDTEMPB,W
	movwf	SYSDIVMULTB
	movf	SYSWORDTEMPB_H,W
	movwf	SYSDIVMULTB_H
;SysDivMultX = 0
	clrf	SYSDIVMULTX
	clrf	SYSDIVMULTX_H
;Avoid division by zero
;if SysDivMultB = 0 then
	movf	SYSDIVMULTB,W
	movwf	SysWORDTempA
	movf	SYSDIVMULTB_H,W
	movwf	SysWORDTempA_H
	clrf	SysWORDTempB
	clrf	SysWORDTempB_H
	call	SYSCOMPEQUAL16
	btfss	SysByteTempX,0
	goto	ENDIF20
;SysWordTempA = 0
	clrf	SYSWORDTEMPA
	clrf	SYSWORDTEMPA_H
;exit sub
	return
;end if
ENDIF20
;Main calc routine
;SysDivLoop = 16
	movlw	16
	movwf	SYSDIVLOOP
SYSDIV16START
;set C off
	bcf	STATUS,C
;Rotate SysDivMultA Left
	rlf	SYSDIVMULTA,F
	rlf	SYSDIVMULTA_H,F
;Rotate SysDivMultX Left
	rlf	SYSDIVMULTX,F
	rlf	SYSDIVMULTX_H,F
;SysDivMultX = SysDivMultX - SysDivMultB
	movf	SYSDIVMULTB,W
	subwf	SYSDIVMULTX,F
	movf	SYSDIVMULTB_H,W
	subwfb	SYSDIVMULTX_H,F
;Set SysDivMultA.0 On
	bsf	SYSDIVMULTA,0
;If C Off Then
	btfsc	STATUS,C
	goto	ENDIF21
;Set SysDivMultA.0 Off
	bcf	SYSDIVMULTA,0
;SysDivMultX = SysDivMultX + SysDivMultB
	movf	SYSDIVMULTB,W
	addwf	SYSDIVMULTX,F
	movf	SYSDIVMULTB_H,W
	addwfc	SYSDIVMULTX_H,F
;End If
ENDIF21
;decfsz SysDivLoop, F
	decfsz	SYSDIVLOOP, F
;goto SysDiv16Start
	goto	SYSDIV16START
;SysWordTempA = SysDivMultA
	movf	SYSDIVMULTA,W
	movwf	SYSWORDTEMPA
	movf	SYSDIVMULTA_H,W
	movwf	SYSWORDTEMPA_H
;SysWordTempX = SysDivMultX
	movf	SYSDIVMULTX,W
	movwf	SYSWORDTEMPX
	movf	SYSDIVMULTX_H,W
	movwf	SYSWORDTEMPX_H
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
	retlw	6
	retlw	76	;L
	retlw	69	;E
	retlw	70	;F
	retlw	84	;T
	retlw	58	;:
	retlw	32	; 


StringTable2
	retlw	7
	retlw	70	;F
	retlw	82	;R
	retlw	79	;O
	retlw	78	;N
	retlw	84	;T
	retlw	58	;:
	retlw	32	; 


;********************************************************************************

;Start of program memory page 1
	ORG	2048
;Start of program memory page 2
	ORG	4096
;Start of program memory page 3
	ORG	6144

 END
