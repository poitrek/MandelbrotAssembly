
.const

floatSize equ	4 ; rozmiar danych typu float
charSize equ	1  ; rozmiar danych typu char
ptrSize equ		8  ; rozmiar wskaznika (x64)
MaxIterations equ 50

localStackSize equ	16 * 7

.data
X1	dd	-2.0
X2	dd	1.0
Y1	dd	-1.0
Y2	dd	1.0

.code

MandelbrotTest_Asm proc

; rcx - pixel array pointer
; rdx - beginning line
; r8 - array part length
; r9 - columns


	;; ALIGN LOCAL VARIABLES ON STACK ;;
	
	push rbp
	sub rsp, localStackSize
	mov rbp, rsp
	
	movd xmm1, X2
	subss xmm1, X1	;  xmm1 = X2 - X1
	cvtsi2ss xmm0, r9  ; (int)r9 --> (float)xmm1
	divss xmm1, xmm0  ;  xmm1 = (X2 - X1) / columns = precisionPerPixel

	insertps xmm1, xmm1, 16
	insertps xmm1, xmm1, 32
	insertps xmm1, xmm1, 48

	
	movd xmm11, X1	;	xmm11 <-- X1
	insertps xmm11, xmm11, 16
	insertps xmm11, xmm11, 32
	insertps xmm11, xmm11, 48

	movd xmm12, Y1	;	xmm12 <-- Y1
	insertps xmm12, xmm12, 16
	insertps xmm12, xmm12, 32
	insertps xmm12, xmm12, 48

	; xmm13 := 2.0
	mov eax, 2
	cvtsi2ss xmm13, eax
	insertps xmm13, xmm13, 16
	insertps xmm13, xmm13, 32
	insertps xmm13, xmm13, 48

	; xmm14 := 4.0 = xmm13 ^ 2
	movaps xmm14, xmm13
	mulps xmm14, xmm13

	;; LOAD ON STACK ;;
	
	;; Stack:
	;;		 [X1][Y1][2.0][4.0][1.0][255.0][50.0]
	;; rbp +  0	  16  32   48   64   80		96

	movaps [rbp], xmm11
	movaps [rbp + 16], xmm12
	movaps [rbp + 32], xmm13
	movaps [rbp + 48], xmm14


	divps xmm13, xmm13	;	xmm13 := 1.0

	; xmm14 := 255.0
	mov eax, 255
	cvtsi2ss xmm14, eax
	insertps xmm14, xmm14, 16
	insertps xmm14, xmm14, 32
	insertps xmm14, xmm14, 48

	; xmm15 := 50.0
	mov eax, MaxIterations
	cvtsi2ss xmm15, eax
	insertps xmm15, xmm15, 16
	insertps xmm15, xmm15, 32
	insertps xmm15, xmm15, 48

	movaps [rbp + 64], xmm13
	movaps [rbp + 80], xmm14
	movaps [rbp + 96], xmm15

	; xmm15 := 1 (int)
	pxor	xmm15, xmm15
	pcmpeqd xmm0, xmm0
	psubd	xmm15, xmm0

	;---- Drop xmm11, xmm12, xmm13, xmm14 ----;
	
	mov r14, rdx	; r14 := beginning line
	add r14, r8		; r14 := r14 + number of lines
	mov r12, rdx	; r12 - LOOP1 iterator

	mov eax, PtrSize
	mul edx
	add rcx, rax	;	rcx += ptrSize * beginning_line


