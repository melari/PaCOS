; 4865 6c6c 6f20 776f 726c 6400
; h e  l l  o    w o  r l  d NULL


SET A, test
JSR stringCompress


:crash SET PC, crash

;void stringCompress(A string* target)
:stringCompress
    SET PUSH, B
    SET PUSH, X
    SET PUSH, Y
    SET PUSH, Z

    SET B, A
    ADD B, 1
    SET Z, A
    
    :_loop__stringCompress
    SET X, [A]
    SET Y, [B]
    SHL X, 8        ; shift char value to high byte
    AND X, 0xFF00   ; clear bottom byte
    AND Y, 0x00FF   ; clear top byte
    
    IFE X, 0x0000
      SET PC, _done__stringCompress
    IFE Y , 0x0000
      SET PC, _shortFinish__stringCompress

    BOR X, Y        ; combine two halfs
    SET [Z], X      ; save compressed word.
    
    ADD A, 2
    ADD B, 2
    ADD Z, 1
    SET PC, _loop__stringCompress
    
    :_shortFinish__stringCompress
    SET [Z], X
    SET PC, _return__stringCompress
    
    :_done__stringCompress
    SET [Z], 0x0000
    
    :_return__stringCompress
    SET Z, POP
    SET Y, POP
    SET X, POP
    SET B, POP
    SET PC, POP
    
:test DAT "Hello world", 0x0000
