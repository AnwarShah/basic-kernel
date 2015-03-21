Macro Read_char attrib_decinput
LOCAL   end_of_line, end_m
    
    ; read a char from current cursor position, echo and advance the cursor
    ; input : none
    ; output: AL will contain the ascii code of char, AH is 00, DX will reflect row,col
    ;         position        
    ; uses  : BX, CX, AX
    
    ; save necessary registers
        push    bx
        push    cx
        
    ;read 
        mov  ah, 00h
        int  16H     ; AL got the char
    ;echo    
        mov  ah, 09h ; attributed
        mov  bh,  0  ; 
        mov  bl,  attrib_decinput
        mov  cx,   1 ; number of times to write
        int  10h
    ; advance the cursor
        mov  ah, 02H 
        cmp  dl, 79  ; end of line
        je   end_of_line
        inc  dl
        int  10H      
        jmp  end_m
    end_of_line:
        inc  dh      ; go to next line
        mov  dl, 0
        int  10H
    end_m:
        pop  cx
        pop  bx
        mov  ah, 00h            
endm         
        
MACRO   go_to_next_line
        
        ; save register    
            push    ax
        ; cursor move function
            mov     ah, 02h
        ; increase line
            inc     dh
            mov     dl, 0
        ; move
            int 10h
        ; restore register
            pop  ax                                                                      
endm                   


Decinput proc
jmp start_decinput
    
    attrib_decinput  db  ?           ; attrib hold the color attribute
    overflow_msg    db      "Overflow, Please enter a number in range (-32767 to +32767)"
    overflow_msg_end:
    invalidmsg_decinput db  "Invalid decimal digit, You can enter only 0-9"
    invalidmsg_decinput_end:
    
    ; input : color and page in Bx, row and col in DX
    ; output: a binary equivalent of decimal input in BX, all other used registers
    ;         unchanged
    ; uses  : bx, ax, cx
    
start_decinput:
        push cx
        push ax
        
        ;mov  bl,     70
        mov  attrib_decinput,  bl        ; save system profile
        xor  bx,    bx          ; bx hold the running total
        xor  cx,    cx          ; cx used as flag for negative number
        
    read_char attrib_decinput
    ; check for a '+' or '-' sign
        cmp  al,  '+'
        je   plus
        cmp  al,  '-'
        je   minus
    ; neither '+' nor '-' sign
        jmp repeat_decinput
            
    minus:
        mov     cx, 1
        read_char   attrib_decinput      ; first digit is symbol, read first digit
    plus:
        read_char   attrib_decinput      ; first digit is symbol, read first digit
    
    repeat_decinput:
    ; check if it is a valid decimal digit
        cmp  al,  '9'
        jg   invalid_decinput   ; invalid
        cmp  al,  '0'
        jl   invalid_decinput   ; invalid
    ;  valid number,
    ; convert to binary     
        and     ax, 000fh       
    ; save last entered digit
        push    ax              
    ; save row, col    
        push    dx
    ; clear dx, for multiplication                  
        xor     dx, dx
    ; load previous total in ax
        mov     ax, bx
    ; load bx with mutiplicand 10
        mov     bx, 10           
    ; multiply 
        imul    bx
    ; if overflow, product > AX, !!!!! here dx is changed !!!!                  
        Jo      mul_overflow_decinput   
    ; else
    ;restore row, col
        pop     dx
    ; bx got the product = total x 10                  
        mov     bx, ax          
    ; restore last digit
        pop     ax              
    ; bx got total = product + last digit
        add     bx, ax          
    ; if overflow, i.e greater than 16 bits
        Jo      add_overflow_decinput   
    ; else
    ; read another digit, since at least 1 digit is entered, this one can be CR
        ; clear the last digit
        xor     ax, ax
        read_char attrib_decinput
    ; check if it is <CR>
        cmp  al, 0DH
        JE   end_decinput
    ; else, jump to another loop
        jmp repeat_decinput
        
                    
    mul_overflow_decinput:
        ; NOTE!! when multiplicaton overflow, dx was pushed but not poped,
        ; restore current row, col
            pop dx
        ; pop last digit
            pop ax
    add_overflow_decinput:
        ; NOTE !! when addition overflow, both dx and ax was poped
        ; clear it
            xor ax,ax
        ; clear total 
            xor bx, bx
        ; go to the next line
            go_to_next_line
        ; print overflow message
        
            ;-------------atomic block---------------
            ; save the used registers
                push    ax
                push    bx
                push    cx
                push    bp
            ; ES:BP contain the address of the string
                push    cs
                pop     es
                ; bp has the offset
                    mov     bp, offset overflow_msg
                ; cx has the size of the string
                    mov     cx, overflow_msg_end - offset overflow_msg
                ; function select 
                    mov     ah,    13h
                ; dh, and dl has row and col
                ; bh has the page
                    mov     bh,     0
                ; got the attrib in bl
                    mov     bl,     attrib_decinput
                ; go!!!!!!!!!!!!!!!
                    int 10h
            ; restore all the registers
                pop     bp
                pop     cx
                pop     bx
                pop     ax
            ;-------------atomic block-----------------
            
        ; go to next line
            go_to_next_line
        ; read again
            read_char   attrib_decinput
        ; loop again for complete input
            jmp repeat_decinput
                
    invalid_decinput:
            ; invalid input, so clear ax and bx
            ; clear last digit
            xor     ax, ax
            ; clear total
            xor     bx, bx
            ; go to new line
                go_to_next_line
            ; print invalid message
            
                ;----------- atomic block------------
                ; save the used registers
                    push    ax
                    push    bx
                    push    cx
                    push    bp
                ; ES:BP contain the address of the string
                    push    cs
                    pop     es
                ; bp has the offset
                    mov     bp, offset invalidmsg_decinput
                ; cx has the size of the string
                    mov     cx, invalidmsg_decinput_end - offset invalidmsg_decinput
                ; function select 
                    mov     ah,    13h
                ; dh, and dl has row and col
                ; bh has the page
                    mov     bh,     0
                ; got the attrib in bl
                    mov     bl,     attrib_decinput
                ; go!!!!!!!!!!!!!!!
                    int 10h
                ; restore all the registers
                pop     bp
                pop     cx
                pop     bx
                pop     ax
                ;--------- atomic block ----------
            
            ; go to another new line
                go_to_next_line
            ; read digit from first
                read_char   attrib_decinput
            ; loop to complete reading
                jmp repeat_decinput    
                        
    end_decinput:
        pop     ax
        pop     cx
                
        ret

endp            