; ECE-222 Lab ... Winter 2013 term 
; Lab 3 sample code 
				THUMB 		; Thumb instruction set 
                AREA 		My_code, CODE, READONLY
                EXPORT 		__MAIN
				ENTRY  
__MAIN

; The following lines are similar to Lab-1 but use a defined address to make it easier.
; They just turn off all LEDs 
				LDR			R10, =LED_BASE_ADR		; R10 is a permenant pointer to the base address for the LEDs, offset of 0x20 and 0x40 for the ports
				MOV 		R3, #0xB0000000		; Turn off three LEDs on port 1  
				STR 		R3, [R10, #0x20]
				MOV 		R3, #0x0000007C
				STR 		R3, [R10, #0x40] 	; Turn off five LEDs on port 2 

				MOV			R11, #0xABCD		; Init the random number generator with a non-zero number
				MOV R0, #0
				MOV R1, #0
				MOV R6, #0						;set the initial values to 0
				
;SIMPLECOUNTER	MOV R1,#0x0
;COUNTER			BL DISPLAY_NUM
;				MOV R0, #1000
;				BL DELAY
;				ADD R1, #1
;				CMP R1, #0xFF
;				BNE COUNTER
;				BEQ SIMPLECOUNTER			
				
LOOP 			BL 	RandomNum
				BFI R0, R11, #0, #8				;get the last 8 bit of R11 to R0
				MOV R7, #0x138
				MUL R0,R0, R7					;make the random number into a range of 0 to 80000
				MOV R8,#20000 
				ADD R0, R8						;make the range into 20000 to 100000
				BL DELAY						;call delay
				BL LIGHT_ON						;after delay, turn on light 
				MOV R4,#0						;initial the value of R4 to 0
				B POLLING						;start polling



POLLING 		ADD R4, R4, #1					;polling counter plus 1
				MOV R0,#0x1						
				BL DELAY						;call delay function for 0.1 ms
				MOV R8, #0xc054
				MOVT R8,#0x2009
				LDR R8, [R8]			;get the value of address FIO2DIR
				AND R6, R8, #0x400				;get the 11th bit into R6
				CMP R6,#0x0
				BNE POLLING						;if button not pressed, back to polling
				BL LIGHT_OFF					;if button pressed, turn off the light 
				
				
				
DISPLAYLOOP		MOV R5,R4						;get the counted reaction time into R5
				MOV R7,#0x4						;initial R7 as 4

TIMESTEP		MOV		R1, #0
				BFI R1,R5, #0, #8				;get the right most 8 bits from R5 into R1
				LSR R5, #8						;shift R5 to the right for 8 bits to get ready for the next 8 bit
				BL DISPLAY_NUM					;go to display_num
				MOV R0, #20000
				BL DELAY						;hold the display for 2s
				SUBS R7,#0x1					;counter minus 1
				BNE TIMESTEP					;if counter not equal to 0, go back for the next 8 bits
				BL LIGHT_OFF					;of counter goes to 0, turn light off
				MOV R0, #50000					
				BL DELAY						;hold light off for 5s
				B DISPLAYLOOP					;display the number again

				
				
DISPLAY_NUM		STMFD		R13!,{R1, R2, R14}
				MOV R12, #0x0
				BFI R12, R1, #0, #5				;get the right most 5 bit from R1 to R12
				LSR R1, #5						;shift right 5 bits
				RBIT R12, R12					;orbit bits in R12
				EOR R12, #0xFFFFFFFF			;flip all bits in R12
				LSR R12, #27					;shift left to remove all the 1s on the right
				LSL R12, #2						;shift 2 bit left to place the light control bit to the correct spot
				STR R12, [R10,#0x40]			;turn on the lights on port 2
								
				MOV R12, #0x0					;reset R12 
				BFI R12, R1, #0, #1				;get the right most bit into R12
				LSR R1, #1						;shift R1 left 1 bit
				LSL R12, #1
				ADD R12, #0x1
				LSL R12, #2
				RBIT R1, R1
				LSR R1, #30
				ADD R12, R12, R1
				EOR R12, #0xFFFFFFFF			;make the bit in R5 (eg, ABC) into the form (-C 0 -B -A) in R12
				LSL R12, #28					;place the control bit on the right spot
				STR R12, [R10,#0x20]			;turn on lights on port 1

				LDMFD		R13!,{R1, R2, R15}

;
; R11 holds a 16-bit random number via a pseudo-random sequence as per the Linear feedback shift register (Fibonacci) on WikiPedia
; R11 holds a non-zero 16-bit number.  If a zero is fed in the pseudo-random sequence will stay stuck at 0
; Take as many bits of R11 as you need.  If you take the lowest 4 bits then you get a number between 1 and 15.
;   If you take bits 5..1 you'll get a number between 0 and 15 (assuming you right shift by 1 bit).
; R11 MUST be initialized to a non-zero 16-bit value at the start of the program OR ELSE!
; R11 can be read anywhere in the code but must only be written to by this subroutine
RandomNum		STMFD		R13!,{R1, R2, R3, R14}

				AND			R1, R11, #0x8000
				AND			R2, R11, #0x2000
				LSL			R2, #2
				EOR			R3, R1, R2
				AND			R1, R11, #0x1000
				LSL			R1, #3
				EOR			R3, R3, R1
				AND			R1, R11, #0x0400
				LSL			R1, #5
				EOR			R3, R3, R1		; the new bit to go into the LSB is present
				LSR			R3, #15
				LSL			R11, #1
				ORR			R11, R11, R3
				
				LDMFD		R13!,{R1, R2, R3, R15}


LIGHT_ON 	   	STMFD		R13!,{R3, R14}		; preserve R3 and R4 on the R13 stack
				MOV R3, #0x0000
				MOVT R3, #0xA000
				STR R3, [R10,#0x20]
				LDMFD		R13!,{R3, R15}
LIGHT_OFF	   	STMFD		R13!,{R3, R14}	; push R3 and Link Register (return address) on stack
				MOV R3, #0x0000
				MOVT R3, #0xB000
				STR R3, [R10,#0x20]
				MOV R3, #0x007C
				STR R3, [R10, #0x40]
				LDMFD		R13!,{R3, R15}	; restore R3 and LR to R15 the Program Counter to return

DELAY			STMFD		R13!,{R2,R0, R14}
MultipleDelay	
LOOP2					
			MOV R2, #0x7F						;set a 0.1ms inside deplay counter
LOOP3						
			SUBS R2,#1
			BNE LOOP3							;delay for 0.1ms
			
			SUB R0,#0x1
			TEQ	R0, #0x0	
			BNE LOOP2							;if the outside deplay counter is not zero, run another o.1ms delay
			BEQ exitDelay						;if zero, finish delay
	
exitDelay		LDMFD		R13!,{R2,R0, R15}


				

LED_BASE_ADR	EQU 	0x2009c000 		; Base address of the memory that controls the LEDs 
PINSEL3			EQU 	0x4002c00c 		; Address of Pi n Select Register 3 for P1[31:16]
PINSEL4			EQU 	0x4002c010 		; Address of Pin Select Register 4 for P2[15:0]
;	Usefull GPIO Registers
;	FIODIR  - register to set individual pins as input or output
;	FIOPIN  - register to read and write pins
;	FIOSET  - register to set I/O pins to 1 by writing a 1
;	FIOCLR  - register to clr I/O pins to 0 by writing a 1

				ALIGN 

				END 

