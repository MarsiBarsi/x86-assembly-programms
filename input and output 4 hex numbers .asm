
org 100h         


start:       MOV AH,9H 
       MOV DX, OFFSET MES
       INT 21H ; print MES         
       
        call tetr_input     ; input 4 hex numbers into BX
        MOV BH,AL           ;
                            ; 
                            ;
        call tetr_input     ;
        mov CL,AL           ;
        rcr CL,4            ;
        ADD BH,CL           ;
                            ;
                            ;
        call tetr_input     ;
        MOV Bl,AL           ;
                            ;
                            ;
        call tetr_input     ;
        mov CL,AL           ;
        rcr CL,4            ;
        ADD Bl,CL           ; end of input
                            
 
        
        
        
       MOV AH,9H 
       MOV DX, OFFSET MES2 
       INT 21H       
        
        mov AH, 9H          ; output BX
        mov DL,BH           ;                                                                   
        RCR DL,4            ;  
        CALL TETR_PRINT     ;
                            ;
        MOV DL,BH           ;
        CALL TETR_PRINT     ;
                            ;
        mov DL,BL           ;                                                                    
        RCR DL,4            ;
        CALL TETR_PRINT     ;
        MOV DL,BL           ; end of output
                            ;                            
        CALL TETR_PRINT     ;                                                                                                             


    INT 20H
               
     
ret                                                                                                              
        
tetr_input proc near         ; proc input
     MOV AH,01H;             ;
     INT 21H;                ;
                             ;
     cmp AL, 30h             ; if < (0..9) - error
     jl  err                 ;
     cmp AL, 39h             ; if in (0..9) - 
     jl  ifright             ; right
                             ;
     cmp AL, 41h             ; if not in (A..F) - err 
     jl err                  ; 
     cmp AL, 46h             ;
     ja err                  ;  
                             ; if in (A..F) - continue to ifright
                             ;
ifright:  SUB AL,030H        ; hex humber of symbol into AL
          CMP AL,0AH;        ;
          JL METK            ;
          SUB AL,07H;        ;
 METK:    ROL AL,4           ;
                             ;
ret                          ;
tetr_input endp              ;
 
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
 
err:     MOV AH,9H 
           MOV DX, OFFSET MES_ERR 
           INT 21H  
         jmp start  
                          
           
MES DB "Input 4 hex numbers for BX --> $"      
MES2 DB 10,13,"BX: $"
MES_ERR DB 10,13,"invalid input, try again",10,13,"$"             
             
              