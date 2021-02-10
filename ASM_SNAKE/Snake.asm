include Irvine32.inc

SCREEN_SIZE = 40
BLACK_CHAR EQU <0e2h, 096h, 093h, 0e2h, 096h, 093h>
WHITE_CHAR EQU <0e2h, 096h, 091h, 0e2h, 096h, 091h>
FOOD_CHAR EQU <0e2h, 096h, 088h, 0e2h, 096h, 088h>
CHAR_LENGTH = 6
SNAKE_INIT_LENGTH = 3
BUFFER_COL_LENGTH = (CHAR_LENGTH * SCREEN_SIZE) + 1

TRUE = 1
FALSE = 0

;point structure
Point STRUCT
	x byte ?
	y byte ?
Point ENDS

.data

	;screen buffer
	screen_buffer byte SCREEN_SIZE dup(SCREEN_SIZE dup(BLACK_CHAR), 0)

	;snake structure
	snake_length dword ?
	snake_body Point SCREEN_SIZE * SCREEN_SIZE dup(<0, 0>)

	;others
	food Point <0, 0>
	direction_vector Point <0, -1>
	direction_vector_old Point <0, -1>

	asd db 92

	;string
	msg_0 byte "Snake Length: ", 0
	msg_1 byte "You Died, Game Over!!!"
.code

;-------------------------------------
;draw content buffer to dos window
;
;using - ECX, EDX
;-------------------------------------
PrintBuffer PROC
	push ebp
	mov ebp, esp
	push ecx
	push edx

	;move cursor to top left
	mov dh, 0
	mov dl, 0
	call Gotoxy

	;draw screen
	mov ecx, SCREEN_SIZE
	mov edx, OFFSET screen_buffer
draw_row:

	call WriteString
	call Crlf
	add edx, BUFFER_COL_LENGTH
	loop draw_row

	mov edx, OFFSET msg_0
	call WriteString
	mov eax, snake_length
	call WriteInt

	;restore registers
	pop edx
	pop ecx
	mov esp, ebp
	pop ebp
	ret
PrintBuffer ENDP

;-------------------------------------
;initialize the game
;using - EBX, ECX, ESI, EDI
;-------------------------------------
Init PROC
	push ebp
	mov ebp, esp
	push edi
	push ecx
	push esi
	push ebx

	mov ecx, SNAKE_INIT_LENGTH
	HALF_HEIGHT = SCREEN_SIZE/2
	HALF_WIDTH = SCREEN_SIZE/2
	mov snake_length, ecx
	;assign initial snake position
	mov esi, OFFSET snake_body
	mov direction_vector.x, 0
	mov direction_vector.y, -1
	mov direction_vector_old.x, 0
	mov direction_vector_old.y, -1

loop_init:
	mov edi, ecx
	dec edi
	imul edi, TYPE Point
	mov ebx, HALF_HEIGHT
	add ebx, ecx
	dec ebx
	mov (Point PTR [esi + edi]).x, HALF_WIDTH
	mov (Point PTR [esi + edi]).y, bl

	loop loop_init

	pop ebx
	pop esi
	pop ecx
	pop edi
	mov esp, ebp
	pop ebp
	ret
Init ENDP

;---------------------------------
;render content to memory buffer
;using EAX, EBX, ECX, ESI, EDI
;---------------------------------
RenderBuffer PROC
	push eax
	push ebx
	push ecx
	push esi
	push edi
	push ebp
	mov ebp, esp
	LOCAL_X = -1
	LOCAL_Y = -2
	; allocate 8 bytes
	sub esp, 2

;clear buffer
	mov esi, OFFSET screen_buffer
	mov ecx, SCREEN_SIZE
loop_clear:
	mov eax, 0
	
	loop_clear_inner:
		mov byte ptr [esi + eax], 0e2h
		mov byte ptr [esi + eax + 1], 096h
		mov byte ptr [esi + eax + 2], 091h
		mov byte ptr [esi + eax + 3], 0e2h
		mov byte ptr [esi + eax + 4], 096h
		mov byte ptr [esi + eax + 5], 091h
		add eax, CHAR_LENGTH
		cmp eax, CHAR_LENGTH * SCREEN_SIZE
		jl loop_clear_inner	

	add esi, BUFFER_COL_LENGTH
	loop loop_clear

	;draw snake
	mov ecx, snake_length
	mov esi, OFFSET screen_buffer
	mov edi, OFFSET snake_body
