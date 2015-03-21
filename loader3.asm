#make_boot#
org 7c00h  ; loaded at 0000:7c00h

jmp start

; Data section
;----------------------------------
loading db "Loading the kernel ........................................................................................"                       
loading_end:
ld_completed   db  0dh, 0ah, 0dh, 0ah, "Loading Completed. Press any key to jump to the kernel"
ld_completed_e:                        
 
 
macro loading_cmpl_msg

	MOV	AH,	13H		; string function
	MOV	al,	1		; update cursor
	inc dh
	inc dh
	mov	dl, 0
	mov	bp,	offset ld_completed
	mov cx,	ld_completed_e - offset ld_completed
	
	mov	bh,	0
	mov	bl,	0000_1011b
	int 10h
	
	
	
endm
 
 
 
; Code section
;-----------------------------------
start:

; set data segment and extra segment
xor ax,ax
push cs
push cs
pop ds
pop es

; initialize the stack
mov     ax, 07c0h
mov     ss, ax
mov     sp, 03feh ; top of the stack.

; set display mode
mov ah, 0h
mov al, 03h
int 10h

; set cursor mode
mov ah, 1h
mov ch, 6       ; starting line
mov cl, 7       ; ending line
int 10h     

; print loading message
call loading_msg
loading_cmpl_msg

; wait for keystroke
mov ah,     0h
int 16h     

; load the kernel at 0800h:0000
mov     ah,     02h     ; read sector function
mov     al,     10   ;load 10 sector
mov     ch,     0    ; cylinder 0
mov     cl,     2    ; start at sector 2
mov     dh,     0    ; head
mov     dl,     0    ; dl not changed
; es:bs points to data buffer
mov     bx,     0800h
mov     es,     bx
mov     bx,     0

; read sector                        
int 13h

; pass control to the kernel
jmp 0800h:0000h   ; go to the kernel


; Procedure section
;-----------------------------------------
loading_msg proc

; print loading message
push    cx
push    si
push    ax

mov cx, loading_end - offset loading ; string size

mov si , 0  ; index

mov ah, 0eh  ; output function

next:
mov al, loading[si]   ; attributed string
int 10h
inc si

;;; wait.........
PUSH    CX
PUSH    DX
PUSH    AX

MOV        AH, 86H
MOV        CX, 0000H
MOV        DX,    0ffe8H
INT        15H

POP        AX
POP        DX
POP        CX
;;; wait

loop next

pop ax
pop si
pop cx

ret
    
endp ; procedure end




db  510-($-7c00H) dup(0)
DW	0AA55H			; boot signature