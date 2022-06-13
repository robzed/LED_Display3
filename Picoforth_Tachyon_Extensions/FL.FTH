\ Fast source code loader ( no prerequisites )
$20028000 constant tbuf
tbuf variable ~flkey
: FLKEY?	-1 ;
: FLKEY
    ~flkey @ C@ DUP IF 1 ~flkey +!
    ELSE
    ['] serial-key hook-key !
    ['] serial-key? hook-key? !
    THEN
;
: !FLKEY
    ['] FLKEY hook-key !
    ['] FLKEY? hook-key? !
    tbuf ~flkey !
;
: FL
    100 ms BEGIN KEY? WHILE KEY DROP 5 ms REPEAT
    cycles tbuf
    BEGIN KEY? UNTIL \ wait for first char
    BEGIN
      KEY? IF KEY OVER C! 1+ 0 OVER C! NIP cycles SWAP 0
      ELSE OVER cycles - ABS 100000 > THEN
    UNTIL
    2DROP
    !FLKEY
    ." Finished"
;

FL
