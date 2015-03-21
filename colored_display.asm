#make_bin#

; BIN is plain binary format similar to .com format, but not limited to 1 segment;
; All values between # are directives, these values are saved into a separate .binf file.
; Before loading .bin file emulator reads .binf file with the same file name.

; All directives are optional, if you don't need them, delete them.

; set loading address, .bin file will be loaded to this address:
#LOAD_SEGMENT=0500h#
#LOAD_OFFSET=0000h#

; set entry point:
#CS=0500h#	; same as loading segment
#IP=0000h#	; same as loading offset

; set segment registers
#DS=0500h#	; same as loading segment
#ES=0500h#	; same as loading segment

; set stack
#SS=0500h#	; same as loading segment
#SP=FFFEh#	; set to top of loading segment

; set general registers (optional)
#AX=0000h#
#BX=0000h#
#CX=0000h#
#DX=0000h#
#SI=0000h#
#DI=0000h#
#BP=0000h#



; set cursor position
mov ah, 02h
mov dh, 15  ; row
mov dl, 30  ; col
mov bh, 0   ; page
int 10h


mov ah, 09h ; write char only at cursor position
mov al, 'A'
mov bh, 0   ; page number
mov bl, 00001110b
mov cx, 10 ; no of times
int 10h

xor ax,ax
; read char
int 16h

HLT           ; halt!


