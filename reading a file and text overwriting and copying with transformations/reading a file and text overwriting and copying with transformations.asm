org 100h

; macros:
next_line macro    ; emulate enter
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
print_mes macro message   ; print message
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


;=====================================================
; main:
start:
  next_line
;------- check string of parameters -------------------------
  mov CL, ES:[80h]            ; addr. of length parameter in psp
    cmp CL, 0                 ; is it 0 in buffer?
        jne $with_parametrs   ; yes
;---------------------------------------------------------------
; without parameters:
$without_parametrs:
  print_mes 'parameters have not been entered'
  next_line
  print_mes 'Please, input file name > '

  mov AH, 0Ah                 ;
  mov DX, offset FileName     ; get filename
  int 21h                     ;

  next_line
;===============================================================
  xor BH, BH                 ;
  mov BL, FileName[1]        ;
  mov FileName[BX+2], 0      ;  add 0 to get ascii-z file path
;===============================================================
  mov AX, 3D02h ; Open file for read and write
  mov DX, offset FileName+2
  int 21h
  jnc ok_of_opening           ; if success
  jmp error_of_opening        ; if there is error

;---------------------------------------------------------------
$with_parametrs:
  xor BH, BH
  mov BL, ES:[80h]
  mov byte ptr [BX+81h],0
;---------------------------------------------------------------
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
  mov AX, 3D02h ; Open file for read and write
  mov DX, DI
  int 21h
  jnc ok_of_opening
  jmp error_of_opening
;=====================================================
ok_of_opening:
  mov Handler, AX

  print_mes 'The file has been successfully opened'

  mov AH, 3Fh          ; read into buf from file
  mov BX, Handler      ;
  mov CX, 255         ; how much we read
  mov DX, OFFSET Buf   ; result into Buf
  int 21H              ;
  jc error_of_writing  ; if there is error


choose:   next_line
          print_mes 'Do you want to write into a new file?'
          next_line
          print_mes '1. Yes'
          next_line
          print_mes '2. No'
          next_line

          mov ah,01h
          int 21H

          cmp al,31h              ; see what a user has choosen
          je into_a_new_file
          cmp al,32h
          je overwriting
          next_line               ; if not 1 or 2 then try again
          print_mes 'incorrect input,try again'
          jmp choose

into_a_new_file:

          mov ah, 3Eh          ; close the old file
          mov BX, Handler      ;
          int 21H

          next_line
          print_mes 'Please, input name of new file > '

          mov AH, 0Ah
          mov DX, offset FileName       ; get name of a new file
          int 21h

          next_line
        ;===============================================================
          xor BH, BH
          mov BL, FileName[1]
          mov FileName[BX+2], 0
        ;===============================================================
          mov AX, 3D01h ; Open the new file for write
          mov DX, offset FileName+2
          int 21h

          mov Handler, AX

          jnc overwriting
          jmp error_of_opening_new



overwriting:

      xor si,si
      xor di,di

      cycle: ; we will write line_buf

          cmp Buf[si],0         ; if 0 - last writting and end of programm
          jne not_null
          mov Line_Buf[di],0
          inc si
          jmp write_buf_into_file

not_null: cmp Buf[si],10        ; if 10 - make next line
          jne symbol
          mov Line_Buf[di],10
          inc di
          mov Line_Buf[di],13
          inc si
          jmp write_buf_into_file

symbol:   mov bl,Buf[si]        ; else continue line_buf
          mov Line_Buf[di],bl
          inc si
          inc di
      jmp cycle

;===============writing of text=======================

      write_buf_into_file:

        xor ax,ax
        xor bx,bx

        mov bx,di           ; how many
        mov al,80           ; spaces
        sub al,bl           ; do we need

        mov CX,ax
        mov AH, 40h          ; write spaces into new line
        mov BX, Handler      ;
        mov DX, OFFSET spaces   ;
        int 21H              ;
        jc error_of_writing  ; if there is error

        mov AH, 40h          ; write Buf into file
        mov BX, Handler      ;
        mov CX, di           ;
        mov DX, OFFSET Line_Buf   ;
        int 21H              ;
        jc error_of_writing  ; if there is error

        cmp Line_Buf[di],0
        je success

        xor di,di
      jmp cycle

;-----------Success: ------------------------------------------
success:
    next_line
    print_mes 'the program has been successfully completed.'

  int 20h ; exit
;
error_of_opening:
  next_line
  print_mes 'Error of opening, try again'
  jmp $without_parametrs

  error_of_opening_new:
    next_line
    print_mes 'Error of opening, try again'
    jmp $into_a_new_file

error_of_writing:
  next_line
  print_mes 'Error of writing, try again'
  jmp ok_of_opening


FileName DB 14,0,14 dup (0)
NewFileName DB 14,0,14 dup (0)
Handler DW ?

spaces db 80 dup (20h)

Buf db 255 dup (0)

Line_Buf db 255 dup (0)
