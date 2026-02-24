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

STR_SIZE          equ 00A0h
VIDEO_MEM         equ 0b800h
TERMINAL_DATA_SEG equ 80h
NUM_PARAMS        equ 13
NUM_SYM_PARAMS    equ 9
TERMINAL_HIGH     equ 25
NUM_TICS		  equ 200

;————————————————————————————————————————————————————————————————————————————————
Start:

	jmp Main

strLEN            db 0
frameHIGH   	  db 0
textCOLOR 		  db 40
frameCOLOR 	      db 50
interiorSYM_COLOR db 70

	Main:

	call take_colors

	call take_frame_size

	mov ax, VIDEO_MEM
	mov es, ax

	call print_frame
	call print_frame_text

	mov ax, 4c00h	
	int 21h

;————————————————————————————————————————————————————————————————————————————————
;Wait specified time

;Enter  : si = num of tics (tic = 55ms)

;Return : -

;Destroy: -
;————————————————————————————————————————————————————————————————————————————————
make_delay      proc

;save registers values
    push ax bx cx dx

    add bx, si
	adc ax, 0

	@@norm_iter:

		mov ax, NUM_TICS

		dec bx
	
		@@mini_iter:
			dec ax
			cmp ax, 0
			ja @@mini_iter

		cmp bx, 0
		ja @@norm_iter

;return previous registers values
    pop dx cx bx ax

    ret
    endp

;————————————————————————————————————————————————————————————————————————————————
;Take input str length and replace pos to start of str

;Enter  : -

;Return : bx = pos of start of input string
;		: ax = str len

;Destroy: ax, bx, cx, dl
;————————————————————————————————————————————————————————————————————————————————

take_input_strlen      proc

	call skip_all_params
	call skip_space

	xor ax, ax

;si == input data size
    mov al, ds:[TERMINAL_DATA_SEG]

;si == input string size
;al = len of input data
    add ax, TERMINAL_DATA_SEG + 1
;cl = pos = TERMINAL_DATA_SEG + len of params
    sub ax, bx

    ret
    endp

;————————————————————————————————————————————————————————————————————————————————
;Count number of lines by length and \n symbols

;Enter  : -

;Return : dh = num of lines
;         si = input string length

;Destroy: ax, bx, cx, si
;————————————————————————————————————————————————————————————————————————————————

count_lines     proc

;take len and pos in input data
    call take_input_strlen

;min value, not empty frame
	mov dh, 0

	mov si, ax

    xor ax, ax

;si = strlen == 0?
    cmp si, 0
    je @@end_lines_counter

    @@count_iter:

        mov al, ds:[bx]

        cmp al, '\'
        je @@n_str_sym

    @@regular_symbol:

        mov al, ds:[bx]

;num of iterations--
        dec si

;pos in current str++
        inc ah

;pos in ds++
        inc bx

;pos in current str = strlen -> lines++
        cmp ah, strLEN
        je @@new_str

		cmp si, 0
        ja @@count_iter

		jmp @@end_lines_counter

    @@n_str_sym:

        mov al, ds:[bx+1]
        cmp al, 'n'
        jne @@regular_symbol

;pos in input string += 2
        add bx, 2
;num of iterations -= 2 (\n)
		sub si, 2



    @@new_str:

;lines++
            inc dh

;num of symbols in current string
            mov ah, 0

			cmp si, 0
			ja @@count_iter

    @@end_lines_counter:

;add not full last str
        cmp ah, 0
        je @@ret_lines

        inc dh

    @@ret_lines:

    ret
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
;Print line with specified length in specified place
;Printing stopping in founded '\n' and fill end of str by spaces

;Enter  : di = pos on the screen
;       : bx = pos in ds (there we take a string)
;		: si = pos of last symbol in ds

;Return : bx = new pos on the screen

;Destroy: ax, cx, bp
;————————————————————————————————————————————————————————————————————————————————

print_line  proc

	xor bp, bp
	xor ax, ax

;ax = 2 * str_len
	mov al, strLEN
	shl ax, 1
;cx = offset to new string == 160 - 2 * str_len
	mov cx, STR_SIZE
	sub cx, ax

    @@print_line_iteration:

;ah == symbol color
        mov ah, textCOLOR

;take regular symbol
        mov al, ds:[bx]

;symbol == '\'
        cmp al, '\'
        je @@comp_new_str

    @@regular_sym:

;take regular symbol
        mov al, ds:[bx]