loop_snake:
	mov eax, ecx
	dec eax
	imul eax, 2
	;assign snake dot position to local variable
	mov bl, (Point PTR [edi + eax]).x
	mov byte PTR [ebp + LOCAL_X], bl
	mov bl, (Point PTR [edi + eax]).y
	mov byte PTR [ebp + LOCAL_Y], bl

	;get string buffer offset
	mov eax, 0
	mov al, byte PTR [ebp + LOCAL_Y]
	imul eax, BUFFER_COL_LENGTH
	mov ebx, 0
	mov bl, byte PTR [ebp + LOCAL_X]
	imul ebx, CHAR_LENGTH
	add eax, ebx

	;fill char
	mov byte ptr [esi + eax], 0e2h
	mov byte ptr [esi + eax + 1], 096h
	mov byte ptr [esi + eax + 2], 093h
	mov byte ptr [esi + eax + 3], 0e2h
	mov byte ptr [esi + eax + 4], 096h
	mov byte ptr [esi + eax + 5], 093h
	loop loop_snake

mov edi, OFFSET food
;draw food
	mov eax, 0
	mov al, (Point PTR [edi]).y
	imul eax, BUFFER_COL_LENGTH
	mov ebx, 0
	mov bl, (Point PTR [edi]).x
	imul ebx, CHAR_LENGTH
	add eax, ebx

	mov byte ptr [esi + eax], 0e2h
	mov byte ptr [esi + eax + 1], 096h
	mov byte ptr [esi + eax + 2], 088h
	mov byte ptr [esi + eax + 3], 0e2h
	mov byte ptr [esi + eax + 4], 096h
	mov byte ptr [esi + eax + 5], 088h

	add esp, 2
	mov esp, ebp
	pop ebp
	pop edi
	pop esi
	pop ecx
	pop ebx
	pop eax
	ret
RenderBuffer ENDP

;--------------------------
;read user input-key
;using EAX, EBX, EDX
;update direction
;--------------------------
ReadKeyEvent PROC
	push eax
	push ebx
	push edx
	push ebp
	mov ebp, esp
	call ReadKey
	jz finish

check_a:
	cmp al, 97
	jne check_s
	mov direction_vector.x, -1
	mov direction_vector.y, 0
	jmp finish
check_s:
	cmp al, 115
	jne check_d
	mov direction_vector.x, 0
	mov direction_vector.y, 1
	jmp finish
check_d:
	cmp al, 100
	jne check_w
	mov direction_vector.x, 1
	mov direction_vector.y, 0
	jmp finish
check_w:
	cmp al, 119
	jne finish
	mov direction_vector.x, 0
	mov direction_vector.y, -1
finish:
	mov esp, ebp
	pop ebp
	pop edx
	pop ebx
	pop eax
	ret
ReadKeyEvent ENDP

;----------------------------------------
;generate food on random location
;using EAX, ECX, EDX, ESI
;update food
;----------------------------------------
GenerateFood PROC
	push ecx
	push eax
	push edx
	push esi
	push ebp
	mov ebp, esp
	mov ecx, SCREEN_SIZE
	mov esi, OFFSET food

	;random x position
	call Random32
	mov edx, 0
	div ecx
	mov (Point ptr [esi]).x, dl

	;random y position
	call Random32
	mov edx, 0
	div ecx
	mov (Point ptr [esi]).y, dl

	mov esp, ebp
	pop ebp
	pop esi
	pop edx
	pop eax
	pop ecx
	ret
GenerateFood ENDP

;-----------------------------------------
;border collision check
;using EAX, EBX
;update al , 1 = true, 0 = false
;----------------------------------------
BorderCollisionCheck PROC
	push ebx
	push ebp
	mov ebp, esp

	;set bl to be x and bh to be y
	mov bl, snake_body.x
	mov bh, snake_body.y
	mov al, 0

x_min_check:
	cmp bl, 0
	jge x_max_check
	mov al, 1
	jmp finish
x_max_check:
	cmp bl, SCREEN_SIZE
	jl y_min_check
	mov al, 1
	jmp finish
y_min_check:
	cmp bh, 0
	jge y_max_check
	mov al, 1
	jmp finish
y_max_check:
	cmp bh, SCREEN_SIZE
	jl finish
	mov al, 1
finish:
	mov esp, ebp
	pop ebp
	pop ebx
	ret
BorderCollisionCheck ENDP

;---------------------------------------
;self collision check
;using EAX, EBX, ESI, ECX, EDX, EDI
;update al, 1 = true, 0 = false
;--------------------------------------
SelfCollisionCheck PROC
	push ebx
	push esi
	push ecx
	push edx
	push edi
	push ebp
	mov ebp, esp

	;get head position and put it in x = bl and y = bh
	mov bl, snake_body.x
	mov bh, snake_body.y

	;iterate body points
	mov esi, OFFSET snake_body
	mov ecx, snake_length
	sub ecx, 1
