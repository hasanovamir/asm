.model tiny
.code

org 100h

STR_SIZE equ 160d

;————————————————————————————————————————————————————————————————————————————————
Start:	
	mov ax, 0b800h; start of video mem
	mov es, ax

	mov di, 0	  ; pos in str

	mov dx, 6
	mov cx, 5
	mov al, '$'
	mov bl, 07

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

	mov cl, ds:[80h]
	cmp cl, 0
	je no_params

	mov al, ds[82h]


	no params:
		mov al, '$'
		mov bl, 07

	ret
	endp

;————————————————————————————————————————————————————————————————————————————————

end		Start