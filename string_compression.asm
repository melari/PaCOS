; 4865 6c6c 6f20 776f 726c 6400
; h e  l l  o    w o  r l  d NULL

SET Z, 0x8000

SET A, test
SET B, 0x1000
JSR stringToDChar
SET A, 0x1000
JSR printDChar


:crash SET PC, crash

;A dchar* stringToDChar(A string* target, B out dchar* location)
; Compress a standard string into dchar format
:stringToDChar
    SET PUSH, A
    SET PUSH, B
    SET PUSH, X
    SET PUSH, Y
    SET PUSH, Z

    SET Z, B
    SET B, A
    ADD B, 1    
    
    :_loop__stringToDChar
    SET X, [A]
    SET Y, [B]
    SHL X, 8        ; shift char value to high byte
    AND X, 0xFF00   ; clear bottom byte
    AND Y, 0x00FF   ; clear top byte
    
    IFE X, 0x0000
      SET PC, _done__stringToDChar
    IFE Y , 0x0000
      SET PC, _shortFinish__stringToDChar

    BOR X, Y        ; combine two halfs
    SET [Z], X      ; save compressed word.
    
    ADD A, 2
    ADD B, 2
    ADD Z, 1
    SET PC, _loop__stringToDChar
    
    :_shortFinish__stringToDChar
    SET [Z], X
    SET PC, _return__stringToDChar
    
    :_done__stringToDChar
    SET [Z], 0x0000
    
    :_return__stringToDChar
    SET Z, POP
    SET Y, POP
    SET X, POP
    SET B, POP
    SET A, POP
    SET PC, POP
    
;void pringDChar(A dchar* message)
:printDChar
    SET PUSH, I
    SET I, A
    
    :_loop__printDChar
    SET A, [I]          
    SHR A, 8    
    IFE A, 0x0000                     ; High character
    SET PC, _done__printDChar
    JSR printChar
    
    SET A, [I]
    AND A, 0x00FF
    IFE A, 0x0000                     ; Low character
    SET PC, _done__printDChar
    JSR printChar
    
    ADD I, 1
    SET PC, _loop__printDChar

    :_done__printDChar
    SET I, POP    
    SET PC, POP
    
    
;void printChar(A char character)
; Print a single character to the console.
:printChar	
    AND A, 0x00FF
    BOR A, [VAR_PRINT_COL]
    SET [Z], A
    ADD Z, 1    
    SET PC, POP
    
    
:test DAT "Hello world", 0x0000
:VAR_PRINT_COL DAT 0xF000