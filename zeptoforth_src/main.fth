\ Neopixel 24x24 display using Zeptoforth on the rp2040
\ Copyright (c) 2024 Rob Probin
\ Open Source - Released under the MIT license

compile-to-flash
#include sounds.fth
#include more_sounds.fth
zap
#include debug_prompt.fth

#include support.fth
#include LED2PICO.FTH

#include pictures.fth

marker LED3base
compile-to-ram

cr cr cr cr ." Please Reboot" cr cr

init-LED2PICO
#include image.fth

