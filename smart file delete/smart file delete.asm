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
  ;mov AX, 3D01h ; Open file for write
  ;mov DX, offset FileName+2
  ;int 21h
  ;jnc ok_of_opening
  ;jmp error_of_opening
  jmp ok_of_opening
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
  ;mov AX, 3D01h ; Open file for write
  ;mov DX, DI
  ;int 21h
  ;jnc ok_of_opening
  ;jmp error_of_opening
;=====================================================
ok_of_opening:
  mov Handler, AX

  print_mes 'Ok'

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



FileName DB 14,0,14 dup (0)
Handler DW ?

Buf db 255 dup (0)
buf_len equ $ - Buf
