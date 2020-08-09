from firebase import Firebase
import json
import threading
# import time
import RPi.GPIO as GPIO
import time

###################################

GPIO.setmode(GPIO.BOARD)

# Set pin 11 as an output, and set servo1 as pin 11 as PWM
GPIO.setup(7,GPIO.OUT)
servo1 = GPIO.PWM(7,50)
GPIO.setwarnings(False)

config = {
  "apiKey": "AIzaSyBYUpdPDgOUtYOZiA38rHL9d5gZXdzq9e8",
  "databaseURL": "https://piproject-e345f.firebaseio.com/",
  "authDomain": "piproject-e345f.firebaseapp.com",
  "storageBucket": "piproject-e345f.appspot.com"
}

firebase = Firebase(config)
db = firebase.database()
state=False

registered_plates = db.child("plateDatas").child("registeredPlates").get()

def rtdb_listen_changes(r_p,db):
    if r_p != None:
        for regPlateDatas in r_p.each():
            key= regPlateDatas.key()
            gate_state = db.child("plateDatas").child("registeredPlates").child(key).get().val()
#             print(gate_state["IsGateOpen"])
            if gate_state["IsGateOpen"] == 'true':
                state = True
                break
            else:
                state= False
    return state
            
while True :
    time.sleep(3)
    state=rtdb_listen_changes(registered_plates,db)
    print(state)
    if state == True:
        print ("Giriş İzni Verildi ...Kapı Açılıyor...")
        servo1.start(0)
        servo1.ChangeDutyCycle(7)
        time.sleep(30)
        print ("Kapı Kapanıyor...")
        servo1.ChangeDutyCycle(2)
        time.sleep(0.5)
        servo1.ChangeDutyCycle(0)
#         print("Geçiş izni verildi")
#         print("Kapı açılıyor")
#         time.sleep(30)
        










