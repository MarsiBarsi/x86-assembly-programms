.MODEL Tiny
.CODE
.STARTUP
.386

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

  count 3                       ; 4 number
  test ax,ax
  jz end
  count 2                       ; third number
  test ax,ax
  jz end
  count 1                       ; second number
  test ax,ax
  jz end
  count 0                       ; first number

  end:                          ; write amount[] to out

    mov AH, 09h          ; write into file
    mov DX, OFFSET amount   ;
    int 21H              ;

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

  mov AH, 0Ah
  mov DX, offset FileName
  int 21h

  next_line
;===============================================================
  xor BH, BH
  mov BL, FileName[1]
  mov FileName[BX+2], 0
;===============================================================
  mov AX, 3D00h ; Open file for read
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
  mov AX, 3D00h ; Open file for read
  mov DX, DI
  int 21h
  jnc ok_of_opening
  jmp error_of_opening
;=====================================================
ok_of_opening:
  mov Handler, AX

  print_mes 'The file has been successfully opened'
  next_line
  print_mes 'Enter new file name: '
;------New file opening:
  mov AH, 0Ah
  mov DX, offset NewFileName       ; get name of a new file
  int 21h

  next_line
;===============================================================
  xor BH, BH
  mov BL, NewFileName[1]
  mov NewFileName[BX+2], 0
;===============================================================
  mov AX, 3D01h ; Open the new file for write
  mov DX, offset NewFileName+2
  int 21h

  mov NewHandler, AX
  print_mes "New file was opened"
  next_line

;------------------------------------
;---Reading from the first FILE:
xor si,si
xor di,di

work:
    mov AH, 3Fh          ; read into buf from file
    mov BX, Handler      ;
    mov CX, 34998         ; how much we read
    mov DX, OFFSET Buf   ; result into Buf
    int 21H              ;
    jc error_of_reading  ; if there is error

    cmp ax,0
    je write_buf_into_a_new_file

;------------get emails:
    xor bp,bp ; pointer for old buf

cycle:
        cmp Buf[bp],0         ; if 0 - last writting and end of programm
        jne not_null
        inc bp
        jmp work

not_null:
        cmp Buf[bp],65h ; 'e'
        jne next_step
        inc bp
        cmp Buf[bp],2dh ; "-"
        jne next_step
        inc bp
        cmp Buf[bp],6dh ; 'm'
        jne next_step

        add bp,5 ; under bp is the first symbol of e-mail

        catch_adress:
          xor bx,bx
          before_at:

            cmp Buf[bp],40h ; is it @ ?
            je before_dot

            cmp Buf[bp],10
            je next_step

            cmp Buf[bp],13
            je next_step

            mov dl,Buf[bp]
            mov Buf[35000+si+bx],dl

            inc bx
            inc bp

            jmp before_at

          before_dot:
            cmp Buf[bp],2eh
            je last_symbols

            cmp Buf[bp],10
            je next_step
            cmp Buf[bp],13
            je next_step


            mov dl,Buf[bp]
            mov Buf[35000+si+bx],dl
            inc bx
            inc bp

            jmp before_dot

          last_symbols:
              cmp Buf[bp],2eh     ; for 2 level domains
              je ok_latin         ;
              cmp Buf[bp], 65     ; is Buf[si] in ASCII codes of latin symbols?
              jl end_of_catching  ;
              cmp Buf[bp], 122    ;
              jg end_of_catching  ;
              cmp Buf[bp], 91     ;
              jl ok_latin
              cmp Buf[bp],96
              jg ok_latin
              jmp end_of_catching

              ok_latin:
                  mov dl,Buf[bp]
                  mov Buf[35000+si+bx],dl
                  inc bp
                  inc bx
                jmp last_symbols

            end_of_catching:
              add si,bx

              mov Buf[35000+si],10
              inc si


              inc di

        next_step:
            inc bp
        jmp cycle


write_buf_into_a_new_file:
        mov CX,si
        mov AH, 40h          ; write spaces into new line
        mov BX, NewHandler   ;
        mov DX, OFFSET Buf[35000]   ;
        int 21H              ;
        jc error_of_writing  ; if there is error

next_line
print_mes "total e-mails: "

mov ax, di
ax_hex_to_dec_and_write

next_line
print_mes 'Done successfully!'

int 20h


error_of_opening:
  next_line
  print_mes 'Error of opening, try again'
  jmp $without_parametrs

error_of_writing:
  next_line
  print_mes 'Error of writing, try again'
  jmp ok_of_opening

error_of_reading:
  next_line
  print_mes 'Reading failed'
  int 20h

amount db 4 dup (0),"$"

FileName DB 14,0,14 dup (0)
Handler DW ?

NewFileName db 14,0,14 dup (0)
NewHandler dw ?

Buf db 55001 dup (0)



END
