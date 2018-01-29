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
;------- check string of parameters -------------------------
  mov CL, ES:[80h]            ; get lenght of parameters
    cmp CL, 0                 ; if not 0
        jne $with_parametrs   ; go to with_parametrs
;---------------------------------------------------------------
; without parameters:
$without_parametrs:
  print_mes 'parameters have not been entered'
  next_line
  next_line
  print_mes 'Please, input mask > '

  mov AH, 0Ah
  mov DX, offset searchmask   ; mask to searchmask
  int 21h

  next_line
;===============================================================
  xor BH, BH                ; bh = 0
  mov BL, searchmask[1]     ; length of searchmask to bl
  mov searchmask[BX+2], 0   ; end of buffer = 0

  lea dx, searchmask[2]      ; pointer for finding of a file

  jmp searching

$with_parametrs:
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


;=====================================================
searching:

   mov ax, 4E01h              ; first file in the dir
   xor cx, cx                 ; cx = 0 (without atributes)
   int 21h
   jc no_more_files           ; if there is an error - there are not files with such mask

   mov ah, 41h                ; delete it
   mov dx, 80h+1Eh            ;
   int 21h                    ;

deleting:
    mov ax, 4F00h       ; finding a next file with such mask
    int 21h
    jc finish           ; if there are not more - finish

    mov ah, 41h         ; delete it
    mov dx, 80h+1Eh     ;
    int 21h             ;
  jmp deleting

;==============================================================
;-----------Success: ------------------------------------------
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
