; print message function
; PARAM: x, y, str

PRINTMESSAGE:
	push bp
	mov bp, sp

	push es
	push si
	push di
	push ax
	push cx
	push dx

	mov ax, 0xB800
	mov es, ax

	mov ax, word [ bp + 6 ]		; assign param 2 (y) to AX register
	mov si, 160					; mul one line's bytes (2 * 80 cul) to SI register
	mul si						; mul AX register to SI register, calculate y address
	mov di, ax					; set DI address

	mov ax, word [ bp + 4 ]		; assign param 1 (x) to AX register
	mov si, 2					; mul one character bytes (2) to SI register
	mul si						; mul AX register to SI register, calculate x address
	add di, ax					; set DI address

	; string address that prints
	mov si, word [ bp + 8 ]		; param 3 (str)

.MESSAGELOOP:
	mov cl, byte [ si ]
	cmp cl, 0
	je .MESSAGEEND

	mov byte [ es: di ], cl

	add si, 1
	add di, 2

	jmp .MESSAGELOOP

.MESSAGEEND:
	pop dx
	pop cx
	pop ax
	pop di
	pop si
	pop es
	pop bp
	ret
