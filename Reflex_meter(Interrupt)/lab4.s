;*-------------------------------------------------------------------
;* Name:    	lab_4_program.s 
;* Purpose: 	A sample style for lab-4
;* Term:		Winter 2014
;*-------------------------------------------------------------------
				THUMB 								; Declare THUMB instruction set 
				AREA 	My_code, CODE, READONLY 	; 
				EXPORT 		__MAIN 					; Label __MAIN is used externally 
				EXPORT 		EINT3_IRQHandler 	; without this the interupt routine will not be found

				ENTRY 

__MAIN
				MOV R2,#0x200000
				LDR R10,=ISER0
				STR R2,[R10]						;enable the interupt
				MOV R2, #0X400
				LDR R10, =IO2IntEnf	
				STR R2,[R10]						;enable the button
				
				
				LDR			R10, =LED_BASE_ADR		; R10 is a  pointer to the base address for the LEDs
				MOV 		R3, #0xB0000000		; Turn off three LEDs on port 1  
				STR 		R3, [r10, #0x20]
				MOV 		R3, #0x0000007C
				STR 		R3, [R10, #0x40] 	; Turn off five LEDs on port 2 

				MOV R0,#0
				MOV R6,#0
				MOV R7,#0
				MOV R4,#1				;set the initial for the flag - not pressed
				MOV R1,#0
				MOV R3,#0
				MOV R8,#0
				MOV R2,#0
				MOV R12,#0				;initial all values
				
				MOV	R11, #0xABCD		; Init the random number generator with a non-zero number
				

				
				
GET_NUMBER 		BL 	RANDOM_NUMBER
				MOV R4,#1						;set R4 back to initial condition (not pressed)
				MOV R6,#0
				BFI R6,R11,#0,#6				;get 6 digit random number
				MOV R8,#3						;make this ramdom number's range as 0-200
				MUL R6,R6,R8
				ADD R6,#50						;make the range as 50-250
				
				
ASSIGN_DISPLAY	TEQ R4,#0
				BEQ GET_NUMBER					;check the interupt, if pressed go and get new random number
				
				MOV R7,R6						;use R7 for display
				BL DISPLAY_NUM					;call display_numm
				MOV R0,#10
				BL DELAY						;hold for 1s
				SUBS R6, #10					
				BGT ASSIGN_DISPLAY				;if the number in R6 is greater than 0, loop in assign_display
				MOV R7,#0
				MOV R6,#0
				MOV R0,#0						;set all used registers back to initial condition
				B FLASH_LIGHT					;else go to flash_light
				
FLASH_LIGHT		TEQ R4,#0
				BEQ GET_NUMBER					;check the interupt, if pressed go and get new random number
				
				MOV R0,#1
				BL LIGHT_ON	
				BL DELAY_10HZ					;light on at for 0.05s
				BL LIGHT_OFF
				BL DELAY_10HZ
				B FLASH_LIGHT					;light off for 0.05 s
				
				;in totle 10 HZ frequency
				
				

				
				
		;
		; Your main program can appear here 
		;
				
				
				
;*------------------------------------------------------------------- 
; Subroutine RNG ... Generates a pseudo-Random Number in R11 
;*------------------------------------------------------------------- 
; R11 holds a random number as per the Linear feedback shift register (Fibonacci) on WikiPedia
; R11 MUST be initialized to a non-zero 16-bit value at the start of the program
; R11 can be read anywhere in the code but must only be written to by this subroutine
RANDOM_NUMBER 	STMFD		R13!,{R1-R3, R14} 	; Random Number Generator 
				AND			R1, R11, #0x8000
				AND			R2, R11, #0x2000
				LSL			R2, #2
				EOR			R3, R1, R2
				AND			R1, R11, #0x1000
				LSL			R1, #3
				EOR			R3, R3, R1
				AND			R1, R11, #0x0400
				LSL			R1, #5
				EOR			R3, R3, R1			; The new bit to go into the LSB is present
				LSR			R3, #15
				LSL			R11, #1
				ORR			R11, R11, R3
				LDMFD		R13!,{R1-R3, R15}
				
DISPLAY_NUM		STMFD		R13!,{R7, R2, R14}
				MOV R12, #0x0
				BFI R12, R7, #0, #5				;get the right most 5 bit from R7 to R12
				LSR R7, #5						;shift right 5 bits
				RBIT R12, R12					;orbit bits in R12
				EOR R12, #0xFFFFFFFF			;flip all bits in R12
				LSR R12, #27					;shift left to remove all the 1s on the right
				LSL R12, #2						;shift 2 bit left to place the light control bit to the correct spot
				STR R12, [R10,#0x40]			;turn on the lights on port 2
								
				MOV R12, #0x0					;reset R12 
				BFI R12, R7, #0, #1				;get the right most bit into R12
				LSR R7, #1						;shift R7 left 1 bit
				LSL R12, #1
				ADD R12, #0x1
				LSL R12, #2
				RBIT R7, R7
				LSR R7, #30
				ADD R12, R12, R7
				EOR R12, #0xFFFFFFFF			;make the bit in R5 (eg, ABC) into the form (-C 0 -B -A) in R12
				LSL R12, #28					;place the control bit on the right spot
				STR R12, [R10,#0x20]			;turn on lights on port 1
				
				MOV R7,#0

				LDMFD		R13!,{R7, R2, R15}
				
DELAY			STMFD		R13!,{R2,R0, R14}
MultipleDelay	
LOOP2					
			MOV R2, #0xF018						;set a 0.1ms inside deplay counter
			MOVT R2, #0x0001
LOOP3						
			SUBS R2,#1
			BNE LOOP3							;delay for 0.1s
			
			SUB R0,#0x1
			TEQ	R0, #0x0	
			BNE LOOP2							;if the outside deplay counter is not zero, run another o.1s delay
			BEQ exitDelay						;if zero, finish delay
	
exitDelay		LDMFD		R13!,{R2,R0, R15}



DELAY_10HZ			STMFD		R13!,{R2,R0, R14}
MultipleDelay_10HZ	
LOOP2_10HZ					
			MOV R2, #0xF80C						;set a 0.1ms inside deplay counter
LOOP3_10HZ						
			SUBS R2,#1
			BNE LOOP3_10HZ							;delay for 0.05s
			
			SUB R0,#0x1
			TEQ	R0, #0x0	
			BNE LOOP2_10HZ							;if the outside deplay counter is not zero, run another o.05s delay
			BEQ exitDelay_10HZ						;if zero, finish delay
	
exitDelay_10HZ		LDMFD		R13!,{R2,R0, R15}




LIGHT_ON 	   	STMFD		R13!,{R3, R14}		; preserve R3 and R4 on the R13 stack
				MOV R3, #0x0000
				STR R3, [R10,#0x20]
				MOV R3, #0x0000
				STR R3, [R10, #0x40]
				LDMFD		R13!,{R3, R15}
				
LIGHT_OFF	   	STMFD		R13!,{R3, R14}	; push R3 and Link Register (return address) on stack
				MOV R3, #0x0000
				MOVT R3, #0xB000
				STR R3, [R10,#0x20]
				MOV R3, #0x007C
				STR R3, [R10, #0x40]
				LDMFD		R13!,{R3, R15}	; restore R3 and LR to R15 the Program Counter to return

				
				

EINT3_IRQHandler 	
				STMFD		R13!,{R2, R10, R14}				; Use this command if you need it  
				MOV R4,#0
				LDR R10,=IO2INTCLR	
				MOV R2,#0x400					;set the 11th pin from the left as 1			
				STR R2,[R10]					;clear the interupt

				LDMFD		R13!,{R2, R10, R15}				; Use this command if you used STMFD (otherwise use BX LR) 





LED_BASE_ADR	EQU 	0x2009c000 		; Base address of the memory that controls the LEDs 
PINSEL3			EQU 	0x4002C00C 		; Pin Select Register 3 for P1[31:16]
PINSEL4			EQU 	0x4002C010 		; Pin Select Register 4 for P2[15:0]
FIO1DIR			EQU		0x2009C020 		; Fast Input Output Direction Register for Port 1 
FIO2DIR			EQU		0x2009C040 		; Fast Input Output Direction Register for Port 2 
FIO1SET			EQU		0x2009C038 		; Fast Input Output Set Register for Port 1 
FIO2SET			EQU		0x2009C058 		; Fast Input Output Set Register for Port 2 
FIO1CLR			EQU		0x2009C03C 		; Fast Input Output Clear Register for Port 1 
FIO2CLR			EQU		0x2009C05C 		; Fast Input Output Clear Register for Port 2 
IO2IntEnf		EQU		0x400280B4		; GPIO Interrupt Enable for port 2 Falling Edge 
ISER0			EQU		0xE000E100		; Interrupt Set-Enable Register 0 
IO2INTCLR		EQU		0x400280AC		; Interrupt Port 2 Clear Register

				ALIGN 

				END 
