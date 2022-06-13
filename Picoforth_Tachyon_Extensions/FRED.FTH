\           ... FORTH RAPID EMBEDDED DEVELOPMENT EDITOR ...

mecrisp
2205281900 tme?                 --- make sure TACHYON.FTH is new enough
~edsect org  FORGET *FRED*          --- reclaim code and data

pub *FRED*      PRINT" FRED - Forth Rapid Embedded Development Editor 220609-1245 " ;

{
TO DO:  Limit editing to file size
    insert/delete page
    add horizontal scroll
    add word wrap
    sleep mode - locks edit
    also other directives i.e. set theme, modes, etc.
    add conditional compile directives #IFDEF #IF etc


}

--- Placing  here allows FRED to load back over itself
pri EDLOAD              PLAIN CLS  -FLOAD  QUIT ;

(   !!! PATCHES !!!     )
pub RENAME      OPEN-FILE IF ." to " fname TIB 11 ACCEPT IF SAVEDIR THEN THEN ;
--- form feed ensures compilation listing is not overwritten by FRED
pub #FF         40 0 DO CRLF LOOP ;





\       *** CONSTANTS ***
DATA $D000 + constant clipboard --- 4kB clipboard holds up to 1 page
DATA $E000 + constant pagebuf --- allocate 4kB PAGEBUF near end of RAM
16 constant maxtabs

\       *** VARIABLES ***

long ~edsect            --- starting sector of current page
long ~page
long ~ey
long ~begin             --- marks beginning of selection (default -1 = none)
long ~end               --- marks end of select
long ~clipsz            --- size of content copied to clipboard
long ~ew                --- width
long ~pagesz
long ~qt                --- quick time latch
long ~find              --- length of find string
long ~idle              --- idle timer - used to determine auto refresh
long ~key               --- ASCII or abbreviated CSI code
long ~seq               --- highlight sequence
long ~hflgs             --- highlight flags
long ~ftab              --- current file tab active
maxtabs 32 * bytes ~ftabs      --- hold the context for files

long ~edcold







\       *** FILE TAB VARIABLES ***

pri @ftab               ~ftab C@ maxtabs MOD ;
pri FTAB$               @ftab 5 << ~ftabs + ;
pri ~tcur               FTAB$ 12 + ;
pri ~theme              FTAB$ 16 + ;
pri ~eflgs              FTAB$ 20 + ;

\       *** CURSOR TRACKING ***
pri tcur@               ~tcur @ ;
pri tcur!               ~tcur ! ;
pri tcur+!              tcur@ + 0 MAX tcur! ;
pri tcur-!              NEGATE tcur+! ;
pri ew                  128 ;
--- editor print width
96 variable ~pw
pri pw                  ~pw @ ;
pri pagesz              4096 ;
pri @x ( -- x )         tcur@ ew // ; --- current x position
pri LEFTLN ( -- row )   tcur@ ew 1- ANDN ;


\       *** BIT FLAGS ***
pri save?               1 ~eflgs ;
pri ins?                2 ~eflgs ;
pri wr?                 7 ~eflgs ;
pri indent?             3 ~eflgs ;
pri lines?              4 ~eflgs ;




(       *** PAGE ACCESS ***     )
pri PAGE#               tcur@ pagesz / ;
pri PAGEADR             tcur@ pagesz 1- ANDN ;

--- compare memory areas
pri COMPARE? ( src dst cnt -- f )
    BOUNDS DO DUP C@ I C@ <> IF DROP 0 LEAVE THEN 1+ LOOP 0<> ;

--- save the current page to file (only save the modified sectors)
pri SAVEPAGE
    ~edsect @ 0EXIT  wr? BIT? 0EXIT             --- don't save if not open or write protected
    ~edsect @ 8 BOUNDS DO I SDBUF SDRD
      pagebuf I ~edsect @ - 9 << + DUP SDBUF 512 COMPARE? NOT
        IF RW I SDWR ELSE DROP THEN
    LOOP RO save? CLRB
;
--- Takes about 13.2ms to read a page (8 sectors = 1.6ms/sector ) less than 1us otherwise
--- Read in a page from SD into the page buffer
pri SDRDPAGE ( sect bytes -- ram )
    OVER ~edsect @ <>                           --- don't do anything if the ed sector is still the same
---   update edsect  buffer size
    IF save? BIT? IF SAVEPAGE THEN              --- autosave modified sectors of page (unless write protect set)
      OVER ~edsect ! pagebuf SWAP SDRDS         --- now read in the new page
    ELSE 2DROP THEN   pagebuf
