.model tiny
.code

org 100h

;————————————————————————————————————————————————————————————————————————————————

Start:

	jmp Main

;———————————————————————————CONSTANTS—————————————————————————————————————————————————————

TERMINAL_LEN        equ 00A0h
VIDEO_MEM           equ 0b800h
TERMINAL_DATA_SEG   equ 80h
NUM_PARAMS          equ 13d
NUM_SYM_PARAMS      equ 9
TERMINAL_HIGH       equ 25d
STD_KEYBOARD_INT    equ 3509h
KEYBOARD_OFFSET     equ 36d
x_0				    equ 60d
y_0				    equ 5
STR_IN_FRAME_LEN    equ 9
FRAME_LEN           equ 11
FRAME_INTERIOR_HIGH equ 12
FRAME_HIGH			equ 14
TEXT_COLOR 		    equ 07h 
FRAME_COLOR 	    equ 15h
INTERIOR_SYM_COLOR  equ 1Eh

;--------------------------------------------------

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

;——————————————————————VARIABLES AND ARRAYS———————————————————————————————————

regVALUES dw 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 

frameSTART_POS dw 0

;array there we will make a frame
frame_array dw 13 * 16 DUP (0)
;array there we will save symbols under the frame
save_array  dw 13 * 16 DUP (0)

;————————————————————————————————————————————————————————————————————————————————

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

;save previous ds in stack, because we destroy it	
	push ds

;put cs in ds to have an opportunity to
;access to memory
	push cs
	pop ds

;move ax bx cx dx si bp es di sp ip in array
	call save_registers
    
;put video_mem address to es to
;have an opportunity to print symbols	
    push VIDEO_MEM
    pop es

;take a click
	in al, 60h

;if (scan cod key == '[') print_frame
	cmp al, 26
	je @@upd_screen

;if (scan cod key == ']') return old terminal
	cmp al, 27
	je @@recover_screen

	jmp @@end

	@@upd_screen:

		call make_frame_in_array
		call update_screen

		jmp @@end

	@@recover_screen:

		call recover_screen

	@@end:

;return registers values to registers from array
    call return_registers

;return previous ds that we destroyed
	pop ds

;long jmp to default int 09h
    db 0eah

;define variables that saves segment
;and offset of old int 09h
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

;Enter  : di = start pos in frame_array
;		: bh = left sym
;		: bl = right sym
;		: dl = middle sym

;Return : di = new pos on the screen

;Destroy: ax, si
;————————————————————————————————————————————————————————————————————————————————

print_frame_line		proc

;clean older part of cx, because we will use loop
	xor ch, ch

;iteration count
	mov cl, STR_IN_FRAME_LEN

;print left sym
	mov byte ptr frame_array[di], bh
	mov byte ptr frame_array[di + 1], FRAME_COLOR

;inc di to 1 sym == 2 bytes
	add di, 2

;ax = middle sym + color, we will print ax
;dl = middle sym
	mov ah, FRAME_COLOR
	mov al, dl

	@@frame_line_iter:

;print middle sym to frame in array
		mov word ptr frame_array[di], ax
;increase pos in array
		add di, 2

		loop @@frame_line_iter

;print right sym
	mov byte ptr frame_array[di], bl
	mov byte ptr frame_array[di + 1], FRAME_COLOR

;inc di to 1 sym == 2 bytes
	add di, 2

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————
;Count start pos to print frame

;Enter  : x_0, y_0

;Return : di = pos
;		: frameSTART_POS = pos

;Destroy: ax
;————————————————————————————————————————————————————————————————————————————————

count_frame_start_pos		proc

;clean ax, because it will be used in multiplication 
	xor ax, ax
	xor di, di

;ax = start_line
;di = start_line
	mov ax, y_0
	mov di, y_0
;ax *= 32
	shl ax, 5
;di *= 128
	shl di, 7
;di = 160 * y_0
;di = offset to first line
	add di, ax

;add offset in cur line
;add 2 times because all sym take 2 bytes
	add di, x_0
	add di, x_0

;save value in variable, because it will be used
;when we will print registers values
	mov frameSTART_POS, di

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————
;Count start pos to print text in frame

;Enter  : -

;Return : di = pos

;Destroy: ax
;————————————————————————————————————————————————————————————————————————————————
count_text_start_pos	proc

;value that we saved from count_frame_start_pos
;pos of first frame sym (left top)
	mov di, frameSTART_POS

;skip 2 lines, frame border symbol and space
	add di, TERMINAL_LEN * 2 + 4

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————
;Count offset that need to add to pos on the screen
;to move to pos of first element in the frame on the next line

;Enter  : TERMINAL_LEN = len of area to str in frame

;Return : si = offset

;Destroy: ax, si
;————————————————————————————————————————————————————————————————————————————————

count_frame_line_offset		proc

;clear ax, to count offset to new str
	xor ax, ax

