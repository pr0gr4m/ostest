[ORG 0x00]		; setting start code address 0x00
[BITS 16]		; setting code 16 bit

SECTION .text	; define text section(segment)

jmp 0x07C0:START		; assign 0x07C0 to CS register and jump to START label

; set configuration
TOTALSECTORCOUNT:	dw 0x02		; MINT64 OS image size except boot loader

KERNEL32SECTORCOUNT:	dw 0x02	; protect mode kernel sector number

; code area
START:
	mov ax, 0x07C0		; assign boot loader's start address(0x7C00) to segment register
	mov ds, ax			; set to DS register
	mov ax, 0xB800		; assign video memory's start address to segment register
	mov es, ax			; set to ES register

	; init stack
	mov ax, 0x0000		; stack start address
	mov ss, ax
	mov sp, 0xFFFE
	mov bp, 0xFFFE

	; clean screen
	mov si, 0			; init si register

.SCREENCLEARLOOP:
	mov byte [ es: si ], 0
	mov byte [ es: si + 1 ], 0x0A
	
	add si, 2
	cmp si, 80 * 25 * 2
	jl .SCREENCLEARLOOP
	
	; print start message
	push MESSAGE1		; push message address
	push 0				; push y coordinate
	push 0				; push x coordinate
	call PRINTMESSAGE
	add sp, 6			; remove parameter

	; print message that load OS image
	push IMAGELOADINGMESSAGE	; push message address
	push 1						; push y coordinate
	push 0						; push x address
	call PRINTMESSAGE
	add sp, 6					; remove parameter

	; OS image loading

	; reset before read disk
RESETDISK:
	; call BIOS Reset Function
	; service number 0, drive number 0 = Floppy
	mov ax, 0
	mov dl, 0
	int 0x13
	; error handle if error occured
	jc HANDLEDISKERROR

	; read disk sector
	; set address 0x10000 that is copied disk content
	mov si, 0x1000
	mov es, si
	mov bx, 0x0000

	mov di, word [ TOTALSECTORCOUNT ]

READDATA:
	cmp di, 0
	je READEND
	sub di, 0x1

	; call BIOS Read function
	mov ah, 0x02
	mov al, 0x1
	mov ch, byte [ TRACKNUMBER ]
	mov cl, byte [ SECTORNUMBER ]
	mov dh, byte [ HEADNUMBER ]
	mov dl, 0x00
	int 0x13
	jc HANDLEDISKERROR

	; calculate track, head, sector address
	add si, 0x0020
	mov es, si

	mov al, byte [ SECTORNUMBER ]
	add al, 0x01
	mov byte [ SECTORNUMBER ], al
	cmp al, 19
	jl READDATA

	xor byte [ HEADNUMBER ], 0x01
	mov byte [ SECTORNUMBER ], 0x01

	cmp byte [ HEADNUMBER ], 0x00
	jne READDATA

	add byte [ TRACKNUMBER ], 0x01
	jmp READDATA

READEND:

	; print to complete OS image
	push LOADINGCOMPLETEMESSAGE
	push 1
	push 20
	call PRINTMESSAGE
	add sp, 6

	jmp 0x1000:0x0000


; function code area

; handle disk error
HANDLEDISKERROR:
	push DISKERRORMESSAGE
	push 1
	push 20
	call PRINTMESSAGE

	jmp $
	
; print message function
; PARAM: x coord, y coord, string
PRINTMESSAGE:
	push bp
	mov bp, sp

	push es
	push si
	push di
	push ax
	push cx
	push dx

	; set video mode address to ES segment register
	mov ax, 0xB800
	mov es, ax

	; calculate video memory address
	; use y first
	mov ax, word [ bp + 6 ]
	mov si, 160
	mul si
	mov di, ax
	; use x then
	mov ax, word [ bp + 4 ]
	mov si, 2
	mul si
	add di, ax

	mov si, word [ bp + 8 ]

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

; data area
; start boot loader message
MESSAGE1:				db 'MINT64 OS Boot Loader Start!!', 0		; set 0 last to tell string's last
DISKERRORMESSAGE:		db 'DISK Error!!', 0
IMAGELOADINGMESSAGE:	db 'OS Image Loading...', 0
LOADINGCOMPLETEMESSAGE:	db 'Complete!!', 0

; variable on disk read
SECTORNUMBER:			db 0x02
HEADNUMBER:				db 0x00
TRACKNUMBER:			db 0x00

times 510 - ( $ - $$ )	db	0x00	; $: current line address
									; $$: current section(.text) start address
									; $ - $$: current section offset
									; 510 - ( $ - $$ ): from current to address 510
									; db 0x00: define 1 byte with 0x00
									; time: loop
									; fill 0x00 from current to address 510

db 0x55			; define 1 byte with 0x55
db 0xAA			; define 1 byte with 0xAA
				; mark boot sector to assign 0x55, 0xAA on address 511, 512
