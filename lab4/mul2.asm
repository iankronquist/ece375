.include "m128def.inc"

.def carry0 = r14
.def carry1 = r15
.def innerCount = r16
.def outerCount = r17
.def I = r18
.def J = r19
.equ srcA = 0x100
.equ srcB = 0x104
.equ ptrA = 0x108
.equ ptrB = 0x109
.equ dest = 0x10a

mul24:
	push	carry0
	push	carry1
	push	innerCount
	push	outerCount
	push	I
	push	J
	push	XL
	push	XH
	push	YL
	push	YH
	push	ZL
	push	ZH
	clr 	carry1
	clr 	carry0
	ldi 	outerCount, 3
	clc

	ldi 	YL,	low(srcB)
	ldi 	YH,	high(srcB)
	ldi 	ZL,	low(dest)
	ldi 	ZH,	high(dest)

	outer:
		ldi 	XL,	low(srcA)
		ldi 	XH,	high(srcA)
		ld  	I, X+
		ldi 	innerCount, 3


	inner:
		ld  	K, 	Z
		ld  	J, 	Y+
		mul 	I, 	J
		add 	r0,	K
		adc 	r1,	zero
		st  	Z+,	r0
		st  	Z, 	r1

		dec 	innerCount
		brne	inner
		
		dec 	outerCount
		brne	outer


	pop 	ZH
	pop 	ZL
	pop 	YH
	pop 	YL
	pop 	XH
	pop 	XL
	pop 	J
	pop 	I
	pop 	outerCount
	pop 	innerCount
	pop 	carry1
	pop 	carry0
