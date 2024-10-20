\ Basic Sounds by Rob Probin, August 2023.
\ 
\ USE WITH: Zeptoforth RP2040 zeptoforth_full-1.x.x.uf2
\
\ MIT License
\
\ Copyright (c) 2023 Rob Probin
\ 
\ Permission is hereby granted, free of charge, to any person obtaining a copy
\ of this software and associated documentation files (the "Software"), to deal
\ in the Software without restriction, including without limitation the rights
\ to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
\ copies of the Software, and to permit persons to whom the Software is
\ furnished to do so, subject to the following conditions:
\ 
\ The above copyright notice and this permission notice shall be included in all
\ copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
\ IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
\ FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
\ AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
\ LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
\ OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
\
\ Modified for LED_Display3 May 2024


pin import
pwm import

\
\ Constants
\
18 constant PIEZO_PIN            \ NOTE: Code below assumes compare A (and not B)
1 constant pwm-out-index        \ this is related to the PIEZO_PIN !!

\ RP2040 system frequency
125000000 constant FSYS



\
\ This is the tune we play. Notes are in Hertz, Durations in milliseconds.
\
\ Remember Forth requires a space then a comma after each value
\

create MELODY_NOTE     659 , 659 ,   0 , 659 ,   0 , 523 , 659 ,   0 , 784 ,
create MELODY_DURATION 150 , 150 , 150 , 150 , 150 , 150 , 150 , 150 , 200 ,
9 constant NUMBER_OF_NOTES


\
\ PWM helper code to make notes
\


\ calculate closest dividers for a PWM frequency
\
\ This routine produces the three parameters for PWM. It's been tested on a 
\ limited amount of audio frequencies and at the moment doesn't use the 
\ fraction part at all - although it might be possible to adjust it 
\ if the scaling part is changed from 2* to, say 1.5 or 1.2. Changes 
\ will need to be made to make the int/frac into a S31.32 fixed point number.
\
\ As mentioned above this routine currently doesn't use the fractional part, just int divider 
\ 
: calculate_closest_dividers ( S31.32-frequency-in-Hz -- frac-divider int-divider top-count )
    0 -rot  \ fraction part - currently always zero (we could bind this with frac divider, and make it divide by less than 2 each time...
    1 -rot  \ scaling = int-divider
    ( 0 1 S31.32-freq )
    FSYS s>f 2swap f/
    begin
        \ if it's above top count, then it won't fit! (we adjust top-count by 1 because fsys/((top+1)*(div_int+div_frac/16))
        2dup 65536 s>f d>
    while
        \ make it smaller, but record how much we divided it by
        2 s>f f/
        rot 2* -rot
    repeat
    f>s 1-  \ topcount-1
;

\
\ This routine prints the actual PWM frequency for a non-phase-correct produced by the routine above
\ 
: print-actual_frequency ( frac-divider int-divider top-count -- )
    dup 65535 u> if
        ." Top count=" u. ." -Error!!!!"
        65535
    then
    1+ \ top+1 equation is fsys/((top+1)*(div_int+div_frac/16))
    s>f FSYS s>f 2swap f/
    ( frac-divider int-divider S31.32-freq-base)
    2swap
    dup 255 u> if
        ." Integer Divider=" u. ." - Error!!!!"
        255
    then
    swap dup 15 u> if
        ." Frac Divider=" u. ." - Error!!!"
        15
    then
    \ convert fraction part to actual fraction
    s>f 16,0 f/
    rot s>f d+  \ combine integer and fraactional parts
    ( D.Fsys/ [TOP+1] D.int+frac )
    f/ 
    ." Freq =" F.
;

: tone_on ( S31.32-frequency-in-Hz  -- )
    \ this line prints out all the frequency details for debugging...
    \ 2dup 2dup f. ." = " calculate_closest_dividers 0 2over 2over drop . . . drop print-actual_frequency cr exit
    pwm-out-index bit disable-pwm
    0 pwm-out-index pwm-counter!

    \ Freq-PWM = Fsys / period
    \ period = (TOP+1) * (CSR_PH_CORRECT+1) + (DIV_INT + DIV_FRAC/16)
    \ e.g. 125 MHz / 16.0 = 7.8125 MHz rate base rate
    \ divider is 8 bit integer part, 4 bit fractional part
    \ Since phase correct is false/0, we only need to worry about TOP and Divider

    calculate_closest_dividers
    dup ( pwm-wrap-count ) pwm-out-index pwm-top!
    2/ ( 50% of pwm-wrap-count ) pwm-out-index pwm-counter-compare-a!
    ( frac-divider int-divider ) pwm-out-index pwm-clock-div!

    pwm-out-index free-running-pwm
    false pwm-out-index pwm-phase-correct!
    pwm-out-index bit enable-pwm
    PIEZO_PIN pwm-pin
;

: tone_off ( -- )
    PIEZO_PIN input-pin
    pwm-out-index bit disable-pwm
;

: tone ( duration-in-milliseconds frequency-in-Hz -- )
\ Note: Frequency 0 = off
    dup if
        \ if we want to use fractional Hertz, e.g. for accuracy, fix the s>f
        s>f tone_on
    else
        \ no tone
        drop
        tone_off
    then
    ms
    tone_off
;

: play_note ( index -- )
    CELLS dup MELODY_DURATION + @ swap MELODY_NOTE + @ tone
;


: mario_test
    NUMBER_OF_NOTES 0 do
        I NUMBER_OF_NOTES < if
            I play_note
        then
    loop
;


: sound_down
  100 784 tone 
  150 659 tone
  200 262 tone
;

: sound_up
  100 262 tone
  150 659 tone
  200 784 tone
;

