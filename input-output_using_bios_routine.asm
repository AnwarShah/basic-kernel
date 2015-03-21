org 100h

mov di, 0
read:
mov ah, 00h
int 16h
; check if enter is pressed
cmp al, 0dh
je end_input ; if yes, go print the entered string
; no , store it and go for another
mov string[di], al
inc di
jmp read ; no? read another

end_input:
mov ah, 0Eh ; teletype output
mov cx, di ; set counter
mov di, 0
print:
mov al, string[di]
int 10h
inc di
loop print

ret

string db 80 dup('$')