.MODEL Tiny
.CODE
.STARTUP
.386                                ;для jump near и команд pusha и popa

      jmp real_start                ;прыгаем на начало программы
Name_of_File     db 14,0,14 dup (0)      ;имя файла
handle            dw 0                 ;заголовок (хендл)
access_status  db 1                    ;флаг готовности

mes db 'sorry,this file is blocked',10,13,'$'

;Новый обработчик 09h прерывания
new_09h:
      pushf                         ;сохраняем все флаги
      pusha                         ;основные регистры
      push  es                      ;регистры ES и DS
      push  ds
      push  cs                      ;в DS равен CS
      pop   ds
                                    ;запретим прерывания
      in    al, 60h                 ;получить сканкод
      cmp al,3Bh                    ; нажата f1 ?
      jne call_old_09

      cmp access_status,0           ; если 0 - ставим 1
      je do_one

      mov access_status,0           ; если 1 - ставим 0
      jmp call_old_09

do_one: mov access_status,1

call_old_09:

      pop   ds
      pop   es
      popa
      popf                          ;востановим все флаги
      db 0eah                       ;jmp dword ptr (опкод)
old_09_offset  dw ?                 ;здесь уже конкретный адрес
old_09_segment dw ?                 ;старого Int 09. прыгаем туда

;Новый обработчик 21h прерывания
new_21h:
      pushf                         ;сейвим все что будем менять
      pusha
      push  es
      push  ds
      push  cs
      pop   ds

      cmp access_status,1
      je call_old_21

locked:
      cmp ah,3dh              ; открытие файла
      je with_filename

      cmp ah,41h              ; удаление файла
      je with_filename

      cmp ah,3Fh              ; чтение из файла
      je with_handle

      cmp ah,40h              ; запись в файл
      je with_handle

      jmp call_old_21

our_command:

  with_handle:  cmp bx,handle
                jne call_old_21
                pop   ds                      ;восстанавливаем флаги и
                pop   es                      ;все такое прочее
                popa                          ;то что меняли
                popf
                stc
                mov bx,00ffh
                jmp to_old

  with_filename:  cmp dx,offset Name_of_File
                  jne call_old_21
                  pop   ds                      ;восстанавливаем флаги и
                  pop   es                      ;все такое прочее
                  popa                          ;то что меняли
                  popf
                  stc
                  mov dx,0
                  jmp to_old

call_old_21:
      pop   ds                      ;восстанавливаем флаги и
      pop   es                      ;все такое прочее
      popa                          ;то что меняли
      popf
to_old: db 0eah                       ;и прыгаем на старый обработчик
old_21_offset  dw ?
old_21_segment dw ?

;===============================================================
int_2fh_vector DD ?

int_2fh proc far
    cmp ax,0b700h
    jne Pass_2fh
    mov al,0ffh
    iret
    Pass_2fh:
    jmp dword ptr cs:[int_2fh_vector]
int_2fh endp
;======================================


;СТАРТ основной программы
real_start:
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    mov ax,0b700h   ; статус мультиплексного прерывания
    int 2fh         ; мультиплекс
    cmp al,0        ; если в al - 0 уже загружены
    jne    already_inst            ;мы уже загружены - выходим

;------- check string of parameters -------------------------
  mov CL, ES:[80h]            ; get lenght of parameters
    cmp CL, 0                 ; if not 0
        je $without_parametrs   ; go to with_parametrs
;---------------------------------------------------------------
$with_parametrs:

    cmp   byte ptr ds:[82h],'-'   ;проверяем параметр командной
    je    remove                  ;строки. Равен "-" -выгружаемсо

    xor BH, BH
    mov BL, ES:[80h]
    mov byte ptr [BX+81h],0
  ;---------------------------------------------------------------
    mov CL, ES:80h  ; lenght of psp
    xor CH,CH     ; CX=CL
    cld           ; DF=0
    mov DI, 81h   ; ES:DI-> di
    mov AL,' '    ; if spaces - delete
    repe scasb    ; while spaces

    dec DI        ; di - first symbol of PSP paramets
  ;---------------------------------------------------------------
    mov dx, di
    jmp int_vectors
