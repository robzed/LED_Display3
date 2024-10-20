import network
import time
#import _thread
import socket

from wifi_details import wifi_ssid, wifi_password

form_callback = None

# HTML content of the form
html = """<!DOCTYPE html>
<html>
    <head> <title>Pico W Form</title> </head>
    <body>
        <h1>Submit Data</h1>
        <form action="/" method="post">
            <label for="data">Data:</label><br>
            <input type="text" id="data" name="data"><br>
            <input type="submit" value="Submit">
        </form>
    </body>
</html>
"""

def start_server():
    addr = socket.getaddrinfo('0.0.0.0', 80)[0][-1]
    s = socket.socket()
    s.bind(addr)
    s.listen(1)
    print('listening on', addr)

    while True:
        cl, addr = s.accept()
        print('client connected from', addr)
        request = cl.recv(1024)
        request = str(request)
        print('Request:', request)

        # Check if the request is a POST
        if 'POST' in request:
            # Extract the form data
            data_start = request.find('data=') + 5
            data_end = request.find(' ', data_start)
            if data_end == -1:
                data_end = len(request)
            form_data = request[data_start:data_end]
            form_data = form_data.replace('%20', ' ')  # Decode spaces

            # Print the form data to the console
            print('Form data:', form_data)

            # Respond with a confirmation message
            response = 'HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n'
            response += f"<html><body><h1>Data received: {form_data}</h1></body></html>"
        else:
            # Respond with the HTML form
            response = 'HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n' + html

        cl.send(response)
        cl.close()

def connect_wifi():

    print("Connecting to Wi-fi...")
    
    wlan = network.WLAN(network.STA_IF)
    wlan.active(True)
    wlan.connect(wifi_ssid, wifi_password)

    # Wait for connection
    while not wlan.isconnected():
        time.sleep(1)

    print('network config:', wlan.ifconfig())


def start_networking(callback=None):
    
    global form_callback
    form_callback = callback
    
    # Main code
    connect_wifi()

    # Start the server on the second core
    # Rob's note: _thread doesn't appear to work consistently
    #_thread.start_new_thread(start_server, ())
    start_server()