;
pri PAGE ( offset -- ram )
    DUP pagesz 1- ANDN                  ---
--- page offset   page sector
    SWAP OVER -   SWAP 9 >>
    @FILE + pagesz SDRDPAGE +
;

\       ... PAGE FORMATTING ...

pri FORMAT.PAGE --- convert block to CR delimited lines and replace nulls with spaces
    pagebuf pagesz BOUNDS DO I C@ 0= IF $20 I C! THEN
      I pagesz // ?DUP   IF 1+ ew // 0=   IF $0D I C! THEN THEN
    LOOP
;
pub WIPE.PAGE               pagebuf pagesz $20 FILL FORMAT.PAGE ;

--- format the whole file as pages (blanks with CRs)
pub FORMAT.PAGES
    @FILE 0EXIT
--- Write over whole file
    RW FSIZE@ 0
    DO
      I PAGE DUP pagesz $20 FILL
      pagesz BOUNDS DO $0D I ew 1- + C! ew +LOOP
      SAVEPAGE SPINNER
      pagesz
    +LOOP
    RO
;
--- confirm complete page format with ENTER
pri ?FORMAT.PAGES        ."  Format? " KEY $0D = IF FORMAT.PAGES THEN ;








\       ... CHARACTER ACCESS ...
pri ED@                 PAGE C@  ;
pri ED!                 PAGE C!  ;

pri FILE?               file$ SWAP C$= ;
pri FLASH?              s" FLASH" FILE? ;
pri RAM?                s" RAM" FILE? ;
pri SECTOR?             s" SECTOR" FILE? ;


pri TEXTXY@ ( -- x y )  tcur@ 0 MAX pagesz // ew U/MOD DUP ~ey C! ;
pri !TEXTXY             TEXTXY@ SWAP 9 + SWAP 3 + XY ;
pri @STATUS ( n -- )    38 + 1 XY ;

\      ... THEME ...    --- black red green yellow blue magenta cyan white
pub THEME               4 << OR 4 << OR 4 << OR ~theme ! ;
pri UseTheme            ~theme @ SWAP 2 << >> >B DUP >N PLAIN PEN 4 >> PAPER ;
---                     text paper info frame
pub -C64                white blue  blue white THEME ;
pub -MINT               blue white black green THEME ;
pub -DARK               yellow black white magenta THEME ;
pub -DAY                white magenta black cyan  THEME ;
pub -BRIGHT             black yellow white magenta THEME ;
pub -MONO               white black white black THEME ;


pri -HDRS               2 UseTheme ;
pri -INFO               white pen red paper ;
pri -TEXT               0 UseTheme ;
pri -TITLE              -HDRS bold white pen ;


\       ... HEADER INFO ...

pri .PAGE#      8 SPACES CR ." PG "  PAGE# 1+ 3 Z U.R SPACE ;
pri .RW         wr? BIT? IF -INFO ."  EDIT" ELSE -HDRS ."  READ" THEN ;
pri .INDENT     indent? BIT? IF -INFO PRINT"  INDENT" ELSE -HDRS PRINT"  nodent" THEN ;
pri .INS        -TEXT  ins? BIT? IF -INFO PRINT"  INS" ELSE -HDRS PRINT"  OWR" THEN ;
pri .CLIP       -HDRS  ."  CLIP: " ~clipsz @ DUP IF -INFO THEN 4 U.R -HDRS ;
pri .SIZE       ." SIZE: "  ew PRINT ." x" pagesz ew / PRINT ;
--- display the clock in the top right corner ( use quick time software clock )
pri .CLOCK      72 1 XY QTIME@ 0 <# # # ` : HOLD # # ` : HOLD # # #> TYPE ;
pri .TXTRULE    pw 0 DO I 7 AND 0= IF I 3 >> 1 U.R ELSE I 3 AND IF ` . ELSE ` | THEN EMIT THEN LOOP ;
\ pri .HEXRULE    pw 0 DO I >N 0 1 .HEX LOOP      pw 16 = IF 16 0 DO SPACE I .BYTE LOOP THEN ;

pri .RULER      -HDRS REVERSE .TXTRULE ;

--- display header  - reset term - plain - clear
pri .INFO       PLAIN  -HDRS ( pw 8 + SPACES ) .RW SPACE .INDENT SPACE .INS SPACE .CLIP ;


pri .FTABS
    PLAIN ERLINE -HDRS PRINT"  FILES: "   PLAIN
    maxtabs 0 DO PLAIN I 1 AND IF REVERSE THEN blue pen
      I 5 << ~ftabs + DUP @
