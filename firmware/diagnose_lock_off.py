"""Run in Thonny to isolate an active-high XY-MOS input; never enables the load.

Disconnect the solenoid's supply before changing wiring. Stop the application
before running this file. Measure GP15 relative to Pico GND, then TRIG/PWM
relative to module GND; a commanded LOW is not an electrical measurement.
"""
from machine import Pin
from time import sleep_ms

_lock = Pin(15, Pin.OUT, Pin.PULL_DOWN, value=0)
_lock.off()
print("GP15 commanded LOW continuously. No network or unlock commands run.")

try:
    while True:
        _lock.off()
        sleep_ms(100)
except KeyboardInterrupt:
    pass
finally:
    _lock.off()
