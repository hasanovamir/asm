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

	mov al, ds:[TERMINAL_DATA_SEG]
	mov ah, 54
	mov word ptr es:[0], ax

;start pos on the screen
	mov di, 0

	call read_frame_params	

	call print_text

	call print_frame

	mov ax, 4c00h	
	int 21h

;————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————————————————————
;Print horizontal frame border
;Entry : es:di -> start of border
;		 dl     = str_len
;		 bh     = symbol to print
;		 bl     = color
; destroy ax, si, cx
;————————————————————————————————————————————————————————————————————————————————

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
;Read frame params from terminal
;Entre:   -
;Return:  cl = len of input terminal string (with all params)
;		  bl = symbol
;		  bh = color
;		  dl = string len
;Destroy: -
;————————————————————————————————————————————————————————————————————————————————
read_frame_params	proc

;clean cx
	xor cx, cx

;mov params len to cx
	mov cl, ds:[TERMINAL_DATA_SEG]

;user given zero params
	cmp cx, 0
	je @@no_len

	call take_usr_str_len

;len that use user
	mov dl, al

;no user sym
	cmp cx, 5
	jb @@no_sym

;take sym
	mov bl, ds:[TERMINAL_DATA_SEG+5]

	cmp cx, 8h
	jb @@no_sym

	call take_frame_color

	jmp @@end_frame_params

	@@no_len:
		mov dl, 20d
		mov dh, 10d
	@@no_sym:
		mov bl, '$'
	@@no_color:
		mov bh, 32h
	
	@@end_frame_params:

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————————————————————
;Take str len that user given to prog
;Enter   : nothing
;return  : dl = usr_str_len
;destroy : ax
;————————————————————————————————————————————————————————————————————————————————
take_usr_str_len	proc

; clean ax
	xor ax, ax

;take first symbol
	mov al, ds:[TERMINAL_DATA_SEG+2]
	sub al, '0'

;multiplication first digit to ten
	mov dl, 0ah
	mul dl

;take second sym
	mov dl, ds:[TERMINAL_DATA_SEG+3]
	sub dl, '0'

;10a + b
	add al, dl

	mov dl, al
	ret
	endp

;————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————————————————————
;Take frame color
;Enter   : nothing
;return  : bl = color
;destroy : ax
;————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————————————————————
take_frame_color	proc

	mov al, ds:[TERMINAL_DATA_SEG+7]
	mov bh, ds:[TERMINAL_DATA_SEG+8]

;first = num or alpha
	cmp al, '9'
	ja @@first_hex

;'9' - '0' for take num
	sub al, '0'
	jmp @@second

	@@first_hex:

;hex -> d
		sub al, 'A'
		add al, 10d

	@@second:

		cmp bh, '9'
		ja @@second_hex

		sub bh, '0'
		jmp @@final_add

	@@second_hex:

		sub bh, 'A'
		add bh, 10d

	@@final_add:

; == * 16
	shl al, 4

	add bh, al

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

end		Start