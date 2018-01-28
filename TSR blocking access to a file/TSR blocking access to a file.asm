
       ;in    al,60h         ;читаем клаву
       ;cmp   al,3Bh         ;F1 ?
       ;jne   @To_old        ;нет!

       org        80h
cmd_len            db    ?          ; длина командной строки
cmd_line           db    ?          ; начало командной строки

       org     100h

       ;===============================================================

       start:  jmp     initze   ;Выполняется только один раз
       tsr: pusha    ;Сохранить регистры
               push ds
               push 40h
               pop ds

               in al,60h
               cmp al,3Bh
               jne exit          ; нет - выйти



              mov ah,02h
              mov dx,'>'
              int 21H


              next_line
            ;===============================================================
              xor BH, BH
              mov BL, cmd_len[0]
            ;===============================================================
              mov AX, 3D01h ; Open file for write
              mov DX, offset cmd_line+2
              int 21h

              next_line

              mov Buf[0], al

              mov AH, 40h          ; write Buf into file
              mov BX, Handler      ;
              mov CX, si           ;
              mov DX, OFFSET Buf   ;
              int 21H              ;


       exit:   pop ds
               popa  ;Восстановить регистры
           db 0EAh  ;Обработать прерывание
       kbsave  dd   ?;двойное слово для сохранения обработчика адреса int 9 BIOS

       Handler DW ?
       Buf db 'privet'

       initze: push 0;Подпрограмма инициализации
               pop ds;Установить сегмент данных ds=0
               cli   ;Запретить прерывания
           mov si,9*4  ; адрес для int 9 в таблице векторов прерываний
           mov di,offset kbsave;для COM-программ es=cs
               movsw;ds:[9*4]->cs:kbsave;сохранить смещение старого обработчика
               movsw;ds:[9*4+2]->cs:kbsave+2;сохранить сегменный адрес старого обработчика
               mov word ptr ds:[si-4],offset tsr;подменить смещение int 9 на смещение нового обработчика
               mov word ptr ds:[si-2],cs;подменить сегменный адрес int 9 на сегменный адрес нового обработчика
               sti    ;Разрешить прерывания
               mov dx,offset initze;Размер программы
               int 27h;Завершить и остаться резидентом
       end     begin
