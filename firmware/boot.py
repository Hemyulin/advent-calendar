"""Keep the active-high lock/MOSFET control inactive before main.py starts."""
from machine import Pin

# Only the actuator GPIO is touched; other pins belong to board peripherals.
LOCK_GPIO = 15
_boot_lock = Pin(LOCK_GPIO, Pin.OUT, Pin.PULL_DOWN, value=0)
_boot_lock.off()
