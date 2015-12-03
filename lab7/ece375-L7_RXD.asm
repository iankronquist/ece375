;***********************************************************
;*
;*	This is the RECEIVE skeleton file for Lab 7 of ECE 375
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multi-Purpose Register
.def	mpr2 = r17				; Multi-Purpose Register

.def	ilcnt = r18				; Inner Loop Counter
.def	olcnt = r19				; Outer Loop Counter
.def	waitcnt = r20			; Wait Loop Counter

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit
.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit

.equ	buffer = $0100

.equ	freezeCount = $0120

.equ	freezeTag = 0b01010101

.equ	whichBit = $0130

.equ	BotID = 42 ;(Enter you group ID here (8bits)); Unique XD ID (MSB = 0)

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////

.equ	MovFwd =  (1<<EngDirR|1<<EngDirL)	;0b01100000 Move Forwards Command
.equ	MovBck =  $00						;0b00000000 Move Backwards Command
.equ	TurnR =   (1<<EngDirL)				;0b01000000 Turn Right Command
.equ	TurnL =   (1<<EngDirR)				;0b00100000 Turn Left Command
.equ	Halt =    (1<<EngEnR|1<<EngEnL)		;0b10010000 Halt Command

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

;Should have Interrupt vectors for:

;- Left whisker
.org	$0002					; Beginning of IVs
		rcall 	HitLeft			; Reset interrupt
		reti

;- Right whisker
.org	$0004					; Beginning of IVs
		rcall 	HitRight			; Reset interrupt
		reti

;- USART receive
.org $003C ; Receive interrupt
	rcall usartReceive
	reti


.org	$0046					; End of Interrupt Vectors

;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT:
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


	;USART1
	;Set baudrate at 2400bps
    ; Set the baud rate
    ldi mpr, low(416)
    sts UBRR1L, mpr
    ldi mpr, high(416)
    sts UBRR1H, mpr
    ldi mpr, (0<<U2X1)
    sts UCSR1A, mpr

    ; Enable receive interrupt
    ldi mpr, (1<<RXCIE1)|(1<<RXEN1)|(1<<TXEN1)
    sts UCSR1B, mpr

    ; Set frame format
	; Set frame format: 8 data bits, 2 stop bits
	; 2 stop bits is USBS1, data bits are UCCSZ*
    ldi mpr, (1<<UCSZ10)|(1<<UCSZ11)|(1<<USBS1)|(1<<UPM01)
    sts UCSR1C, mpr


	;External Interrupts
	;Set the Interrupt Sense Control to low level detection
	; Don't use any of the higher interrupts
	ldi	mpr, 0x0
	sts	EICRB, mpr

	; Interrupts 0 and 1 should fire on a falling edge
	ldi	mpr, 0xa
	sts	EICRA, mpr
	; Set the External Interrupt Mask

	;Set the External Interrupt Mask
	; Enable interrupts 2 and 3, External interrupt requests 0 and 1
	ldi	mpr, 0x03
	out	EIMSK, mpr

	; Move forward
	ldi	mpr,	MovFwd
	out	PORTB,	mpr

	; Zero the freezeCount
	ldi XL, low(freezeCount)
	ldi XH, high(freezeCount)
	ld mpr, X
	clr mpr
	st X, mpr

	sei

;Other


;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:

	rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

usartReceive:
	push waitcnt
	push mpr
	push mpr2
	push XL
	push XH
	push ZL
	push ZH


	; Read byte
	ldi XL, low(buffer)
	ldi XH, high(buffer)

	lds mpr, UDR1

	cpi mpr, freezeTag ; The robot was tagged
	breq tag

	; Which byte are we expecting?
	ldi ZL, low(whichBit)
	ldi ZH, high(whichBit)
	ld  mpr2, Z
	cpi mpr2, 0x0
	breq command

action:
	; Expect a device byte next
	com mpr2
	st Z, mpr2

	cpi mpr, 0b11110000 ; reserved
	breq sendFreeze

	cpi mpr, BotID ; Race condition encountered. Attempt to recover.
	breq usartReceiveCleanup

	lsr mpr
	out PORTB, mpr
	rjmp usartReceiveCleanup

command:
	; Check if we got the freeze command
	; If the bytes don't match cleanup and continue waiting for a valid command 
	; byte.
	out PORTB, mpr
	;ldi waitcnt, 100
	;rcall Wait
	cpi mpr, BotID
	brne usartReceiveCleanup
	; Expect an action byte next
	com mpr2
	st Z, mpr2
	; Fall through to cleanup.

usartReceiveCleanup:
	pop ZH
	pop ZL
	pop XH
	pop XL
	pop mpr2
	pop mpr
	pop waitcnt
	ret


tag:

	ldi mpr, Halt
	out PORTB, mpr

	ldi XL, low(freezeCount)
	ldi XH, high(freezeCount)
	ld mpr, X
	inc mpr
	out PORTB, mpr


	; If it has been tagged three times enter an infinite loop
	cpi mpr, 3
	breq shutdown
	st X, mpr
	; Wait for 250 milliseconds twice for a total of 5 seconds
	ldi waitcnt, 250
	rcall Wait
	rcall Wait
	rjmp usartReceiveCleanup

sendFreeze:
	out PORTB, mpr
	;pollTransmit:
	;	lds mpr2, UCSR1A
	;	sbrs mpr2, TXC1
	;	rjmp pollTransmit
	ldi mpr, freezeTag
	sts UDR1, mpr
	out PORTB, mpr
	; Once the receive flag is set, read back the freeze byte so we don't
	; accidentally receive our own freeze command
	pollReceive:
		lds mpr2, UCSR1A
		sbrs mpr2, RXC1
		rjmp pollReceive
	lds mpr, UDR1
	out PORTB, mpr
	rjmp usartReceiveCleanup

; Disable interrupts and loop forever
shutdown:
	rjmp shutdown

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
