.model small
.stack 100h
.data

	old_handler dd ?

.code
	
main:
	
	mov ax, @data
	mov ds, ax
	
	push es
	xor ax, ax
	mov es, ax
	
	; saving old handler :
	mov ax, word ptr es:[09h * 4]
	mov word ptr old_handler, ax
	mov ax, word ptr es:[09h * 4 + 2]
	mov word ptr old_handler + 2, ax
	
	; setting new handler :
	mov ax, cs
	mov word ptr es:[09h * 4 + 2], ax
	mov ax, offset new_handler
	mov word ptr es:[09h * 4], ax
	
	pop es
	
; get char cycle

	mov ah, 01h
cyc:
	
	int 21h
	cmp al, 27 ; check if the char is esc
	jne cyc
	
enter_pressed:
	
	push es
	
	; restoring old handler :	
	xor ax, ax
	mov es, ax
	
	mov ax, word ptr old_handler + 2
	mov word ptr es:[09h * 4 + 2], ax
	mov ax, word ptr old_handler
	mov word ptr es:[09h * 4], ax
	
	pop es
	
	mov ax, 4c00h
	int 21h
	
	new_handler:
	
	push es ds si di ax bx cx dx ; saving registers' values
	
	in al, 60h ; retrieve the code of the pressed key into al
	
	; looking for vowels :
	
	cmp al, 12h ; e
	je vowel_found
	
	cmp al, 16h ; u
	je vowel_found
	
	cmp al, 17h ; i
	je vowel_found
	
	cmp al, 18h ; o
	je vowel_found
	
	cmp al, 1eh ; a
	je vowel_found
	
	; vowels not found
	
	pop dx cx bx ax di si ds es ; restoring registers' values
	jmp dword ptr cs:old_handler ; and doing whatever default handler does
	
vowel_found:
	
	mov al, 20h
	out 20h, al
	
	pop dx cx bx ax di si ds es ; restoring registers' values
	iret
	
end