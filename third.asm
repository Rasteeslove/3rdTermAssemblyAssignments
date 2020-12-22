.model small
.stack 100h
.data
    
	base dw 16

	mssg1 db 'Enter the dividend: $'
	mssg2 db 'Enter the divisor: $'
	mssg3 db 'Divisor cannot be zero!', 13, 10, '$'
	mssg4 db ' = $'
	mssg5 db ' * $'
	mssg6 db ' + $'	
	
	crlf db 13, 10, '$'
	
	lscope db '($'
	rscope db ')$'
	
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
    
	mov bx, base ; setting base [could've been done by user]
	
; getting the dividend :
	ostr mssg1

	call isint
	push ax
	
; getting the divisor :
dvsr:

	ostr mssg2

	call isint
	cmp ax, 0h
	jne rslt
	
	; so you have chosen death [the divisor is zero]

	ostr mssg3
	
	jmp dvsr
	
; output result in the tasm way and in "a = b*q + r" form :
rslt:	
	
	; calculations :
	
	; preparing to divide :
	mov bx, ax
	pop ax
	mov cx, ax
	cwd
	
	; dividing
	idiv bx
	
	; so qraw is in AX, rraw is in DX
	
	; saving them for later two times:
	push dx
	push ax
	push bx
	push cx
	
	push dx
	push ax
	push bx
	push cx
	
	; restoring base :
	mov bx, base
	
	; at this point the stack is like : 
	; a on b on qraw on rraw
	
	
	
	; output the result the tasm way	
	
	pop ax
	call osint ; a 
	
	ostr mssg4 ; =
	
	pop ax
	call osintws ; ( b )
	
	ostr mssg5 ; *
	
	pop ax ; ( qraw )
	call osintws
	
	ostr mssg6 ; +
	
	pop ax ; ( rraw )
	call osintws
	
	ostr crlf
	
	; output result the canonic way
		; canonic way :

	pop ax
	call osint ; a 
	
	ostr mssg4 ; =
	
	pop ax
	call osintws ; ( b )
	mov cx, ax	
	
	ostr mssg5 ; *
	
	
	
	pop ax ; qraw
	pop dx ; rraw
	
	cmp dx, 8000h
	jb skipaj
	
	cmp cx, 8000h
	jb skipneg
	
	add ax, 1
	sub dx, cx
	
	jmp skipaj
	
  skipneg:
  
    sub ax, 1
	add dx, cx
	
  skipaj:

	call osintws ; ( q )
	
	ostr mssg6 ; +
	
	mov ax, dx
	call osintws ; ( r )

fin:

    mov ax, 4c00h
    int 21h
	

; ==============================================================
; ==================== P R O C E D U R E S =====================
; ==============================================================

; ISINT = input signed integer procedure facilitates 16-bit ...
;         ... signed integer input with the same validation ...
;         ... and same everything as in the IUINT procedure .


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
	cmp ax, 8000h ; also check positive signed int overflow
	jb idignovf ; continue if it didn't
	
  isidigov: ; isi digit overflow
	
	pop dx ; dump useless digit that caused overflow
	jmp idigcyc ; ask for input digit again
	
  idignovf: ; input digit no overflow
	
	pop dx ; get entered digit (int)
	
	add ax, dx ; try adding digit to number
	cmp ax, 8000h
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
  
	; printing CR LF == enter
	mov ah, 2
	mov dl, 13
	int 21h
	mov dl, 10
	int 21h
	
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
	
	
; output from AX
osintws proc

	cmp ax, 8000h
	jb oiwssk1
	
	ostr lscope
	
	oiwssk1:
	
	call osint
	
	cmp ax, 8000h
	jb oiwssk2
	
	ostr rscope
	
	oiwssk2:

	ret
	
osintws endp
	
	
end main