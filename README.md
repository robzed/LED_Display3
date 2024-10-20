LED Display 3 - Raspberry Pi Pico based driver board with a NeoPixel display

# Overview

There are two versions in this Repo:

1. Zeptoforth version under zeptoforth_src - see main.fth.
2. Micropython version under micropython.

There is also an incomplete version that targetted Mecrisp Stellaris with Peter Jakacki's extensions inside old_src/ - but don't use that.

# History 

I originally started with mecrisp with Peter Jakack's extensions to use the SD card, and his editor FRED. I ran out of time,
switched projects and left it unfinished.

I ported a bunch of the work to Micropython, and had a workking display with realtime clock. But manual clock 
setting was required via a lead and Micropython hacking. I intended to use the 
button on the board to set the time. I also wanted to use the web interface - but I couldn't get the 
web interface working running the webserver on the Pico W with a thread.

I returned to the Forth version that I'd previously done under Zeptoforh and committed to 
Git. 


# Zeptoforth version

Add notes here....


# Micropython version

See the files in 'micropython'. You should start with main.py.

Add notes here... 


# Hardware

The display itself is a 24 x 24 pixel Neopixel (WS2812) based display. You can see an image of the LEDs wired up, without the picture frame or frosted 'glass' in the LED_Display2 project (link below).

The controller board is loosely based on the Maker Pi Pico board by Cytron https://www.cytron.io/p-maker-pi-pico - the code will work with other configurations - see TACHYON.FTH for details and custom configuration.

![Board Picture](images/board.jpg)

# Background

Second LED board, but with new controller board (Rasberry Pi Pico rather than Arduino Nano 33 BLE).

Previous versions:
 * Second Display, Nano 33 BLE controller - ported pForth with flash file system (unpublished)
 * Second Display, Nano 33 BLE controller, Arduino (unfinished) https://github.com/robzed/LED_Display2
 * Original Display - One version Forth, Second version Forth plus Python/Rasbperry Pi  https://github.com/robzed/LED_Display


# License

LED display code Copyright (c) 2022 Rob Probin. 

PicoForth/Tachyon Extensions/FRED Copyright (c) 2021-2022 Peter Jackacki.

MIT License - See LICENSE



# OLD INFORMATION

You'll need Mecrisp Stellaris. You can use the stock 115200 baud serial Pico image, but Peter Jakacki supplied one with 921600 baud here: https://github.com/forth2020/tachyon/tree/main/rp2040/mecrisp (mecrisp-2.61-921600bd.uf2).

You'll need to load TACHYON (you can do this with FL and get the whole thing loaded in a couple of seconds). I'll add instructions later. You might want FRED.FTH editor. Both of these are in the 'Picoforth_Tachyon_Extensions/' folder.

You'll then need to load LED2PICO.FTH from the src/ directory.

## Serial Emulator

Since the PicoForth/Tachyon extensions use colour ANSI sequences - minicom has good support. It might also work via screen.

minicom --color=on -8 -b 921600 -D <<<insert serial port here>>>

For example
  minicom --color=on -8 -b 921600 -D COM4
  minicom --color=on -8 -b 921400 -D /dev/tty.serial0
  minicom --color=on -8 -b 921600 -D /dev/cu.usbserial-A50285BI

### Mac Users

NOTE: The Mac requires a switch to a higher baud rate than API that minicom uses will All. You have to switch the baud rate from another terminal session while minicom is running because MacOS API doesn’t allow setting baud rate that high via the API that minicom uses…

stty -f /dev/cu.usbserial-A50285BI 921600

(Use same device - cu or tty as above for Minicom)

## Original code

Simple test image

![Test Image](images/test_image.jpeg)


