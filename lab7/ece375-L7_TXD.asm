;***********************************************************
;*
;*	Enter Name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the TRANSMIT skeleton file for Lab 7 of ECE 375
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
.def	mpr = r16				; Multi-Purpose Register

.def	ilcnt = r18				; Inner Loop Counter
.def	olcnt = r19				; Outer Loop Counter
.def	waitcnt = r20			; Wait Loop Counter

; Use these commands between the remote and TekBot
; MSB = 1 thus:
; commands are shifted right by one and ORed with 0b10000000 = $80

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit
.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit


.equ	BotID = 42 ;(Enter you group ID here (8bits)); Unique XD ID (MSB = 0)

.equ	MovFwd =  ($80|1<<(EngDirR-1)|1<<(EngDirL-1))	;0b10110000 Move Forwards Command
.equ	MovBck =  ($80|$00)								;0b10000000 Move Backwards Command
.equ	TurnR =   ($80|1<<(EngDirL-1))					;0b10100000 Turn Right Command
.equ	TurnL =   ($80|1<<(EngDirR-1))					;0b10010000 Turn Left Command
.equ	Halt =    ($80|1<<(EngEnR-1)|1<<(EngEnL-1))		;0b11001000 Halt Command
.equ	Freez =   ($80|$F8)
;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

;- Left whisker
.org	$0002					; Beginning of IVs
		rcall 	sendFreeze
		reti

;- Right whisker
.org	$0004					; Beginning of IVs
		rcall 	HaltAndCatchFire
		reti



.org	$0046					; End of Interrupt Vectors

;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT:
	;Stack Pointer (VERY IMPORTANT!!!!)
	;USART1
		;Set baudrate at 2400bps
		;Enable transmitter
		;Set frame format: 8 data bits, 2 stop bits
	;Stack Pointer (VERY IMPORTANT!!!!)
	ldi		mpr, low(RAMEND)
	out		SPL, mpr		; Load SPL with low byte of RAMEND
	ldi		mpr, high(RAMEND)
	out		SPH, mpr		; Load SPH with high byte of RAMEND


	;I/O Ports
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


	; USART1
	; Set baudrate at 2400bps
    ; Set the baud rate and enable double data rate
    ldi mpr, low(416)
    sts UBRR1L, mpr
    ldi mpr, high(416)
    sts UBRR1H, mpr
    ldi mpr, (0<<U2X1)
    sts UCSR1A, mpr

    ; Enable Transmission
    ldi mpr, (1<<TXEN1)
    sts UCSR1B, mpr

	; Set frame format: 8 data bits, 2 stop bits
	; 2 stop bits is USBS1, data bits are UCCSZ*
    ldi mpr, (1<<UCSZ10)|(1<<UCSZ11)|(1<<USBS1)|(1<<UPM01)
    sts UCSR1C, mpr


	;External Interrupts
	;Set the Interrupt Sense Control to low level detection
	; Don't use any of the higher interrupts
	ldi	mpr, 0x0
	sts	EICRA, mpr

	; Interrupts 0 and 1 should fire on a falling edge
	ldi	mpr, 0xa
	out	EICRB, mpr
	; Set the External Interrupt Mask

	;Set the External Interrupt Mask
	; Enable S1 & S2
	ldi	mpr, 0x03
	out	EIMSK, mpr

	clr mpr
	out PORTB, mpr

	sei


	;Other


;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:
	;in mpr, PORTD
	;out PORTB, mpr

	sbis PIND, 7
	rjmp forward
	sbis PIND, 6
	rjmp backward
	sbis PIND, 5
	rjmp turnLeft
	sbis PIND, 4
	rjmp turnRight
	rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

sendBotId:
	ldi mpr, BotID
	sts UDR1, mpr
	rcall waitSent
	ret

forward:
	rcall sendBotId
	ldi mpr, MovFwd
	sts UDR1, mpr
	out PORTB, mpr
	rcall waitSent
	rjmp MAIN

backward:
	rcall sendBotId
	ldi mpr, MovBck
	sts UDR1, mpr
	out PORTB, mpr
	rcall waitSent
	rjmp MAIN

turnLeft:
	rcall sendBotId
	ldi mpr, TurnL
	sts UDR1, mpr
	out PORTB, mpr
	rcall waitSent
	rjmp MAIN

turnRight:
	rcall sendBotId
	ldi mpr, TurnR
	sts UDR1, mpr
	out PORTB, mpr
	rcall waitSent
	rjmp MAIN

HaltAndCatchFire:
	rcall sendBotId
	ldi mpr, Halt
	sts UDR1, mpr
	out PORTB, mpr
	rcall waitSent
	reti

sendFreeze:
	rcall sendBotId
	ldi mpr, 0b11110000
	sts UDR1, mpr
	out PORTB, mpr
	rcall waitSent
	reti

waitSent:
	lds mpr, UCSR1A
	andi mpr, 0x80
	breq waitSent
	ret


; Useful for debugging
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


;***********************************************************
;*	Stored Program Data
;***********************************************************



;***********************************************************
;*	Additional Program Includes
;***********************************************************