---   if active and current focus then display in red whether normal/reverse tab
      IF @ftab I = IF bold white I 1 AND IF paper ELSE pen THEN THEN
        SPACE DUP LEN$ 12 MIN TYPE SPACE
      ELSE DROP LEAVE THEN
    LOOP PLAIN
;



\       ... TEXT SELECTION ...
pri ?SELECT
    ~end @
    IF --- selection is active if ~end is non-zero
      DUP ~begin @ ~end @ WITHIN
        IF DROP REVERSE ELSE ~end @ 1+ = IF 0 -TEXT  THEN THEN
    ELSE DROP
    THEN ;
pri hflgs? ( b -- f )       DUP ~hflgs BIT? DUP IF SWAP ~hflgs CLRB ELSE SWAP ~hflgs SETB THEN ;
pri MATCH? ( b s -- f )
    ~seq SWAP C$=
    IF   hflgs? IF -TEXT 0 ELSE 1 THEN
    ELSE DROP 0
    THEN ;

\       ... KEYBOARD INPUT ...
pri EDINP ( str -- len )        0 @STATUS -INFO 26 SPACES 0 @STATUS -HDRS TYPE -INFO TIB 32 ACCEPT ;

pri EDNUM ( str -- num f )      EDINP TIB SWAP NUMBER ;
\       *** ENHANCED KEY INPUT ***
--- return with char or long for single key or escape sequence
pub EDKEY ( --- code )
    KEY DUP $1B =
    IF  cycles SWAP
      BEGIN KEY?
---                ignore ;      else merge to code       update timeout
        IF KEY DUP ` ; = IF DROP ELSE SWAP 8 << OR THEN   NIP cycles SWAP THEN
---     timeout after 3ms of inactivity - must be end of sequence
        OVER cycles - ABS 3000 >
      UNTIL NIP
    THEN DUP ~key ! ;

\       ... HIGHLIGHTING ...

create :$   $20 C, ` : C, $0D C,
pri ?CODE
                7 ~hflgs BIT? IF ~seq C@ $20 = IF -TEXT 7 ~hflgs CLRB THEN THEN
                7 s" ( " MATCH? IF -TEXT THEN
                7 s"  bup" MATCH? IF red pen THEN               --- pub
                7 :$ 3 MATCH? IF red pen THEN
                7 s"  irp" MATCH? IF black pen BOLD THEN ;      --- pri
pri ?BOLD       0 s" ***" MATCH? IF BOLD THEN ;
pri ?UL         1 s"  ___" MATCH? IF UL THEN ;
pri ?BLINK      2 s" !!!" MATCH? IF BLINK THEN ;
pri ?COMMENT    3 s"  ---" MATCH? IF magenta PEN THEN
                3 s"  \"  MATCH? IF magenta pen THEN ;
pri ?REVERSE    4 s"  ..." MATCH? IF REVERSE THEN ;
pri ?PARA       5 s" ("  MATCH? IF magenta PEN THEN
                5 s" )"  MATCH? IF -TEXT THEN  ;
pri ?BRACES     6 s" {" MATCH? IF magenta PEN THEN
                6 s" }" MATCH? IF -TEXT THEN  ;

{
block comments
\ comment row
( comments *** BOLD *** )
*** BOLD ***
___ UNDERLINE ___
!!! BLINK !!!
... REVERSE ...
}



\       ... TEXT DISPLAY ...

pri ?HIGHLIGHT ( ch -- )
    ~seq @ 8 << OR ~seq !
    ?BOLD ?UL ?BLINK ?COMMENT ?REVERSE ?PARA  ?BRACES
    ?CODE
;
pri .ROW# ( index -- )
--- print line numbers or offset
    PLAIN CR lines? BIT?
    IF L>W .B .H
    ELSE 7 >> 2 SPACES 1+ 4 U.R
    THEN
;
--- Start each row with address offset
pri .ROW ( index -- )
    DUP .ROW#
---           text theme, reset hightlights
    ." :" SPACE -TEXT ~hflgs C~ pw BOUNDS
      DO I ?SELECT  I ED@ DUP ?HIGHLIGHT
---   indicate CR terminators anywhere in the line else display char
        DUP $0D = IF DROP REVERSE ` < EMIT -TEXT ELSE ` . AEMIT THEN
      LOOP
    -TEXT
;
--- refresh line
pri .LINE               LEFTLN .ROW ;





\       ... PAGE DISPLAY ...
pri .PAGE
--- page offset    for page size
    PAGEADR pagesz BOUNDS
      DO CRLF I .ROW  ew +LOOP ;
