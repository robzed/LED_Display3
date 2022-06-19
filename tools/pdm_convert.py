# Little program for converting PBM to Forth
import sys

char_height = 5
pad_to_width = 8

def load_image():
    f = open("CG-pixel-4x5.pbm")
    lines = f.readlines()
    f.close()
    linenum = 1
    raw_image_list = [ ]
    for line in lines:
        line = line.strip()
        if linenum == 1:
            if line != "P1":
                print("Expected P1 to include .pbm image file")
        elif linenum == 2:
            if not line.startswith("#"):
                print("Expected comment line")
        elif linenum == 3:
            width, height = line.split()
            width = int(width)
            height = int(height)
            #print(width, height)
        else:
            ls = line.split()
            #print(ls)
            raw_image_list.append(ls)

        linenum += 1
    if linenum != height+4:
        print("File length not as expected")
        print(height)
        print(linenum)

    return raw_image_list, width, height

def is_vertical_clear(image, x, y):
    global char_height
    for i in range(char_height):
        if image[y+i][x]=='1':
            return False
    return True

def get_width(image, x, y, gap_in_char=False):
    offset = 0
    while True:
        if is_vertical_clear(image, x+offset, y):
            if gap_in_char:
                gap_in_char = False
            else:
                break
        offset += 1
        #print(x+offset, len(image[0]))
        if x+offset >= len(image[0]):
            break;

    return offset

def get_char(image, x, y, gap_in_char=False):
    width = get_width(image, x, y, gap_in_char)
    global char_height
    char = []
    for y1 in range(char_height):
        char.append(image[y+y1][x:x+width])
    return char

def skip_spaces(image, x, y):
    width = 0
    while is_vertical_clear(image, x+width, y):
        width += 1

        if x+width >= len(image[0]):
            break;

    return width
    

def print_char(what_char, c):
    global pad_to_width
    print(len(c[0]), "c, \ character", what_char)
    for line in c:
        bitmap = ''.join(line)
        if len(bitmap) > pad_to_width:
            print("Pad not wide enough")
            sys.exit()

        bitmap = bitmap.rjust(pad_to_width, '0')
        print("%"+bitmap, "c,")

def decode_row(image, width, string_char, x, y):
    char_dict = {}
    count = 0
    while True:
        c = get_char(image, x, y, string_char[count]=='"')
        c_width = len(c[0])
        if c_width == 0:
            print("Zero width character!")
            sys.exit()

        
        #print_char(string_char[count], c)
        #print(string_char[count])
        char_dict[string_char[count]] = c
        x += c_width
        if x >= width:
            break
        #print("Char width", c_width)

        space_width = skip_spaces(image, x, y)
        #print("Space width", space_width)
        x += space_width
        if x >= width:
            break
        count += 1

    return char_dict

def print_row(image_dict, output_order):
    for c in output_order:
        print_char(c, image_dict[c])

def main():
    image, width, height = load_image()
    if len(image) != height:
        print("Unexpected height")
    for line in image:
        if len(line) != width:
            print("Unexpected width")
    global char_height
    if height != char_height*2+1:
        print("Unexpected height [2]")

    # first line is characters
    string_char = "AQUICKBROWNFOXJUMPSOVERTHELAZYDOG"
    x = 0
    y = 0
    dict_image = decode_row(image, width, string_char, x ,y)
    print_row(dict_image, "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    
    # second line is characters and symbols
    string_char = "0123456789!\"#%$%&/()=?+\\{}[],.;:-*@^'`<>|"
    x = 0
    y = char_height+1
    dict_image = decode_row(image, width, string_char, x ,y)

    print_row(dict_image, "!\"#$%&'()*+,-./0123456789:;<=>?@")
    #"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    print_row(dict_image, "[\\]^`{|}")
    #"abcdefghijklmnopqrstuvwxyz"
    #print_row(dict_image, "_~")

main()