;pos in ds++
        inc bx

		push si
		mov si, 1500
		call make_delay
		pop si

        call put_char

;number of printed symbols++
        inc bp

		cmp bx, si
		je @@fill_by_spaces

;bp haven`t low part so to cmp num of printed symbols and num of symbols that need to print we
;mov bp to ax, and then compare to make new iterations
        mov ax, bp
        cmp al, strLEN
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

        @@fill_by_spaces:

;print space
            mov al, ' '
            mov ah, textCOLOR

			push si
			mov si, 1
			call make_delay
			pop si

            call put_char
;num of printed symbols++
            inc bp
;cmp printed symbol with num of symbols that need to print
            mov ax, bp
            cmp al, strLEN
            jb @@fill_by_spaces

    @@print_line_end:

	add di, cx

    ret
    endp

;————————————————————————————————————————————————————————————————————————————————
;Take regular symbol from ds and inc pos if sym == space
;Enter  : bx = pos in str
;Return : bx = new pos in str, after skipping spaces
;Destroy: al, bx
;————————————————————————————————————————————————————————————————————————————————

skip_space	proc

	@@skip_iteration:

;take next symbol
	mov al, ds:[bx]

;cur sym == space
	cmp al, ' '
;jump to end if sym not space
	jne @@and_skip_space

;pos++
	inc bx
;jmp to next iteration
	jmp @@skip_iteration

	@@and_skip_space:

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————
;translate str to int (digit and hex)

;Enter  : bx = pos in (terminal) str

;Return : ax = parameter
;		: bx = new pos in str

;Destroy: ax, bx, cx, dl
;————————————————————————————————————————————————————————————————————————————————

str_to_i	proc

;skip spaces before new parameter
	call skip_space

;clean ax, bx to count
	xor ax, ax
	xor dl, dl

	@@count_iteration:

;take next symbol
		mov dl, ds:[bx]

;jump to end if it space
		cmp dl, ' '
		je @@end_next_params

;pos++
		inc bx

		sub dl, '0'

;ax *= 10
		mov cx, ax
		shl cx, 1
		shl ax, 3
		add ax, cx

;ab = 10a + b
		add al, dl

		jmp @@count_iteration

	@@end_next_params:

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————
;translate str to hex

;Enter  : bx = pos in (terminal) str

;Return : ax = parameter
;		: bx = new pos in str

;Destroy: ax, bx, cx, dl
;————————————————————————————————————————————————————————————————————————————————

str_to_hex	proc

;skip spaces before new parameter
	call skip_space

;clean ax, bx to count
	xor ax, ax
	xor dl, dl

	@@hex_count_iteration:

;take next symbol
		mov dl, ds:[bx]

;jump to end if it space
		cmp dl, ' '
		je @@hex_end_next_params

;pos++
		inc bx

;jump if int hex
		cmp dl, '9'
		ja @@hex

;'9'->9
		sub dl, '0'
		jmp @@hex_count

	@@hex:

;hex->10th
		sub dl, 'A'
		add dl, 10

	@@hex_count:

;ax *= 16
		shl ax, 4

;ab = 10a + b
		add al, dl

		jmp @@hex_count_iteration

	@@hex_end_next_params:

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————
;Take symbol parameter and increment pos

;Enter  :bx = pos in ds

;Return :al = symbol
;		:bx = new_pos

;Destroy: cx
;————————————————————————————————————————————————————————————————————————————————

take_sym_parameter		proc

	call skip_space

;take sym
	mov al, ds:[bx]
;pos++
	inc bx

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————
;Skip all params in ds

;Enter  : -

;Return : bx = pos in ds (after all params)

;Destroy: ax, bx, cx, dl
;————————————————————————————————————————————————————————————————————————————————

skip_all_params		proc

	mov bx, 81h

;str len
	call str_to_i

	mov dx, NUM_SYM_PARAMS

	@@skip_symbols:

		call take_sym_parameter

		dec dx

		cmp dx, 0
		ja @@skip_symbols

;3 colors
	call str_to_hex
	call str_to_hex
	call str_to_hex

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————
;Print frame line
;It takes 7 params: start pos, strlen, left symbol, middle, right, color of left and right sym, color of middle

;Enter  : di bx = start pos on the screen
;		: ch = left sym
;		: cl = right sym
;		: dl = middle sym
;		: dh = color of middle

;Return : bx = new pos on the screen

;Destroy: ax, si
;————————————————————————————————————————————————————————————————————————————————

print_frame_line		proc

	push bp

	xor ax, ax
	mov al, STR_SIZE

;si = offset to new str
;si == 160
	mov si, ax
;2 bytes on sym
	mov al, strLEN
	sub si, ax
	sub si, ax
;2 left symbols and 2 right symbols 
	sub si, 8

;num of iterations
	mov bp, ax
;2 skips after frame border
	add bp, 2

;left sym
	mov ah, frameCOLOR
	mov al, ch

;print left sym
	call put_char

;middle sym
	mov ah, dh
	mov al, dl

	@@frame_line_iter:

		call put_char
		dec bp

		cmp bp, 0
		ja @@frame_line_iter

;right sym
	mov ah, frameCOLOR
	mov al, cl

;print right sym
	call put_char

;go to new str
	add di, si

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

	mov bx, TERMINAL_DATA_SEG + 1

;skip first parameter
	call str_to_i

;3 params to first line
	call take_sym_parameter
	mov ch, al

	call take_sym_parameter
	mov dl, al

	call take_sym_parameter
	mov cl, al

	xor ax, ax
	mov al, TERMINAL_HIGH

;color of middle part
	mov dh, frameCOLOR
;di = start pos on the screen
	mov di, si

	call print_frame_line

;3 params to first line
	call take_sym_parameter
	mov ch, al

	call take_sym_parameter
	mov dl, al

	call take_sym_parameter
	mov cl, al

	xor ax, ax
	mov al, frameHIGH

;num of iterations
	mov bp, ax
;2 empty str, highest asn lowest
	add bp , 2
	mov dh, interiorSYM_COLOR

	@@print_line_iter:

		call print_frame_line
		dec bp

		cmp bp, 0
		ja @@print_line_iter

	call take_sym_parameter
	mov ch, al

	call take_sym_parameter
	mov dl, al

	call take_sym_parameter
	mov cl, al

	mov dh, frameCOLOR

	call print_frame_line

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————
;Take colors from ds

;Enter  : -

;Return : colors in variables

;Destroy: ax, bx, cx, dl
;————————————————————————————————————————————————————————————————————————————————
take_colors		proc

;start pos in ds
	mov bx, TERMINAL_DATA_SEG + 1

	call str_to_i

	mov dx, NUM_SYM_PARAMS

	@@skip_symbols_iter:

		call take_sym_parameter

		dec dx

		cmp dx, 0
		ja @@skip_symbols_iter

	call str_to_hex
	mov frameCOLOR, al

	call str_to_hex
	mov interiorSYM_COLOR, al

	call str_to_hex
	mov textCOLOR, al

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————
;Take frame size and mov them to variables

;Enter  : -

;Return : size in strLen and high in frameHigh

;Destroy: ax, bx, cx, si, dl
;————————————————————————————————————————————————————————————————————————————————

take_frame_size		proc

	mov bx, TERMINAL_DATA_SEG + 1

	call str_to_i

	mov strLEN, al

	call count_lines

	mov frameHIGH, dh

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————
;Count start pos to print frame

;Enter  : -

;Return : si = pos

;Destroy: ax
;————————————————————————————————————————————————————————————————————————————————

count_frame_start_pos		proc

;al = (25 - high - 2) / 2
	xor ax, ax
	mov al, TERMINAL_HIGH
	sub al, frameHIGH
	sub al, 2
	shr al, 1

;al = al * 160

	mov cx, STR_SIZE
	mul cx
	mov si, ax

;al = (80 - 4 - str_len) / 2 * 2
	xor ax, ax
	mov al, 80d
	sub al, strLEN
	sub al, 4
	shr al, 1
	shl al, 1

	add si, ax

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————
;Count start pos to print text in frame

;Enter  : -

;Return : si = pos

;Destroy: ax
;————————————————————————————————————————————————————————————————————————————————
count_text_start_pos	proc

	call count_frame_start_pos

	add si, STR_SIZE
	add si, STR_SIZE

	add si, 4

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————

print_frame_text	proc

	call count_text_start_pos

;start pos on the screen
	mov di, si

	call take_input_strlen

	;si = last sym pos
	mov si, ax
	add si, bx

	@@text_iter:
	
;bx == si == end
	cmp bx, si
	jae @@enp_print_text

	call print_line
	jmp @@text_iter

	@@enp_print_text:

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————

end		Start