THUMB		; Declare THUMB instruction set 
	AREA		My_code, CODE, READONLY 	; 
	EXPORT		__MAIN 		; Label __MAIN is used externally q
	ENTRY 
__MAIN

	MOV 		R2, #0xC000		; move 0xC000 into R2
	MOV 		R4, #0x0		; init R4 register to 0 to build address
	MOVT 		R4, #0x2009		; assign 0x20090000 into R4
	ADD 		R4, R4, R2 		; add 0xC000 to R4 to get 0x2009C000 

	MOV 		R3, #0x0000007C	; move initial value for port P2 into R3 
	STR 		R3, [R4, #0x40] 	; Turn off five LEDs on port 2 
	
	MOV 		R3, #0xB0000000	; move initial value for port P1 into R3
	STR 		R3, [R4, #0x20]	; Turn off three LEDs on Port 1 using an offset
	
	MOV 		R2, #0x20		; put Port 1 offset into R2 for user later
loop1
	MOV 		R0, #0xFFFF 	; Initialize R0 lower word for countdown
	MOVT		R0, #0x000A		; Initialize R0 higher word for countdown
	
loop2
	SUBS 		R0, #1 			; Decrement r0 and set the N,Z,C status bits
	BNE loop2					; when R0 count down to 0, exit loop2
	EOR 		R3,#0x10000000		; flip the bit of R3 between 0xB0000000 and 0xA0000000
	STR 		R3, [R4, R2] 		; write R3 to port 1 to change the status for LED
	B loop1							; countinue infinite loop1
	

 	END 