;we will save offset in si, but TERMINAL_LEN is a byte const,
;and si haven`t low part, so we put TERMINAL_LEN in al and clean ah
;to put it in si
	mov al, TERMINAL_LEN

;put 160d in si
	mov si, ax

;put len of area to string in frame in al
	mov al, STR_IN_FRAME_LEN

;it takes 2 bytes to print 1 sym, so 
;we multiplicate len of area to str to 2,
;to skip len of area symbols
	shl al, 1

;160d - str_IN_FRAME_len
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

;Destroy: ax, bx, dx, cx
;————————————————————————————————————————————————————————————————————————————————

print_register_value proc

;we need to take 4 digits, so we need 4 iterations
    mov dx, 4

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
	mov word ptr frame_array[di], bx
;inc pos on the screen
	add di, 2
;down size num of iterations
	dec dx

;repeat it 4 times to print all register
	cmp dx, 0
	ja @@convert_loop

    ret
	endp

;————————————————————————————————————————————————————————————————————————————————
;print in frame lines like ax = ABCD

;Enter  : -

;Return : -

;Destroy: ax, bx, cx, dx, si, bp
;————————————————————————————————————————————————————————————————————————————————

print_frame_text 	proc

;count start pos in frame_array
;it will be 2 line 2 column
;--------------------------------------------------

;clean older part of ax
	xor ah, ah

;al = len of area to text
	mov al, STR_IN_FRAME_LEN

;si = 2 * str_IN_FRAME_len
	mov di, ax
	shl di, 1

;2 symbols in first line, and 1 frame sym
	add di, 6

;--------------------------------------------------

	xor cx, cx
	xor bp, bp

	@@print_iter:

;copy str from REG_NAMES to terminal
		mov al, cl
		call print_reg_name

;it takes value in ax and print it in terminal
		mov ax, cs:regVALUES[bp]
		call print_register_value

;inc num of cur reg
;cx = num of cur line == num of cur register
;bp == address of value of cur register in cs:regVALUES
		inc cx
		add bp, 2

		add di, 4

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

	mov cs:regVALUES[0], ax
	mov cs:regVALUES[2], bx
	mov cs:regVALUES[4], cx
	mov cs:regVALUES[6], dx
	mov cs:regVALUES[8], si
	mov cs:regVALUES[10], di
	mov cs:regVALUES[12], bp
	mov cs:regVALUES[14], sp
	mov cs:regVALUES[22], es

;we add 10 because in stack cx, ip, ret address, ds, flags = 10 bytes
	add cs:regVALUES[14], 10

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
    mov cs:regVALUES[20], ax

;take ip from stack and save in array
    mov ax, [bp+4]
    mov cs:regVALUES[16], ax

;take cs from stack and save in array
    mov ax, [bp+6]
    mov cs:regVALUES[18], ax

;--------------------------------------------------

;return destroyed registers
    ; mov ax, cs:regVALUES[0]
    ; mov bp, cs:regVALUES[12]

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————
;print str form REG_NAMES

;Enter  : al = num of cur str
;       : di = pos on the screen

;Return : di = new pos on the screen

;Destroy: bx, dx, si
;————————————————————————————————————————————————————————————————————————————————

print_reg_name proc

;clean bh, because wi will put cur str to bx
    xor bh, bh

;bl = num of cur str
    mov bl, al

;bl = num of cur str * 5
;because all strings have size of 5 bytes
;--------------------------------------------------	

    mov si, bx
;bx *= 4
	shl bx, 2
;bx += bx
	add bx, si

;--------------------------------------------------

;take address of cur str and put it to si
    lea si, REG_NAMES[bx] 

;put color of text to ah, to print ax
    mov ah, TEXT_COLOR

;5 symbols in all str 
	mov dx, 5

;print symbols
;--------------------------------------------------

	@@print_reg_str_iter:

;take next sym from str
		mov al, [si]
;print sym
		mov frame_array[di], ax
;inc pos in frame_array
		add di, 2
;inc pos in cur str
		inc si
;down size num of iterations
		dec dx

		cmp dx, 0
		ja @@print_reg_str_iter

;--------------------------------------------------

    ret
	endp

;————————————————————————————————————————————————————————————————————————————————

return_registers		proc

	mov ax, cs:regVALUES[0]
	mov bx, cs:regVALUES[2]
	mov cx, cs:regVALUES[4]
	mov dx, cs:regVALUES[6]
	mov si, cs:regVALUES[8]
	mov di, cs:regVALUES[10]
	mov bp, cs:regVALUES[12]
	mov es, cs:regVALUES[22]
	mov ds, cs:regVALUES[20]

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————
;make frame if frame_array

;Enter  : -

;Return : -

;Destroy: ax, bx,cx, dl, di
;————————————————————————————————————————————————————————————————————————————————

make_frame_in_array		proc

;count frame start pos in terminal and put it in variable
	call count_frame_start_pos

;di = 0 == start pos in frame_array
	xor di, di

;beautiful symbols, that will be part of frame border
	mov bh, 201
	mov dl, 205
	mov bl, 187

	call print_frame_line

;print semi-empty lines, where will be text
;--------------------------------------------------

;prepare frame sym
	mov bl, 186
	mov bh, FRAME_COLOR

;num of iterations
	xor cx, cx
	mov cl, FRAME_INTERIOR_HIGH

	@@print_line_iter:

;print left frame sym
		mov word ptr frame_array[di], bx

;add to pos 2 bytes == left frame sym
;add to pos STR_IN_FRAME_LEN * 2 == skip area, where will
;be registers values
		add di, 2 + STR_IN_FRAME_LEN * 2

;print right frame sym
		mov word ptr frame_array[di], bx

;inc pos, frame right sym == 2 bytes
		add di, 2

		loop @@print_line_iter

;--------------------------------------------------

;print last line, bot border

;beautiful symbols, that will be part of frame border
	mov bh, 200
	mov dl, 205
	mov bl, 188

	call print_frame_line

	call print_frame_text

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————
;print if frame new register values
;we always rewrite registers values to frame array,
;because it have the same num of access to mem, but it have
;less num of instructions, so it would be faster
;as a bonus it isn`t ruin conveyor belt

