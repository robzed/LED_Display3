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

$1000 variable dcolour
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

( Character printing )

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
: dwrap
  _dx @ dwidth >= IF
    b/glyph _dy +! 0 _dx !
    _dy @ dheight >= IF 0 _dy ! THEN
  THEN
;

\ Write a font character
: .fontch ( char -- )
  glyph dup c@ ( addr width )
  dup setdwidth 1 dpixw +!
  swap 1+           ( width addr+1    )
  b/glyph 1- _dx @ _dy @ wrchar
  1+ _dx +!
  dwrap
;

( Do some demo display )

: .fontstr ( addr n -- )
  0 do
    dup c@ .fontch
    1+
  loop drop
;

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
\ ` C .fontch
\ ` P .fontch
: F2020 S" Forth 2020" .fontstr ;
\ F2020
\ 8 setdwidth
\ heart 6 8 18 wrchar

\ show


( number printing)

: .LED2  ( u  ) 0 <# # #S #> .fontstr ;


( colour for printing )
: dark_red $1000 dcolour ! ;
: dark_green $100000 dcolour ! ;

( time printing)

: _LEDtime TIME@ HMS .LED2 ` : .fontch .LED2 drop ;
: .LEDdate ;
: .LEDday ;

: time_of_day
  time@ hms nip nip
  dup 22 > if drop 0 exit then
  dup 7 < if drop 0 exit then
  drop 1
;

: .LEDtime dark_red dcls 0 0 draw_at _LEDtime show ;
: schedule_time
 time_of_day
 1 = if .LEDtime else dcls show then
;

: time_loop begin schedule_time  1000 ms key? until key ;

