zap 
$10 neo!
24 constant dwidth 
24 constant dheight
4 constant pixsize
dwidth dheight * pixsize * bytes mybuf 
\ $202000 mybuf !
\ $000020 mybuf 4 + !
\ $200000 mybuf 8 + !
\ $002000 mybuf 12 + !
\ mybuf 4 neos! --- 

\ : test 25 0 do I . loop ;
: show mybuf dwidth dheight * neos! ;
: pixaddr ( x y -- addr ) dwidth * + pixsize * mybuf + ;
: setpixel ( colour x y -- ) pixaddr ! ;
: cline ( y -- ) dwidth 0 do 0 over I swap setpixel loop drop ;
: dcls ( -- ) dheight 0 do I cline loop ;

\ 00000000011111111112222222222333
\ 12345678901234567890123456789012

$2000 variable dcolour

: wrpix ( data dest-addr -- )
8 0 do 
    over $80 and if
    dcolour @ over !
    else
    0 over !
    then
    swap 1 << swap pixsize +
loop 2drop ;


\ %11111111 0 0 pixaddr wrpix
\ %10000001 0 1 pixaddr wrpix
\ %10011001 0 2 pixaddr wrpix

: wrchar ( s-addr height x y -- )
  pixaddr swap
  0 do  
    ( s-addr d-addr )
    over c@ over wrpix
    dwidth pixsize * + swap 1+ swap
  loop
;

dcls show
8 bytes grx 
$c5c181ff grx ! 
$fef0c080 grx 4 + ! 
grx 8 0 0 wrchar
show

    
