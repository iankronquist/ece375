;***********************************************************
;*
;*	Enter Name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the skeleton file Lab 5 of ECE 375
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
.def	mpr = r16				; Multipurpose register 
.def	waitcnt = r17				; Wait Loop Counter
.def	ilcnt = r18				; Inner Loop Counter
.def	olcnt = r19				; Outer Loop Counter
; Other register renames


; Constants for interactions such as
.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit

; Using the constants from above, create the movement 
; commands, Forwards, Backwards, Stop, Turn Left, and Turn Right

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

.org	$0002					; Beginning of IVs
		rcall 	HitLeft			; Reset interrupt
		reti

.org	$0004					; Beginning of IVs
		rcall 	HitRight			; Reset interrupt
		reti

.org	$0046					; End of Interrupt Vectors

;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT:	; The initialization routine
		ldi		mpr, low(RAMEND)
		out		SPL, mpr		; Load SPL with low byte of RAMEND
		ldi		mpr, high(RAMEND)
		out		SPH, mpr		; Load SPH with high byte of RAMEND

		; Initialize Port B for output
		ldi		mpr, $00		; Initialize Port B for outputs
		out		PORTB, mpr		; Port B outputs low
		ldi		mpr, $FF		; Set Port B Directional Register
		out		DDRB, mpr		; for output

		; Initialize Port D for inputs
		ldi		mpr, $FF		; Initialize Port D for inputs
		out		PORTD, mpr		; with Tri-State
		ldi		mpr, $00		; Set Port D Directional Register
		out		DDRD, mpr		; for inputs

		; Initialize external interrupts
		; Set the Interrupt Sense Control to low level 
		; NOTE: must initialize both EICRA and EICRB

		; Don't use any of the higher interrupts
		ldi	mpr, 0x0
		sts	EICRA, mpr

		; Interrupts 0 and 1 should fire on a falling edge
		ldi	mpr, 0xa
		out	EICRB, mpr
		; Set the External Interrupt Mask

		; Enable interrupts 2 and 3, External interrupt requests 0 and 1
		ldi	mpr, 0x03
		out	EIMSK, mpr

		sei

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:	; The Main program

		; Send command to Move Robot Forward 
		; That is all you should have in MAIN

		; Turn off motors for good measure.
		ldi	mpr,	0xF0
		out	PORTB,	mpr
		; Move forward
		ldi	mpr,	0x60
		out	PORTB,	mpr

		rjmp	MAIN			; Create an infinite while loop to signify the 
								; end of the program.


HitLeft:
	; Save registers
	push	mpr
	push	waitcnt
	; Save flags
	in  	mpr,	SREG
	push	mpr
	; Reverse
	ldi	mpr,	0x00
	out	PORTB,	mpr
	ldi	waitcnt, 100
	rcall Wait
	; Turn left
	ldi	mpr,	0x20
	out	PORTB,	mpr
	ldi	waitcnt, 100
	rcall Wait
	; Move forward
	ldi	mpr,	0x60
	out	PORTB,	mpr

	pop 	mpr
	out 	SREG,	mpr
	pop 	waitcnt
	pop 	mpr
	ret

HitRight:
	push	mpr
	push	waitcnt
	; Save flags
	in  	mpr,	SREG
	push	mpr
	; Reverse
	ldi	mpr,	0x0
	out	PORTB,	mpr
	ldi	waitcnt, 100
	rcall	Wait
	; Turn right
	ldi	mpr,	0x40
	out	PORTB,	mpr
	ldi	waitcnt, 100
	rcall	Wait
	; Move forward
	ldi	mpr,	0x60
	out	PORTB,	mpr

	pop 	mpr
	out 	SREG,	mpr
	pop 	waitcnt
	pop 	mpr
	ret


; Shamelessly stolen from lab 1
Wait:
		push	waitcnt			; Save wait register
		push	ilcnt			; Save ilcnt register
		push	olcnt			; Save olcnt register

Loop:	ldi		olcnt, 224		; load olcnt register
OLoop:	ldi		ilcnt, 237		; load ilcnt register
ILoop:	dec		ilcnt			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		olcnt		; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		waitcnt		; Decrement wait 
		brne	Loop			; Continue Wait loop	

		pop		olcnt		; Restore olcnt register
		pop		ilcnt		; Restore ilcnt register
		pop		waitcnt		; Restore wait register
		ret				; Return from subroutine
