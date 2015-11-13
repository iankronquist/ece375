;***********************************************************
;*
;*	Enter Name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the skeleton file Lab 6 of ECE 375
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
.def	mpr2 = r17				; Multipurpose register
.def	waitcnt = r18				; Wait Loop Counter
.def	ilcnt = r19				; Inner Loop Counter
.def	olcnt = r20				; Outer Loop Counter

.equ	EngEnR = 4				; right Engine Enable Bit
.equ	EngEnL = 7				; left Engine Enable Bit
.equ	EngDirR = 5				; right Engine Direction Bit
.equ	EngDirL = 6				; left Engine Direction Bit

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000
		rjmp	INIT			; reset interrupt

		; place instructions in interrupt vectors here, if needed

.org	$0002					; Beginning of IVs
		rcall 	Decr			; Reset interrupt
		reti

.org	$0004					; Beginning of IVs
		rcall 	Incr			; Reset interrupt
		reti


.org	$0046					; end of interrupt vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:

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
		ldi		mpr, 0x0
		sts		EICRA, mpr

		; Interrupts 0 and 1 should fire on a falling edge
		ldi		mpr, (1<<ISC41)|(1<<ISC40)|(1<<ISC51)|(1<<ISC50)

		out		EICRB, mpr
		; Set the External Interrupt Mask

		; Enable interrupts 2 and 3, External interrupt requests 0 and 1
		ldi		mpr, 0x03
		out		EIMSK, mpr

		ldi		mpr,	(1<<WGM01)|(1<<WGM00)|(1<<COM00)|(1<<COM01)|(1<<CS00)
		out		TCCR0,	mpr
		out		TCCR2,	mpr

		; Turn off motors.
		;ldi		mpr,	0xff
		;out		OCR0,	mpr
		;out		OCR2,	mpr


		sei



;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		; poll Port D pushbuttons (if needed)

								; if pressed, adjust speed
								; also, adjust speed indication

		rjmp	MAIN			; return to top of MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************


Incr:
	; Save registers
	push    mpr
	push    mpr2
	push    ZH
	push    ZL

	in	    mpr,	OCR0

	;cpi	    mpr,	0xff
	;breq    IncrDone

	ldi		mpr2,	16
	add		mpr,	mpr2
	out		OCR0,	mpr
	in		mpr,	OCR2
	add		mpr,	mpr2
	out		OCR2,	mpr

	ldi		ZL,		low(Level)
	ldi		ZH,		high(Level)
	ld		mpr,	Z
	inc		mpr
	st		Z,		mpr
	andi	mpr,	0x0F
	out		PORTB,	mpr
	ldi		mpr,	255
	rcall	Wait



IncrDone:
	pop		ZL
	pop		ZH
	pop		mpr2
	pop		mpr
	ret

Decr:
	; Save registers
	push    mpr
	push    mpr2
	push    ZH
	push    ZL

	in	    mpr,	OCR0

	;cpi	    mpr,	0x0
	;breq    DecrDone

	ldi		mpr2,	16
	sub		mpr,	mpr2
	out		OCR0,	mpr
	in		mpr,	OCR2
	sub		mpr,	mpr2
	out		OCR2,	mpr


	ldi		ZL,	low(Level)
	ldi		ZH,	high(Level)
	ld		mpr,	Z
	dec		mpr
	st		Z,		mpr

	andi	mpr,	0x0F
	out		PORTB,	mpr
	ldi		mpr,	255
	rcall	Wait


DecrDone:
	pop		ZL
	pop		ZH
	pop		mpr2
	pop		mpr
	ret


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
	

;***********************************************************
;*	Stored Program Data
;***********************************************************
		; Enter any stored data you might need here
Level:
.dw 0

;***********************************************************
;*	Additional Program Includes
;***********************************************************
		; There are no additional file includes for this program

