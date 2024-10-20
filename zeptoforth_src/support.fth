\ Some support words

: WITHIN ( test low high -- flag ) OVER - >R - R> U< ;



\ from Tachyon, Peter Jakacki 2021, MIT license.
: << LSHIFT ;
: >> RSHIFT ;

\ Logical left-rotation of one bit-place
: rol  ( x1 - - x2 )
  dup 1 << swap $80000000 and if 1+ then
;

: EMITD ( 0...9 -- )    9 MIN $30 + EMIT ;

: .HEX ( n cnt -- ) HEX  <# 0 DO # LOOP #> TYPE DECIMAL ;
: .B        0 2 .HEX ;
: .H        0 4 .HEX ;
: .L        0 8 .HEX ;
: .BINX
    32 OVER - ROT SWAP <<  SWAP 0
    DO I IF I 3 AND 0= IF $5F EMIT THEN  THEN ROL DUP 1 AND EMITD LOOP
    DROP ;
: .BIN  32 .BINX ;
: .BIN8 8 .BINX ;


