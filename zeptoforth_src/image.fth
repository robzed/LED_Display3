\ Image display by Rob Probin, October 2024.
\ 
\ USE WITH: Zeptoforth RP2040_big zeptoforth_full-1.x.x.uf2
\ MIT License
\ Copyright (c) 2023 Rob Probin



: clear_image
    dcls \ np.fill(black)
;

: show_pixels
    show
;

20 constant max_brightness
: max_brightness, 20 c, ;
: max_brightness//4, max_brightness 4 /  c, ;
: max_brightness//2, max_brightness 2 /  c, ;
: max_brightness*0.63, max_brightness 100 * 63 /  c, ;
: max_brightness*0.13, max_brightness 100 * 13 /  c, ;
: max_brightness*0.94, max_brightness 100 * 94 /  c, ;
: 0, 0 c, ;

create character_lookup_table
    bl c,   0 c, 0 c, 0 c,	\ black
    char W c, max_brightness, max_brightness, max_brightness,	\ white
    char w c, max_brightness//4, max_brightness//2, max_brightness//4, \ dim white
    char R c, max_brightness, 0, 0,    \ red
    char r c, max_brightness//4, 0, 0, \ dim white
    char G c, 0, max_brightness, 0,    \ green
    char g c, 0, max_brightness//4, 0, \ dim green
    char B c, 0, 0, max_brightness,    \ blue
    char b c, 0, 0, max_brightness//4, \ dim blue
    char C c, 0, max_brightness, max_brightness,  \ cyan
    char O c, max_brightness, max_brightness//4, 0,  \ orange
    char P c, max_brightness*0.63, max_brightness*0.13, max_brightness*0.94, \ purple
    char M c, max_brightness, 0, max_brightness,   \ magenta
    char m c, max_brightness//4, 0, max_brightness//4,  \ dim magenta
    char Y c, max_brightness, max_brightness, 0,     \ yellow
    char y c, max_brightness//4, max_brightness//4, 0,  \ dim yellow (brown?)
    \ end of table - default value
    0 c, max_brightness//4, 0, 0,


: character_lookup ( char -- r g b )
    { findchar }
    character_lookup_table
    { table } 
    begin
        \ findchar . table .l space table c@ . cr
        table c@ findchar <>
        table c@ 0<>
        and
    while
         4 +to table
    repeat
    table 1+ c@ table 2 + c@ table 3 + c@    
;


: set_colour ( r g b -- )
    _blue c!
    _green c!
    _red c!
;

defer do_pixel  ( x y -- )

: display_image_line ( y caddr len -- )
    { y caddr len -- }
    len 0 ?do
        caddr c@ character_lookup set_colour
        i y do_pixel
        1 +to caddr
    loop
;

variable test_y
: test_do_pixel ( x y -- )
    dup test_y @ <> if
        cr
        test_y !
        drop
    else
        2drop
    then
    _blue c@ _green c@ _red c@ + +
    0 > if
        ." #"
    else
        ."  "
    then
;

: image_display_base ( image -- )
    0 { image y }
    begin
        \ terminated by zero length line
        image c@
    while
        y image count display_image_line
        \ next line
        image c@ 1+ +to image
        1 +to y
    repeat
;


: image_display ( image -- )
    ['] setpixelxy ['] do_pixel defer!
    clear_image
    ( image ) image_display_base
    show_pixels
;

: test_image ( image -- )
    ['] test_do_pixel ['] do_pixel defer!
    image_display_base
;

