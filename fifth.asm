.model small
.stack 100h
.data

	mssg1 db 'Enter the first matrix: $'
	mssg2 db 'Enter the second matrix: $'
	mssg12 db 'The multiplication matrix is: $'
	
	space db ' $'
	crlf db 13, 10, '$'
	
	base dw 10
	
	mtrx1 dw 100 dup (?)
	mtrx1_r db 2
	mtrx1_c db 2
	
	mtrx2 dw 100 dup (?)
	mtrx2_r db 2
	mtrx2_c db 2
	
	mtrx12 dw 100 dup (?)

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
	
	; first matrix input
	
	ostr mssg1
	ostr crlf
	
	lea bx, mtrx1
	mov dh, mtrx1_r
	mov dl, mtrx1_c
	
	call imtrx
	
	ostr crlf
	
	; second matrix input
	
	ostr mssg2
	ostr crlf
	
	lea bx, mtrx2
	mov dh, mtrx2_r
	mov dl, mtrx2_c
	
	call imtrx
	
	ostr crlf
	
	; matrix multiplication here
	
	xor si, si
	xor cx, cx
	mov cl, mtrx1_r
	
cycle1:
	
	push cx
	mov cl, mtrx2_c
	
	cycle2:
	
		push cx
		mov cl, mtrx1_c
		dec cl
		
		; i = (si / 2) / mtrx2_c
		; j = (si / 2) % mtrx2_c
			
		mov bx, 2
			
		mov ax, si
		div bl
		div mtrx2_c
		
		mov dx, ax
		
		xor ax, ax
		
		cycle3:
			
			push dx
			mov bx, 2
			
			push ax ; saving current sum
			
			; so now i is in dl, j is in dh
			
			push si
			
			; calculate mtrx1[i][cl] * mtrx2[cl][j] into ax
			; si = (i * mtrx1_c + cl) * 2
			; bx = (cl * mtrx2_c + j) * 2
			
			xor ax, ax
			mov al, dl
			mul mtrx1_c
			add ax, cx
			mul bl ; which is still 2
			
			mov si, ax ; si now contains the pointer to mtrx1[i][cl]
			
			
			
			; bx = (cl * mtrx2_c + j) * 2
			
			mov ax, cx
			mul mtrx2_c
			add al, dh
			mul bl
			
			mov bx, ax ; bx now contains the pointer to mtrx2[cl][j]
		
			mov ax, mtrx1[si]
			imul mtrx2[bx]
			
			pop si
			pop dx
			
			add ax, dx
			
			dec cx
			pop dx
			
			cmp cx, 0ffffh
			je ex_cyc3
			
			jmp cycle3
			
			ex_cyc3:
			
		mov mtrx12[si], ax
		
		inc si
		inc si
			
		pop cx
	
		loop cycle2
	
	pop cx
	
	loop cycle1
	
	; multiplication matrix output
	
	ostr mssg12
	ostr crlf
	
	lea bx, mtrx12
	mov dh, mtrx1_r
	mov dl, mtrx2_c
	
	call omtrx
	
exit:
	
    mov ax, 4c00h
    int 21h
	
; ==============================================================
; ==================== P R O C E D U R E S =====================
; ==============================================================

; kind of a problem : imtrx and omtrx use global base variable though it should be an argument imo 
; could be resolved in 20-50 lines of code or so of fiddling around with the registers

; imtrx = input matrix (of signed integers)
; args : dimensions in dl and dh, array address in bx
imtrx proc

	push ax
	push cx
	push si
	
	xor si, si
	xor cx, cx
	mov cl, dh
	
im_extrn:

	push cx
	mov cl, dl
	
	im_intrn:
	
		push bx
		
		mov bx, base
		call isint
		
		pop bx
		
		mov [bx][si], ax
		
		ostr space
		
		inc si
		inc si
		
		loop im_intrn
		
	ostr crlf
	
	pop cx

	loop im_extrn
	
	pop si
	pop cx
	pop ax

	ret

imtrx endp

; omtrx = output matrix (of signed integers)
; args : dimensions in dl and dh, array address in bx
omtrx proc

	push ax
	push cx
	push si
	
	xor si, si
	xor cx, cx
	mov cl, dh
	
om_extrn:

	push cx
	mov cl, dl
	
	om_intrn:
	
		mov ax, [bx][si]
		
		push bx
		
		mov bx, base
		
		call osint
		
		pop bx
		
		ostr space
		
		inc si
		inc si
		
		loop om_intrn
		
	ostr crlf
	
	pop cx

	loop om_extrn
	
	pop si
	pop cx
	pop ax
	
	ret

omtrx endp

; ISINT = input signed integer procedure facilitates 8-bit ...
;         ... signed integer input with the same validation ...
;         ... and same everything as in the IUINT procedure .

; remarks : this proc is slightly modified isint from 3rd lab assignment ...
;           ... - this one gets ints in [-127; 128] range to minimize overflow ... 
;           ... when multiplying matrices .

isint proc

	push cx ; saving registers'
	push dx ; values

	;   ax is whatever
	;   bx is argument [base]
	xor cx, cx ; CL to store num of digits ; CH to indicate minus
	xor dx, dx ; DX is the buffer register for operations in this proc
	push dx ; cause the number is atop the stack all the time

idigcyc: ; input digit cycle

	mov ah, 08h ; getchar w/o echo
	int 21h
	
	; ------------------------- VALIDATION --------------------------
	
	cmp al, '0'
	jb isiservs ; if AL < '0' than it might be BACKSPACE or ENTER
	
	cmp al, 'z'
	ja idigcyc ; if AL > 'z' than it is some garbage
	
	cmp al, 'a'
	jb idignsl
	
	; so it's in [a ; z] interval
	sub al, 39 ; move it to digits
	jmp idigverc
	
  idignsl: ; input digit < than small letters in ascii
	
	cmp al, 'Z'
	ja idigcyc ; input digit is between [A ; Z] and [a ; z]
	
	cmp al, 'A'
	jb idignbl
	
	; so it's in [A ; Z] interval
	sub al, 7
	jmp idigverc
	
  idignbl: ; input digit < than big letters in ascii
  
    cmp al, '9'
	ja idigcyc ; input digit is between [0 ; 9] and [A ; Z]
	
	; at this point AL is in [0 ; 9] interval
	
  idigverc: ; input digit verification completed
            ; meaning that entered char is digit or letter
	
	; so it is digit or letter	
	
	; check if it is included in numalphabet of the base
	
	sub al, '0'
	cmp al, bl
	
	jb idignain
	jmp idigcyc
	
	; -------------------- PREVENTING OVERFLOW -----------------------
	
  idignain: ; input digit numalphabet included
	
	pop dx  ; - P E E K
	push dx ; -   D X
	cmp dx, 0
	jne isitradd

	; so the number is zero
	cmp cl, 0
	jne idigcyc
	
isitradd: ; try adding digit to number
	
	xor ah, ah
	push ax ; save the entered digit (in AL)
	mov ax, dx ; move number to ax
	
	mul bx ; multiply the number by the base
	cmp dx, 0 ; if MUL caused AX-overflow ...
	jne isidigov ; ... then handle it
	cmp ax, 0080h ; also check positive signed int overflow
	jb idignovf ; continue if it didn't
	
  isidigov: ; isi digit overflow
	
	pop dx ; dump useless digit that caused overflow
	jmp idigcyc ; ask for input digit again
	
  idignovf: ; input digit no overflow
	
	pop dx ; get entered digit (int)
	
	add ax, dx ; try adding digit to number
	cmp ax, 0080h
	jae idigcyc
	
	; so everything's successful and the number has been changed
	
	inc cl
	push ax ; save new num (there's the old one under it)
	
	mov ah, 2 ; int-21h service to output char from dl
	cmp dl, 10
	jb isidoNic
	add dl, 7 ; for non-numeric digits [they will be displayed as big ones]
	
isidoNic: ; isi digit output numeric
	add dl, '0' ; int -> char
	int 21h ; print the digit
	
	pop ax ; get the new num into AX
	pop dx ; dump the old num into DX ...
	push ax ; ... and replace it with the new one
	
	jmp idigcyc ; repeat
	
isiservs: ; check if BACKSPACE or ENTER is pressed

	cmp al, 08h ; BACKSPACE ?
	jne isimore
	
	; so it is backspace
	
	cmp cx, 0 ; if number has no digits and no minus ...
	je idigcyc ; ... than ask to reenter
	
	; so we're to do a backspace
	
	; print it :
	
	mov ah, 2 ; 
	mov dl, 8 ; - M O V E   C U R S O R   L E F T
	int 21h   ; 
	
	mov dl, ' ' ; R E W R I T E   B A C K S P A C E D
	int 21h     ;             D I G I T
	
	mov dl, 8 ; M O V E 
	int 21h   ; C U R S O R   L E F T
	
	; change the data :
	
	cmp cl, 0
	je isibsmin ; no digits then there's minus
	
	; so we are to backspace a digit
	
	dec cl ; -1 digit
	
	xor dx, dx ; prepare to divide DX:AX by base by clearing DX
	pop ax ; pop the number into AX ...
	div bx ; ... divide by base ...
	push ax ; ... and set as the new number
	
	jmp idigcyc ; repeat
	
  isibsmin:	
	
	xor ch, ch
	jmp idigcyc
	
isimore:
	
	cmp al, '-'
	jne isient
	
	; so it is minus
	cmp cx, 0
	je isimin
	
	jmp idigcyc
	
  isimin:
    
	mov ah, 2
	mov dl, '-'
	int 21h
	
	mov ch, 1
	jmp idigcyc
	
isient:

	cmp al, 0dh ; ENTER ?
	je isientc
	
	; so entered digit is garbage - ask for input char again
	jmp idigcyc
	
  isientc: ; isi enter confirmed
	; so it is enter
	
	cmp cl, 0 ; check if user tries to enter nothing as a number
	jne isifin 
	
	jmp idigcyc ; if they does than dont let 'em
	
  isifin: ; exit the procedure with output in AX
	
	pop ax ; pop the final number into AX
	
	cmp ch, 0
	je isiskipn
	
	; so the number is to become negative
	neg ax
	
  isiskipn: ; isi skip NEG
	
	pop dx ; restoring
	pop cx ; registers' values
	
	ret ; and finish the procedure.

isint endp


; output signed 16-bit integer from AX in binary..decimal..hex...
; ARGS : base in BX [2 - 36] ; base >36 means bugs
; works fine
osint proc

	push ax
	push cx
	push dx

    xor cx, cx
	cmp ax, 8000h
	jae omin
	
	neg ax
	jmp sdigcyc
	
  omin: ; output minus
    
	push ax
	
	mov ah, 2
	mov dl, '-'
	int 21h
	
	pop ax
	
sdigcyc:

    cwd
    idiv bx
	neg dx

    push dx
    inc cx

    test ax, ax
    jnz sdigcyc

    mov ah, 02h
	
odigcyc:

    pop dx
	;; FOR BASE >10 {
    cmp dl, 9
    jbe oiskip1
    add dl, 7
	;; FOR BASE >10 }
	
oiskip1:
    
	add dl, '0'
    int 21h

    loop odigcyc
	
	pop dx
	pop cx
	pop ax
    
    ret

osint endp
	
end main
