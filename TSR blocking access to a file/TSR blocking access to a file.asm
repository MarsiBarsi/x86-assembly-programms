.MODEL Tiny
.CODE
.STARTUP
.386                                ;для jump near и команд pusha и popa

      jmp real_start                ;прыгаем на начало программы
magic       dw 0BABAh               ;идентификатор - уже сидим в памяти
logfile     db 'file.txt',0      ;имя файла
handle            dw 0              ;заголовок (хендл)
buf         db 41 dup (?)           ;буффер 40 байт + 1 байт на всякий
bufptr            dw 0              ;текущий указатель буффера (смещение)
must_write  db 0                    ;флаг готовности к записи

mes db 'sorry,this file is blocked$'

;Новый обработчик 09h прерывания
new_09h:
      pushf                         ;сохраняем все флаги
      pusha                         ;основные регистры
      push  es                      ;регистры ES и DS
      push  ds
      push  cs                      ;в DS равен CS
      pop   ds
      ;cli                          ;запретим прерывания
      in    al, 60h                 ;получить сканкод
      cmp al,3Bh                    ; нажата f1 ?
      jne    call_old_09

call_old_09:
      ;sti                          ;разрешим прерывания
      pop   ds
      pop   es
      popa
      popf                          ;востановим всю хренотень
      db 0eah                       ;jmp dword ptr (опкод)
old_09_offset  dw ?                 ;здесь уже конкретный адрес
old_09_segment dw ?                 ;старого Int 09. прыгаем туда

;Новый обработчик 21h прерывания
;DOS IDLE INTERRUPT
new_21h:
      pushf                         ;сейвим все что будем менять
      pusha
      push  es
      push  ds
      push  cs
      pop   ds


      cmp ah,3dh
      je our_command

      cmp ah,41h
      je our_command

      cmp ah,3Fh
      je our_command

      cmp ah,40h
      je our_command
      jmp call_old_21

our_command:

      cmp dx,offset logfile
      jne call_old_21

      mov ah,09h
      mov dx,offset mes
      int 21h



call_old_21:
      pop   ds                      ;восстанавливаем флаги и
      pop   es                      ;все такое прочее
      popa                          ;то что меняли
      popf
      db 0eah                       ;и прыгаем на старый обработчик
old_21_offset  dw ?
old_21_segment dw ?


;СТАРТ основной программы
real_start:
      mov   ax,3509h                ;получить в ES:BX вектор 09
      int   21h                     ;прерывания

      cmp   byte ptr ds:[82h],'-'   ;проверяем параметр командной
      je    remove                  ;строки. Равен "-" -выгружаемсо

      cmp   word ptr es:magic,0BABAh;сравниваем с идентификатором
      je    already_inst            ;мы уже загружены - выходим

      push  es
      mov   ax,ds:[2Ch]             ;psp
      mov   es,ax
      mov   ah,49h                  ;хватит памяти чтоб остаться
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

      call  create_log_file         ;проверяем лог-файл.
                                    ;если нет - создаем.

      mov   dx,offset ok_installed  ;выводим что все ок
      mov   ah,9
      int   21h
      mov   dx,offset real_start    ;остаемся в памяти резидентом
      int   27h                     ;и выходим
;КОНЕЦ основной программы

;Проверим существует ли файл, если нет
;создадим его. Процедура.
create_log_file:
      mov   ax, 3D01h
      lea   dx, logfile
      int   21h                     ;попробуем открыть файл
      mov   handle, ax              ;
      jnc   clog4                   ;файл есть - закрываем его

 clog3: mov ah, 3Ch                 ;создаем файл
      mov   cx, 02h                 ;аттрибут - скрытый
      lea   dx, logfile
      int   21h
      mov   handle, ax

 clog4: mov bx, handle              ;закрываем файл
      mov   ah, 3Eh
      int   21h
      ret

;сюда попадаем если в командной строке
;был указан ключ "-". Выгружаемся из памяти
remove:
      cmp   word ptr es:magic,0BABAh;а мы ваще были загружены?
      jne   not_installed           ;не были - выходим

      push  es
      push  ds
      mov   dx,es:old_09_offset     ;возвращаем вектор прерывания
      mov   ds,es:old_09_segment    ;09 как и было
      mov   ax,2509h
      int   21h

      mov   dx,es:old_21_offset     ;востановим вектор прерывания
      mov   ds,es:old_21_segment    ;28 как было
      mov   ax,2521h
      int   21h

      pop   ds
      pop   es
      mov   ah,49h                  ;освобождаем память
      int   21h
      jc    not_remove              ;не освободилась? Хз - ошибка

      mov   dx,offset removed_msg   ;выводим сообщение - все ок
      mov   ah,9                    ;выгрузились
      int   21h
      jmp   exit                    ;выходим воще из проги

;Сюда попадаем если был указан ключ "-", но перед
;этим tsr не был загружен
not_installed:
      mov   dx, offset noinst_msg
      mov   ah,9
      int   21h
      jmp   exit

;Какая-то ошибка с высвобождением памяти.
not_remove:
      mov   dx, offset noremove_msg
      mov   ah,9
      int   21h
      jmp   exit

;Пользователь пытается повторно загрузить прогу
already_inst:
      mov   dx, offset already_msg
      mov   ah,9
      int   21h
      jmp   exit

;Не хватает памяти чтоб остаться резидентом
not_mem:
      mov   dx, offset nomem_msg
      mov   ah,9
      int   21h

;Выходим из программы
exit:
      int  20h

ok_installed      db 'tsr successful installed$'
already_msg       db 'tsr already installed$'
nomem_msg         db 'No free memory for loading tsr$'
removed_msg       db 'tsr successful removed$'
noremove_msg      db 'Can not remove tsr. Error$'
noinst_msg        db 'tsr not installed. Nothing remove$'
END
