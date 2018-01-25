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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;

;=====================================================
; main:
start:
  next_line
  print_mes 'Please, input mask > '

  mov AH, 0Ah
  mov DX, offset searchmask
  int 21h

  next_line
;===============================================================
  xor BH, BH
  mov BL, searchmask[1]
  mov searchmask[BX+2], 0

;---------------------------------------------------------------

;=====================================================


   mov ax, 4E01h              ;найдём первый файл в текущем каталоге
   xor cx, cx                 ; кладем 0, потому что атрибуты не нужны. Ищем в своем каталоге
   lea dx, searchmask[2]      ;возьмём указатель на маску поиска
   int 21h
   jc no_more_files           ;если была ошибка - файлов по такой маске нет

   mov ah, 41h
   mov dx, 80h+1Eh
   int 21h

deleting:
    mov ax, 4F00h       ;ищем следующий файл
    int 21h
    jc finish           ;если не находим - выйдем

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
