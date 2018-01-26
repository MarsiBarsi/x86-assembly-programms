org 100h

; macros:
next_line macro ; макрос для перехода на следующую строку
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
print_mes macro message ; макрос для печати сообщений
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;

;=====================================================
; main:
start:
;------- check string of parameters -------------------------
  mov CL, ES:[80h]            ; получаем длину параметров в CL
    cmp CL, 0                 ; если длина 0,
        jne $with_parametrs   ; то переходим на метку
;---------------------------------------------------------------
; without parameters:
$without_parametrs:
  print_mes 'parameters have not been entered'
  next_line
  next_line
  print_mes 'Please, input mask > '

  mov AH, 0Ah
  mov DX, offset searchmask   ; положим в searchmask название маски
  int 21h

  next_line
;===============================================================
  xor BH, BH                ; занулим bh
  mov BL, searchmask[1]     ; положим длину буфера в bl
  mov searchmask[BX+2], 0   ; положим 0 в конец буфера - конец файла

  lea dx, searchmask[2]      ;возьмём указатель на маску поиска, чтобы
                            ; чтобы использовать его при нахождении файла

  jmp searching              ; прыгаем на метку с поиском первого файла

$with_parametrs:
    xor BH, BH
    mov BL, ES:[80h]
    mov byte ptr [BX+81h],0
  ;---------------------------------------------------------------
    mov CL, ES:80h  ; длина строки в psp в cl
    xor CH,CH     ; CX=CL
    cld           ; DF=0
    mov DI, 81h   ; ES:DI-> начало строки в di
    mov AL,' '    ; стираем лишние пробелы, если они есть
    repe scasb    ; сканируем, пока пробелы

    dec DI        ; в итоге, в di - адрес первого символа в psp
  ;---------------------------------------------------------------
    mov dx, di


;=====================================================
searching:

   mov ax, 4E01h              ;найдём первый файл в текущем каталоге
   xor cx, cx                 ; кладем 0, потому что атрибуты не нужны. Ищем в своем каталоге
   int 21h
   jc no_more_files           ;если была ошибка - файлов по такой маске нет

   mov ah, 41h                ; удаляем
   mov dx, 80h+1Eh            ;
   int 21h                    ;

deleting:
    mov ax, 4F00h       ;ищем следующий файл
    int 21h
    jc finish           ;если больше не находим - выходим

    mov ah, 41h         ; удаляем найденный файл
    mov dx, 80h+1Eh     ;
    int 21h             ;
  jmp deleting

;==============================================================
;-----------Успешное завершение: ------------------------------------------
finish:
    next_line
    print_mes 'all files have been found'
    next_line
    print_mes 'the program has been successfully completed.'

  int 20h ; exit

no_more_files:
  print_mes 'the are no files with such name'
  int 20h


searchmask db 14,0,14 dup (0)
