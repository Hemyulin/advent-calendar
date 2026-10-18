from machine import Pin
from time import sleep

print("Advent Calendar starting...")

led = Pin("LED", Pin.OUT)

def blink(duration):
    led.on()
    sleep(duration)
    led.off()

while True:
    blink(0.2)
    sleep(2)

