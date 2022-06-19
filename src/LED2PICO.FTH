mybuf org  forget *led2pico*   : *led2pico* ;

include font.f

24 constant dwidth
24 constant dheight
4 constant pixsize

\ create a buffer for the image to be displayed
dwidth dheight * pixsize * bytes mybuf
: show mybuf dwidth dheight * neos! ;
: pixaddr ( x y -- addr ) dwidth * + pixsize * mybuf + ;
: setpixel ( colour x y -- ) pixaddr ! ;
: cline ( y -- ) dwidth 0 do 0 over I swap setpixel loop drop ;
: dcls ( -- ) dheight 0 do I cline loop ;

$2000 variable dcolour
8 variable dpixw
$80 variable dmask

: wrpix ( data dest-addr -- )
dpixw @ 0 do
    over dmask @ and if
    dcolour @ over !
      else
    0 over !
    then
    swap 1 << swap pixsize +
loop 2drop ;
: setdwidth ( width -- ) dup dpixw ! 1- |< dmask ! ;


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
  2drop
;

0 variable _dx
0 variable _dy
: draw_at ( x y -- ) _dy ! _dx ! ;

\ Write a font character
: .fontch ( char -- )
  glyph dup c@ ( addr width )
  dup setdwidth 1 dpixw +!
  swap 1+           ( width addr+1    )
  b/glyph 1- _dx @ _dy @ wrchar
  1+ _dx +!
;





( Do some demo display )

create heart
%01100110 c,
%11111111 c,
%11111111 c,
%01111110 c,
%00111100 c,
%00011000 c,

dcls
\ 8 bytes grx
\ $c5c181ff grx !
\ $fef0c080 grx 4 + !
\ grx 8 2 2 wrchar
` C .fontch
` P .fontch
8 setdwidth
heart 6 8 18 wrchar

show

