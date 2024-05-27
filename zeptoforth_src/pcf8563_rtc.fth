\ PCF8563 Real Time Clock Routines
\ Rob Probin, 19 May 2024
\ MIT License


\ PCF8563 Registers:
\
\ 00 Control Status 1 = b8=test(0=normal), b5=stop, b3=testc/POR enabled
\ 01 Control Status 2

\ 02 VL_Seconds -  b6-b4=tens, b0-b3 units, b7=VL (1=clock not ok, 0=clock ok)
\ 03 Minutes - b7=unused, b6-4 tens, b0-3 units
\ 04 Hours - b6-7=unused, b5-4 tens, bit3-0 units
\ 05 Days - b6-7=unused, b5-4 tens, bit3-0 units
\ 06 weekdays - b0-6 (0=Sun, 6=Sat) - can be redefined by user
\ 07 Century months - b7=century+1, b6-b5=unused, b4 = tens months, b3-b0=units months (months start at 1 = January)
\ 08 Years - b7-b4 = tens, b0-3 units

\ 09 = minute alarm
\ 0A = hour alarm
\ 0B = day alarm
\ 0C = weekday alarm
\ 0D = clkout control
\ 0E = timer control
\ 0F = timer

\ Read the time method
\
\ Send a START condition and the slave address for write (A2h).
\ 2. Set the address pointer to 2 (VL_seconds) by sending 02h.
\ 3. Send a RESTART condition or STOP followed by START.
\ 4. Send the slave address for read (A3h).
\ 5. Read VL_seconds.
\ 6. Read Minutes.
\ 7. Read Hours.
\ 8. Read Days.
\ 9. Read Weekdays.
\ 10. Read Century_months.
\ 11. Read Years.
\ 12. Send a STOP condition.

begin-module PCF8563-RTC

pin import
i2c import

2 constant time_start_register
7 constant number_time_registers

number_time_registers cell align buffer: RTC-buffer

: base_init_rtc  { addr pin0 pin1 i2c-periph -- }
    i2c-periph i2c::clear-i2c
    i2c-periph pin0 i2c::i2c-pin
    i2c-periph pin1 i2c::i2c-pin
    i2c-periph i2c::master-i2c
    addr $80 u< if i2c-periph 7-bit-i2c-addr else i2c-periph 10-bit-i2c-addr then 
    addr i2c-periph i2c-target-addr! 
;

: base_read_rtc { addr pin0 pin1 i2c-periph -- }
    addr pin0 pin1 i2c-periph base_init_rtc

    i2c-periph enable-i2c

    \ send the register where time starts
    0. { D^ buf } time_start_register buf c! 
    buf 1 i2c-periph >i2c-restart drop \ ." >i2c-restart sent" . cr
    \ read the time
    RTC-buffer number_time_registers i2c-periph i2c-stop> drop \ ." i2c-stop> got" . cr

    i2c-periph disable-i2c
;

$51 constant PCF8563-address

2 constant rtc-i2c-pin0
3 constant rtc-i2c-pin1
1 constant rtc-i2c-peripheral

\ base_read_rtc already calls init_rtc
: init_rtc ( -- ) 
    PCF8563-address rtc-i2c-pin0 rtc-i2c-pin1 rtc-i2c-peripheral base_init_rtc 
;


cvariable bad_rtc
cvariable seconds
cvariable minutes
cvariable hours
cvariable days
cvariable weekdays
cvariable months
hvariable year

: decode_rtc ( -- )
    RTC-buffer c@ $80 and if true else false then bad_rtc c! 
    RTC-buffer c@ dup
        $70 and 4 rshift 10 *
        swap $0F and + seconds c!
    RTC-buffer 1+ c@ dup
        $70 and 4 rshift 10 *
        swap $0F and + minutes c!
    RTC-buffer 2 + c@ dup
        $30 and 4 rshift 10 *
        swap $0F and + hours c!
    RTC-buffer 3 + c@ dup
        $30 and 4 rshift 10 *
        swap $0F and + days c!
    RTC-buffer 4 + c@ 
        $07 and weekdays !
    RTC-buffer 5 + c@ dup
        $10 and 4 rshift 10 *
        swap $0F and + months c!
    RTC-buffer 6 + c@ dup
        $F0 and 4 rshift 10 *
        swap $0F and + year h!
    \ century bit
    RTC-buffer 5 + c@ 
        $80 and if 2000 else 1900 then
        year h+!
;


: read_rtc ( -- )
    PCF8563-address rtc-i2c-pin0 rtc-i2c-pin1 rtc-i2c-peripheral base_read_rtc
    decode_rtc
;

: print_raw_rtc ( -- )
    hex
    read_rtc 
    cr
    number_time_registers 0 do I RTC-buffer + c@ . loop
;

: get_short_weekday_name ( weekday -- caddr u )
    3 *
    S" SUNMONTUEWEDTHUFRISAT" drop
    +
    3
;

: get_short_month_name ( month -- caddr u )
    1-  \ 1=Jan
    3 * 
    S" JanFebMarAprMayJunJulAugSepOctNovDec" drop
    + 
    3
;

\ print a two digit decimal number
: .02d ( n -- )
    dup 100 >= if drop ." ??" else
        dup 10 / [CHAR] 0 + EMIT
        10 MOD [CHAR] 0 + EMIT
    then
;

: print_rtc ( -- )
    decimal
    weekdays c@ get_short_weekday_name type space
    hours c@ .02d [CHAR] : EMIT minutes c@ .02d [CHAR] : EMIT seconds c@ .02d
    space
    days c@ .02d [CHAR] - EMIT months c@ .02d ." -(" months c@ get_short_month_name type ." )-" year h@ .

    bad_rtc c@ if ." <Warning bad>" then
    cr
;

\ **UNTESTED**
: set_time { hrs mins secs -- }
    0 bad_rtc c!
    secs seconds c!
    mins minutes c!
    hrs hours c!
;

\ **UNTESTED**
: set_date { d m y weekdy -- }
    d days c!
    weekdy weekdays c!
    m months c!
    y year h!
;

\ **UNTESTED**
: >BCD ( n -- n' )
    dup 10 / 4 lshift
    swap 10 mod + 
;

\ **UNTESTED**
: write_rtc ( -- )
    seconds c@ >BCD RTC-buffer c!
    minutes c@ >BCD RTC-buffer 1+ c!
    hours c@ >BCD RTC-buffer 2 + c!
 
    days c@ >BCD RTC-buffer 3 + c!

    weekdays c@ RTC-buffer 4 + c!

    months c@ >BCD RTC-buffer 5 + c!
    year h@ 100 mod >BCD RTC-buffer 6 + c!
    year h@ 2000 >= if
        RTC-buffer 5 + c@ $80 + RTC-buffer 5 +
    then

;


end-module


\
\ Test code
\ 
\ tested on rp2040_big/zeptoforth_full_usb-1.4.0.1.uf2 - doesn't work
\ tested on rp2040_big/zeptoforth_full_usb-1.5.5.uf2 - does work
\ 
PCF8563-RTC import
init_rtc 
.s 
print_raw_rtc
.s
print_rtc
.s





