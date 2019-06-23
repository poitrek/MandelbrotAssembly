
.const

doubleSize equ 8  ; rozmiar danych typu doulbe
floatSize equ 4 ; rozmiar danych typu float
charSize equ 1  ; rozmiar danych typu char
ptrSize equ 8  ; rozmiar wskaznika (x64)
MaxIterations equ 50

.data
X1	dd	-2.0
X2	dd	1.0
Y1	dd	-1.0
Y2	dd	1.0
_real_4 dd 4.0

.code

MandelbrotTest_Asm1 proc

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
@
	
	;; ALIGN LOCAL VARIABLE ;;

	push	rbp
	sub		rsp, 16
	mov		rbp, rsp

	pxor xmm0, xmm0
	pcmpeqd xmm1, xmm1
	psubd xmm0, xmm1

	movaps [rsp], xmm0

	;; ======== ;;



	movd	xmm1, X2
	subss	xmm1, X1	;  xmm0 = X2 - X1
	cvtsi2ss xmm0, r9  ; (int)r9 --> (double)xmm1
	divss	xmm1, xmm0  ;  xmm1 = (X2 - X1) / columns = precisionPerPixel

	
	movd xmm11, X1	;	xmm11 <-- X1
	movd xmm12, Y1	;	xmm12 <-- Y1

	mov r14, rdx  ; r14 := beginning line
	add r14, r8   ; r14 := r14 + number of lines
	mov r12, rdx ; r12 - Loop1 iterator


	mov eax, PtrSize
	mul edx

	add rcx, rax	;	rcx += ptrSize * beginning_line


Loop1:
	
	xor r15d, r15d   ;  r15 - Loop2 iterator := 0
	mov rbx, [rcx]

	Loop2:
		
		;-------- Set p_re and p_im ;

		cvtsi2ss xmm2, r15
		;; Error : illegal instruction
		;vfmadd132ps xmm2, xmm11, xmm1 ;	xmm2 = j * px + X1 = p_re
		mulss xmm2, xmm1
		addss xmm2, xmm11
		
		cvtsi2ss xmm3, r12
		;vfmadd132ps xmm3, xmm12, xmm1 ;	xmm3 = i * py + Y1 = p_im
		mulss xmm3, xmm1
		addss xmm3, xmm12

		;; FOR TEST ;;

		;;movaps xmm4, [rbp]
		;;addps xmm4, [rbp]

		;; ======== ;;




		;-------- Set up z_re, z_im and z_norm ;

		xorps xmm4, xmm4	;	xmm4 = z_re := 0
		xorps xmm5, xmm5	;	xmm5 = z_im := 0
		xorps xmm6, xmm6	;	xmm6 = z_norm := 0
		xorps xmm8, xmm8	;	xmm8 = z_re^2 := 0
		xorps xmm9, xmm9	;	xmm9 = z_im^2 := 0

		xor r10d, r10d	;	iterations := 0

		Loop3:
			
		COMMENT @
			; xmm7 = new_z_re
			;-------- Process z_re, z_im --------;

			movss xmm0, xmm5
			vfmsub132ss xmm0, xmm2, xmm5 ;	xmm0 = z_im * z_im - p_re

			movss xmm7, xmm4
			vfmsub132ss xmm7, xmm0, xmm4 ;	xmm7 = z_re*z_re - z_im*z_im + p_re

			mulss xmm5, xmm4 ;	z_im = z_im * z_re
			
			mov eax, 2
			cvtsi2ss xmm0, eax
			vfmadd132ss xmm5, xmm3, xmm0 ;	z_im = 2 * z_re * z_im + p_im

			;-------- Compute z_norm --------;

			movss xmm0, xmm5
			mulss xmm0, xmm5 ;	xmm0 = xmm5*xmm5
			movss xmm6, xmm4
			vfmadd132ss xmm6, xmm0, xmm4 ;	xmm6 = xmm5*xmm5 + xmm4*xmm4
		@

			;================================;

			movss xmm7, xmm8
			subss xmm7, xmm9	;	xmm7 = z_re*z_re - z_im*z_im
			addss xmm7, xmm2	;	xmm7 = z_re^2 - z_im^2 + p_re

			mov eax, 2
			cvtsi2ss xmm0, eax	;	xmm0 = 2.0
			mulss xmm5, xmm4	;	z_im := z_im * z_re
			mulss xmm5, xmm0
			addss xmm5, xmm3	;	xmm5 = z_im * z_re * 2 + p_im

			movss xmm4, xmm7 ;	z_re = new_z_re

			movss xmm8, xmm4
			mulss xmm8, xmm4	;	xmm8 = z_re^2
			movss xmm9, xmm5
			mulss xmm9, xmm5	;	xmm9 = z_im^2

			movss xmm6, xmm8
			addss xmm6, xmm9	;	xmm6 = z_re^2 + z_im^2

			;================================;
			
			;-------- Check loop conditions --------;
			; if (z_norm < 4)
			;mov eax, 4
			;cvtsi2ss xmm0, eax

			movd eax, xmm6
			cmp eax, _real_4			
			jg EndOfLoop3

			; if (iterations < MaxIterations)
			inc r10
			cmp r10, MaxIterations
			jl Loop3
			jmp EndOfLoop3
		
		;mov [rbx], al   ;  [rbx] <-- al  (lower byte!!)

		;----	 Drop xmm2, xmm3, xmm4, xmm5, xmm6, xmm7	----;
		;-------- Convert value in r10b to pixel saturation --------;
	EndOfLoop3:

		cvtsi2ss xmm0, r10d
		mov eax, MaxIterations
		cvtsi2ss xmm2, eax
		divss xmm0, xmm2	; xmm0 = iterations / MaxIterations
		mov eax, 1
		cvtsi2ss xmm2, eax		; xmm2 = 1.0
		subss xmm2, xmm0	; xmm2 = 1 - iterations / MaxIterations
		mov eax, 255
		cvtsi2ss xmm0, eax
		mulss xmm2, xmm0	; xmm2 = 255*(1 - iter / MaxIter)

		cvtss2si eax, xmm2	; xmm2 --> eax (cvt)


		mov [rbx], al


		inc r15
		add rbx, CHARSIZE

		cmp r15, r9  ; if r15 < columns, then jump Loop2
		jl Loop2
	

	
	inc r12
	add rcx, PTRSIZE

	cmp r12, r14  ;  if rdx < r14, then jump to Loop1
	jl Loop1


	
	;; RESTORE LOCAL VARIABLE ;;

	add rsp, 16
	pop rbp

	;; ======== ;;


	ret

MandelbrotTest_Asm1 endp

end