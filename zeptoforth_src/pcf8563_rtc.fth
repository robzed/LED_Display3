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
\ 07 Century months - b7=century+1, b6-b5=unused, b4 = tens months, b3-b0=units months
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
    buf 1 i2c-periph >i2c-restart ." >i2c-restart sent" . cr
    \ read the time
    RTC-buffer number_time_registers i2c-periph i2c-stop> ." i2c-stop> got" . cr

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

: read_rtc ( -- )
    PCF8563-address rtc-i2c-pin0 rtc-i2c-pin1 rtc-i2c-peripheral base_read_rtc
;

: print_raw_rtc ( -- )
    base @
    hex
    read_rtc 
    cr
    number_time_registers 0 do I RTC-buffer + c@ . loop
    base !
;

end-module


\
\ Test code
\ 
\ test on rp2040/zeptoforth_full_usb-1.4.0.1.uf2
\ 
PCF8563-RTC import
init_rtc 
.s 
print_raw_rtc
.s




