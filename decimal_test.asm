INCLUDE  'decimal_input.asm'
include  'decimal_output.asm'

org 100h

jmp start
    
 
;;;; Data section -----------    
	row_dt				db		0         		; current row
	col_dt				db		0               ; current col
	
	attrib			db		0111_0000b  	; color attribute
	
    msg1			db		"Enter a Number (-32767 to +32767):"
    msg1_end:
    



;;;; Code section -----------
start:
    
    LEA		bp, msg1
    MOV		CX, msg1_end - offset msg1
    call    print_string
    
    MOV     BL,  0AH        ; load color profile   
	call 	Decinput        ; decinput return decimal in BX
	
	; go to a new line
	PUSH    AX
	MOV     AL,  02H
	INC     DH
	MOV     DL, 0
	INT     10H
	POP     AX
	mov     ax ,    bx
	call    decoutput
    jmp		$
    
    
print_string: 

     ; this procedure prints a string in the data segment and move cursor after it
     ; Input: BP = address of the string, CX = total size of the string
     
     PUSH   ax
     push   bx
     
     mov	ah,		13h		; string print function
     mov 	al,		1		; update cursor
     mov 	bh,		0		; page 0
     mov 	bl,		attrib	; color
     mov	dh,		row_dt	; current row
     mov	dl,		col_dt		;
     int 	10h
     
     ; get cursor position
     mov    bh, 0
     mov    ah, 03h
     int    10h
     
     POP    bx
     pop    ax
     
ret
    
DEFINE_DEC_INPUT
DEFINE_DEC_OUTPUT




END
     