$without_parametrs:
      print_mes 'parameters have not been entered'
      next_line
      next_line
      print_mes 'Please, input filename > '

      mov AH, 0Ah
      mov DX, offset Name_of_File   ; mask to searchmask
      int 21h

      next_line
    ;===============================================================
      xor BH, BH                ; bh = 0
      mov BL, Name_of_File[1]     ; length of searchmask to bl
      mov Name_of_File[BX+2], 0   ; end of buffer = 0

      lea dx, Name_of_File[2]      ; pointer for finding of a file



int_vectors:
      mov   ax,3509h                ;получить в ES:BX вектор 09
      int   21h                     ;прерывания

      push  es
      mov   ax,ds:[2Ch]             ;psp
      mov   es,ax
      mov   ah,49h                  ;хватит памяти, чтобы остаться
      int   21h                     ;резидентом?
      pop   es
      jc    not_mem                 ;не хватило - выходим

      mov   cs:old_09_offset,bx     ;запомним старый адрес 09
      mov   cs:old_09_segment,es    ;прерывания
      mov   ax,2509h                ;установим вектор на 09
      mov   dx,offset new_09h       ;прерывание
      int   21h

      mov   ax,3521h                ;получить в ES:BX вектор 21
      int   21h                     ;прерывания
      mov   cs:old_21_offset,bx     ;запомним старый адрес 21
      mov   cs:old_21_segment,es    ;прерывания
      mov   ax,2521h                ;установим вектор на 21
      mov   dx,offset new_21h       ;прерывание
      int   21h

      call  create_file         ;проверяем лог-файл.
                                    ;если нет - создаем.

      print_mes 'tsr successful installed'
      mov   dx,offset real_start    ;остаемся в памяти резидентом
      int   27h                     ;и выходим
;КОНЕЦ основной программы

;Проверим существует ли файл, если нет
;создадим его. Процедура.
create_file:
      mov   ax, 3D01h
      lea   dx, Name_of_File
      int   21h                     ;попробуем открыть файл
      mov   handle, ax              ;
      jnc   close_f                   ;файл есть - закрываем его

 create_f: mov ah, 3Ch                 ;создаем файл
          mov   cx, 02h
          lea   dx, logfile
          int   21h
          mov   handle, ax

 close_f: mov bx, handle              ;закрываем файл
          mov   ah, 3Eh
          int   21h
    ret

;сюда попадаем если в командной строке
;был указан ключ "-". Выгружаемся из памяти
remove:
      cmp   word ptr es:magic,0BABAh  ;а мы были загружены?
      jne   not_installed             ;не были - выходим

      push  es
      push  ds
      mov   dx,es:old_09_offset     ;возвращаем вектор прерывания
      mov   ds,es:old_09_segment    ;09 как и было
      mov   ax,2509h
      int   21h

      mov   dx,es:old_21_offset     ;востановим вектор прерывания
      mov   ds,es:old_21_segment    ;21 как было
      mov   ax,2521h
      int   21h

      pop   ds
      pop   es
      mov   ah,49h                  ;освобождаем память
      int   21h
      jc    not_remove              ;не освободилась? ошибка

      print_mes 'tsr successful removed'
      jmp   exit                    ;выходим

;Сюда попадаем если был указан ключ "-", но перед
;этим tsr не был загружен
not_installed:
      print_mes 'tsr not installed. Nothing remove'
      jmp   exit

; ошибка с высвобождением памяти.
not_remove:
      print_mes 'Can not remove tsr. Error'
      jmp   exit

;Пользователь пытается повторно загрузить прогу
already_inst:
      print_mes 'tsr already installed'
      jmp   exit

;Не хватает памяти чтоб остаться резидентом
not_mem:
      print_mes 'No free memory for loading tsr'
      jmp exit

;Выходим из программы
exit:
      int  20h

END
