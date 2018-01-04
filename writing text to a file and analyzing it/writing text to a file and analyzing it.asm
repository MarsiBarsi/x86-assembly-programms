org 100h

; macros:
next_line macro
  push AX
  push DX

  mov AH, 02h

  mov DL, 13
  int 21h
  mov DL, 10
  int 21h

  pop DX
  pop AX
endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print_mes macro message
  local msg, nxt
  push AX
  push DX

  mov AH,09h
  mov DX, offset msg
  int 21h

  pop DX
  pop AX
  jmp nxt
  msg DB message,'$'
  nxt:
endm
;=====================================================
; main:
start:
  next_line
;------- check string of parameters -------------------------
<<<<<<< HEAD
  mov CL, ES:[80h]  ; addr. of length parameter in psp
    cmp CL, 0       ; is it 0 in buffer?
        jne $with_parametrs   ; yes
;---------------------------------------------------------------
; without parameters:
$without_parametrs:
=======
  mov CL, ES:[80h] ; addr. of length parameter in psp
    cmp CL, 0 ; is it 0 in buffer?
        jne $cont ; yes
;---------------------------------------------------------------
; without parameters:

>>>>>>> 655effa316a257e61634884bd0714f0f785a94a9
  print_mes 'parameters have not been entered'
  next_line
  print_mes 'Please, input file name > '

  mov AH, 0Ah
  mov DX, offset FileName
  int 21h

  next_line
;===============================================================
  xor BH, BH
  mov BL, FileName[1]
  mov FileName[BX+2], 0
;===============================================================
<<<<<<< HEAD
  mov AX, 3D01h ; Open file for write
=======
  mov AX, 3D02h ; Open file for read/write
>>>>>>> 655effa316a257e61634884bd0714f0f785a94a9
  mov DX, offset FileName+2
  int 21h
  jnc ok_of_opening
  jmp error_of_opening

;---------------------------------------------------------------
<<<<<<< HEAD
$with_parametrs:
=======
$cont:
>>>>>>> 655effa316a257e61634884bd0714f0f785a94a9
  xor BH, BH
  mov BL, ES:[80h]
  mov byte ptr [BX+81h],0
;---------------------------------------------------------------
<<<<<<< HEAD
  mov CL, ES:80h  ; length of parameter string in PSP
  xor CH,CH     ; CX=CL= length of parameter string
  cld           ; DF=0 - forward direction flag
  mov DI, 81h   ; ES:DI-> start of parameter string in PSP
  mov AL,' '    ; delete spaces in start
  repe scasb    ; scan while spaces
                ; AL - (ES:DI) -> proc flags
                ; repeat while elements are equal
  dec DI        ; DI-> first symbol after spaces
;---------------------------------------------------------------
  mov AX, 3D01h ; Open file for write
=======
  mov CL, ES:80h ; Длина хвоста в PSP
  xor CH,CH ; CX=CL= длина хвоста
  cld ; DF=0 - флаг направления вперед
  mov DI, 81h ; ES:DI-> начало хвоста в PSP
  mov AL,' ' ; Уберем пробелы из начала хвоста
  repe scasb ; Сканируем хвост пока пробелы
  ; AL - (ES:DI) -> флаги процессора
  ; повторять пока элементы равны
  dec DI ; DI-> на первый символ после пробелов
;---------------------------------------------------------------
  mov AX, 3D02h ; Open file for read/write
>>>>>>> 655effa316a257e61634884bd0714f0f785a94a9
  mov DX, DI
  int 21h
  jnc ok_of_opening
  jmp error_of_opening
;=====================================================
ok_of_opening:
<<<<<<< HEAD
  mov Handler, AX

  next_line
  print_mes 'The file has been successfully opened'

  next_line
  print_mes 'Text for file > '

  
=======
  next_line
  print_mes 'The file has been successfully opened'

>>>>>>> 655effa316a257e61634884bd0714f0f785a94a9


  int 20h
;
error_of_opening:
  next_line
  print_mes 'Error of opening, try again'
<<<<<<< HEAD
  jmp $without_parametrs

FileName DB 14,0,14 dup (0)
Handler DW ?
=======
  jmp start

FileName DB 14,0,14 dup (0)
>>>>>>> 655effa316a257e61634884bd0714f0f785a94a9
