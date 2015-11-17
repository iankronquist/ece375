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


; Use these commands between the remote and TekBot
; MSB = 1 thus:
; commands are shifted right by one and ORed with 0b10000000 = $80

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit
.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit


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
    ldi mpr, (1<<U2X1)
    sts UCSR1A, mpr

    ; Enable receive interrupt
    ; ldi mpr, (1<<RXCIE1)|(1<<RXEN1)
    ; out UCSR1B, mpr

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
	; Enable interrupts 2 and 3, External interrupt requests 0 and 1
	ldi	mpr, 0x03
	out	EIMSK, mpr


	;Other


;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:

		rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************



;***********************************************************
;*	Stored Program Data
;***********************************************************



;***********************************************************
;*	Additional Program Includes
;***********************************************************
