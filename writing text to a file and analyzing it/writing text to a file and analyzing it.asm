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
count macro letter    ; macro for ax_hex_to_dec_and_write
    xor dx,dx
    div bx
    add dl,'0'
    mov amount[letter],dl
endm
;;;
ax_hex_to_dec_and_write macro   ; value of ax to dec
  local end
  xor cx,cx
  mov bx,10

  count 2                       ; third number
  test ax,ax
  jz end
  count 1                       ; second number
  test ax,ax
  jz end
  count 0                       ; first number

  end:                          ; write amount[] to file

    mov AH, 40h          ; write into file
    mov BX, Handler      ;
    mov CX, 3            ;
    mov DX, OFFSET amount   ;
    int 21H              ;
    jc error_of_writing  ; if there is error

    mov amount[0],0 ; zeros to amount to use again
    mov amount[1],0 ;
    mov amount[2],0 ;
endm

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

  mov AH, 0Ah
  mov DX, offset FileName
  int 21h

  next_line
;===============================================================
  xor BH, BH
  mov BL, FileName[1]
  mov FileName[BX+2], 0
;===============================================================
  mov AX, 3D01h ; Open file for write
  mov DX, offset FileName+2
  int 21h
  jnc ok_of_opening
  jmp error_of_opening

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
  mov AX, 3D01h ; Open file for write
  mov DX, DI
  int 21h
  jnc ok_of_opening
  jmp error_of_opening
;=====================================================
ok_of_opening:
  mov Handler, AX

  print_mes 'The file has been successfully opened'

  next_line
  print_mes 'Text for file > '
  next_line

  xor si,si     ; counter of symbols
  xor di,di     ; russian symbols
  xor bp,bp     ; latin symbols

  cycle_for_input_into_buf:

     mov ah, 01h       ;
	   int 21h           ;
     mov Buf[si], al   ;

     cmp Buf[si],13
     je write_buf_into_file
    ;-----------------------------------------------------
     check_for_russian:
        cmp Buf[si], 127      ; is Buf[si] in ASCII codes of russian symbols?
        jle  check_for_latin  ;
        cmp Buf[si], 192
        jl check_for_latin
        cmp Buf[si], 255      ;
        je check_for_latin    ;

        inc di              ; if yes then di+=1
     ;-----------------------------------------------------

     check_for_latin:
        cmp Buf[si], 65     ; is Buf[si] in ASCII codes of latin symbols?
        jl check_of_lenght  ;
        cmp Buf[si], 122    ;
        jg check_of_lenght  ;
        cmp Buf[si], 91     ;
        jl ok_latin
        cmp Buf[si],96
        jg ok_latin

        jmp check_of_lenght ; if between 91 and 96(not latin symbols)

        ok_latin:
          inc bp             ; if yes then bp+=1
      ;-----------------------------------------------------


      check_of_lenght:      ; because buf for 255 bytes
          cmp si, 255       ;
          je limit_of_lenght;
      ;-----------------------------------------------------

      inc si                ; next step of cycle

    jmp cycle_for_input_into_buf ; end of cycle

;===============writing of text=======================

    write_buf_into_file:

      mov AH, 40h          ; write Buf into file
      mov BX, Handler      ;
      mov CX, si           ;
      mov DX, OFFSET Buf   ;
      int 21H              ;
      jc error_of_writing  ; if there is error

;================writing of statistics================
; ---------------Symbols:-----------------------------
      mov AH, 40h          ; write symbols_amount text into file
      mov BX, Handler      ;
      mov CX, symbols_amount_len            ;
      mov DX, OFFSET symbols_amount   ;
      int 21H              ;
      jc error_of_writing  ; if there is error

      mov ax,si                 ; amount to ax
      ax_hex_to_dec_and_write   ; write amount into file
;----------------Strings:-----------------------------
      mov AH, 40h          ; write strings_amount text into file
      mov BX, Handler      ;
      mov CX, strings_amount_len            ;
      mov DX, OFFSET strings_amount   ;
      int 21H              ;
      jc error_of_writing  ; if there is error

      mov ax,si           ; ax = (si div 80)
      mov bl,80
      div bl              ; 80 - lenght of full string in DOS

      xor ah,ah
      inc al                 ; amount to ax
      ax_hex_to_dec_and_write   ; write amount into file
;-----------------Russian-----------------------------
      mov AH, 40h          ; write russian_amount text into file
      mov BX, Handler      ;
      mov CX, russian_symbols_amount_len            ;
      mov DX, OFFSET russian_amount   ;
      int 21H              ;
      jc error_of_writing  ; if there is error

      mov ax,di                 ; amount to ax
      ax_hex_to_dec_and_write   ; write amount into file
;------------------Latin--------------------------------
      mov AH, 40h          ; write latin_amount text into file
      mov BX, Handler      ;
      mov CX, latin_symbols_amount_len           ;
      mov DX, OFFSET latin_amount   ;
      int 21H              ;
      jc error_of_writing  ; if there is error

      mov ax,bp                ; amount to ax
      ax_hex_to_dec_and_write  ; write amount into file
;==============================================================
;-----------Success: ------------------------------------------

    next_line
    print_mes 'the program has been successfully completed.'

  int 20h ; exit
;
error_of_opening:
  next_line
  print_mes 'Error of opening, try again'
  jmp $without_parametrs

error_of_writing:
  next_line
  print_mes 'Error of writing, try again'
  jmp ok_of_opening

limit_of_lenght:
  next_line
  print_mes 'unfortunately, the maximum length of text is 255 characters'
  jmp write_buf_into_file


FileName DB 14,0,14 dup (0)
Handler DW ?

Buf db 255 dup (0)

symbols_amount db 10,13,'total were entered symbols: '
symbols_amount_len equ $ - symbols_amount

strings_amount db 10,13,'Strings: '
strings_amount_len equ $ - strings_amount

russian_amount db 10,13,'Russian symbols: '
russian_symbols_amount_len equ $ - russian_amount

latin_amount db 10,13,'Latin symbols: '
latin_symbols_amount_len equ $ - latin_amount

amount db 3 dup (0)
