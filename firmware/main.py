
import network
import socket
import time
import json
from machine import Pin
from config import WIFI_NAME, WIFI_PASSWORD, AP_NAME, AP_PASSWORD

# ==========================================
# CONFIGURATION
# ==========================================



HTTP_PORT = 80

CONNECT_TIMEOUT_MS = 12000
AP_RETRY_INTERVAL_MS = 120000
LOOP_DELAY_MS = 100

# ==========================================
# HARDWARE
# ==========================================

led = Pin("LED", Pin.OUT)
led.off()

sta = network.WLAN(network.STA_IF)
ap = network.WLAN(network.AP_IF)

mode = "connecting"
server = None
last_ap_retry = time.ticks_ms()
last_led_update = time.ticks_ms()

# ==========================================
# LED STATUS
# ==========================================

def update_led():
    global last_led_update

    now = time.ticks_ms()

    if mode == "connected":
        led.on()
        return

    if mode == "connecting":
        interval = 500
    elif mode == "hotspot":
        interval = 150
    else:
        led.off()
        return

    if time.ticks_diff(now, last_led_update) >= interval:
        led.value(1 - led.value())
        last_led_update = now


# ==========================================
# NETWORK
# ==========================================

def close_server():
    global server

    if server is not None:
        try:
            server.close()
        except OSError:
            pass

    server = None



def connect_wifi():
    global mode

    mode = "connecting"
    led.off()

    print("Connecting to home Wi-Fi...")

    try:
        ap.active(False)

        sta.active(False)
        time.sleep_ms(500)
        sta.active(True)
        time.sleep_ms(500)

        sta.connect(WIFI_NAME, WIFI_PASSWORD)

        started = time.ticks_ms()
        last_status = None

        while time.ticks_diff(
            time.ticks_ms(), started
        ) < 30000:

            update_led()

            status = sta.status()

            if status != last_status:
                print("Wi-Fi status:", status)
                last_status = status

            if sta.isconnected():
                mode = "connected"
                print("Wi-Fi connected!")
                print("Pico IP:", sta.ifconfig()[0])
                return True

            time.sleep_ms(100)

    except Exception as error:
        print("Wi-Fi error:", repr(error))

    print("Final Wi-Fi status:", sta.status())
    print("Home Wi-Fi unavailable")
    return False



def start_hotspot():
    global mode, last_ap_retry

    print("Starting fallback hotspot...")

    try:
        sta.active(False)

        ap.active(False)

        # WPA2-PSK secured hotspot.
        ap.config(
            ssid=AP_NAME,
            security=network.WLAN.SEC_WPA_WPA2,
            key=AP_PASSWORD
        )

        ap.active(True)

        if not ap.active():
            raise RuntimeError("AP failed to activate")

        print("AP security:", ap.config("security"))
        print("AP SSID:", ap.config("ssid"))
        print("AP password length:", len(AP_PASSWORD))

        mode = "hotspot"
        last_ap_retry = time.ticks_ms()

        print("Hotspot:", AP_NAME)
        print("Hotspot IP:", ap.ifconfig()[0])
        return True

    except Exception as error:
        print("Hotspot error:", error)
        mode = "error"
        return False


def establish_network():
    if connect_wifi():
        return True

    return start_hotspot()


# ==========================================
# HTTP SERVER
# ==========================================

def start_server():
    global server

    close_server()

    try:
        server = socket.socket()

        server.setsockopt(
            socket.SOL_SOCKET,
            socket.SO_REUSEADDR,
            1
        )

        server.bind(("0.0.0.0", HTTP_PORT))
        server.listen(2)
        server.settimeout(0.2)

        print("HTTP server ready!")
        return True

    except Exception as error:
        print("Server error:", error)
        close_server()
        return False


