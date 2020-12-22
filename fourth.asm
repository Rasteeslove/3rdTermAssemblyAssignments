.model small
.stack 100h
.data

	mssg1 db 'Enter the s-space-p string: $'
	mssg_err db 'The string is of invalid format.$'
	yay db 'yes$'
	nah db 'no$'
	crlf db 13, 10, '$'
	
	max_len db 20
	s_p db 21 dup ('$')

ostr macro msg

	push ax
	push dx

	mov ah, 09h
	lea dx, msg
	int 21h
	
	pop dx
	pop ax
	
endm ostr
	
.code

main:

    mov ax, @data
	mov ds, ax
	mov es, ax

	xor cx, cx
	xor dx, dx
	
	cld
	
	ostr mssg1

	lea di, s_p
	
gc_cyc: ; get char cycle

	mov ah, 08h ; getchar w/o echo
	int 21h
	
	; is it enter?
	cmp al, 13
	je ent_prsd
	cmp al, 10
	je ent_prsd
	
	; is it space?
	cmp al, ' '
	je spc_prsd
	
	; finally - is the char in the legal [a-z] range?
	cmp al, 'a'
	jb gc_cyc
	
	cmp al, 'z'
	ja gc_cyc

  c_is_lgl: ; char is legal
	
	stosb ; saving it to the string
	
	inc cl ; strlen++
	
	; printing the entered char
	mov ah, 02h
	
	push dx
	xor dx, dx
	mov dl, al
	
	int 21h
	
	pop dx
	
	; now let's check if the last pressed char is the last possible one
	
	cmp cl, max_len ; check if the string is full
	je ex_gc ; if it is then moving on to the next stage w/o enter pressed
	
	jmp gc_cyc
	
spc_prsd: ; space pressed so we are to check if it is legal. basically check if space was pressed already

	; check if space was pressed
	cmp ch, 0
	jne gc_cyc
	
	; so yeah - it is the first space so...
	mov ch, 1 ; setting flag that the space was pressed
	
	mov dl, cl ; saving p position in s_p
	inc dl
	
	jmp c_is_lgl

ent_prsd: ; enter pressed so we are to check if it is legal depending on the current string
	
	; check if space was pressed
	cmp ch, 0
	je gc_cyc
	
	; space is pressed indeed so enter is legal
	
ex_gc: ; exit getting chars

	cmp ch, 0
	jne fmt_fine
	
	; space is apsent in s_p - that's invalid format
	
	ostr crlf
	ostr mssg_err
	jmp exit
	
fmt_fine: ; string format is fine

; the string analysing stage :
; at this point enter is pressed and we are to determine if s is within p
	
	; p position in s_p is in dx ; it is at least 1 ; s length is hence dx - 1
	
	lea bx, s_p
	mov di, bx
	add di, dx
	dec dl
	
	; check if s length is 0; if it is then say yes
	cmp dl, 0
	je s_found
	
fs_cyc: ; find s (in p) cycle

	cmp byte ptr [di], '$'
	je ex_fs
	
	call pref
	
	cmp dl, dh
	je s_found
	
	add di, 1

	jmp fs_cyc
	
s_found:

	ostr crlf
	ostr yay
	jmp exit

ex_fs:

	; s is not within p
	ostr crlf
	ostr nah
	jmp exit

exit:
	
    mov ax, 4c00h
    int 21h

; P R O C E D U R E S :

; prefix function for the algorithm
; args : bx - s address, di - p[i] address
; output : dh
pref proc

	push bx
	push di
	push cx

	xor dh, dh
	
pref_cyc:

	mov cl, [bx]
	mov ch, [di]
	
	cmp cl, ch
	jne pref_ex
	
	inc dh
	add bx, 1
	add di, 1
	
	jmp pref_cyc
	
pref_ex:

	pop cx
	pop di
	pop bx

	ret

pref endp
	
end main
