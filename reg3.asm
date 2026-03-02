.model tiny
.code

org 100h

;————————————————————————————————————————————————————————————————————————————————

FRAME_LEN          equ 00A0h
VIDEO_MEM          equ 0b800h
TERMINAL_DATA_SEG  equ 80h
NUM_PARAMS         equ 13d
NUM_SYM_PARAMS     equ 9
TERMINAL_HIGH      equ 25d
STD_KEYBOARD_INT   equ 3509h
KEYBOARD_OFFSET    equ 36d
x_0				   equ 60d
y_0				   equ 5
STR_LEN            equ 9
FRAME_HIGH   	   equ 12
TEXT_COLOR 		   equ 07h 
FRAME_COLOR 	   equ 15h
INTERIOR_SYM_COLOR equ 1Eh

;————————————————————————————————————————————————————————————————————————————————

Start:

	jmp Main

REG_NAMES   db "ax = "
			db "bx = "
			db "cx = "
			db "dx = "
			db "si = "
			db "di = "
			db "bp = "
			db "sp = "
			db "ip = "
			db "cs = "
			db "ds = "
			db "es = "

REG_VALUES dw 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 

	Main:

;we call dos int 3509h and it put address of command
;in es:bx, we save it in variables to return to old
;interrupt to use it
    mov ax, STD_KEYBOARD_INT
    int 21h

;save old int offset
    mov old09ofs, bx
;we cant mov from es, so firstly we mov
    mov bx, es
;save old int segment
    mov old09seg, bx

;put 0 to es, to access to zero segment
;to change default int to our
    mov bx, 0
    mov es, bx

;write cli to save our code from another int while we change it
    cli 

;change offset of default int to offset of our int
    mov bx, KEYBOARD_OFFSET
    mov es:[bx], offset New09

;change offset of default int to segment of our int
    mov ax, cs
    mov es:[bx + 2], ax

;return opportunity to use another int
    sti

	int 09h

;int 21h with ax == 3100h == leave and keep our program in memory
;in dx we put size of our program in 16 bytes blocks
    mov ax, 3100h

;put in dx size of our program in bytes
    mov dx, offset EndOfProgram

;div dx to 16, because memory blocks have size = 16 bytes
    shr dx, 4
;add 1 block, if size rounded up was bad
;and we add 10h to save org info (.org 100h)
	add dx, 11h

    int 21h

;————————————————————————————————————————————————————————————————————————————————

New09    proc
    
	push ds
	push cs
	pop ds

;move ax bx cx dx si bp es di sp ip
	call save_registers
    
    push 0b800h
    pop es

	;in al, 60h

	;cmp al, 26
	;jne @@end

	;cli

    call print_frame

	;sti

	@@end:

    call return_registers

	pop ds

    db 0eah

	old09ofs dw 0
    old09seg dw 0

    endp

;————————————————————————————————————————————————————————————————————————————————
;Print the specified character in the specified place

;Enter  : al = symbol
;         ah = color of symbol
;         di = pos on the screen

;Return : di = incremented pos

;Destroy: -
;————————————————————————————————————————————————————————————————————————————————

put_char    proc

;Print symbol
    mov word ptr es:[di], ax

;pos++
    add di, 2

    ret
    endp

;————————————————————————————————————————————————————————————————————————————————
;Print frame line
;It takes 7 params: start pos, STR_len, left symbol, middle, right, color of left and right sym, color of middle

;Enter  : di bx = start pos on the screen
;		: ch = left sym
;		: cl = right sym
;		: dl = middle sym
;		: dh = color of middle

;Return : bx = new pos on the screen

;Destroy: ax, si
;————————————————————————————————————————————————————————————————————————————————

print_frame_line		proc

;we save bp, because it will be iteration counter
	push bp

;bp = str_len = num of iterations of printing 
;interior symbol into the frame
;we add 2 to bp, because we have a space before and
;after the string
	mov bp, STR_LEN + 2

;prepare to print left symbols (border part)
;ch = left symbol of this line
	mov ah, FRAME_COLOR
	mov al, ch

;print left sym and inc di == pos on the screen
	call put_char

;middle sym
;dh = color of middle sym
;dl = middle sym
	mov ah, dh
	mov al, dl

	@@frame_line_iter:

;print sym, inc di, dec iteration count
		call put_char
		dec bp

		cmp bp, 0
		ja @@frame_line_iter

