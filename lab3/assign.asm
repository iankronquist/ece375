.include "m128def.inc"

.def	mpr = r16
.def	ReadCnt = r23
.def	val = r5

.cseg							; Beginning of code segment

INIT:
		; Initialize Stack Pointer
		ldi		mpr, HIGH(RAMEND)
		out		SPH, mpr
		ldi		mpr, LOW(RAMEND)
		out		SPL, mpr

		; Initialize LCD display
		rcall	LCDInit

		; Load the location of the program text into the Z register. This is
		; our data source.
		ldi		ZL, low(TXT0<<1)
		ldi		ZH, high(TXT0<<1)
		; Load the location of memory which the LCD data is pulled from into
		; the Y register. This is the destination address.
		ldi		YL, low(LCDLn1Addr)
		ldi		YH, high(LCDLn1Addr)
		; Initialize the counter for the number of bytes written
		ldi		ReadCnt, LCDMaxCnt

		; Load the text of line 1 from the program memory into the data memory
INIT_LINE1:
		lpm		mpr, Z+
		st		Y+, mpr
		dec		ReadCnt
		brne	INIT_LINE1
		; Write the text
		rcall	LCDWrLn1

		; Load the location of the program text into the Z register. This is
		; our data source.
		ldi		ZL, low(TXT1<<1)
		ldi		ZH, high(TXT1<<1)
		; Load the location of memory which the LCD data is pulled from into
		; the Y register. This is the destination address.
		ldi		YL, low(LCDLn2Addr)
		ldi		YH, high(LCDLn2Addr)
		; Initialize the counter for the number of bytes written
		ldi		ReadCnt, LCDMaxCnt
		; Load the text of line 2 from the program memory into the data memory
INIT_LINE2:
		lpm		mpr, Z+
		st		Y+, mpr
		dec		ReadCnt
		brne	INIT_LINE2
		; Write the text
		rcall	LCDWrLn2




;***********************************************************
;*	The main program 
;***********************************************************
MAIN:

NEXT:	rjmp	MAIN			; Go back to beginning



;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;***********************************************************
;* Func:	WriteText
;* Desc:	Writes the text that is pointed to by the Z pointer
;*			from Program Memory to the second line of the LCD 
;*			Display.
;***********************************************************
WriteText:
		push	mpr				; Save the mpr register
		push	ReadCnt			; Save the ReadCounter
		rcall	LCDClrLn2		; CLEAR LINE 2 OF LCD
								; LOAD THE LCD MAX LINE COUNT (16)
		ldi		ReadCnt, LCDMaxCnt
								; LOAD THE Y POINTER WITH THE DATA
								; ADDRESS FOR LINE 2 DATA
		ldi		YL, low(LCDLn2Addr)
		ldi		YH, high(LCDLn2Addr)
WriteText_lp:					; Loop that reads the data
		lpm		mpr, Z+			; Read program data
		st		Y+, mpr			; Store data to memory
		dec		ReadCnt			; Decrement counter
		brne	WriteText_lp	; Loop untill all data is read
		rcall	LCDWrLn2		; WRITE DATA TO LINE 2
		pop		ReadCnt			; Restore the ReadCounter
		pop		mpr				; Restore the mpr register
		ret						; Return from function



;***********************************************************
;*	Data Definitions
;***********************************************************
TXT0:
.DB "Ian Kronquist   "
TXT1:
.DB "Hello world     "
;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver
