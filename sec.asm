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
	
.code

main:

	mov ax, @data
    mov ds, ax
	
	mov bx, base ; setting base [could've been done by user]
	
; getting the dividend :
	lea dx, mssg1
	mov ah, 9h
	int 21h

	call iuint
	push ax
	
; getting the divisor :
dvsr:

	lea dx, mssg2
	mov ah, 9h
	int 21h

	call iuint
	cmp ax, 0h
	jne rslt
	
	; so you have chosen death [the divisor is zero]

	lea dx, mssg3
	mov ah, 9h
	int 21h

	jmp dvsr
	
; output result (in "a = b*q + r" form):
rslt:	

	mov bx, ax
	pop ax

	push bx
	push ax
	
	; at this point a is in AX and b is in BX and ...
    ; ... there are also b and a on top of stack for future output
	
	xor dx, dx
	div bx 

	; q is in AX and r is in DX now
	; the stack should contain (counting down) : a, b, q, r
	
	pop bx
	pop cx
	push dx
	push ax
	push cx
	push bx
	
; printing "a = b * q + r" taking variables off the stack :

	mov bx, base ; resetting base

	pop ax
	call ouint ; a 
	
	lea dx, mssg4 ; =
	mov ah, 9h
	int 21h
	
	pop ax 
	call ouint ; b
	
	lea dx, mssg5 ; *
	mov ah, 9h
	int 21h
	
	pop ax
	call ouint ; q
	
	lea dx, mssg6 ; +
	mov ah, 9h
	int 21h
	
	pop ax
	call ouint ; r

; finish the program

	mov ax, 4c00h
    int 21h


; ========================================================================
; ========================= P R O C E D U R E S ==========================
; ========================================================================



; iuint procedure facilitates unsigned 16-bit integer ... 
; ... symbol-by-symbol input ; after the call of the procedure ...
; ... the integer is in AX register

	; ARGS : base [ 2 - 36 ] into BX
	;        >36 will probably cause bugs

	; NOTE 1 : user shouldn't be allowed to enter :
	;        1) any digit after zero being the first one ;
	;        2) garbage-digits (meaning characters not included ... 
	;           ... in numeric alphabet) ;
	;	     3) digits making the number that is being entered ...
	;           ... exceed 65535 ;
	;        4) nothing as a number .
	
	; NOTE 2 : CX is set as a digit counter in order to forbid ...
	;          user from entering smth after zero being the first ...
    ;          digit and entering nothing as a number .
	
iuint proc

	push cx ; saving registers'
	push dx ; values

	;   ax is whatever
	;   bx is argument [base]
	xor cx, cx ; CX to store number of number's digits
	xor dx, dx ; DX is the buffer register for operations in this proc
	push dx ; cause the number is atop the stack all the time

idigcyc: ; input digit cycle

	mov ah, 08h ; getchar w/o echo
	int 21h
	
	; ------------------------- VALIDATION --------------------------
	
	cmp al, '0'
	jb iuiservs ; if AL < '0' than it might be BACKSPACE or ENTER
	
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
	jne iuitradd

	; so the number is zero
	cmp cx, 0
	jne idigcyc
	
iuitradd: ; try adding digit to number
	
	xor ah, ah
	push ax ; save the entered digit (in AL)
	mov ax, dx ; move number to ax
	
	mul bx ; multiply the number by the base
	cmp dx, 0 ; check if MUL exceeded AX
	je idignovf ; continue if it didn't
	
	pop dx ; dump useless digit that caused overflow
	jmp idigcyc ; ask for input digit again
	
  idignovf: ; input digit no overflow
	
	pop dx ; get entered digit (int)
	
	add ax, dx ; try adding digit to number
	jc idigcyc ; if overflow than getch
	
	; so everything's successful and the number has been changed
	
	inc cl
	push ax ; save new num (there's the old one under it)
	
	mov ah, 2 ; int-21h service to output char from dl
	cmp dl, 10
	jb iuidoNic
	add dl, 7 ; for non-numeric digits [they will be displayed as big ones]
	
iuidoNic: ; iui digit output numeric
	add dl, '0' ; int -> char
	int 21h ; print the digit
	
	pop ax ; get the new num into AX
	pop dx ; dump the old num into DX ...
	push ax ; ... and replace it with the new one
	
	jmp idigcyc ; repeat
	
iuiservs: ; check if BACKSPACE or ENTER is pressed

	cmp al, 08h ; BACKSPACE ?
	jne iuient
	
	; so it is backspace
	
	cmp cx, 0 ; if number has no digits ...
	je idigcyc ; ... than ask to reenter
	
	; so we're to do a backspace
	
	dec cl ; -1 digit
	
	mov ah, 2 ; 
	mov dl, 8 ; - M O V E   C U R S O R   L E F T
	int 21h   ; 
	
	mov dl, ' ' ; R E W R I T E   B A C K S P A C E D
	int 21h     ;             D I G I T
	
	mov dl, 8 ; M O V E 
	int 21h   ; C U R S O R   L E F T
	
	xor dx, dx ; prepare to divide DX:AX by base by clearing DX
	pop ax ; pop the number into AX ...
	div bx ; ... divide by base ...
	push ax ; ... and set as the new number
	
	jmp idigcyc ; repeat
	
iuient:

	cmp al, 0dh ; ENTER ?
	je iuientc
	
	; so entered digit is garbage - ask for input char again
	jmp idigcyc
	
  iuientc: ; iui enter confirmed
	; so it is enter
	
	cmp cx, 0 ; check if user tries to enter nothing as a number
	jne iuifin 
	
	jmp idigcyc ; if they does than dont let 'em
	
  iuifin: ; exit the procedure with output in AX
  
	; printing CR LF == enter
	mov ah, 2
	mov dl, 13
	int 21h
	mov dl, 10
	int 21h
	
	pop ax ; pop the final number into AX
		
	pop dx ; restoring
	pop cx ; registers' values
	
	ret ; and finish the procedure.

iuint endp

; output unsigned 16-bit integer from AX in binary..decimal..hex...
; ARGS : base in BX [2 - 36] ; base >36 means bugs
ouint proc

    xor cx, cx
	
sdigcyc:

    xor dx, dx
    div bx

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
    
    ret

ouint endp

end main