def send_response(client, status, data):
    body = json.dumps(data).encode()

    headers = (
        "HTTP/1.1 " + status + "\r\n"
        "Content-Type: application/json\r\n"
        "Content-Length: " + str(len(body)) + "\r\n"
        "Connection: close\r\n"
        "\r\n"
    )

    client.sendall(headers.encode() + body)


def handle_request(client):
    client.settimeout(2)

    request = client.recv(1024)

    if not request:
        return

    try:
        first_line = request.decode().split("\r\n")[0]
        parts = first_line.split(" ")

        method = parts[0]
        path = parts[1].split("?")[0]

    except (IndexError, ValueError, UnicodeError):
        send_response(
            client,
            "400 Bad Request",
            {"error": "Invalid request"}
        )
        return

    if method != "GET":
        send_response(
            client,
            "405 Method Not Allowed",
            {"error": "Method not allowed"}
        )
        return

    if path in ("/", "/health", "/status"):

        if mode == "connected":
            ip = sta.ifconfig()[0]
        elif mode == "hotspot":
            ip = ap.ifconfig()[0]
        else:
            ip = None

        send_response(
            client,
            "200 OK",
            {
                "device": "DoorZero",
                "status": "ready",
                "mode": mode,
                "ip": ip,
                "uptime_seconds": time.ticks_ms() // 1000
            }
        )

    elif path in ("/led/on", "/led/off"):
        send_response(
            client,
            "410 Gone",
            {
                "error": "LED is now a status indicator"
            }
        )

    else:
        send_response(
            client,
            "404 Not Found",
            {"error": "Unknown endpoint"}
        )


# ==========================================
# MAIN LOOP
# ==========================================

def main():
    global mode, last_ap_retry

    print("Door Zero starting...")

    if not establish_network():
        print("Network startup failed")

    if mode in ("connected", "hotspot"):
        start_server()

    while True:

        update_led()

        # Home Wi-Fi lost
        if mode == "connected" and not sta.isconnected():

            print("Wi-Fi connection lost")

            close_server()

            if not establish_network():
                time.sleep_ms(1000)

            if mode in ("connected", "hotspot"):
                start_server()

        # In hotspot mode, periodically retry home Wi-Fi.
        # Only do this if no client is connected to our hotspot.
        elif mode == "hotspot":

            elapsed = time.ticks_diff(
                time.ticks_ms(),
                last_ap_retry
            )

            if elapsed >= AP_RETRY_INTERVAL_MS:

                if not ap.isconnected():
                    print("Retrying home Wi-Fi...")

                    close_server()

                    if not establish_network():
                        time.sleep_ms(1000)

                    if mode in ("connected", "hotspot"):
                        start_server()

        # Network or server startup failure:
        # periodically retry.
        elif mode == "error":

            elapsed = time.ticks_diff(
                time.ticks_ms(),
                last_ap_retry
            )

            if elapsed >= AP_RETRY_INTERVAL_MS:
                last_ap_retry = time.ticks_ms()

                if establish_network():
                    start_server()

        # HTTP processing
        if server is not None:

            client = None

            try:
                client, address = server.accept()
                handle_request(client)

            except OSError:
                # Usually an accept timeout.
                # The loop continues so Wi-Fi and LED
                # states can be checked.
                pass

            except Exception as error:
                print("HTTP error:", error)

            finally:
                if client is not None:
                    try:
                        client.close()
                    except OSError:
                        pass

        elif mode in ("connected", "hotspot"):
            # Recover from failure to open HTTP socket.
            start_server()
            time.sleep_ms(500)

        time.sleep_ms(LOOP_DELAY_MS)


# ==========================================
# STARTUP
# ==========================================

try:
    main()

except KeyboardInterrupt:
    print("Stopped manually")
    close_server()
    led.off()

except Exception as error:
    print("Fatal error:", error)
    close_server()
    led.off()

    # Reboot so a transient failure doesn't
    # leave Door Zero permanently unresponsive.
    time.sleep(5)

    import machine
    machine.reset()
