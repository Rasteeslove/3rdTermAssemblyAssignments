.model small
.stack 100h
.data
    
	err_mess db 'The overflow has happened$'
	a dw 1
    b dw 2
    c dw 3
    d dw 4
	
.code

main:

    mov ax, @data
    mov ds, ax
    
	
	
    mov ax, a
    or ax, b

    mov bx, c
    sub bx, d
	
	jc else_1

    cmp ax, bx
	
	jnz elif_1
	
		; (c | d) + (b & d) :
	
		mov ax, c
		or ax, d
	
		mov bx, b
		and bx, d

		add ax, bx
		
		; report if the overflow happened
		jnc skip1
		
		mov ah, 9
		mov dx, offset err_mess
		int 21h
		
		skip1:
		
		jmp exit_1
	
	elif_1:

	mov ax, a
	add ax, b
	
	jc else_1
	
	mov bx, c
	sub bx, d
	
	cmp ax, bx
	
	jnz else_1

		; (a ^ b) | (c ^ d) :
	
		mov ax, a
		xor ax, b
	
		mov bx, c
		xor bx, d
	
		or ax, bx
		jmp exit_1
	
	else_1:
	
		; (a | b) ^ (c | d) :

		mov ax, a
		or ax, b
	
		mov bx, c
		or bx, d
	
		xor ax, bx

	exit_1:	; print ax:
		
		call print

    mov ax, 4c00h
    int 21h
	
	
	
	
	
	
; prints number in AX if it's not zero :
print proc

    mov cx, 0
    mov dx, 0

    pu_dig:

        cmp ax, 0
        jz pr_char

        mov bx, 10
        div bx

        push dx
        inc cx
        xor dx, dx

		jmp pu_dig

    pr_char:

        cmp cx, 0 
        jz ex_pr
          
        pop dx 
        add dx, 48 
        mov ah, 02h 
        int 21h 
          
        dec cx 
        jmp pr_char 

	ex_pr: 
	ret
	
print endp
	
	
	
end main