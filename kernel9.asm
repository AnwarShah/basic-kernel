    ; This kernel is assumed to be loaded at memory location 0800:0000
    ;
    
    org 0000h       ; loaded at 0800:0000 by loader
    
    jmp start           ; first instruction must be jmp
    
    ;--------------------------------------------------------------------
    ;--------------------------------------------------------------------
    attrib db  0110_1111b      ;cyan background, bright white foreground
    
    ;--------------------------------------------
    black  equ  0000b      ; black
    green   equ 0010b       ; green
    red     equ 0100b       ; red
    white   equ 1111b       ; white
    ;--------------------------------------------
    
    ;--------------------------------------------
    black_white     equ     0000_1111b       ; white text on black background
    blue_yellow      equ    0001_1110b       ; yellow   text on blue  background
    gray_black      equ     0111_0000b       ; black text   on light gray background
    default         equ     0110_1111b       ; cyan background, bright white text
    ;---------------------------------------------
                
    option   		db  0                  ; used for get input
    temp    		dw  0            
    temp1   		db  0                   ; a temporary variable 
    
    msg         	db          "Welcome to The Mini OS Kernel"
    msg_end:
    
    invalid_msg     db      0dh,0ah,"Invalid option, Press Correct Letter"
    invalid_msg_end:
    
    prompt      			db  0dh,0ah,"What do you want to do ?"
               				db  0dh,0ah,"(R)Reverse Print - Input your string and get its reverse"
                			db  0dh,0ah,"(C)Colorized print - Print your string with your favorite color"
                			db  0dh, 0ah, "(A)Change Color Attribute - Change the background and font color"
                			db  0dh,0ah,"(S)Screen clear - Clear the entire screen"
                			db  0dh, 0ah, "(E)Exit - Exit the system (reboot)"
                 
    prompt_end:
    
    pr_str      			db      "Enter your string (Upto 80 characters): "
    pr_str_end:
    
    color_sel       		db  0ah, 0dh,"Select Color: (B)Black,   (G)Green,  (R)Red,  (W)White "
    color_sel_end:
    
    
    
    profile_select  db  0ah, 0dh, "Choose a profile: (1) - White font on black background"
                    db  0ah, 0dh, "                  (2) - Yellow font on blue  background"
                    db  0ah, 0dh, "                  (3) - Black font on light gray background"
                    db  0ah, 0dh, "                  (4) - Default"
    profile_select_end:
       
    
    
    reboot_msg  			db  0dh,0ah,0dh,0ah, "Press any key to reboot...."
    reboot_msg_end:
    
    str     				db      80      dup('$')
    end_str:                                                                              
    
    ;------------------------------------- MACROS-----------------------------------------
    ;------------------------------------------------------------------------------------
    
    ; Macro: move_cursor
    move_cursor macro  col, row
        
        ; save register state
        push ax
        push bx
        
        ; cursor move function
        mov ah, 2
        mov dh, row
        mov dl, col
        mov bh, 0           ; page
        int 10h
        
        ;restore register state
        pop bx
        pop ax
    endm    
    
    ; Macro : move_next_line
    ;--------------------------
    move_next_line  macro
        inc dh
        mov dl, 0
        move_cursor     dl,     dh
    endm
    
    
    ;Macro : move_next_col
    ;---------------------------
    move_next_col   macro
        inc dl
        move_cursor     dl,     dh
    endm
            
    ; macro : print_all
    ;------------------
    print_all macro 
        
        ; save regs
        push ax
        push bx
        push cx
        push dx
        push bp
        
        
        ; print
        mov ah, 13h         ; function select
        mov al, 1           ; update cursor
        ;attribute
        mov bl, attrib
        mov bh, 0            ; page 0
        
        int 10h
        
        ; restore register
        pop bp
        pop dx
        pop cx
        pop bx
        pop ax
    endm
    
    ; Macro : echo
    ;------------------------
    echo macro
        ; store the value of ah
        mov temp1,   ah
        mov ah, 0eh             ; display char function
        int 10h                 ; display and progress cursor
        mov ah, temp1
    endm
    
    ; Macro : scroll_down_line
    ;-----------------------------    
    scroll_down_line macro
        push  ax
        push bx
        
        mov ah, 7              ; scroll down
        mov al  , 1             ; one line
        mov bh  ,  0110b        ; cyan
        int 10h
        
        pop bx
        pop ax
    endm    
        
    ;----------------------Code Section---------------------------------
    ;-------------------------------------------------------------------
    
    start: 
    
    ; initialize ds and es with cs, and stack
    mov ax, 07c0h
    mov ss, ax
    mov sp, 03feh
    push cs
    push cs
    pop ds
    pop es
    
    ;clear bx and dx register
    xor     bx, bx
    xor     dx, dx
    
    ; set display mode
    mov ah, 0h
    mov al, 03h
    int 10h
    
    ;set blinking text-cursor
    mov ah, 1h
    mov ch, 7           ; ending row
    mov cl, 6           ; starting row
    int 10h
    
    ;--------- print welcome ---------
    call clear_window
    mov     si,     offset msg                  ; si points to msg address
    mov     cx,     msg_end - offset msg        ; cx contain total chars in string
    move_cursor     0 , 0                       ; move at line 0
    call    print_normal
    move_cursor     0  , 1                      ; move at line 3
    
    
    question:
    
    ;------------ prompt for option-----------
    mov     bp,     offset prompt;  
    mov     cx,     prompt_end - offset prompt ;
    print_all  
    
    ;---------- get the option selection --------
    call getchar ; 'option' will contain the code
    
    ; process selected option
    call process_option
    
    ; move cursor to the next line
    inc dh
    move_cursor dl, dh
    
    ; start again    
    jmp question    
    
    
    ;------------- PROCEDURES -----------------
    ;-------------------------------------------
    ; proc : getchar 
    ;---------------------------
    getchar proc 
        push ax
        
        ;get cursor position
        mov ah, 3h
        mov bh, 0
        int 10h
        
        ; go to next line
        ; dh - row, dl-col
        mov ah, 2h
        mov bh, 0
        inc dh              ; next line
        mov dl, 0           ; go at left
        int 10h
        
        ; get char
        mov ah, 0h
        int 16h
        ;echo
        mov option, al      ; store in option
        
        ; restore regs
        pop ax
        
        ret
    endp    
        
    
    ; Procedure : print_normal 
    ;-----------------------------------------------------
    print_normal proc
        
        push ax         ; save ax
        push cx         ; save cx
        push si         ; save si
        
        mov ah, 0eh     ; teletype output select
        
        repeat:
        mov al, [si]        ; get the char
        int 10h
        inc si              ; increament si
        loop repeat         ; repeat until all chars have printed
        
        ; restore the registers
        pop si
        pop cx
        pop ax
        
        ; return
        ret
    endp                    ; end process
    
    
    ; Procedure : clear_window
    ;-----------------------------------------------------
    clear_window proc
        
        push ax
        push cx
        push dx
        push bx
        
        mov     ah, 07h                   ; scroll up
        mov     al,  0                  ; clear entire window
        mov     ch  ,   0               ;    row
        mov     cl  ,   0           ;    column
        mov     dh  ,   24          ;   25th row
        mov     dl  ,   79          ; 80th column
        mov     bh  ,   attrib          ; cyan background, bright white foreground
        int 10h
        
        ; move cursor at top left
        move_cursor 0, 0
        
        pop bx
        pop dx
        pop cx
        pop ax
    ret
    endp  ; end process    
    
    
    ; procedure : process_option
    ;-----------------------------
    process_option proc 
        
        push ax       
        push cx
        push si
        
        mov al, option  
        cmp al, 'R'             ; is it reverse string option
        JE reverse                ; if yes, OK
        cmp al, 'C'             ; no?, is it colorize option
        JE colorize                ; if yes, OK
        cmp al, 'S'             ; is it clear screen option
        JE  clearscr
        cmp al, 'E'             ; is it Exit request?
        JE  exit               ; yes. OK
        cmp al,  'A'            ; change color attribute
        JE  change_attrib       
        
                    
        ; all options fails, so invalid option
        ; print invalid message
        mov bp, offset invalid_msg
        mov cx, invalid_msg_end - offset invalid_msg
        print_all
        
        jmp  end_validate
        
    ; option is reverse string    
    reverse:
        call print_reverse
        jmp end_validate
    
    
    ; option is colorized printing    
    colorize:
        call colorized_print
        jmp end_validate
    
    
    ; option is change attribute of system
    change_attrib:
        call change_attribute
        jmp     end_validate
        
    
    
    ; option is clear screen
    clearscr:
        call clear_window
        
        ; move cursor at top left
        mov dl, 0   ; column 0
        mov dh, 0   ; row 0
        mov ah, 2   ; function
        mov bh, 0   ; page 0
        int 10h
        
        ; after clearing window print the welcome message
        mov bp, offset msg              ; si points to msg address
        mov cx, msg_end - offset msg    ; cx contain total chars in string
        mov al,1
        mov bh, 0
        mov bl, attrib
        mov dl, 0
        mov dh, 0
        mov ah, 13h
        int 10h
        jmp end_validate
        
    
    ; option is REBOOT  
    exit:    
        mov bp, offset reboot_msg
        mov cx, reboot_msg_end - offset reboot_msg
        print_all
        
        mov ah, 0   
        int 16h             ; wait for pressing key
        
        
        int 19h             ; reboot
        
        jmp end_validate
            
    end_validate:    
        pop cx
        pop si
        pop ax
                
        ret
        
        endp    
    
    
        
    
    ; proc : print_reverse    
    ;-----------------------------------
    print_reverse proc
        push ax
        push bx
        push bp
        push cx
         
        mov bp, offset pr_str
        mov cx, pr_str_end - offset pr_str
        print_all
        
        mov ah,0
        ; set up counter
        xor cx,cx
      
        rev_get:
        
        int 16h         ; get char
        echo            ; echo the char
        
        ; if enter, stop  and get from stack
        cmp al, 0dh
        je get_reverse
        
        ; otherwise store in stack
        mov ah, 0
        push ax
        inc cx          ; increase counter
        jmp rev_get
    
        get_reverse:
        
        ; move ahead two line, for long string
        move_next_line
        move_next_line
            
        ; display function
        mov ah, 0eh     
        ; page 0
        mov bh, 0
        ; bl = foreground color
        mov bl, attrib
        
        
        pop_r:    
        
        ; pop and display
        pop ax
        
        ; display function
        mov ah, 0eh 
        
        ;mov al, byte ptr temp
        int 10h
        loop pop_r  ; loop until cx 0
            
    
    end_rev:
        
               
        pop cx
        pop bp
        pop bx
        pop ax
        
        ret
    endp;    
    
    ; Proc : colorized_print
    ;---------------------------------------------     
    colorized_print proc 
        push ax
        push bx
        push bp
        push cx
        
        ; prompt for string 
        mov bp, offset pr_str
        mov cx, pr_str_end - offset pr_str
        print_all
        
        ; read until 'Enter'
        xor bx,bx   ; index
        
        rep_c:
        ; function select
        mov ah, 0
        ; execute interrupt
        int 16h
        ; echo 
        echo
        ; compare, 
        cmp al, 0dh
        ;if 'Enter' end input
        je print_color
        ; else, store the character
        mov str[bx], al
        ; increase counter
        inc bx
        ; read another
        jmp rep_c
        
    print_color:
        
        mov total_char, bl  
        
    get_select:    
        ; prompt for color sel
        lea bp, color_sel
        mov cx, color_sel_end - offset color_sel
        move_next_line              ; for long string
        print_all
              
        call getchar    ; get the option
        mov al, option  ; get option
        
        ; compare and validate
        cmp al, 'W'
        je white_s
        cmp al, 'R'
        je red_s
        cmp al, 'B'
        je black_s
        cmp al, 'G'
        je green_s
        ; else invalid selection
        
        ;print warning and get selection again
        ; invalid
        mov bp, offset invalid_msg
        mov cx, invalid_msg_end - offset invalid_msg
        print_all
        jmp get_select
    
    white_s:
        ; get current background
        mov al, 0
        mov al, attrib      ; current profile
        and al, 0f0h         ; clear low nibble, font color
        or  al, white   ; get user selected text color
        mov user_attrib, al
        jmp print
    black_s:
        
        ; get current background
        mov al, 0
        mov al, attrib      ; current profile
        and al, 0f0h         ; clear low nibble
        or  al, black   ; get user selected text color
        mov user_attrib, al
        jmp print
    green_s:
        
        ; get current background
        mov al, 0
        mov al, attrib      ; current profile
        and al, 0f0h        ; clear low nibble
        or  al, green   ; get user selected text color
        mov user_attrib, al
        jmp print
    red_s:
        
        ; get current background
        mov al, 0
        mov al, attrib      ; current profile
        and al, 0f0h        ; clear low nibble
        or  al, red   ; get user selected text color
        mov user_attrib, al
        
        jmp print
    
    print:                          
        
        mov al,1
        ; page 0
        mov bh, 0
        ; attribute
        mov bl, user_attrib
        ; total char
        xor cx,cx
        mov cl, total_char
        ; function select
        mov ah, 13h
        ; load bp with offset
        mov bp , offset str
        ; execute
        int 10h
        
    end_print_c:
        pop cx
        pop bp
        pop bx
        pop ax
        
        ret
        
        ; varible for procedure
        user_attrib db  ?
        total_char db ?
        
    endp
    
    ; Proc: change_attrib
    ;-------------------------------------------
     change_attribute  proc
        
        push    ax
        push    bp
        push    cx
        
        get_selection:   
        ; prompt and get option
        mov     bp,     offset  profile_select
        mov     cx,     profile_select_end - offset profile_select
        print_all
        
        call getchar        ; selection is in option var
        
        ; compare, validate and change
        mov     al,     option
        
        cmp     al,     '1'
        je      black_W         ; black-W
        cmp     al,     '2'
        je      blue_Y          ; blue-Yellow
        
        cmp     al,     '3'     ; lightgray_black
        je      gray_B
        
        cmp     al,     '4' 
        je      cyan_W          ; cyan-White
        
        ; if invalid, display invalid msg
        mov bp, offset invalid_msg
        mov cx, invalid_msg_end - offset invalid_msg
        print_all
        move_next_line          ; move the cursor next line
        
        ; get the input, again
        jmp    get_selection
        
        ; option valid, so process
        black_W:
        mov     attrib,     black_white
        call    clear_window 
        jmp     end_change_attrib
        
        blue_Y:
        mov     attrib,     blue_yellow
        call    clear_window
        jmp     end_change_attrib
        
        cyan_W:
        mov     attrib,     default
        call    clear_window
        jmp     end_change_attrib
        
        gray_B:
        mov     attrib,     gray_black
        call    clear_window
        jmp     end_change_attrib
        
        
        end_change_attrib:
        ; processing complete, pop  the registers
        pop     cx
        pop     bp
        pop     ax  
        
        
        ret
        
        endp
        
    
    ; © Mohammad Anwar Shah            