pri HEADER
    OFF CURSOR -HDRS HOME pw 8 + SPACES CR
    .PAGE# SPACE .INFO 1 2 XY .FTABS ;
pri REFRESH
    15 EMIT HEADER .PAGE 9 35 XY .RULER CRLF PLAIN 16 SPACES *FRED*
--- current cursor
    !TEXTXY ON CURSOR
--- refresh timer
    cycles ~idle !  0 ~eflgs CLRB ;
--- check if block needs to be refreshed (but not if key input busy)
pri ?REFRESH    KEY? ?EXIT   ~page @ ~edsect @ <> IF ~edsect @ ~page ! REFRESH THEN ;
pri ?PAGE       tcur@ PAGE DROP ?REFRESH ;
pri ?IDLE
    cycles ~idle @ - ABS 500000 >
    0 ~eflgs BIT? AND IF REFRESH THEN
    ~qt @ QTIME@ <> IF QTIME@ ~qt ! -HDRS .CLOCK -TEXT !TEXTXY THEN ;
pri EDDIR       PLAIN CLS HEADER  CRLF DIRW  ;

\       ... CHARACTER STORE ...
--- write a char to the page and set modified flag
pri EDCHAR! ( ch -- )   wr? BIT? IF tcur@ ED!  3 ~eflgs SET THEN ;
--- write new char but skip over any CR terminators
pri EDCHAR!!            wr? BIT? IF EDCHAR! 1 tcur+! tcur@ ED@ $0D = IF 1 tcur+! THEN ELSE DROP THEN ;
--- write character to file      forward but skip any embedded CR    then check refresh
pri EDCHAR              DUP EMIT EDCHAR!! ?REFRESH ;


\       ... NAVIGATION ...
--- smart tab will jump to comments column or indent 4 spaces etc
pri EDTAB
    @x 0= IF 4 tcur+! EXIT THEN  --- only 4 spaces from left margin
--- if previous a char & some text between cols 8..47 then tab to 48   else standard tab       set cursor
    tcur@ 1- ED@ $20 > tcur@ ew 1- AND 8 47 WITHIN AND
--- but no more text on the remainder of the line
    0 tcur@ PAGE BEGIN DUP C@ $0D <> WHILE DUP C@ $20 > IF NIP 1 SWAP THEN 1+ REPEAT DROP 0= AND
    IF LEFTLN 48 +  ELSE tcur@ 8 + 7 ANDN THEN tcur! ;

pri GOLEFT              1 tcur-! ;
pri GORIGHT             1 tcur+! ;
pri LNUP                ew tcur-! ?PAGE ?REFRESH ;
pri LNDN                ew tcur+! ?PAGE ?REFRESH ;
pri PGUP                pagesz tcur-! REFRESH ;
pri PGDN                pagesz tcur+! REFRESH ;
--- go to last char in line -
pri ENDLN               LEFTLN ew + BEGIN 1- DUP ED@ $20 > UNTIL 1+ tcur! ;
pri ENDTEXT             tcur@ BEGIN 1+ DUP ED@ 0= UNTIL tcur! REFRESH ;
pri ENDKEY              tcur@ ED@ 0= IF LNDN ENDTEXT ELSE tcur@ ENDLN tcur@ = IF ENDTEXT THEN THEN ;
--- If cursor is already on left then go to page or file home
pri ?HOME
    PAGEADR tcur@ = IF 0 tcur! REFRESH EXIT THEN
    LEFTLN tcur@ = IF PAGEADR tcur! REFRESH ELSE LEFTLN tcur! THEN
;

pri CLRLN ( ch -- )     LEFTLN PAGE ew 1- ROT FILL .LINE save? SETB ;
pri WIPELN              $20 CLRLN ;
pri BLANKS? --- test if  line is blank
    0 SWAP ew 1- BOUNDS DO I C@ OR LOOP $20 = ;


\       ... INSERT/DELETE ...


pri INS --- toggle insert/overwrite mode
    ins? BIT? IF ins? CLRB ELSE ins? SETB THEN REFRESH !TEXTXY ;
pri INSLN? --- Insert a line in the page
    pagebuf pagesz + ew - BLANKS? DUP 0EXIT
    LEFTLN PAGE DUP ew + pagebuf pagesz + OVER - MOVE WIPELN save? SETB ;
