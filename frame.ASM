.model tiny
.code

org 100h

STR_SIZE  equ 160d
VIDEO_MEM equ 0b800h

;————————————————————————————————————————————————————————————————————————————————
Start:	

;start of video mem
	mov ax, VIDEO_MEM
	mov es, ax

;start pos on the screen
	mov di, 0

	call read_frame_params	

	call print_frame

	mov ax, 4c00h
	int 21h

;————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————————————————————
;Print horizontal frame border
;Entry : es:di -> start of border
;		 cx     = symbols count
;		 al     = symbol to print
;		 bl     = color
; destroy si
;————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————————————————————
print_horizontal_border		proc

; make offset to new str in si
	mov si, STR_SIZE
	shl cx, 1
	sub si, cx
	shr cx, 1

	horizontal_border_iteration:

		mov byte ptr es:[di], al
		mov byte ptr es:[di+1], bl

		add di, 2
		dec cx

		jnz horizontal_border_iteration

	add di, si

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————————————————————
;Print vertical frame borders 
;Entry : es:di -> start of border
;		 dl     = string length
;		 cx		= border highth
;		 al     = symbol to print
;		 bl     = color
;destroy : si
;————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————————————————————
print_vertical_border		proc

	shl dx, 1 ; 2 bytes on symbol

	mov si, STR_SIZE ; si = 160
	sub si, dx	     ; si = offset to and of str
	sub si, 4		 ; 2 symbols from border (left and right)

	@@vertical_border_iteration:

		mov byte ptr es:[di],   al ;print first symbol
		mov byte ptr es:[di+1], bl

		add di, 2  ; first symbol
		add di, dx ; pos for last symbol

		mov byte ptr es:[di],   al ;print last symbol
		mov byte ptr es:[di+1], bl

		add di, 2  ; last symbol
		add di, si ; offset to new str

		dec cx

		jnz @@vertical_border_iteration
		
	shr dx, 1

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————————————————————
;Print full frame
;Entry : es:di -> start of border
;		 dl     = string length
;		 cx		= border highth
;		 al     = symbol to print
;		 bl     = color
;destroy : si
;————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————————————————————
print_frame	proc

;save hight
	mov bp, cx

;print_horizontal_border take str_len in cx
;add 2 to str_len because we have 2 symbols in frame border
	mov cx, dx
	add cx, 2

	call print_horizontal_border

;return frame hight to cx
	mov cx, bp

	call print_vertical_border

;print_horizontal_border take str_len in cx
;add 2 to str_len because we have 2 symbols in frame border
	mov cx, dx
	add cx, 2

	call print_horizontal_border

;return cx
	mov cx, bp

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————————————————————
;Read frame params from terminal
;Entre:   -
;Return:  cl = len of input terminal string (with all params)
;		  ax = symbol
;		  bx = color
;Destroy: -
;————————————————————————————————————————————————————————————————————————————————
read_frame_params	proc
mov cx, bp

	call print_vertical_border
;clean cx
	xor cx, cx

;mov params len to cx
	mov cl, ds:[80h]

;user given zero params
	cmp cx, 0
	je @@no_len

	call take_usr_str_len

;len that use user
	mov dx, ax

;no user sym
	cmp cx, 5
	jb @@no_sym

	mov ax, ds:[85h]

	cmp cx, 8h
	jb @@no_sym

	call take_frame_color

	jmp @@end_frame_params

	@@no_len:
		mov dx, 20d
		mov cx, 10d
	@@no_sym:
		mov al, '$'
	@@no_color:
		mov bl, 07h
	
	@@end_frame_params:

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————————————————————
;Take str len t	hat user given to prog
;Enter   : nothing
;return  : ax = usr_str_len
;destroy : bx
;————————————————————————————————————————————————————————————————————————————————
take_usr_str_len	proc

; clean ax
	xor ax, ax

;take first symbol
	mov al, ds:[82h]
	sub al, '0'

;multiplication first digit to ten
	mov bl, 0ah
	mul bl

;take second sym
	mov bl, ds:[83h]
	sub bl, '0'

;10a + b
	add al, bl

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————————————————————
;Take frame color
;Enter   : nothing
;return  : bl = color
;destroy : si
;————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————————————————————
take_frame_color	proc

	mov bx, ds:[87h]
	mov si, ds:[88h]

;first = num or alpha
	cmp bx, 9
	ja @@first_hex

;'9' - '0' for take num
	sub bx, '0'
	jmp @@second

	@@first_hex:

;hex -> d
		sub bx, 'A'
		add bx, 10d

	@@second:

		cmp si, 9
		ja @@second_hex

		sub si, '0'
		jmp @@final_add

	@@second_hex:

		sub si, 'A'
		add si, 10d

	@@final_add:

; == * 16
	shl bx, 4

	add bx, si

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————————————————————
;Get string (that will be printed) length
;Enter:  cl = len of "dirty" string
;Return: ch = len of "clean" string
;————————————————————————————————————————————————————————————————————————————————

get_string_length	proc

	
end		Start