;cl = right sym
	mov ah, FRAME_COLOR
	mov al, cl

;print right sym
	call put_char

;go to new line
;si = offset to first element in the frame on the next line
	add di, si

;return bp
	pop bp

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————
;Print full frame

;Enter  : -

;Return : -

;Destroy: ax, bx, cx, dx, si, bp
;————————————————————————————————————————————————————————————————————————————————

print_frame		proc

	call count_frame_start_pos
	call count_frame_line_offset

	mov ch, 201
	mov dl, 205
	mov cl, 187

;color of middle part
	mov dh, FRAME_COLOR

	call print_frame_line

	mov ch, 186
	mov dl, '#'
	mov cl, 186

	xor ax, ax
	mov al, FRAME_HIGH

;num of iterations
	mov bx, ax
;2 empty str, highest asn lowest
	add bx , 2
	mov dh, INTERIOR_SYM_COLOR

	@@print_line_iter:

		call print_frame_line
		dec bx

		cmp bx, 0
		ja @@print_line_iter

	mov ch, 200
	mov dl, 205
	mov cl, 188

	mov dh, FRAME_COLOR

	call print_frame_line

	call print_frame_text

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————
;Count start pos to print frame

;Enter  : x_0, y_0

;Return : di = pos

;Destroy: ax
;————————————————————————————————————————————————————————————————————————————————

count_frame_start_pos		proc

;clean ax, because it will be used in multiplication 
	xor ax, ax
	xor di, di

;ax = start_line
;di = start_line
	mov ax, y_o
	mov di, y_o
;ax *= 32
	shl ax, 5
;di *= 128
	shl di, 7
;di = 160 * y_o
;di = offset to first line
	add di, ax

;add offset in cur line
;add 2 times because all sym take 2 bytes
	add di, x_0
	add di, x_0

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————
;Count start pos to print text in frame

;Enter  : -

;Return : di = pos

;Destroy: ax
;————————————————————————————————————————————————————————————————————————————————
count_text_start_pos	proc

;di = start pos of the frame, destroy ax
	call count_frame_start_pos

;skip 2 lines, frame border symbol and space
	add di, FRAME_LEN * 2 + 4

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————
;Count offset that need to add to pos on the screen
;to move to pos of first element in the frame on the next line

;Enter  : FRAME_LEN = len of area to str in frame

;Return : si = offset

;Destroy: ax, si
;————————————————————————————————————————————————————————————————————————————————

count_frame_line_offset		proc

;clear ax, to count offset to new str
	xor ax, ax