pri INSLN               INSLN? IF REFRESH THEN ;
pri DELLN --- Delete a line in the page
    LEFTLN PAGE DUP ew + SWAP   OVER pagesz 1- AND pagesz SWAP - MOVE
    tcur@ pagesz 1- ANDN pagesz + ew - PAGE ew 1- $20 FILL REFRESH save? SETB ;
pri DELCH --- Delete a char but if the line is blank then delete the line
    LEFTLN PAGE BLANKS? IF DELLN ELSE tcur@ PAGE DUP 1+ SWAP ew @x - 2- MOVE THEN
   .LINE save? SETB ;

pri INSCR
--- cur - insert new line  & cur   adr   adr-of-next-line+    ( cur src dst )
    tcur@ ew tcur+! INSLN? IF DUP PAGE DUP ew + ew 1- ANDN indent? BIT? IF 4 + THEN
    ( s d ) DUP BEGIN 1- DUP C@ $20 > UNTIL 1+ ( s d e ) 3RD -
    ( s d c ) 3rd 3rd 3rd  MOVE NIP $20 FILL REFRESH THEN tcur! ;

pri EDCR --- go to start of next line or auto-indent OR insert a line if at start and insert on.
    ins? BIT? IF LEFTLN tcur@ = IF INSLN ELSE INSCR THEN EXIT  THEN
    LEFTLN indent? BIT?
    IF
      BEGIN DUP ED@ $20 = WHILE 1+ REPEAT
      DUP ED@ $0D = IF DROP LEFTLN THEN
    THEN
    ew + tcur! ?REFRESH ;


\    ... CLIPBOARD ROUTINES ...

pri !CLIP               ~end ~ ~begin ~~ ;
pri !CLIPS              !CLIP ~clipsz ~ ;
--- save selected text
pri SAVECLIP        ~begin @ PAGE clipboard   ~end @ ~begin @ -   DUP ~clipsz ! MOVE ;

pri COPY --- mark the end and copy from begin -OR- copy the whole page if begin and end are same
    tcur@ ~begin @ = IF tcur@ pagesz 1- ANDN DUP ~begin ! pagesz 2- + ~end ! SAVECLIP REFRESH EXIT THEN
--- if begin is set - select block else  just select the current line
    ~begin @ 1+
    IF tcur@ ~end !   ~end @ ~begin @ <=
---    swap begin and end if wrong way around (why not?)
      IF ~end @ ~begin @ SWAP  ~begin ! ~end ! THEN
    ELSE
      LEFTLN DUP ~begin ! ew 1- + ~end !
    THEN
    SAVECLIP REFRESH ;
pri PASTE --- paste text marked by ^B and ending in ^C to current cursor - skip terminators
    ~clipsz @ ?DUP IF clipboard + clipboard ( to from )
    BEGIN DUP C@ DUP $0D = IF DROP ELSE EDCHAR!! THEN
    1+ DUP 3RD >= UNTIL 2DROP THEN
    ~end @ 0= IF !CLIPS THEN REFRESH ;
pri CUT --- cut the selected block -OR- only copy if there is no begin
    ~clipsz @ 0= IF COPY THEN
    ~begin @ tcur!  ~end @ ~begin @ DO $20 EDCHAR!! LOOP
    ~begin @ tcur!    !CLIP REFRESH ;





\       *** FILE OPERATIONS ***


pri OPENTAB ( -- f )    FTAB$ DUP C@ IF FOPEN$ ELSE DROP FALSE THEN ;

pri REVERT              save? CLRB OPENTAB DROP tcur@ pagesz + ED@ DROP PLAIN CLS REFRESH ~end ~ ;
--- just revert the page for an undo for the present
pri UNDO                REVERT ;
--- open FRED.CFG file but create if it doesn't exist
\ pri EDCFG              BEGIN s" FRED.CFG" FOPEN$ NOT WHILE 32 KB FSIZE! REPEAT 512 SDADR RW ;
pri EDCFG               s" FRED.CFG" FOPEN$ DROP 512 SDADR RW ;

pri LOADCFG             EDCFG ~ftabs 512 MOVE ;
pri SAVECFG             EDCFG DUP ~ftabs 512 COMPARE? NOT IF RW ~ftabs SWAP 512 MOVE FLUSH ELSE DROP THEN  ;

pub SAVEFILE
    SAVEPAGE RO MODIFIED
    SAVECFG
    0 @STATUS PRINT" SAVED    "
    OPENTAB DROP ;          --- RE-OPEN












\       ... MULTIPLE FILE TABS ...

pri TRIMTABS
    ~ftabs maxtabs 1- 5 << BOUNDS
    DO I @ 0= I FOPEN$ 0= OR  IF  I 32 + I 32 MOVE I 32 + 32 ERASE  THEN  32 +LOOP ;

