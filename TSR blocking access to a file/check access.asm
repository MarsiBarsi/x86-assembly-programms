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

  mov ah,40h
  mov DX, offset FileName+2
  int 21h

  print_mes 'The file has been successfully opened'

;-----------Success: ------------------------------------------
success:
    next_line
    print_mes 'the program has been successfully completed.'



  int 20h ; exit
;
error_of_opening:
  next_line
  print_mes 'Error of opening, try again'
  int 20h

  error_of_opening_new:
    next_line
    print_mes 'Error of opening, try again'
    int 20h

error_of_writing:
  next_line
  print_mes 'Error of writing, try again'
  int 20h


FileName DB 14,0,14 dup (0)
NewFileName DB 14,0,14 dup (0)
Handler DW ?

spaces db 80 dup (20h)

Buf db 255 dup (0)

Line_Buf db 255 dup (0)