;Enter  : -

;Return : -

;Destroy: ax, bx, cx, dx, bp, di
;————————————————————————————————————————————————————————————————————————————————

update_frame_array		proc

;num of registers, num of iterations
	mov cx, 12

;start pos in cs:regVALUES array
	mov bp, 0

;count pos in frame_array of first register value
;2 line, 7 column
	mov di, (11 + 6) * 2 

	@@update_iter:

;it takes value in ax and print it in terminal
		mov ax, cs:regVALUES[bp]
		call print_register_value

;take next register value
		add bp, 2
;goto next line	
		add di, 11 * 2 - 8

		loop @@update_iter

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————
;compare element from frame_array and terminal
;if the different, sym in terminal -> save_buffer,
;sym in frame_array -> terminal, so we always save the screen

;Enter  : -

;Return : updated frame_array
;		: updated save_array

;Destroy: ax, bx, cx, dx, bp, di, es
;————————————————————————————————————————————————————————————————————————————————

update_screen		proc

;put new registers values in frame array
	call update_frame_array

;---------------README-----------------------------
;bx == pos in save and frame arrays
;di == pos in terminal
;si == offset to new line in terminal
;--------------------------------------------------

;put to es address of video mem to have 
;an opportunity to access to video mem
	mov ax, VIDEO_MEM
	mov es, ax

;preparing constants
;bx = 0
	xor bx, bx
;di = pos of frame top left sym
	mov di, frameSTART_POS
;si = 160 - 11 * 2
	mov si, TERMINAL_LEN - FRAME_LEN * 2

;num of iterations of processing lines
	mov cx, FRAME_HIGH

;processing of lines	
;--------------------------------------------------

	@@processing_lines:

;num of processing symbols in every lines
		mov dx, FRAME_LEN

	;--------------------------------------------------

		@@processing_sym:

;compare sym in frame array and terminal
;if the equal, we cmp colors, and if the 
;are equal, we don`t copy sym from terminal to save _array 
;and from frame_array to terminal

			mov byte ptr ax, es:[di]

			cmp frame_array[bx], ax
			je @@skip_copying

			@@copy:

;mov sym from terminal to register, because
;we can`t cmp mem-mem, only mem-rem/ reg-mem
				mov ax, es:[di]

				;terminal -> save_array
				mov word ptr save_array[bx], ax
				;frame_array -> terminal
				mov word ptr ax, frame_array[bx]

				mov es:[di], ax

			@@skip_copying:

;increase pos in arrays and terminal
			add di, 2
			add bx, 2

;down size num of iterations in this line
			dec dx

			cmp dx, 0
			ja @@processing_sym

	;--------------------------------------------------

;goto nest line in terminal
		add di, si

		loop @@processing_lines

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————
;return symbols from save_array to terminal

;Enter  : -

;Return : default terminal

;Destroy: ax, bx, cx, dx, bp, di, es
;————————————————————————————————————————————————————————————————————————————————

recover_screen		proc

;---------------README-----------------------------
;bx == pos in save arrays
;di == pos in terminal
;si == offset to new line in terminal
;--------------------------------------------------

;put to es address of video mem to have 
;an opportunity to access to video mem
	mov ax, VIDEO_MEM
	mov es, ax

;preparing constants
;bx = 0
	xor bx, bx
;di = pos of frame top left sym
	mov di, frameSTART_POS
;si = 160 - 11 * 2
	mov si, TERMINAL_LEN - FRAME_LEN * 2

;num of iterations of processing lines
	mov cx, FRAME_HIGH

;processing of lines	
;--------------------------------------------------

	@@rec_processing_lines:

;num of processing symbols in every lines
		mov dx, FRAME_LEN

	;--------------------------------------------------

		@@rec_processing_sym:

;save_array -> terminal
			mov word ptr ax, save_array[bx]
			mov word ptr es:[di], ax

;increase pos in arrays and terminal
			add di, 2
			add bx, 2

;down size num of iterations in this line
			dec dx

			cmp dx, 0
			ja @@rec_processing_sym

	;--------------------------------------------------

;goto nest line in terminal
		add di, si

		loop @@rec_processing_lines

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————

EndOfProgram:

end     Start