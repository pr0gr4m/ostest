TOTALSECTORCOUNT:	dw	1024	; MINT64 OS image size
SECTORNUMBER:		db	0x02	; start sector number
HEADNUMBER:			db	0x00	; start head number
TRACKNUMBER:		db	0x00	; start track number

	; set ES:BX 0x10000 that copys disk content
	mov si, 0x1000				; assign address 0x10000 that will be copied OS image to segment register
	mov es, si
	mov bx, 0x0000

	mov di, word [ TOTALSECTORCOUNT ]	; assign OS image sector count to DI register

READDATA:						; reading disk code routine start
	; check reading all data
	cmp di, 0
	je READEND
	sub di, 0x1

	; Call BIOS Read Function
	mov ah, 0x02				; BIOS service number 2 (Read Sector)
	mov al, 0x1					; read 1 sector
	mov ch, byte [ TRACKNUMBER ]	; set track number
	mov cl, byte [ SECTORNUMBER ]	; set sector number
	mov dh, byte [ HEADNUMBER ]		; set head number
	mov dl, 0x00				; set drive number (Floppy)
	int 0x13					; start interupt service
	jc HANDLEDISKERROR			; if error occured, jump

	; calculate address, track, head, sector
	add si, 0x0020				; add 512(reading) bytes to si register
	mov es, si

	; increment sector and check that is last
	; if not, jump to read
	mov al, byte [ SECTORNUMBER ]	; set AL register with sector number
	add al, 0x01					; increment sector
	mov byte [ SECTORNUMBER ], al
	cmp al, 19
	jl READDATA

	; if last, togle head and set sector 1
	xor byte [ HEADNUMBER ], 0x01
	mov byte [ SECTORNUMBER ], 0x01

	; if head change 1 to 0, complete to read both sides header
	; so increment track number
	cmp byte [ HEADNUMBER ], 0x00
	jne READDATA

	add byte [ TRACKNUMBER ], 0x01
	jmp READDATA
READEND:

HANDLEDISKERROR:
