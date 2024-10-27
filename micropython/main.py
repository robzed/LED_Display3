# Neopixel 24x24 display using Micropython on the rp2040
# Copyright (c) 2024 Rob Probin
# Open Source - Released under the MIT license
#
from machine import Pin, PWM, I2C
import time
from neopixel import NeoPixel
from font import glyph, list_glyph, b_per_glyph
from pictures import halloween_list, xmas_list
import math
from web_server import start_networking

p6 = Pin(6, Pin.OUT)    # create output pin on GPIO0
p20 = Pin(20, Pin.IN)     # create input pin on GPIO2
p21 = Pin(21, Pin.IN)     # create input pin on GPIO2
p22 = Pin(22, Pin.IN)     # create input pin on GPIO2

np_pin = Pin(28, Pin.OUT)   # set GPIO0 to output to drive NeoPixels

width = 24
height = 24

np = NeoPixel(np_pin, width*height)   # create NeoPixel driver on GPIO0 for 8 pixels

i2c=I2C(1, sda=Pin(2), scl=Pin(3), freq=400000)


black = (0, 0, 0)
blue = (0, 0, 10)
red = (10, 0, 0)
magenta = (10, 0, 10)
green = (0, 10, 0)
dark_green = (0, 2, 0)
cyan = (0, 10, 10)
yellow = (10, 10, 0)
white = (10, 10, 10)
orange = (10, 5, 0)
purple = (5, 0, 10)

background_colour = black
current_colour = white

def clear_image():
    np.fill(black)

def set_colour(c):
    global current_colour
    current_colour = c

def set_pixel(x, y):
    if y >= 0 and x >= 0 and x < width and y < height:
        np[(y*width) + x] = current_colour

def set_pixel_colour(x, y, colour):
    if y >= 0 and x >= 0 and x < width and y < height:
        np[(y*width) + x] = colour
    
def set_pixel_rgb(x, y, r, g, b):
    if y >= 0 and x >= 0 and x < width and y < height:
        np[(y*width) + x] = (r, g, b)

def show_pixels():
    np.write()

def printchar(x, y, char):
    width, graphic = glyph(char)
    height = b_per_glyph-1
    mask = 1 << (width-1)
    orig_x = x
    for line in graphic:
        x = orig_x
        current_mask = mask
        while current_mask:
            if line & current_mask:
                set_pixel_colour(x, y, current_colour)
            else:
                set_pixel_colour(x, y, background_colour)
            current_mask >>= 1
            x += 1
        y += 1
    return width

def print_string(x, y, string):
    for c in string:
        x += printchar(x, y, c)
        x += 1

def beep_on():
    global pwm0
    pwm0 = PWM(Pin(18), freq=2000, duty_u16=32768)      # create PWM object from a pin

def beep_off():
    global pwm0
    #pwm0.deinit()           # turn off PWM on the pin
    #pwm0 = None
    pwm0 = PWM(Pin(18), freq=2000, duty_u16=1)      # create PWM object from a pin

def double_beep():
    beep_on()
    time.sleep_ms(50) 
    beep_off()
    time.sleep_ms(50) 
    beep_on()
    time.sleep_ms(50) 
    beep_off()

def single_beep():
    beep_on()
    time.sleep_ms(50) 
    beep_off() 
    
i2c_addr=81
i2c_mem_size=7
i2c_mem_addr=2

def get_rtc_raw():
    # read from 8563
    #
    # read 7 bytes from memory of peripheral 
    #   starting at memory-address 2 in the peripheral
    return i2c.readfrom_mem(i2c_addr, i2c_mem_addr, i2c_mem_size)

day_names = [ "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" ]
short_day_names = [ "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" ]
short_month_names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" ]

