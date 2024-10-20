\ Tests derived from Tachyon/Peter J.
\ MIT License


: 3RD 2 PICK ;

: oTONE ( hz ms -- ) swap tone ;
\ : CLICK         spkr C@ ?DUP IF DUP HIGH 100 us LOW THEN ;
: BIP           3000 50 oTONE ;
: BEEP          3000 150 oTONE ;
: BEEPS         0 DO BEEP 50 ms LOOP ;
: WARBLE ( hz1 hz2 ms -- )    3 0 DO 3RD OVER oTONE 2DUP oTONE LOOP DROP 2DROP ;
: SIREN                 400 550 400 WARBLE ;
: ~R                    500 600 40 WARBLE ;
: RING                  ~R 200 ms ~R ;
: RINGS ( rings -- )    0 DO RING 1000 ms LOOP ;

: ZAP               3000 100 DO I 15 I 300 / - oTONE 200 +LOOP ;
: ZAPS ( cnt -- )   0 DO ZAP 50 ms LOOP ;
: SAUCER            10 0 DO 600 50 oTONE 580 50 oTONE LOOP ;

: invade SAUCER ZAP SAUCER 3 ZAPS SIREN ;

