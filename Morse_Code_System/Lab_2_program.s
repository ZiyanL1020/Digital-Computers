
		THUMB 		
                AREA 		My_code, CODE, READONLY 	; 
                EXPORT 		__MAIN 	
		ENTRY 
__MAIN

; Turn off all LEDs 
		MOV 		R2, #0xC000
		MOV 		R3, #0xB0000000	
		MOV 		R4, #0x0
		MOVT 		R4, #0x2009
		ADD 		R4, R4, R2 		; 0x2009C000 - the base address for dealing with the ports
		STR 		R3, [r4, #0x20]		; Turn off the three LEDs on port 1
		MOV 		R3, #0x0000007C
		STR 		R3, [R4, #0x40] 	; Turn off five LEDs on port 2 

ResetLUT
		LDR         R5, =InputLUT            ; assign R5 to the address at label LUT


;MAIN DONE
NextChar
        	LDRB        R0, [R5]		; Read a character to convert to Morse
        	ADD         R5, #1              ; point to next value for number of delays, jump by 1 byte
		TEQ         R0, #0              ; If we hit 0 (null at end of the string) then reset to the start of lookup table
		BNE		ProcessChar	; If we have a character process it

		MOV		R0, #4		; delay 4 extra spaces (7 total) between words
		BL		DELAY
		BEQ         ResetLUT

ProcessChar
		BL CHAR2MORSE	; convert ASCII to Morse pattern in R1		
		B FIND_ONE
FIND_ONE
		MOV R6, #0x0000	 
		MOVT R6, #0x8000
		LSL	R1, R1, #1	
		ANDS R7, R1, R6	
		BEQ	FIND_ONE
		BNE	CHECK_LIGHT

CHECK_LIGHT
		TEQ R1, #0
		BEQ ENDCHAR

		MOV R6, #0x0000
		MOVT R6, #0x8000
		ANDS R7, R6, R1
		LSL R1, R1, #1
		BEQ BLANK
		BNE LIGHT

BLANK
		MOV R0, #1
		BL LED_OFF
		BL DELAY
		B CHECK_LIGHT
		
LIGHT 
		MOV R0, #1
		BL LED_ON
		BL DELAY
		B CHECK_LIGHT

ENDCHAR
		MOV R0, #3
		BL LED_OFF
		BL DELAY
		B NextChar
		

;DONE
Again		MOV	R3, #0x200
loopBuzz	MOV	R2, #0x200		; aprox 1kHz since looping 0x10000 times is ~ 10Hz
loopMore	SUBS	R2, #1			; decreament inner loop to make a sound;
		BNE	loopMore
		EOR	R5, #0x4000000		; toggle speaker output
		STR	R5, [R4]		; write to speaker output
		SUBS	R3, #1
		B	Again



;DONE 
CHAR2MORSE	STMFD		R13!,{R0,R14}	; push Link Register (return address) on stack
		SUB R0, #0x41
		ADD R0,R0
		LDR R9, =MorseLUT
		LDRH R1, [R0,R9]
		LDMFD		R13!,{R0,R15}	; restore LR to R15 the Program Counter to return

;DONE

LED_ON 	   	STMFD		R13!,{R3, R14}		; preserve R3 and R4 on the R13 stack
		MOV R3, #0x0000
		MOVT R3, #0xA000
		STR R3, [R4,#0x20]
		LDMFD		R13!,{R3, R15}

;DONE
LED_OFF	   	STMFD		R13!,{R3, R14}	; push R3 and Link Register (return address) on stack
		MOV R3, #0x0000
		MOVT R3, #0xB000
		STR R3, [R4,#0x20]
		LDMFD		R13!,{R3, R15}	; restore R3 and LR to R15 the Program Counter to return


;DONE
DELAY			STMFD		R13!,{R2, R14}
MultipleDelay	
LOOP2
					
			MOV R2, #0xFFFF
			MOVT R2, #0x000A
			
LOOP3						
			SUBS R2,#1
			BNE LOOP3
			
			SUB R0,#1
			TEQ	R0, #0	
			BNE LOOP2
			BEQ exitDelay
	
exitDelay		LDMFD		R13!,{R2, R15}


		ALIGN				


InputLUT	DCB		"ZLYZG", 0	

		ALIGN				
MorseLUT 
		DCW 	0x17, 0x1D5, 0x75D, 0x75 	; A, B, C, D
		DCW 	0x1, 0x15D, 0x1DD, 0x55 	; E, F, G, H
		DCW 	0x5, 0x1777, 0x1D7, 0x175 	; I, J, K, L
		DCW 	0x77, 0x1D, 0x777, 0x5DD 	; M, N, O, P
		DCW 	0x1DD7, 0x5D, 0x15, 0x7 	; Q, R, S, T
		DCW 	0x57, 0x157, 0x177, 0x757 	; U, V, W, X
		DCW 	0x1D77, 0x775 			; Y, Z

; One can also define an address using the EQUate directive
;
LED_PORT_ADR	EQU	0x2009c000	; Base address of the memory that controls I/O like LEDs

		END 
