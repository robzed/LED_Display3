\ Real Time Clock Routines
\ Rob Probin, May 2024
\ MIT License
\ based on Tachyon, Peter Jakacki 2021, MIT license. 


    ( *** RTC *** )

\ these two may be combined with current bms to derive the time without reading rtc
variable bdate  \ data at reset
variable btime  \ time at reset
variable bms    \ ms time at reset

cvariable ~rtc
\ rtc buffer
cvariable @sec
cvariable @min
cvariable @hour
cvariable @day
cvariable @date
cvariable @month
cvariable @year


    ( *** RV-3028-C7 RTC *** )

( Changed @RTC to use a variable instead to allow for other RTC chips)
\ $A4 variable ~rtc
: @RTC    ~rtc C@ ;
: RTC? ( -- flg )   @RTC I2CRD? I2C.STOP ;

\ fetch reg from 8-bit reg      ADDR      REG   ADDR  DATA
: I2CREG@ ( reg dev -- dat )    DUP I2CWR SWAP I2C! I2CRD nakI2C@ I2C.STOP ;
: RTC@ ( reg -- byte )  @RTC I2CREG@ ;

: I2CREG! ( dat reg dev -- )    I2CWR I2C! I2C! I2C.STOP ;
: RTC! ( byte reg -- )	@RTC I2CREG! ;
\ RTC BCD STORE - store byte as BCD in RTC register
: RTCB! ( bcd reg -- )	SWAP 10 U/MOD 4 << OR SWAP RTC! ;

    ( RTC DUMP )
: RTC           ['] RTC@ DUP DUP DUMP! ;

    ( *** HIGH LEVEL TIME KEEPING RTC INTERFACE *** )
: 8563?     @RTC $A2 = ;
: RTCSEC    0 8563? IF 2+ THEN ;

\ fast sequential read of first 7 time keeping registers
: RDRTC
    @sec 7 ERASE
    @RTC 0EXIT
\                   start from reg 0  or 2 for PCF8563
    I2C.START @RTC I2CPUT ?EXIT  RTCSEC I2C!
\    read
    <I2C> @RTC 1+ I2C!    @sec 6 BOUNDS DO I2C@ I C! LOOP
    nakI2C@ @year C! I2C.STOP
    8563? IF @day C@ @date C@ @day C! @date C! THEN
;

\ Init RTC configs etc ( not time ) on boot
: !RTC
    @RTC $D0 = IF $B4 $37 RTC! 0 $10 RTC! 0 $0F RTC! THEN
;

: TRYRTC    DUP I2CRD? IF DUP ~rtc C! R> DROP THEN DROP ;

\ scans the I2C bus and returns with a possible RTC addr if I2C pins are set
: SCANRTC ( -- )
\           MCP79410   DS3231 etc RV3028 etc PCF8563
    I2C? IF $DE TRYRTC $D0 TRYRTC $A4 TRYRTC $A2 TRYRTC THEN
;


:   >HMS ( s m h -- hhmmss )    100 * + 100 * + ;

: secs@         $40054024 DUP 4 + @ SWAP @ 1000000 um/mod nip ;
\ pub ms@       cycles 1000 U/ ;
\ pub secs@     ms@ 1000 U/ ;
: QTIME@        secs@ bms @ + 60 U/MOD 60 U/MOD >HMS ;

\ read hardware RTC and sync software time
: QTIME!        HMS 60 * + 60 * + secs@ - bms ! ;



: BCDS ( bcds -- dec rem )  DUP >N OVER 4 >> >N 10 * + SWAP 8 >> ;
: BCD>DEC ( bcds -- val )   BCDS BCDS BCDS DROP >HMS ;

\ RV-3028 supports UNIX time in seconds from 1970
: UTIME@ ( -- secs )    0 27 4 BOUNDS DO I RTC@ OR 8 >> LOOP ;
: UTIME! ( secs -- )    27 4 BOUNDS DO DUP I RTC! 8 >> LOOP DROP ;
: RTC3!                 3 BOUNDS DO I RTCB! LOOP ;
\ : TIME! ( hhmmss -- )     !RTC 100 U/MOD SWAP 0 RTCB! 100 U/MOD SWAP 1 RTCB! 2 RTCB! ;
: TIME! ( hhmmss -- )
    RTC? IF !RTC DUP HMS SWAP ROT  RTCSEC RTC3! THEN QTIME! ;
: DAY!          7 AND @day C! ; \ 3 RTC! ;
: DATE! ( yymmdd -- )
    HMS @year C! @month C! @date C!
    RTC? IF !RTC  @RTC $A2 =
      IF @date C@ 5 RTCB! @month C@ 7 RTCB! @year C@ 8 RTCB! @day C@ 6 RTC!
      ELSE @date C@ 4 RTCB! @month C@ 5 RTCB! @year C@ 6 RTCB! @day C@ 3 RTC!
      THEN
    THEN
;

\         0 1 2 3 4 5 6 7 8
\ PCF8563 x x s m h D W M Y
\ DS3231    s m h W D M Y

\ read bcd fields and mask before converting to decimal
: TIME@         RTC? IF RDRTC @sec U@ $3F7F7F AND BCD>DEC ELSE QTIME@ THEN ;
: DATE@         RDRTC @date U@ $FF1F3F AND BCD>DEC ;
: DAY@          @day C@ 7 AND 1 MAX ;

: .DT           DATE@ 6 U.R $2D EMIT TIME@ 6 Z U.R ;

: .HMS ( n ch -- )      >R HMS 2 Z U.R R@ EMIT 2 Z U.R R> EMIT 2 Z U.R ;
: .DATE           DATE@ ." 20" $2F .HMS ;
: .DAY            DAY@ 1- 3 * s" MONTUEWEDTHUFRISATSUN" DROP + 3 TYPE ;
: .TIME           TIME@ $3A .HMS ;
: .FDT            .DATE SPACE .DAY SPACE .TIME ;

: !QTIME            TIME@ QTIME! ;
\

\ checks for different RTC chips and sets them up
: ?RTC
\   init vars    scan    found?  then synch
    ~rtc 8 ERASE SCANRTC ~rtc C@ IF !QTIME THEN
;

\ ' .FDT ^ T CTRL!