loop_body:

	mov edi, ecx
	imul edi, TYPE Point
	mov dl, (Point PTR [esi + edi]).x
	mov dh, (Point PTR [esi + edi]).y

	cmp bl, dl
	jne loop_next
	cmp bh, dh
	jne loop_next
	mov al, 1
	jmp loop_end
loop_next:
	cmp ecx, 1
	jle loop_end
	loop loop_body
loop_end:

	mov esp, ebp
	pop ebp
	pop edi
	pop edx
	pop ecx
	pop esi
	pop ebx
	ret
SelfCollisionCheck ENDP

;----------------------------------------
;make snake go forward
;using EAX, ESI, EDI, ECX
;----------------------------------------
GoForward PROC
	push eax
	push esi
	push edi
	push ecx
	push ebp
	mov ebp, esp

	mov esi, OFFSET snake_body
	mov ecx, snake_length
	dec ecx
	mov edi, ecx
	imul edi, TYPE Point
loop_body:
	mov al, (Point PTR [esi + edi - 2]).x
	mov ah, (Point PTR [esi + edi - 2]).y
	mov (Point PTR [esi + edi]).x, al
	mov (Point PTR [esi + edi]).y, ah
	sub edi, TYPE Point
	cmp ecx, 1
	jle loop_end
	loop loop_body
loop_end:	
	mov al, snake_body.x
	mov ah, snake_body.y

	;update head
	mov cl, direction_vector.x
	mov ch, direction_vector.y
	add cl, direction_vector_old.x
	add ch, direction_vector_old.y

	cmp cl, 0
	je check_next
	mov cl, 1
check_next:
	cmp ch, 0
	je check_final
	inc cl
check_final:
	cmp cl, 2
	jne direction_end
different_direction:
	mov cl, direction_vector.x
	mov ch, direction_vector.y
	mov direction_vector_old.x, cl
	mov direction_vector_old.y, ch
direction_end:
	add al, direction_vector_old.x
	add ah, direction_vector_old.y
	mov (Point PTR [esi]).x, al
	mov (Point PTR [esi]).y, ah

	mov esp, ebp
	pop ebp
	pop ecx
	pop edi
	pop esi
	pop eax
	ret
GoForward ENDP

;---------------------------------------
;check if snake is collision with food
;using EAX, EBX
;update al, 1 = true, 0 = false
;---------------------------------------
FoodCollisionCheck PROC
	push ebx
	push ebp
	mov ebp, esp

	mov al, 0
	mov bl, snake_body.x
	mov bh, snake_body.y
	cmp bl, food.x
	jne check_end
	cmp bh, food.y
	jne check_end
	mov al, 1
check_end:
	mov esp, ebp
	pop ebp
	pop ebx
	ret
FoodCollisionCheck ENDP

;--------------------------------------
;increase snake body length
;using EAX, ECX, ESI, EDI
;--------------------------------------
SnakeGrow PROC
	push eax
	push ecx
	push esi
	push edi
	push ebp
	mov ebp, esp

	mov ecx, snake_length
	mov esi, OFFSET snake_body
loop_body:
	mov edi, ecx
	imul edi, TYPE Point
	mov al, (Point PTR [esi + edi - 2]).x
	mov ah, (Point PTR [esi + edi - 2]).y
	mov (Point PTR [esi + edi]).x, al
	mov (Point PTR [esi + edi]).y, ah
	cmp ecx, 1
	jle loop_end
	loop loop_body

loop_end:
	mov al, snake_body.x
	mov ah, snake_body.y
	add al, direction_vector_old.x
	add ah, direction_vector_old.y
	mov (Point PTR [esi]).x, al
	mov (Point PTR [esi]).y, ah

	mov eax, 0
	mov eax, snake_length
	inc eax
	mov snake_length, eax
	mov esp, ebp
	pop ebp
	pop edi
	pop esi
	pop ecx
	pop eax
	ret
SnakeGrow ENDP

;----------------------------------------
;entry of the program
;---------------------------------------
main PROC
	
	call Randomize

start:
	call Init
	call GenerateFood
game_loop:
	call ReadKeyEvent
	call GoForward

	call BorderCollisionCheck
	cmp al, TRUE
	je game_loop_end

	call SelfCollisionCheck
	cmp al, TRUE
	je game_loop_end

	call FoodCollisionCheck
	cmp al, TRUE
	jne next
	call GenerateFood
	call SnakeGrow
next:

	call RenderBuffer
	call PrintBuffer
	mov eax, 200
	call Delay
	jmp game_loop
game_loop_end:

call Crlf
call Crlf
mov edx, OFFSET msg_1
call WriteString
call Crlf
call Crlf

exit

mov bl, asd
cbw
add ax, bx

main ENDP
END main