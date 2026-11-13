import network
import socket
import time
from machine import Pin
from config import WIFI_NAME, WIFI_PASSWORD


led = Pin("LED", Pin.OUT)
led.off()

wifi = network.WLAN(network.STA_IF)
wifi.active(True)

if not wifi.isconnected():
    wifi.connect(WIFI_NAME, WIFI_PASSWORD)

    for attempt in range(20):
        if wifi.isconnected():
            break
        time.sleep(1)

if not wifi.isconnected():
    raise RuntimeError("Wi-Fi connection failed")

ip = wifi.ifconfig()[0]
print("Pico IP:", ip)

server = socket.socket()
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(("0.0.0.0", 80))
server.listen(1)

print("HTTP server ready!")

while True:
    client, address = server.accept()

    try:
        request = client.recv(1024).decode()
        path = request.split(" ")[1]

        if path == "/led/on":
            led.on()
            message = "LED ON"
        elif path == "/led/off":
            led.off()
            message = "LED OFF"
        else:
            message = "Pico W is running"

        response = (
            "HTTP/1.1 200 OK\r\n"
            "Content-Type: text/plain\r\n"
            "Connection: close\r\n"
            "\r\n"
            + message
        )

        client.sendall(response.encode())
    finally:
        client.close()

