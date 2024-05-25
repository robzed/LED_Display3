
from machine import Pin, PWM, I2C
import time
from neopixel import NeoPixel
from font import glyph, list_glyph, b_per_glyph

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
    mask = 1 << width
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
    pwm0.deinit()           # turn off PWM on the pin
    pwm0 = None
    
def double_beep():
    beep_on()
    time.sleep_ms(50) 
    beep_off()
    time.sleep_ms(50) 
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
    
def main():
    double_beep()
    #p6.on()                 # set pin to "on" (high) level
    #time.sleep_ms(500) 
    #p6.off()                # set pin to "off" (low) level
    
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

    while False:
        r = 0
        g = 0
        b = 0
        if p20.value()==0:
            r = 20
        if p21.value()==0:
            g = 20
        if p22.value()==0:
            b = 20
        
        #np[0] = (r, g, b)
        #np.write()              # write data to all pixels
        #r, g, b = np[0]         # get first pixel colour
        set_pixel_rgb(0, 0, r, g, b)
        show_pixels()

        time.sleep_ms(50) 

    while True:
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

        if False:
            set_pixel_colour(0, 0, current_colour)
            set_pixel_colour(2, 0, current_colour)
            set_pixel_colour(10, 0, current_colour)

            set_pixel_colour(1, 1, white)
            set_pixel_colour(2, 2, white)
            set_pixel_colour(3, 3, white)
            set_pixel_colour(4, 4, blue)
        
        show_pixels()
        time.sleep_ms(250) 
        time_rtc.read_RTC()

main()