class PCF8563:
    def __init__(self):
        self.read_RTC()            
    
    def _decompose_raw(self):
        self.seconds = self.seconds_tens * 10 + self.seconds_units
        self.minutes = self.minutes_tens * 10 + self.minutes_units
        self.hours = self.hours_tens * 10 + self.hours_units
        self.days = self.days_tens * 10 + self.days_units
        self.weekday_name = day_names[self.weekdays]
        self.short_weekday_name = short_day_names[self.weekdays]
        self.months = self.months_tens * 10 + self.months_units
        self.short_month_name = short_month_names[self.months-1]
        self.year = self.year_tens * 10 + self.year_units
        if self.century:
            self.year += 2000
        else:
            self.year += 1900
        
    def read_RTC(self):
        data = get_rtc_raw()
        self.bad = (data[0] & 0x80) != 0
        self.seconds_tens = (data[0] & 0x70) >> 4
        self.seconds_units = data[0] & 0x0F
        
        self.minutes_tens = (data[1] & 0x70) >> 4
        self.minutes_units = data[1] & 0x0F
        
        self.hours_tens = (data[2] & 0x30) >> 4
        self.hours_units = data[2] & 0x0F

        self.days_tens = (data[3] & 0x30) >> 4
        self.days_units = data[3] & 0x0F

        self.weekdays = data[4] & 0x07
        
        self.century = (data[5] & 0x80) != 0
        self.months_tens = (data[5] & 0x10) >> 4
        self.months_units = data[5] & 0x0F
        
        self.year_tens = (data[6] & 0xF0) >> 4
        self.year_units = data[6] & 0x0F
        
        self._decompose_raw()

    def print_last(self):
        print("%s %02d:%02d:%02d %02d-%02d-(%s)-%04d" %(self.short_weekday_name, self.hours, self.minutes, self.seconds, self.days, self.months, self.short_month_name, self.year))    
        if self.bad:
            print("<Warning bad>")

    def write_RTC(self):
        self._make_bytearray()
        i2c.writeto_mem(i2c_addr, i2c_mem_addr, self._bytearray_data)
        
    def set_weekday(self, weekday):
        
        self.weekdays = weekday
        self._decompose_raw()

    def set_time(self, hours, minutes, seconds):
        self.seconds_tens = (seconds // 10) % 10
        self.seconds_units = seconds % 10
        
        self.minutes_tens = (minutes // 10) % 10
        self.minutes_units = minutes % 10
        
        self.hours_tens = (hours // 10) % 10
        self.hours_units = hours % 10

        self._decompose_raw()
        self.bad = False

    def set_date(self, days, months, year):

        self.days_tens = (days // 10) % 10
        self.days_units = days % 10
        
        self.months_tens = (months // 10) % 10
        self.months_units = months % 10

        self.year_tens = (year // 10) % 10
        self.year_units = year % 10

        if year >= 2000:
            self.century = True
        else:  
            self.century = False

        self._decompose_raw()


    def _make_bytearray(self):
        self._bytearray_data = bytearray(7)
        
        self._bytearray_data[0] = ((0x07 & self.seconds_tens) << 4) + (self.seconds_units & 0x0F)
        self._bytearray_data[1] = ((0x07 & self.minutes_tens) << 4) + (self.minutes_units & 0x0F)

        self._bytearray_data[2] = ((0x03 & self.hours_tens)   << 4) + (self.hours_units & 0x0F)
        self._bytearray_data[3] = ((0x03 & self.days_tens)    << 4) + (self.days_units & 0x0F)
        self._bytearray_data[4] = (0x07 & self.weekdays)
        self._bytearray_data[5] = ((0x01 & self.months_tens)  << 4) + (self.months_units & 0x0F)
        if self.century:
            self._bytearray_data[5] += 0x80
        self._bytearray_data[6] = ((0x0F & self.year_tens)    << 4) + (self.year_units & 0x0F)
        #print(self._bytearray_data.hex())

#def set_colour():

def any_button():
    return p20.value()==0 or p21.value()==0 or p22.value()==0

def left_button():
    return p20.value()==0

def right_button():
    return p21.value()==0

def enter_button():
    return p22.value()==0


max_brightness = 20

character_lookup = {
    ' ': (0, 0, 0),	# black
    'W': (max_brightness, max_brightness, max_brightness),	# white
    'w': (max_brightness//4, max_brightness//2, max_brightness//4), # dim white
    'R': (max_brightness, 0, 0),    # red
    'r': (max_brightness//4, 0, 0), # dim white
    'G': (0, max_brightness, 0),	# green
    'g': (0, max_brightness//4, 0), # dim green
    'B': (0, 0, max_brightness),    # blue
    'b': (0, 0, max_brightness//4), # dim blue
    'C': (0, max_brightness, max_brightness),  # cyan
    'O': (max_brightness, max_brightness//4, 0),  # orange
    'P': (int(max_brightness*0.63), int(max_brightness*0.13), int(max_brightness*0.94)), # purple
    'M': (max_brightness, 0, max_brightness),   # magenta
    'm': (max_brightness//4, 0, max_brightness//4),  # dim magenta
    'Y': (max_brightness, max_brightness, 0),     # yellow
    'y': (max_brightness//4, max_brightness//4, 0),  # dim yellow (brown?)
}

def image_display_base(image):
    # convert image

    for row, line in enumerate(image):

        for col, c in enumerate(line):

            if c in character_lookup:
                colour = character_lookup[c]
            else:
                # default
                colour = (max_brightness//4, 0, 0)
            
            set_pixel_colour(col, row, colour)

def image_display(image):

    clear_image()
    image_display_base(image)
    show_pixels()
    
def slideshow(image_list):
    
    while True:
        for image_set in image_list:
            image, image_time = image_set
            image_display(image)

            while image_time > 0:
                if any_button():
                    return
                            
                time.sleep_ms(100)
                image_time -= 1


def show_time(time_rtc):
    while any_button()==False:
        clear_image()
        
        set_colour(orange)
        #printchar(0, 0, '!')
        print_string(0, 0, time_rtc.short_weekday_name)

        time_string = "%02d:%02d" % (time_rtc.hours, time_rtc.minutes)
        print_string(0, b_per_glyph, time_string)

        set_colour(red)
        date_string = "%d%s" % (time_rtc.days, time_rtc.short_month_name)
        print_string(0, 2*b_per_glyph, date_string)

        sec_string = "%02d" % time_rtc.seconds
        set_colour(blue)
        print_string(10, 3*b_per_glyph, sec_string)
        
        show_pixels()
        time.sleep_ms(250) 
        time_rtc.read_RTC()


# This test display displays a complete column of pixels in Red then green
# then blue across the display.
def row_swipe():
    display_mode = 0
    display_col = 0
    clear_image()
    
    while any_button()==False:
        if display_mode == 0:
            r = max_brightness; g = 0; b = 0;
        elif display_mode == 1:
            r = 0; g = max_brightness; b = 0;
        else:
            r = 0; g = 0; b = max_brightness;

        for row in range(height):
            set_pixel_rgb(display_col, row, r, g, b)

        show_pixels()

        # clear this led for the next time around the loop
        for row in range(height):
            set_pixel_rgb(display_col, row, 0, 0, 0)
            
        time.sleep_ms(100)
  
        display_col += 1
        if display_col >= width:
            display_col = 0
            display_mode += 1
            if display_mode == 3:
                display_mode = 0

# this test display fills each row with white, one pixel at a time
def slow_tickup():

    display_col = 0
    clear_image()
    
    while any_button()==False:

        set_pixel_rgb(display_col%width, display_col // width, max_brightness, max_brightness, max_brightness)
        show_pixels()
        time.sleep_ms(50)

        display_col += 1;
        if display_col % width == 0:
            clear_image()

        if display_col >= width * height: 
            display_col = 0


def pixel_walk():
    display_mode = 0
    display_col = 0
    clear_image()
    
    while any_button()==False:

        if display_mode == 0:
            r = max_brightness; g = max_brightness; b = max_brightness;
        elif display_mode == 1:
            r = max_brightness; g = 0; b = 0;
        elif display_mode == 1:
            r = 0; g = max_brightness; b = 0;
        else:
            r = 0; g = 0; b = max_brightness;

        set_pixel_rgb(display_col%width, display_col // width, r, g, b)
        show_pixels()
        set_pixel_rgb(display_col%width, display_col // width, 0, 0, 0)

        time.sleep_ms(30)
  
        display_col += 1
        if display_col >= width * height: 
            display_col = 0
            display_mode += 1
            if display_mode == 4:
                display_mode = 0

def fill_image_white():
    while any_button()==False:
        np.fill(white)
        time.sleep_ms(200)
        show_pixels()

def fill_image_red():
    while any_button()==False:
        np.fill(red)
        time.sleep_ms(200)
        show_pixels()

def fill_image_green():
    while any_button()==False:
        np.fill(green)
        time.sleep_ms(200)
        show_pixels()

def fill_image_blue():
    while any_button()==False:
        np.fill(blue)
        time.sleep_ms(200)
        show_pixels()

test_mode = row_swipe

def switch_test_mode():
    global test_mode
    if test_mode == row_swipe:
        test_mode = slow_tickup
    elif test_mode == slow_tickup:
        test_mode = pixel_walk
    elif test_mode == pixel_walk:
        test_mode = fill_image_white
    elif test_mode == fill_image_white:
        test_mode = fill_image_red
    elif test_mode == fill_image_red:
        test_mode = fill_image_green
    elif test_mode == fill_image_green:
        test_mode = fill_image_blue
    else:
        test_mode = row_swipe

clock_face = [
#123456789012345678901234
"           BB           ", #1
"                        ", #2
"      b          b      ", #3
"                        ", #4
"                        ", #5
"                        ", #6
"  b                  b  ", #7
"                        ", #8
"                        ", #9
"                        ", #0
"                        ", #1
"B                      B", #2
"B                      B", #3
"                        ", #4
"                        ", #5
"                        ", #6
"  b                  b  ", #7
"                        ", #8
"                        ", #9
"                        ", #0
"                        ", #1
"      b          b      ", #2
"                        ", #3
"           BB           ", #4
#123456789012345678901234
]

def set_pixel_rounded(x, y, colour):
    set_pixel_colour(int(x + 0.5), int(y + 0.5), colour)
    
# Bresenham's line algorithm
def plotLineInt(x0, y0, x1, y1, colour):
    dx = abs(x1 - x0)
    sx = 1 if x0 < x1 else -1
    dy = -abs(y1 - y0)
    sy = 1 if y0 < y1 else -1
    error = dx + dy
    
    while True:
        set_pixel_colour(x0, y0, colour)
        if x0 == x1 and y0 == y1:
            break
        e2 = 2 * error
        if e2 >= dy:
            if x0 == x1:
                break
            error = error + dy
            x0 = x0 + sx

        if e2 <= dx:
            if y0 == y1:
                break
            error = error + dx
            y0 = y0 + sy


def plotLine(x0, y0, x1, y1, colour):
    plotLineInt(int(x0+0.5),int(y0+0.5),int(x1+0.5),int(y1+0.5), colour)
    
def draw_clock_radius(x, y, length, angle_degrees_from_12, colour):
    #angle_degrees_from_12 = -angle_degrees_from_12	# clock hand goes clockwise, sine, cosine goes anticlockwise
    #angle_degrees_from_12 += 90	# adjust for normal 3 o'clock position for sine/cosine
    finish_x = x + length * math.sin((angle_degrees_from_12*2*math.pi)/360)
    finish_y = y - length * math.cos((angle_degrees_from_12*2*math.pi)/360)
    plotLine(x, y, finish_x, finish_y, colour)

def draw_60_hand(x, y, length, sixtieths_0_59, colour):
    # 360/60 = 6
    draw_clock_radius(x, y, length, sixtieths_0_59*6, colour)

def draw_12_hand(x, y, length, twelfths, colour):
    # 360/12 = 30
    draw_clock_radius(x, y, length, twelfths*30, colour)

def show_analogue_clock(time_rtc):
    while any_button()==False:
        clear_image()
        
        image_display_base(clock_face)

        draw_60_hand(12.4, 12.4, 10, time_rtc.seconds, blue)
        draw_60_hand(12.4, 12.4, 10, time_rtc.minutes, green)
        draw_12_hand(12.4, 12.4, 5, time_rtc.hours+(time_rtc.minutes/60), cyan)
        
        show_pixels()
        time.sleep_ms(250) 
        time_rtc.read_RTC()


def main():
    double_beep()
    #p6.on()                 # set pin to "on" (high) level
    #time.sleep_ms(500) 
    #p6.off()                # set pin to "off" (low) level
    #start_networking()
    print("Connected")
    
    time_rtc = PCF8563()
    time_rtc.print_last()
    
    set_the_time = False
    if set_the_time:
        time_rtc.set_weekday(5)
        time_rtc.set_date(24, 5, 2024)
        time_rtc.set_time(17, 29, 0)
        time_rtc.print_last()
        time_rtc.write_RTC()
    
    #list_glyph(*glyph('a'))
    #list_glyph(*glyph('!'))
    #list_glyph(*glyph('}'))
    #print(i2c.scan())

    mode = 0
    while True:
        if mode == 0:
            show_time(time_rtc)
        elif mode == 1:
            slideshow(halloween_list)
        elif mode == 2:
            slideshow(xmas_list)
        elif mode == 3:
            show_analogue_clock(time_rtc)
        elif mode == 4:
            test_mode()

        if right_button():
            single_beep()
            mode += 1
            if mode == 5:
                mode = 0
            print("Left, mode =", mode)
        elif left_button():
            single_beep()
            mode -= 1
            if mode == -1:
                mode = 5
            print("Right, mode =", mode)
        elif enter_button():
            single_beep()
            print("Enter")
            if mode == 4:
                switch_test_mode()

        time.sleep_ms(300)


main()

