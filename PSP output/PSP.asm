
org 100h




start:       MOV AH,9H
             MOV DX, OFFSET MES
             INT 21H ; print start message



          xor si,si ; main_counter = 0

cycle:

  xor cx,cx ; more one counter to make enter after 8 bytes. Or a divisibility check can also be used.

  cycle2:
          mov   bx, es:[si]


                            ; output BX
         mov DL,BL           ;
         RCR DL,4            ;
         CALL TETR_PRINT     ;
                            ;
        MOV DL,BL           ;
        CALL TETR_PRINT     ;

        MOV AH,9H           ; print space
        MOV DX, OFFSET space  ;
        INT 21H             ;

                            ;
        mov DL,BH           ;
        RCR DL,4            ;
        CALL TETR_PRINT     ;
        MOV DL,BH           ; end of output
                            ;
        CALL TETR_PRINT     ;

        MOV AH,9H                ; print BIGspace
        MOV DX, OFFSET bigspace  ;
        INT 21H                  ;

        INC si;          ; main_counter+=2
        INC si;          ;

        inc cx;


       cmp cx,8h
       jl cycle2

        MOV AH,9H            ; print enter
        MOV DX, OFFSET enter ;
        INT 21H              ;


      cmp SI,100h
      jl cycle





    INT 20H


ret


TETR_PRINT PROC NEAR         ; proc print
             MOV AH,02H      ;
             AND DL,0FH      ;
             ADD DL,30H      ;
             CMP DL,3AH      ;
             JL PRINT        ;
             ADD DL,07H      ;
PRINT:       INT 21H         ;
             mov AH, 9H      ;
             RET             ;
TETR_PRINT ENDP              ;


MES DB "PSP: ",10,13,"$"
space DB " $"
bigspace DB "   $"
enter db 10,13,"$"
