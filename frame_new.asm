;Enter params to program:
;2th------------3th--------------4th
;|                                 |
;|                                 |
;5th------------6th--------------7th
;|                                 |
;|                                 |
;8th------------9th-------------10th
;1th == string field length
;2th - 10th params == frame params
;11th == color of borders
;12th == color of frame interior (without text)
;13th == color of text
;then text

;————————————————————————————————————————————————————————————————————————————————


.model tiny
.code

org 100h

STR_SIZE          equ 160d
VIDEO_MEM         equ 0b800h
TERMINAL_DATA_SEG equ 80h

;————————————————————————————————————————————————————————————————————————————————
Start:	

;start of video mem
	mov ax, VIDEO_MEM
	mov es, ax	

	call print_text

	call print_frame

	mov ax, 4c00h	
	int 21h

;————————————————————————————————————————————————————————————————————————————————
;Print the specified character in the specified place
;Enter  : al = symbol
;         ah = color of symbol
;         cx = pos on the screen
;Return : cx = incremented pos
;Destroy: -
;————————————————————————————————————————————————————————————————————————————————

put_char    proc

;Print symbol
    mov byte word es:[VIDEO_MEM + cx], ax

;pos++
    inc cx

    ret
    endp

;————————————————————————————————————————————————————————————————————————————————
;Print line with specified length in specified place
;Printing stopping in founded '\n' and fill end of str by spaces

;Enter  : cx = pos on the screen
;       : bx = pos in ds (there we take a string)
;       : dh = text color
;       : dl = line length

;Return : cx = new pos on the screen
;       : al = \n flag

;Destroy: bp
;————————————————————————————————————————————————————————————————————————————————

print_line  proc

    @@print_line_iteration:

;ah == symbol color
        mov ah, dh

;take regular symbol
        mov bl, ds:[bx]

;symbol == '\'
        cmp al, '\'
        je @@comp_new_str

    @@regular_sym:

;pos in ds++
        inc bx

        call put_char

;number of printed symbols++
        inc bp