;we will save offset in si, but FRAME_LEN is a byte const,
;and si haven`t low part, so we put FRAME_LEN in al and clean ah
;to put it in si
	mov al, FRAME_LEN

;put 160d in si
	mov si, ax

;put len of area to string in frame in al
	mov al, STR_LEN

;it takes 2 bytes to print 1 sym, so 
;we multiplicate len of area to str to 2,
;to skip len of area symbols
	shl al, 1

;160d - str_len
	sub si, ax
;we have 2 extra symbols on both sides
;frame sym and space, so we have 4 extra sym = 8 bytes 
	sub si, 8

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————
;take 4 bin symbols in register, translate it ti hex and print it in cycle

;Enter  : ax = immediate, that we will print
;       : di = pos on the screen

;Return : di = new pos on the screen

;Destroy: ax, bx, cx
;————————————————————————————————————————————————————————————————————————————————

print_register_value proc

;save previous value of cx, because it used 
;like iteration count in print frame
	push cx

;we need to take 4 digits, so we need 4 iterations
    mov cx, 4

	@@convert_loop:

;mov 4 left symbol to right side, and another part shifts to right
;like rol al, 2 == 11001100-> 00110011
;its need to take first hex symbol from register
    rol ax, 4

;copy ax to bx, to save another part of register,
;because we will clean it
    mov bx, ax
;clean older part of bl
    and bl, 0Fh

;translate to hex
    cmp bl, 10
;if it just a number we will just add '0' to translate it to ASCII
    jl @@is_digit

;if it hex we need to add 7, because '9' have number 57d,
;meanwhile 'A' have number 65, so if register value above or equal
;than 10 we need to add 65 - 57 - 1 (-1 because we cmp with 10)
    add bl, 7

@@is_digit:

;just translate a number in bl to ASCII number
    add bl, '0'

;put text color to bh to print it
	mov bh, TEXT_COLOR
    
;print symbol
	mov word ptr es:[di], bx
;inc pos on the screen
	add di, 2

;repeat it 4 times to print all register
    loop @@convert_loop

;return value of cx to print frame
	pop cx

    ret
	endp

;————————————————————————————————————————————————————————————————————————————————
;print in frame lines like ax = ABCD

;Enter  : -

;Return : -

;Destroy: ax, bx, cx, dx, si, bp
;————————————————————————————————————————————————————————————————————————————————

print_frame_text 	proc

;di = start pos to print text, ax - destroyed
	call count_text_start_pos

;si = offset, but in contain 4 extra sym, so we need
;to add 8 to si. destroy ax
	call count_frame_line_offset
	add si, 8

;save offset in dx, because si will be destroyed
	mov dx, si

	xor cx, cx
	xor bp, bp

	@@print_iter:

;copy str from REG_NAMES to terminal
		mov al, cl
		call print_reg_name

;it takes value in ax and print it in terminal
		mov ax, REG_VALUES[bp]
		call print_register_value

;goto next line
		add di, dx
;inc num of cur reg
		inc cx
		add bp, 2

		cmp cx, 12
		jb @@print_iter

	
	ret
	endp

;————————————————————————————————————————————————————————————————————————————————
;save all register in variables

;Enter  : all registers

;Return : -

;Destroy: ax, bp
;————————————————————————————————————————————————————————————————————————————————

save_registers		proc

	mov REG_VALUES[0], ax
	mov REG_VALUES[2], bx
	mov REG_VALUES[4], cx
	mov REG_VALUES[6], dx
	mov REG_VALUES[8], si
	mov REG_VALUES[10], di
	mov REG_VALUES[12], bp
	mov REG_VALUES[14], sp
	mov REG_VALUES[22], es

;we add 10 because is stake cx, ip, ret address, ds, flags = 10 bytes
	add REG_VALUES[14], 10

;we will take reg values from stack
;--------------------------------------------------

;move sp to bp to have an opportunity 
;to access the memory directly
	mov bp, sp

;[bp+0] = ret address to call save_registers
;[bp+2] = ds
;[bp+4] = ip
;[bp+6] = cs
;[bp+8] = flags

;take ds from stack and save in array
    mov ax, [bp+2]
    mov REG_VALUES[20], ax

;take ip from stack and save in array
    mov ax, [bp+4]
    mov REG_VALUES[16], ax

;take cs from stack and save in array
    mov ax, [bp+6]
    mov REG_VALUES[18], ax

;--------------------------------------------------

;return destroyed registers
    mov ax, REG_VALUES[0]
    mov bp, REG_VALUES[12]

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————
;print str form REG_NAMES

;Enter  : al = num of cur str
;       : di = pos on the screen

;Return : di = new pos on the screen

;Destroy: bx, si
;————————————————————————————————————————————————————————————————————————————————

print_reg_name proc

;clean bh, because wi will put cur str to bx
    xor bh, bh

;bl = num of cur str
    mov bl, al
;bl = num of cur str * 5
;because all strings have size of 5 bytes
    mov si, bx
;bx *= 4
	shl bx, 2
;bx += bx
	add bx, si
    
;take address of cur str and put it to si
    lea si, REG_NAMES[bx] 

;put color of text to ah, to print ax
    mov ah, TEXT_COLOR

;save cx to make a cycle
	push cx

;5 symbols in all str 
	mov cx, 5

;--------------------------------------------------

	@@print_reg_str_iter:

;take next sym from str
		mov al, [si]
;print sym
		mov es:[di], ax
;inc pos on the screen
		add di, 2
;inc pos in cur str
		inc si

		loop @@print_reg_str_iter

;--------------------------------------------------

	pop cx

    ret
	endp

;————————————————————————————————————————————————————————————————————————————————

return_registers		proc

	mov ax, REG_VALUES[0]
	mov bx, REG_VALUES[2]
	mov cx, REG_VALUES[4]
	mov dx, REG_VALUES[6]
	mov si, REG_VALUES[8]
	mov di, REG_VALUES[10]
	mov bp, REG_VALUES[12]
	mov es, REG_VALUES[22]
	mov ds, REG_VALUES[20]

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————

EndOfProgram:

end     Start