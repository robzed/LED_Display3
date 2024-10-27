\   PICO LED dislay routines   Copyright (c) 2022 Rob Probin   (MIT License)                                                   
\   Modified for Zeptoforth 18 May 2024

24 constant dwidth
24 constant dheight
\ 4 constant pixsize

#include font.fth
#include neopixel.fs

dwidth dheight * constant num_pixels
28 constant pixel_gpio

0 constant neopixel-state-machine

neopixel import
pio import

num_pixels neopixel-size ( dup . cr ) buffer: pixels

: init-LED2PICO
  neopixel-state-machine PIO0 num_pixels pixel_gpio pixels init-neopixel

  pixels clear-neopixel
  pixels update-neopixel
;

\ 64 64 64 0 pixels neopixel!
\ 32 32 32 1 pixels neopixel!
\ 16 16 16 2 pixels neopixel!
\ 8 8 8 3 pixels neopixel!
\ 8 8 8 8 pixels neopixel!
\ 1 1 1 10 pixels neopixel!
\ pixels update-neopixel




\ create a buffer for the image to be displayed
\ dwidth dheight * pixsize * bytes mybuf
: show pixels update-neopixel ;
\ : pixaddr ( x y -- addr ) dwidth * + pixsize * mybuf + ;

cvariable _red
cvariable _green
cvariable _blue

: setpixel ( offset -- ) >R _red c@ _green c@ _blue c@ R> pixels neopixel! ;
: clrpixel ( offset -- ) >R 0 0 0 R> pixels neopixel! ;
: setpixelxy ( x y -- ) dwidth * + setpixel ;
: clrpixelxy ( x y -- ) dwidth * + clrpixel ;
\ : cline ( y -- ) dwidth 0 do over I swap setpixel loop drop ;
: dcls ( -- ) clear-neopixel ;

\ $1000 variable dcolour
( 8 ) variable dpixw
( $80 ) variable dmask

: calc-offset dwidth * + ;
 
: wrpix ( data offset -- )
    dpixw @ 0 do
    over dmask @ and if
    dup setpixel
      else
    dup clrpixel
    then
    swap 1 << swap 1+
loop 2drop ;

: |< ( b -- m )   1 SWAP << ;
: setdwidth ( width -- ) dup dpixw ! 1- |< dmask ! ;

( Character printing )

: wrchar ( s-addr height x y -- )
  calc-offset swap
  0 do
    ( s-addr d-offset )
    over c@ over wrpix
    dwidth + swap 1+ swap
  loop
  2drop
;

variable _dx
variable _dy
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

\ init-neopixel
\ dcls
\ 8 bytes grx
\ $c5c181ff grx !
\ $fef0c080 grx 4 + !
\ grx 8 2 2 wrchar
\ ` C .fontch
\ ` P .fontch
\ : F2020 S" Rob 2024" .fontstr ;
\ F2020
\ 8 setdwidth
\ heart 6 8 18 wrchar

\ show


( number printing)

: .LED2  ( u  ) 0 <# # #S #> .fontstr ;


( colour for printing )
: dark_red 4 _red c!  0 _green c! 0 _blue c! ;
: dark_green 0 _red c!  4 _green c! 0 _blue c! ;
: dark_blue 0 _red c!  0 _green c! 4 _blue c! ;                                                                                                     

( time printing)

\ : _LEDtime TIME@ HMS .LED2 ` : .fontch .LED2 drop ;
\ : .LEDdate ;
\ : .LEDday day@ 1- 3 * s" MONTUEWEDTHUFRISATSUN" DROP + 3 .fontstr ;                                                            


\ : time_of_day
\   time@ hms nip nip
\   dup 22 > if drop 0 exit then
\   dup 7 < if drop 0 exit then
\   drop 1
\ ;


\ : .LEDtime dark_red 0 0 draw_at _LEDtime ;                                                                                     
\ : .LEDtime dark_red dcls 0 0 draw_at _LEDtime show ;

\ : schedule_time                                                                                                                
\  dcls time_of_day                                                                                                              
\  1 = if                                                                                                                        
\     dcls 0 6 draw_at dark_blue .LEDday .LEDtime                                                                                
\  then                                                                                                                          
\  show                                                                                                                          
\ ;

\ : schedule_time
\ time_of_day
\ 1 = if .LEDtime else dcls show then
\ ;

\ : time_loop begin schedule_time  1000 ms key? until key ;

