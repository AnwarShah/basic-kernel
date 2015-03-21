; Filename: DecimalOutput.asm
; Description: This procedure takes a number in AX and display its 
; decimal equivalent

;---------- Algorithm ----------
; If the number is negative, 
	; print a (-) sign
	; negate the number
; Convert the number in AX in decimal in stack
	;do
		; Divide AX by 10, save remainder in Stack
		; count the remainder
	; until AX != 0
; Pop the decimal numbers in stack
; convert them to ascii
; display the converted digit
;----------- Algorithm -----------

DEFINE_DEC_OUTPUT	MACRO

JMP		DECOUTPUT

;------------ Data section ----------

DO_Color		db			?
DO_col			db			?			; current col position
DO_row			db			?			; current row position

;----------- Program begins --------

 
DECOUTPUT	PROC
	;This procedure take a number in AX and display it's decimal in next line
	; Input:    AX = number,    DX = row, col   ,BX = page/color
	; Output:   None
	; Uses  :   AX, BX, CX, DX
	; Destroys:  Nothing, at the end all are same as before except cursor position
	
	;save BX and DX and CX and Color
		PUSH	DX
		PUSH	BX
		PUSH	CX
	; also save the original number
		PUSH	AX					
	; save row and column position
		MOV		DO_row	, DH
		MOV		DO_col	, DL
	; save the system color profile
		MOV		DO_Color,	BL		
		
		
	; clear CX for use as counter
		XOR		CX, CX
			 
	; Check if AX is negative
		OR		AX,	AX
	; if not negative , jump to conversion
		JNS		DO_Convert			
	
	; else , print a negative (-) sign
		; first save the number
    		push    ax
    		MOV  AH, 0EH
    		MOV	 AL, '-'
    		INT 	10H
    	
    		POP		AX
    		
    	; two's complement it, to get the positive
		    NEG		AX					  


; Convert the number in AX to decimal and put in stack
DO_Convert:
	
		; Divide AX by 10, save remainder in AH in stack
		; clear high word for dividend
		XOR		DX, DX				
		; save the color profile before using Bx as divisor
		PUSH    BX
		; load divisor
		MOV		BX ,10				
		; DX = remainder, AX = qoutient
		DIV		BX                  
		; restore the color profile after using it as divisor
		POP     BX                  
		; save the remainder
		PUSH	DX
		; increase digit counter
		INC		CX					
		; if AX = 0 , stop conversion
		CMP		AX,	0
		; and go to display it				
		JE		DO_Display
		; else repeat until AX = 0
		JMP		DO_Convert
		     
DO_Display:
        
        ; go to new line to print it
        ; restore the row and col
        MOV     DH, DO_row
        MOV     DL, DO_col
        ; go at new line lef
        INC     DH
        MOV     DL, 0
        ; move cursor function
        MOV     AH, 2
        int     10h
        
DO_Display_loop:
		; Display the digits in stack
		POP		AX
		; convert to ascii
		OR		AL,	30H			  	
		; display it with attribute
		
    	
    	; attributed character display function
    	MOV		AH,	09H
    	; AL has the character
    	; BH is current page
    	MOV		BL, DO_Color
    	; we will use cx, which holding the digit count, so save it
    	push    cx			
    	; only one times
    	MOV		CX,	1					
        ; call interrupt   
        INT 10H
        ; restore cx and decrease it 1
        pop     cx
             
        INC		DL
        ; cursor move function
        MOV		AH,	2					
        INT 	10H
        
        ; loop until all digit is displayed
        LOOP	DO_Display_loop			
        
DO_EXIT:
		
		POP		AX
		POP		CX
		POP		BX
		POP		DX
		
		RET

DECOUTPUT ENDP

DEFINE_DEC_OUTPUT	ENDM