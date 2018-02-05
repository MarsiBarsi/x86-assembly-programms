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
  mov CX, 1000         ; how much we read
  mov DX, OFFSET Buf   ; result into Buf
  int 21H              ;
  jc error_of_writing  ; if there is error

  mov ah, 3Eh          ; close the old file
  mov BX, Handler      ;
  int 21H

  xor si,si

main_cycle:
      cmp Buf[si], 122    ; if between 96 and 122 - our
      jl our_symbol         ; because 96-122 - small latyn letters
      cmp Buf[si], 97     ;
      jg our_symbol          ;

      cmp Buf[si], 192
      jl not_our
      cmp Buf[si], 255      ;
      je not_our   ;


  our_symbol:
      mov al,Buf[si]      ; make symbol capital (ascii code -= 32 )
      sub al,32           ;
      mov Buf[si],al      ;

  not_our:
      inc si              ; si++

      cmp Buf[si],0       ; if 0 - it is the end of the file
      je new_file         ;

jmp main_cycle


new_file:
          dec si          ; si-- because now Buf[si] - 0

          next_line
          print_mes 'Please, input name of new file > '

          mov AH, 0Ah
          mov DX, offset FileName       ; get name of a new file
          int 21h

          next_line
        ;===============================================================
          xor BH, BH
          mov BL, FileName[1]           ; get lenght of the filename
          mov FileName[BX+2], 0         ; make ascii-z string with 0 at end
        ;===============================================================
          mov AX, 3D01h ; Open the new file for write
          mov DX, offset FileName+2
          int 21h

          mov Handler, AX       ; handler is a logical number of the new file

          jnc write_buf_into_file       ; if there are not mistakes - jump
          jmp error_of_opening_new      ; if there are some mistakes

;===============writing of text=======================

      write_buf_into_file:

        mov AH, 40h          ; write Buf into file
        mov BX, Handler      ;
        mov CX, si           ;
        mov DX, OFFSET Buf   ;
        int 21H              ;
        jc error_of_writing  ; if there is error

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
    jmp new_file

error_of_writing:
  next_line
  print_mes 'Error of writing, try again'
  jmp ok_of_opening


FileName DB 14,0,14 dup (0)
Handler DW ?

spaces db 80 dup (20h)

Buf db 1023 dup (0)
