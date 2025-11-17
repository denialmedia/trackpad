#!/usr/bin/env python3
import socket
import threading
import pyautogui
import time
from pynput.mouse import Button, Controller

# pyautogui.FAILSAFE = False  # Disable failsafe, use with care

mouse = Controller()

SERVER_IP = '0.0.0.0'  # Listen on all interfaces
SERVER_PORT = 5005

def handle_mouse(data):
    message = data.decode('utf-8').strip()
    parts = message.split(':')
    if len(parts) != 3:
        print(f"Invalid message: {message}")
        return

    cmd, x, y = parts[0], float(parts[1]), float(parts[2])

    print(f"Received: {cmd} {x} {y}")

    if cmd == "MOVE":
        # Move relative
        pyautogui.moveRel(x, y, _pause=False)
        # smooth, but for low latency
    elif cmd == "DOWN":
        # Start drag or press (but for trackpad, perhaps just move without click)
        # For trackpad, usually not press on touch down, but move
        # Perhaps better: when receiving DOWN, set drag mode, but for simplicity
        # Let's assume no press, just move relative on all.
        # To simulate click, perhaps detect short touch.
        # But since UDP, and no timer, hard.
        # Perhaps send separate command for click.
        # For now, ignore DOWN/UP, only move.
        pass
    elif cmd == "UP":
        # Release if dragging
        pass
    elif cmd == "CLICK":
        # If we add gesture detection on Android
        pyautogui.click()
    elif cmd == "RIGHT_CLICK":
        pyautogui.rightClick()

def receive_data(sock):
    while True:
        try:
            data, addr = sock.recvfrom(1024)
            print(f"Received from {addr}: {data}")
            handle_mouse(data)
        except Exception as e:
            print(f"Error receiving data: {e}")
            break

def main():
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((SERVER_IP, SERVER_PORT))
    print(f"Server listening on {SERVER_IP}:{SERVER_PORT}")

    # Start a thread to receive data
    receiver_thread = threading.Thread(target=receive_data, args=(sock,))
    receiver_thread.daemon = True
    receiver_thread.start()

    try:
        while True:
            time.sleep(1)  # Keep main thread alive
    except KeyboardInterrupt:
        print("Shutting down server")
    finally:
        sock.close()

if __name__ == "__main__":
    main()
