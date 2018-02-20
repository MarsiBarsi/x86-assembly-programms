.MODEL Tiny
.CODE
.STARTUP
.386                                ;для jump near и команд pusha и popa

      jmp real_start                ;прыгаем на начало программы
magic       dw 0BABAh               ;идентификатор - уже сидим в памяти

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
      cmp al,19h                    ; нажата p ?
      jne call_old_09

      push es ; Сохраним ES
      mov ax, 40h ; Настроим ES на начало
      mov es, ax ; Данных BIOS;
      mov AL, ES: [17h] ; Получим слово флагов клавиатуры
      pop ES ; Восстановим ES – он больше не нужен
      cmp AL, 12 ; (Alt и ctrl) уже нажаты?
      jne call_old_09 ; если нет - на старый

      push    0ffffh
      push    0000h
      retf


call_old_09:

      pop   ds
      pop   es
      popa
      popf                          ;востановим все флаги
      db 0eah                       ;jmp dword ptr (опкод)
old_09_offset  dw ?                 ;здесь уже конкретный адрес
old_09_segment dw ?                 ;старого Int 09. прыгаем туда


;СТАРТ основной программы
real_start:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

int_vectors:
      mov   ax,3509h                ;получить в ES:BX вектор 09
      int   21h                     ;прерывания


          cmp   byte ptr ds:[82h],'-'   ;проверяем параметр командной
          je    remove

          cmp   word ptr es:magic,0BABAh;сравниваем с идентификатором
          je    already_inst            ;мы уже загружены - выходим

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

      print_mes 'tsr successful installed'
      mov   dx,offset real_start    ;остаемся в памяти резидентом
      int   27h                     ;и выходим
;КОНЕЦ основной программы


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
