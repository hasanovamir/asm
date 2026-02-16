.model tiny
.code

org 100h

STR_SIZE equ 160d

;————————————————————————————————————————————————————————————————————————————————
Start:	
	mov ax, 0b800h; start of video mem
	mov es, ax

	mov di, 0	  ; pos in str

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

	mov si, STR_SIZE
	shl cx, 1
	sub si, cx
	shr cx, 1         ; make offset to new str in si

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

	vertical_border_iteration:

		mov byte ptr es:[di],   al ;print first symbol
		mov byte ptr es:[di+1], bl

		add di, 2  ; first symbol
		add di, dx ; pos for last symbol

		mov byte ptr es:[di],   al ;print last symbol
		mov byte ptr es:[di+1], bl

		add di, 2  ; last symbol
		add di, si ; offset to new str

		dec cx

		jnz vertical_border_iteration
		
	shr dl, 1

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————————————————————
;Print full frame
;Print vertical frame borders 
;Entry : es:di -> start of border
;		 dl     = string length
;		 cx		= border highth
;		 al     = symbol to print
;		 bl     = color
;destroy : si
;————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————————————————————
print_frame	proc

	push cx ; save hight

	mov cx, dx

	add cx, 2 ; symbols from vertical border

	call print_horizontal_border

	pop cx

	call print_vertical_border

	mov cx, dx

	add cx, 2

	call print_horizontal_border

	pop cx

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————

read_frame_params	proc

	mov cx, ds:[80h] ; mov params len to cx
	cmp cx, 0
	je no_len

	call take_usr_str_len

	mov dx, ax ; len that use user

	cmp cx, 5  ; no user sym
	jb no_sym

	mov ax, ds:[85h]

	cmp cx, 8h  ; if
	jb no_sym

	call take_frame_color

	jmp end_frame_params

	no_len:
		mov dx, 20d
	no_sym:
		mov al, '$'
	no_color:
		mov bl, 07h
	
	end_frame_params:

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————

;————————————————————————————————————————————————————————————————————————————————
;Take str len that user given to prog
;Enter   : nothing
;return  : ax = usr_str_len
;destroy : bx
;————————————————————————————————————————————————————————————————————————————————
take_usr_str_len	proc
	
	xor ax, ax; clean ax

	mov al, ds:[82h]
	sub al, '0'

	mov bl, ds:[83h]
	sub bl, '0'

	mul 0ah
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

	cmp bx, 9    ; if first = num or alpha
	ja first_hex ; if first = alpha

	sub bx, '0'  ; '9' - '0' for take num

	first_hex:

		sub bx, 'A' ; 'B' - 'A' = 1 
		add bx, 10d  ; + 10 = 11

	cmp si, 9     ; if second = num or alpha
	ja second_hex ; if second = alpha

	sub si, '0'

	second_hex:

		sub si, 'A'
		add si, 10d

	shl bx, 4 ; == * 16

	add bx, si ; now we got hex num

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————

end		Start