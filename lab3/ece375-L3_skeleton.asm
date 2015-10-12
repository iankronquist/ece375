;***********************************************************
;*
;*	Enter Name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the skeleton file Lab 3 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Enter your name
;*	   Date: Enter Date
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register required for LCD Driver


;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp INIT				; Reset interrupt

.org	$0046					; End of Interrupt Vectors

;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT:							; The initialization routine
		; Initialize Stack Pointer
		; Load the high bits of the address of the end of ram into the mpr
		ldi		mpr, HIGH(RAMEND)
		; Write the high bits of the address of the end of ram into the high
		; bits of the stack pointer.
		out		SPH, mpr
		; Load the low bits of the address of the end of ram into the mpr
		ldi		mpr, LOW(RAMEND)
		; Write the low bits of the address of the end of ram into the low
		; bits of the stack pointer.
		out		SPL, mpr

		; Initialize LCD Display
		rcall LCDInit
		rcall	LCDClrLn2		; CLEAR LINE 2 OF LCD

		; Move strings from Program Memory to Data Memory
		; initialize Z with the destination value
		ldi	zh, high(LCDLn1Addr)<<1
		ldi	zl, low(LCDLn1Addr)<<1
		; initialize X with the source value
		ldi	r27, high(STRING_BEG)
		ldi	r26, low(STRING_BEG)


		loop:
			; Load data from the 
			lpm r0,	Z+
			st	X+, r0

			cpi	r28,	0x10
			brlt	loop


;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:
		rcall LCDWrLn1

		rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
FUNC:							; Begin a function with a label
		; Save variable by pushing them to the stack

		; Execute the function here
		
		; Restore variable by popping them from the stack in reverse order\
		ret						; End a function with RET


;***********************************************************
;*	Stored Program Data
;***********************************************************

STRING_BEG:
.DB		"Ian Kronquist"		; Storing the string in Program Memory
STRING_END:

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver
