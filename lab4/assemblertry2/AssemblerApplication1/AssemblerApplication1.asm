;***********************************************************
;*
;*	Enter Name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the skeleton file Lab 4 of ECE 375
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
.def	rlo = r0				; Low byte of MUL result
.def	rhi = r1				; High byte of MUL result
.def	zero = r2				; Zero register, set to zero in INIT, useful for calculations
.def	A = r3					; An operand
.def	B = r4					; Another operand
.def	C = r5

.def	oloop = r17				; Outer Loop Counter
.def	iloop = r18				; Inner Loop Counter

.equ	addrA = $0100			; Beginning Address of Operand A data
.equ	addrB = $0102			; Beginning Address of Operand B data
.equ	LAddrP = $0104			; Beginning Address of Product Result
.equ	HAddrP = $0109			; End Address of Product Result
.equ	addrC = 0x0110
.equ	addrD = 0x0113
.equ	addDest0 = $0110			; End Address of Product Result\
.equ	mulDest0 = 0x0145			; End Address of Product Result


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
INIT:							; The initialization routine
		; Initialize Stack Pointer
		ldi	mpr,	HIGH(RAMEND)				; Init the 2 stack pointer registers
		out SPH,	mpr
		ldi	mpr,	LOW(RAMEND)				; Init the 2 stack pointer registers
		out SPL,	mpr

		clr		zero			; Set the zero register to zero, maintain
								; these semantics, meaning, don't load anything
								; to it.

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:							; The Main program
		; Setup the add function
		ldi	r16,	0xff
		ldi r17,	0xff
		ldi	r18,	0xff
		ldi r19,	0xff
		ldi	ZL,	low(addrA)
		ldi	ZH,	high(addrA)
		st	Z+,	r16
		st	Z,	r17
		ldi	ZL,	low(addrB)
		ldi	ZH,	high(addrB)
		st	Z+,	r18
		st	Z,	r19
		;rcall MUL24
		;rjmp	DONE
		; Add the two 16-bit numbers
		rcall	ADD16			; Call the add function

		; Setup the multiply function

		ldi	YL,	low(addrC)
		ldi	YH,	high(addrC)
		ld	r0,	Y+
		ld	r1,	Y+
		ld	r2,	Y

		ldi	ZL,	low(addrD)
		ldi	ZH,	high(addrD)
		st	Z+,	r0
		st	Z+,	r1
		st	Z,	r2

		; Multiply two 24-bit numbers
		rcall	MUL24			; Call the multiply function

DONE:	rjmp	DONE			; Create an infinite while loop to signify the 
								; end of the program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: ADD16
; Desc: Adds two 16-bit numbers and generates a 24-bit number
;		where the high byte of the result contains the carry
;		out bit.
;-----------------------------------------------------------
ADD16:
		; Save registers
		push r0
		push r1
		push r2
		push r3
		push r4
		push ZL
		push ZH

		ldi	ZL,	low(addrA)
		ldi	ZH,	high(addrA)
		mov	r1, ZH
		mov	r2, ZL

		ldi	ZL,	low(addrB)
		ldi	ZH,	high(addrB)
		; TODO: optimize away
		mov	r3, ZH
		mov	r4, ZL

		; Add operands
		add	r1, r3
		adc	r2, r4
		; Put the carry bit in r0
		adc	r0, zero
		
		; Write the result to addrC[0] through addrC[2]
		ldi	ZL, low(addrC)
		ldi	ZH, high(addrC)
		st	Z+,	r0
		st	Z+,	r1
		st	Z,	r2

		; Restore registers
		pop ZH
		pop ZL
		pop r4
		pop r3
		pop r2
		pop	r1
		pop r0
		ret


MUL24v1:
		push 	A				; Save A register
		push	B				; Save B register
		push	C
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL				
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop				

		clr		zero			; Maintain zero semantics

		; Set Y to beginning address of B
		ldi		YL, low(addrB)	; Load low byte
		ldi		YH, high(addrB)	; Load high byte

		; Set Z to begginning address of resulting Product
		ldi		ZL, low(mulDest0)	; Load low byte
		ldi		ZH, high(mulDest0); Load high byte

		; Begin outer for loop
		ldi		oloop, 3		; Load counter
MUL24_OLOOP:
		; Set X to beginning address of A
		ldi		XL, low(addrA)	; Load low byte
		ldi		XH, high(addrA)	; Load high byte

		; Begin inner for loop
		ldi		iloop, 3		; Load counter
MUL24_ILOOP:
		ld		A, X+			; Get byte of A operand
		ld		B, Y			; Get byte of B operand
		mul		A,B				; Multiply A and B
		ld		A, Z+			; Get a result byte from memory
		ld		B, Z+			; Get the next result byte from memory
		add		rlo, A			; rlo <= rlo + A
		adc		rhi, B			; rhi <= rhi + B + carry
		ld		A, Z			; Get a third byte from the result
		adc		A, zero			; Add carry to A
		st		Z, A			; Store first byte to memory
		st		-Z, rhi			; Store second byte to memory
		st		-Z, rlo			; Store third byte to memory
		adiw	ZH:ZL, 1		; Z <= Z + 1			
		dec		iloop			; Decrement counter
		brne	MUL24_ILOOP		; Loop if iLoop != 0
		; End inner for loop

		sbiw	ZH:ZL, 1		; Z <= Z - 1
		adiw	YH:YL, 1		; Y <= Y + 1
		dec		oloop			; Decrement counter
		brne	MUL24_OLOOP		; Loop if oLoop != 0
		; End outer for loop
		 		
		pop		iloop			; Restore all registers in reverves order
		pop		oloop
		pop		ZL				
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		C
		pop		B
		pop		A
		ret						; End a function with RET
;-----------------------------------------------------------
; Func: MUL24
; Desc: Multiplies two 24-bit numbers and generates a 48-bit 
;		result.
;-----------------------------------------------------------
MUL24:
;.include "m128def.inc"

.def carry = r15
.def innerCount = r16
.def outerCount = r17
.def I = r18
.def J = r19
.def K = r20
.def zero = r21
.equ srcA = addrC
.equ srcB = addrD
;.equ ptrA = 0x108
;.equ ptrB = 0x109
.equ dest = addDest0

;mul24:
	push	carry
	push	innerCount
	push	outerCount
	push	I
	push	J
	push	K
	push	zero
	push	XL
	push	XH
	push	YL
	push	YH
	push	ZL
	push	ZH
	clr 	carry
	clr		zero
	ldi 	outerCount, 3
	clc


	;ldi 	ZL,	low(mulDest0)
	;ldi 	ZH,	high(mulDest0)
	ldi 	XL,	low(srcA)
	ldi 	XH,	high(srcA)

	outer:
		ldi 	ZL,	low(mulDest0)
		ldi 	ZH,	high(mulDest0)
		mov		K,	outerCount
		ldi		I, 0x3
		sub		I, K
		sub		ZL, I
		sbc		ZH, zero

		ldi 	YL,	low(srcB)
		ldi 	YH,	high(srcB)
		ld  	I, X+
		ldi 	innerCount, 3

	inner:
		ld		K,	Z
		ld  	J,	Y+
		mul 	I,	J
		;add 	r0,	carry
		add		r0,	K
		adc		r1,	zero
		;mov 	carry,	r1
 		st  	Z,	r0
		ld		K,	-Z
		add		r1,	K
		clr		carry
		adc		carry, zero
		st  	Z,	r1
		ld		K, -Z
		add		K, carry
		st  	Z,	K
		adiw	Z,	1
		dec 	innerCount
		brne	inner
		
		;sbiw	zl,	1
		dec 	outerCount
		brne	outer
		;st		Z, carry

	pop 	ZH
	pop 	ZL
	pop 	YH
	pop 	YL
	pop 	XH
	pop 	XL
	pop		zero
	pop		K
	pop 	J
	pop 	I
	pop 	outerCount
	pop 	innerCount
	pop 	carry

		ret						; End a function with RET

;-----------------------------------------------------------
; Func: MUL16
; Desc: An example function that multiplies two 16-bit numbers
;			A - Operand A is gathered from address $0101:$0100
;			B - Operand B is gathered from address $0103:$0102
;			Res - Result is stored in address 
;					$0107:$0106:$0105:$0104
;		You will need to make sure that Res is cleared before
;		calling this function.
;-----------------------------------------------------------
MUL16:
		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL				
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop				

		clr		zero			; Maintain zero semantics

		; Set Y to beginning address of B
		ldi		YL, low(addrB)	; Load low byte
		ldi		YH, high(addrB)	; Load high byte

		; Set Z to begginning address of resulting Product
		ldi		ZL, low(LAddrP)	; Load low byte
		ldi		ZH, high(LAddrP); Load high byte

		; Begin outer for loop
		ldi		oloop, 2		; Load counter
MUL16_OLOOP:
		; Set X to beginning address of A
		ldi		XL, low(addrA)	; Load low byte
		ldi		XH, high(addrA)	; Load high byte

		; Begin inner for loop
		ldi		iloop, 2		; Load counter
MUL16_ILOOP:
		ld		A, X+			; Get byte of A operand
		ld		B, Y			; Get byte of B operand
		mul		A,B				; Multiply A and B
		ld		A, Z+			; Get a result byte from memory
		ld		B, Z+			; Get the next result byte from memory
		add		rlo, A			; rlo <= rlo + A
		adc		rhi, B			; rhi <= rhi + B + carry
		ld		A, Z			; Get a third byte from the result
		adc		A, zero			; Add carry to A
		st		Z, A			; Store third byte to memory
		st		-Z, rhi			; Store second byte to memory
		st		-Z, rlo			; Store third byte to memory
		adiw	ZH:ZL, 1		; Z <= Z + 1			
		dec		iloop			; Decrement counter
		brne	MUL16_ILOOP		; Loop if iLoop != 0
		; End inner for loop

		sbiw	ZH:ZL, 1		; Z <= Z - 1
		adiw	YH:YL, 1		; Y <= Y + 1
		dec		oloop			; Decrement counter
		brne	MUL16_OLOOP		; Loop if oLoop != 0
		; End outer for loop
		 		
		pop		iloop			; Restore all registers in reverves order
		pop		oloop
		pop		ZL				
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A
		ret						; End a function with RET

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

; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
; There are no additional file includes for this program
