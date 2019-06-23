

.const

doubleSize equ 8  ; rozmiar danych typu doulbe
charSize equ 1  ; rozmiar danych typu char
ptrSize equ 8  ; rozmiar wskaznika (x64)


.code

MandelbrotTest_Asm2 proc

; rcx - pixel array pointer
; rdx - beginning line
; r8 - array part length
; r9 - columns

; stack: 
;	Y2
;	Y1
;	X2
;	X1
	
COMMENT @

	;movq xmm0, rax  - correct
	;movd xmm0, rax  - correct
	;movq xmm0, eax  - incorrect
	;movd xmm0, eax  - correct

	movq xmm0, r12
	cvtsi2sd xmm1, r9  ; convert integer in r9 to double in xmm1
	;movq xmm1, r9

	divss xmm0, xmm1  ;  xmm0 = (X2 - X1) / columns = precisionPerPixel

@
	;push rbp
	;mov rbp, rsp


	
	mov rax, r8
	mul r9
	mov r14, rax	;	r14 <-- columns * lines

	cvtsi2sd xmm0, rax  ;  xmm0 <-- r8 * r9 = columns * lines
	mov rax, 255
	cvtsi2sd xmm1, rax  ; xmm1 <-- (double)255
	divsd xmm1, xmm0   ;  xmm1 <-- 255 / columns * lines


	mov rbx, [rcx]


	mov r12, 0	;	r12 - Loop1 iterator
	;-----------------------------------;
	Loop1:

		cvtsi2sd xmm0, r12  ; xmm0 <-- r12
		mulsd xmm0, xmm1

		cvtsd2si rax, xmm0
		
		
		mov [rbx], al   ;  [rbx] <-- al  (lower byte!!)
						;   = 5*r12 + r15		
		
		

		add rbx, CHARSIZE
		inc r12

		cmp r12, r14  ;  if rdx < r14, then jump to Loop1
		jl Loop1
	;-----------------------------------;




COMMENT @

	movq r10, xmm0

	movq r11, xmm1

	sub r10, r11  ; r10 := xmm1 - xmm0

	push r9
	push r10

	fdivrp  ; st(1) := st(0) / st(1)  =  (X2 - X1) / columns

	pop r10  ; r10 := st(0) = precisionPerPixel

@



	ret

MandelbrotTest_Asm2 endp

end