pri SHOWTAB             OPENTAB IF ~page ~ ~edsect ~  ?PAGE THEN ;
--- switch to next tab - save first then find the next active tab  (shouln't be necessary if trimmed)
pri NEXTTAB             SAVEFILE BEGIN ~ftab ++ OPENTAB UNTIL SHOWTAB ;
pri PREVTAB             SAVEFILE BEGIN ~ftab -- OPENTAB UNTIL SHOWTAB ;
--- find the next spare tab
pri NEWTAB              BEGIN ~ftab ++  FTAB$ @ 0= UNTIL ;
--- save current, setup new tab with name, sector, etc
pri ADDTAB              NEWTAB  file$ FTAB$ $!   0 tcur! -MINT ?PAGE SAVECFG ;


pri CLOSETAB            SAVEFILE FTAB$ 32 ERASE PREVTAB TRIMTABS SAVECFG SHOWTAB ;
pri CLOSETABS           SAVEFILE FTAB$ 512 ERASE ~ftab C~ SHOWTAB ;

--- switch directly to the tab numbered 1..9
pri TABX                ~key C@ $31 - ~ftab C! FTAB$ @ if SHOWTAB ELSE NEXTTAB THEN ;


pri EDOPEN? ( s -- f )  EDINP DUP IF TIB + C~ TIB FOPEN$ THEN ;
pri NEWFILE             SAVEFILE RWC s" NEW: " EDOPEN? IF FORMAT.PAGES ADDTAB SHOWTAB THEN ;

pri EDOPEN              SAVEFILE EDDIR s" OPEN: " EDOPEN? IF ADDTAB THEN SHOWTAB ;





\       *** FIND & HELP etc ***

pri EDHELP              s" HELP" FOPEN$ IF 0 tcur! REFRESH THEN ;

pri ?EDFIND
    ~find @
    IF tcur@ 1+
      BEGIN DUP PAGE C@
      WHILE DUP PAGE TIB ~find @ C$=
         IF tcur! REFRESH EXIT THEN
        1+
      REPEAT  DROP
   THEN 0 @STATUS PRINT"  NOT FOUND     "
;
pri GOPAGE              1 MAX 1- pagesz * tcur! REFRESH ;
pri MARKEND             0 CLRLN REFRESH ;
pri EDPAGE              s" PAGE " EDNUM IF GOPAGE THEN ;
pri EDFIND              s" FIND " EDINP ~find ! ?EDFIND ;

pri EDESC               PLAIN CLS !CLIPS REFRESH ;
pub EDPRINT             PLAIN CLS ` * 40 EMITS  CRLF CRLF -FPRINT CRLF PRINT" <RETURN>" KEY DROP CLS REFRESH ;
pub EDQUIT              SAVEFILE FCLOSE SAVECFG 1 36 XY -INFO ( file$ PRINT$ ) PRINT"  CLOSED " PLAIN !SP QUIT ;

pri EDBS                1 tcur-! $20 EDCHAR! .LINE ;
pri EDNOP               REFRESH ;
pri REVTAB              tcur@ 8 - 7 ANDN tcur! ;
pri EDBEGIN             !CLIPS tcur@ ~begin ! ~end ~ ;
pri EDEDIT              wr? SETB REFRESH ;

INCLUDE IMPORT          --- ... import to page format routines ...


































\ ****************************************************
\               *** KEY COMMANDS ***
\ ****************************************************

(       *** FUNCTION KEYS F1-F10 ETC ***        )

pri FNC1        EDHELP ;
pri FNC2        ;
pri FNC3        ?EDFIND REFRESH ;
pri FNC4        ;
pri FNC5        ;
pri FNC6        ;
pri FNC7        ;
pri FNC8        ;
pri FNC9        pw 8 + $7 ANDN ew 1+ MOD 64 MAX ~pw ! PLAIN CLS REFRESH ;
pri FNC10       SAVEFILE SAVECFG OPENTAB DROP 0 EDLOAD ;
pri FNC11       ;
pri FNC12       EDDIR EDKEY DROP file$ FOPEN$ DROP REFRESH ;
pri ^F10        0 @STATUS CRLF clipboard ~clipsz @ + C~ clipboard MLOAD QUIT ;













\       *** CTL+ESC KEYS ***


pri ^HOME       0 tcur! REFRESH ;
pri ^END        ENDTEXT ;
pri ^PGUP       PGUP PGUP PGUP PGUP ;
pri ^PGDN       PGDN PGDN PGDN PGDN ;
pri ^LEFT       8 tcur-! ;
pri ^RIGHT      8 tcur+! ;
pri ^UP         LNUP LNUP LNUP LNUP ;
pri ^DOWN       LNDN LNDN LNDN LNDN ;





















\       *** ESCAPE SEQUENCES ***
CREATE CSIVECS
    $001B5B48 , ' ?HOME ,       $001B4F46 , ' ENDKEY ,
    $001B5B56 , ' PGUP ,        $001B5B55 , ' PGDN ,
    $001B5B44 , ' GOLEFT ,      $001B5B43 , ' GORIGHT ,
    $001B5B41 , ' LNUP ,        $001B5B42 , ' LNDN ,
    $001B5B5A , ' REVTAB ,      $00001B0D , ' INSLN ,
    $001B4F4D , ' DELLN ,       $00001B1B , ' EDESC ,
    $001B5B40 , ' INS ,         $00001B7F , ' DELCH ,
    --- ALT ---
    $5B313346 , ' MARKEND ,
    $5B35337E , ' PREVTAB ,     $5B36337E , ' NEXTTAB ,
    $5B313344 , ' PREVTAB ,     $5B313343 , ' NEXTTAB ,
    $5B33337E , ' WIPELN ,
---     ALT 1..9 switch to FILE TAB
    $1B31 , ' TABX , $1B32 , ' TABX , $1B33 , ' TABX , $1B34 , ' TABX ,
    $1B35 , ' TABX , $1B36 , ' TABX , $1B37 , ' TABX , $1B38 , ' TABX ,
    $1B39 , ' TABX ,

    --- CTRL ---
    $5B313548 , ' ^HOME ,       $5B313546 , ' ^END ,
    $5B35357E , ' ^PGUP ,       $5B36357E , ' ^PGDN ,
    $5B313544 , ' ^LEFT ,       $5B313543 , ' ^RIGHT ,
    $5B313541 , ' ^UP ,         $5B313542 , ' ^DOWN ,









    --- FUNCTION KEYS ---
    $001B4F50 , ' FNC1 ,        $001B4F51 , ' FNC2 ,
    $001B4F52 , ' FNC3 ,        $001B4F53 , ' FNC4 ,
    $001B4F54 , ' FNC5 ,        $001B4F55 , ' FNC6 ,
    $001B4F56 , ' FNC7 ,        $001B4F57 , ' FNC8 ,
    $001B4F58 , ' FNC9 ,        $5B32317E , ' FNC10 ,
    $001B4F59 , ' FNC12 ,
    --- CTRL FUNCTION KEYS ---
    $3231357E , ' ^F10 ,




    --- VT100 CODES ---
    $1B5B357E , ' PGUP ,        $1B5B367E , ' PGDN ,
    $1B5B317E , ' ?HOME ,       $001B4F46 , ' ENDKEY ,
    $1B5B327E , ' INS ,         $1B5B337E , ' DELCH ,
    $001B4F50 , ' FNC1 ,        $001B4F51 , ' FNC2 ,
    $001B4F52 , ' FNC3 ,        $001B4F53 , ' FNC4 ,
    $5B31367E , ' FNC5 ,        $5B31377E , ' FNC6 ,
    $5B31387E , ' FNC7 ,        $5B31397E , ' FNC8 ,
    $5B32307E , ' FNC9 ,        $5B32317E , ' FNC10 ,
    $5B32347E , ' FNC12 ,       $5B31317E , ' FNC1 ,
    $1B5B347E , ' ENDKEY ,      $5B31337E , ' FNC3 ,


    0 ,     --- table terminator




(       *** CONTROL SEQUENCE COMMANDS ***       )

pri EDCMD
    EDKEY a>A CASE
    ` I OF indent? TOGB REFRESH                 ENDOF
    ` L OF lines?  TOGB REFRESH                 ENDOF
    ` X OF MARKEND                              ENDOF   --- erase current line (nulls)
    ` Z OF WIPE.PAGE REFRESH                    ENDOF   --- wipe & format page
    ^ Q OF 0 @STATUS PLAIN QUIT                 ENDOF   --- special debug quit
    ^ Z OF ?FORMAT.PAGES                        ENDOF   --- page format the whole file

    ` 0 OF -MONO REFRESH                        ENDOF
    ` 1 OF -MINT REFRESH                        ENDOF
    ` 2 OF -DARK REFRESH                        ENDOF
    ` 3 OF -DAY REFRESH                         ENDOF
    ` 4 OF -BRIGHT REFRESH                      ENDOF
    ` 5 OF -C64 REFRESH                         ENDOF
    ` W OF wr? TOGB REFRESH                     ENDOF   --- toggle read/write & read-only mode

    $0D OF FORMAT.PAGE REFRESH                  ENDOF
    $20 OF WIPELN                               ENDOF   --- blank current line (spaces)
    ENDCASE
;









\                        *** CONTROL KEYS ***

CREATE EDCTLS
        ' EDNOP ,
        ' GOLEFT  ,     ' EDBEGIN ,     ' COPY ,        ' GORIGHT ,     --- A B C D
        ' EDEDIT ,      ' EDFIND ,      ' EDPAGE ,      ' EDBS ,        --- E F G H
        ' EDTAB ,       ' EDNOP ,       ' EDNOP ,       ' PGDN ,        --- I J K L
        ' EDCR ,        ' NEWFILE ,     ' EDOPEN ,      ' EDPRINT ,     --- M N O P
        ' EDQUIT ,      ' REVERT ,      ' SAVEFILE ,    ' EDNOP ,       --- Q R S T
        ' EDNOP ,       ' PASTE ,       ' CLOSETAB ,    ' CUT ,         --- U V W X
        ' EDCMD ,       ' UNDO ,        ' EDESC ,       ' EDNOP ,       --- Y Z [ \
        ' EDNOP ,       ' EDNOP ,       ' EDNOP ,                       --- ] ^ _
\ J T U \ ] ^ _

--- scan CSI vectors for matching key sequence code and execute - othewwise ignore
pri EDCSI       CSIVECS BEGIN DUP @ WHILE OVER OVER @ = IF NIP 4 + @ EXECUTE EXIT THEN 8 + REPEAT ;

pri ?INS        ins? BIT? IF tcur@ PAGE DUP 1+ ew @x - 2- MOVE THEN  ;
--- process key input into: controls - characters - CSI escape keys
pri EDKEY:
--- process control keys via EDCTLS table
    DUP $20 < IF 2 << EDCTLS + @ EXECUTE EXIT THEN
--- in case an ASCII DEL key is received (normally it's a CSI seq)
    DUP $7F = IF DROP DELCH EXIT THEN
--- if key > $FF then display the seq & process else insert/write char
    DUP 8 >> IF DUP 1 35 XY .L !TEXTXY EDCSI   ELSE ?INS EDCHAR  THEN
;





(       ... MAIN EDITOR TASK ...        )


--- main task loop handles keyboard input and idle time checks
pri EDTASK ( <addr>  -- )
    tcur! file$ FTAB$ $!
    CLS REFRESH
    cycles ~idle ! ~ftab C~ SHOWTAB
    BEGIN
      !SP   KEY?
        IF cycles ~idle !   -TEXT EDKEY EDKEY: !TEXTXY
        ELSE ?IDLE POLLS
        THEN
    AGAIN
;

(       *** INIT EDIT ***      )
pri !ED
    SD? 0= IF ."  No SD CARD! " QUIT THEN
    ~edcold @ $A55A <>
    IF
      ~edsect ~edcold OVER - ERASE
      -MINT
      ~edsect ~~
      $A55A ~edcold !
    THEN
;

0 bytes org?



(       *** EDITOR ENTRY MODES ***      )

--- edit a sector (current in text mode)
pub EDSECT        !ED OPEN-SECTOR file$ 16 ERASE s" SECTOR" file$ SWAP MOVE 0 EDTASK ;

--- Create a new preformatted file - default size = 1MB (else use "n FSIZE! NEWED <name>")
pub EDNEW         !ED RWC OPEN-FILE IF FORMAT.PAGES 0 EDTASK THEN ;

--- Edit FRED itself
pub EDME          !ED indent? SETB s" FRED" FOPEN$ IF tcur@ EDTASK THEN ;
--- edit a file or if none specified then the last one opened
pub ED ( ED <file> )
    SD? 0= ~sdpins @ 0=  OR IF PRINT"  Sorry - no SD card! " EXIT THEN
    !ED LOADCFG TRIMTABS  GET$ DUP LEN$
      IF SPACE FOPEN$ IF indent? SETB  0 EDTASK THEN
--- try to reopen the last file at the same position
      ELSE OPENTAB IF tcur@ EDTASK THEN
      THEN
    PRINT"  Unknown file " DIRW
    ;

\ End of load - 13676  code bytes and 576 data bytes used in 1,286,265us
*END*
 #FF
 CON ED
