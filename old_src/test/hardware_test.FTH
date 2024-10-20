compiletoflash

pub LED2PICO
    100 ms !TACHYON
    $0F0C0B0A SDPINS ( &15.12.11.10 )
    18 spkr C!
    28 NEOPIN $200000 NEO!
    %11 S" MAKER PI PICO" PCB! ( b0 = Pico )
    .PCB
    CRLF !PICO BEEP
    3 2 I2CPINS ?RTC ~rtc C@ IF !QTIME CRLF .FDT THEN
    KEY? IF KEY $1B = IF PLAIN EXIT THEN THEN
    SD? IF cyan pen CRLF PRINT" MOUNTING " MOUNT THEN
    PLAIN
;

: INIT  LED2PICO ;

compiletoram
SAVE

: buts ( s -- ) pin@ 0= if zap then ;
: buts1 pin@ 0= if bip then ;  
: buts2 pin@ 0= if click then ; 
: butsx 20 buts 21 buts1 22 buts2 ;
: butsound begin butsx 100 ms key? until ;  
butsound 




\ pub lsi2c $100 0 DO I dup . I2CRD? IF I ."  $" .B THEN 2 +LOOP ;