LOOP1:	
	xor r15d, r15d   ;  r15 - LOOP2 iterator := 0
	mov rbx, [rcx]	 ;  rbx = imagePixels[..]

	;-------- Set p_im;

	; Insert into xmm3 converted r12
	cvtsi2ss xmm3, r12d
	insertps xmm3, xmm3, 16
	insertps xmm3, xmm3, 32
	insertps xmm3, xmm3, 48
	mulps xmm3, xmm1
	addps xmm3, [rbp + 16]	;	xmm3 = i * px + Y1

	LOOP2:
		
		;-------- Set p_re;

		; insert ascending r15 values into xmm2
		; xmm2 := [r15+3][r15+2][r15+1][r15]		
		pinsrd xmm2, r15d, 0
		inc r15d
		pinsrd xmm2, r15d, 1
		inc r15d
		pinsrd xmm2, r15d, 2
		inc r15d
		pinsrd xmm2, r15d, 3
		cvtdq2ps xmm2, xmm2

		mulps xmm2, xmm1
		addps xmm2, [rbp]	;	xmm2 = [j] * px + X1


		;-------- Set up z_re, z_im and z_norm ;

		xorps xmm4, xmm4	;	xmm4 = z_re := 0
		xorps xmm5, xmm5	;	xmm5 = z_im := 0
		xorps xmm6, xmm6	;	xmm6 = z_norm := 0
		xorps xmm8, xmm8	;	xmm8 = z_re^2 := 0
		xorps xmm9, xmm9	;	xmm9 = z_im^2 := 0
		movaps xmm11, xmm15	;	xmm11 = 4 x 1 (int)
		xorps xmm10, xmm10	;	xmm10 - iterations := 0
		xor r10d, r10d	;	iterations := 0

		LOOP3:			
		
			;================================;

			movaps xmm7, xmm8
			subps xmm7, xmm9	;	xmm7 = z_re*z_re - z_im*z_im
			addps xmm7, xmm2	;	xmm7 = z_re^2 - z_im^2 + p_re

			;;mov eax, 2
			;;cvtsi2ss xmm0, eax	;	xmm0 = 2.0
			mulps xmm5, xmm4	;	z_im := z_im * z_re
			mulps xmm5, [rbp+32];	z_im := z_im * 2.0
			addps xmm5, xmm3	;	xmm5 = z_im * z_re * 2 + p_im

			movaps xmm4, xmm7 ;	z_re = new_z_re

			movaps xmm8, xmm4
			mulps xmm8, xmm4	;	xmm8 = z_re^2
			movaps xmm9, xmm5
			mulps xmm9, xmm5	;	xmm9 = z_im^2

			movaps xmm6, xmm8
			addps xmm6, xmm9	;	xmm6 = z_re^2 + z_im^2

			;================================;
			
			;-------- Check loop conditions --------;
			; if (z_norm < 4)

			movaps xmm0, xmm6	
			
			;; FOR TEST ;;
			;;movaps xmm11, [rbp + 48]
			;;divss xmm0, xmm11
			;; ======== ;;

			cmpps xmm0, [rbp + 48], 1	;	cmp (z_norm < 4.0)

			addps xmm10, xmm11	;	increment for every pixel

			andps xmm11, xmm0
			ptest xmm11, xmm0	;	Testing if xmm11 == 0
			jz EndOfLoop3

			; if (iterations < MaxIterations)
			inc r10
			cmp r10, MaxIterations
			jl LOOP3
			jmp EndOfLoop3
		
		;mov [rbx], al   ;  [rbx] <-- al  (lower byte!!)

		;----	 Drop xmm2, xmm3, xmm4, xmm5, xmm6, xmm7	----;
		;-------- Convert value in r10b to pixel saturation --------;
	EndOfLoop3:
		
		cvtdq2ps xmm10, xmm10	;	convert to floats
		divps xmm10, [rbp + 96]	;	xmm10 = iterations / 50.0
		movaps xmm0, [rbp + 64]	;	xmm0 = 1.0
		subps xmm0, xmm10		;	xmm0 = 1.0 - iterations / 50
		mulps xmm0, [rbp + 80]	;	xmm0 = 255 * (1 - iterations / 50)

		cvtps2dq xmm0, xmm0	;	convert to integers
		
		extractps eax, xmm0, 1
		pinsrb xmm0, eax, 1
		extractps eax, xmm0, 2
		pinsrb xmm0, eax, 2
		extractps eax, xmm0, 3
		pinsrb xmm0, eax, 3

		movd eax, xmm0
		mov [rbx], eax


		inc r15
		add rbx, CHARSIZE * 4

		cmp r15, r9  ; if r15 < columns, then jump Loop2
		jl LOOP2
	
	
	inc r12
	add rcx, PTRSIZE
	cmp r12, r14  ;  if rdx < r14, then jump to Loop1
	jl LOOP1

	
	;;------ RESTORE STACK ------;;

	add rsp, localStackSize
	pop rbp
	ret

MandelbrotTest_Asm endp
end