\ Basic utilities to help things for the programmer
\

: type-my-base ( -- )
  base @ dup { saved-base } case
    #10 of ." #" endof
    #16 of ." $" endof
    #8 of ." /" endof
    #2 of ." %" endof
    dup #10 base ! (.) saved-base base !
  endcase
;

: my-prompt ( ? -- ? )
  ." ok<"
  type-my-base
  compiling-to-flash? if ." , flash>" else ." , RAM>" then
  .s
  cr
;

: debugprompt ['] my-prompt prompt-hook ! ;

debugprompt
\ : init init debugprompt ; 
