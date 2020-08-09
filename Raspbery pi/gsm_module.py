import RPi.GPIO as GPIO
import serial
import time
import sys
from firebase import Firebase


GPIO.setmode(GPIO.BOARD)

# Set pin 11 as an output, and set servo1 as pin 11 as PWM
GPIO.setup(7, GPIO.OUT)
servo1 = GPIO.PWM(7, 50)
GPIO.setwarnings(False)


config = {
    "apiKey": "AIzaSyBYUpdPDgOUtYOZiA38rHL9d5gZXdzq9e8",
    "databaseURL": "https://piproject-e345f.firebaseio.com/",
    "authDomain": "piproject-e345f.firebaseapp.com",
    "storageBucket": "piproject-e345f.appspot.com"
}

firebase_data = Firebase(config)
db = firebase_data.database()

registered_plates = db.child("plateDatas").child("registeredPlates").get()
items = {}


SERIAL_PORT = "/dev/ttyS0"
port = serial.Serial(SERIAL_PORT, baudrate=9600, timeout=2)

port.write('AT'+'\r\n')
port.write("\x0D\x0A")
rcv = port.read(13)
print(rcv)
time.sleep(1)

#
while port.available:

    if registered_plates != None:
        for regPlateDatas in registered_plates.each():
            items = regPlateDatas.val()
            if items["PhoneNumber"] == rcv:
                print("Gelen Arama --> ")
                print(rcv)
                print("Numara Kaydı Doğrulandı. Kapı Açılıyor. ")
                print("Arama Sonlandırılıyor...")
                # Arama Sonlandı
                port.write("ATH\r")
                # port.write("ATA\r") aramayı açar kapalı olmalı .
                servo1.start(0)
                servo1.ChangeDutyCycle(7)
                time.sleep(20)
                print("Kapı Kapanıyor...")
                servo1.ChangeDutyCycle(2)
                time.sleep(0.5)
                servo1.ChangeDutyCycle(0)
            else:
                print("Gelen Arama --> ")
                print(rcv)
                print("Arayan Numara Kayıtlı Değil")
                print("Arama Sonlandırılıyor...")
                port.write("ATH\r")