;bp haven`t low part so to cmp num of printed symbols and num of symbols that need to print we
;mov bp to ax, and then compare to make new iterations
        mov ax, bp
        cmp al, dl
        jb @@print_line_iteration

;\n flag == 0
    mov al, 0

    jmp @@print_line_end

    @@comp_new_str:

;take symbol after '\' to compare with 'n'
        mov al, ds:[bx + 1]

;compare symbol with 'n' and jump if it \n
        cmp al, 'n'
        je @@new_str_sym
        jmp @@regular_sym

    @@new_str_sym:

;skip \n symbol
        add bx, 2

        mov ax, bp

;al == flag about \n
;al == 1 if that was \n else al == 0
        mov al, 1

        jmp @@print_line_end

    @@print_line_end:

    ret
    endp

;————————————————————————————————————————————————————————————————————————————————
;Print horizontal frame border
;Entry : es:di -> start of border
;		 dl     = str_len
;		 bh     = symbol to print
;		 bl     = color
; destroy ax, si, cx
;————————————————————————————————————————————————————————————————————————————————

print_horizontal_border		proc

	xor ax, ax
	xor cx, cx

; make offset to new str in si
;si = 160
	mov si, STR_SIZE
;al = str_len
	mov al, dl
;al *= 2
	add al, 4
	shl ax, 1
;si = 2 * (80 - str_len)
	sub si, ax

	mov cl, dl

	add cl, 2

	@@horizontal_border_iteration:

		mov word ptr es:[di], bx

		add di, 2
		dec cx

		jnz @@horizontal_border_iteration

	add di, si
	add di, 4

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————————————————————
;Print vertical frame borders 
;Entry : es:di -> start of border
;		 dl     = string length
;		 dh		= border highth
;		 bl     = symbol to print
;		 bh     = color
;destroy : si, cx, ax
;————————————————————————————————————————————————————————————————————————————————

print_vertical_border		proc

;clean ax
	xor ax, ax
	xor cx, cx

	mov cl, dl
;2 bytes on symbol
	shl cx, 1

;si = 160
	mov si, STR_SIZE
;si = offset to and of str
	sub si, cx
; 2 symbols from border (left and right)
	sub si, 4

	xor cx, cx
;count of iterations
	mov cl, dh

	mov al, dl
	shl al, 1

	@@vertical_border_iteration:

;print first symbol
		mov word ptr es:[di], bx

;first symbol
		add di, 2 

;pos for last symbol
		add di, ax

		mov word ptr es:[di], bx

;last symbol
		add di, 2
;offset to new str
		add di, si

		dec cx

		jnz @@vertical_border_iteration

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————————————————————
;Print full frame
;Entry : es:di -> start of border
;		 dl     = string length
;		 dh		= border highth
;		 bl     = symbol to print
;		 bh     = color
;destroy : si, cx, ax
;————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————————————————————
print_frame	proc

	mov di, 0

	call print_horizontal_border

	call print_vertical_border

	call print_horizontal_border

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————————————————————
;Get string (that will be printed) length
;Enter  : cl = len of "dirty" string
;Return : cx = len of "clean" string
;Destroy: ax
;————————————————————————————————————————————————————————————————————————————————

get_string_length	proc

;start val of str_len
	mov ch, cl

	cmp ch, 10
	jbe @@end

	sub ch, 9

	@@end:

	xor ax, ax
	mov al, ch
	mov cx, ax

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————
;Print input string
;Enter  : cx = str_len
;Return : -
;Destroy: ax, si, cx, di

;————————————————————————————————————————————————————————————————————————————————

print_text	proc

	push bp

	xor ax, ax

; minimum 1 str
	mov dh, 1

;cl = dirty str_len
	mov cl, ds:[TERMINAL_DATA_SEG];
;cx = clean str_len
	call get_string_length
;bp = iteration counter
	mov bp, cx
;ch = str_len - 2
;cl = pos in str
	mov ch, dl
	sub ch, 2

	mov cl, 0

;3 line, 3 column
	mov si, STR_SIZE
	shl si, 1
	add si, 4

;start pos
	mov di, si

	mov si, TERMINAL_DATA_SEG
	add si, 10

	@@print_iteration:
		cmp cl, ch
		je @@goto_nest_string 

		mov al, ds:[si]
		mov ah, 12h

		mov word ptr es:[di], ax

		add di, 2
		inc si
		inc cl

		dec bp

		cmp bp, 0

		ja @@print_iteration

	jmp @@end_print

	@@goto_nest_string:

		mov byte ptr es:[di]  , '-'
		mov byte ptr es:[di+1], ah

;di += 160 - 4 - 2*str_len
;after di += 4 because we have a space and frame
		add di, STR_SIZE

		xor ax, ax
		mov al, dl
		shl al, 1

		sub di, ax

		add di, 4
;line += 1
		inc dh

		mov cl, 0

		cmp bp, 0

		ja @@print_iteration

	@@end_print:

	pop bp

	add dh, 2

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————————————————————
;Take regular symbol from ds and inc pos if sym == space
;Enter  : cx = pos in str
;Return : ax = new pos in str, after skipping spaces
;Destroy: cx
;————————————————————————————————————————————————————————————————————————————————

skip_space	proc

	@@skip_iteration:

;take next symbol
	mov al, ds:[cx]

;cur sym == space
	cmp al, ' '
;jump to end if sym not space
	jne @@and_skip_space

;pos++
	inc cx
;jmp to next iteration
	jmp @@skip_iteration

	@@and_skip_space:

	mov ax, cx

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————————————————————
;translate str to int (digit and hex)
;Enter  : cx = pos in (terminal) str
;Return : ax = parameter
;		: cx = new pos in str
;Destroy: ax, bl, cx
;————————————————————————————————————————————————————————————————————————————————

take_regular_parameter	proc

;skip spaces before new parameter
	call skip_space

;ax = new pos
	mov cx, ax

;clean ax, bx to count
	xor ax, ax
	xor bl, bl

	@@count_iter:

;take next symbol
		mov bl, ds:[cx]

;jump to end if it space
		cmp bl, ' '
		je @@end_next_params

;pos++
		inc cx

;jump if int hex
		cmp bl, '9'
		ja @@hex

;'9'->9
		sub bl, '0'
		jmp @@count

	@@hex:

;hex->10th
		sub bl, 'A'
		add bl, 10

	@@count:

;ax *= 10
		lea (ax, ax, 4)
		shl ax, 1

;ab = 10a + b
		add ax, bl

		jmp 

	@@end_next_params:

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————

end		Start