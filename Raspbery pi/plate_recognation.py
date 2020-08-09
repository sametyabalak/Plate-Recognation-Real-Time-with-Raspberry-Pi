import cv2
import imutils
import numpy as np
import pytesseract
from PIL import Image
from picamera.array import PiRGBArray
from picamera import PiCamera
from firebase import Firebase
import datetime
import json
import re
import RPi.GPIO as GPIO
import time


###################

# Set GPIO numbering mode
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

firebase_data = Firebase(config)
db = firebase_data.database()

items= {}
registered_plates = db.child("plateDatas").child("registeredPlates").get()

#      print(plateDatas.key()) 

def character_det(string):
    n_str=""
    x=re.findall("\w", string)
    for i in x:
        n_str=n_str+i
    return n_str             
        
# my_data_file = open('platedata.txt', 'w')
camera = PiCamera()
camera.resolution = (640, 480)
camera.framerate = 30
rawCapture = PiRGBArray(camera, size=(640, 480))
    
for frame in camera.capture_continuous(rawCapture, format="bgr", use_video_port=True):
        image = frame.array
        cv2.imshow("Frame", image)
        key = cv2.waitKey(1) & 0xFF
        rawCapture.truncate(0)
        if key == ord("s"):
             gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY) #convert to grey scale
             gray = cv2.bilateralFilter(gray, 11, 17, 17) #Blur to reduce noise
             edged = cv2.Canny(gray, 30, 200) #Perform Edge detection
             cnts = cv2.findContours(edged.copy(), cv2.RETR_TREE,              cv2.CHAIN_APPROX_SIMPLE)
             cnts = imutils.grab_contours(cnts)
             cnts = sorted(cnts, key = cv2.contourArea, reverse = True)[:10]
             screenCnt = None
             for c in cnts:
                peri = cv2.arcLength(c, True)
                approx = cv2.approxPolyDP(c, 0.018 * peri, True)
                if len(approx) == 4:
                  screenCnt = approx
                  break
             if screenCnt is None:
               detected = 0
               print ("No contour detected")
               continue
             else:
               detected = 1
             if detected == 1:
               cv2.drawContours(image, [screenCnt], -1, (0, 255, 0), 3)
             mask = np.zeros(gray.shape,np.uint8)
             new_image = cv2.drawContours(mask,[screenCnt],0,255,-1,)
             new_image = cv2.bitwise_and(image,image,mask=mask)
             (x, y) = np.where(mask == 255)
             (topx, topy) = (np.min(x), np.min(y))
             (bottomx, bottomy) = (np.max(x), np.max(y))
             Cropped = gray[topx:bottomx+1, topy:bottomy+1]
             text = pytesseract.image_to_string(Cropped, config='--psm 11')
             print("Detected Number is:",text)
             r_text = character_det(text)
             print("Organized Number is:",r_text)
             x = datetime.datetime.now()
             this_time = x.strftime("%c")
#              my_data_file.write(text)
             if registered_plates != None:
                for regPlateDatas in registered_plates.each():
                    items= regPlateDatas.val()
                    y = json.dumps(items)
                    z = json.loads(y)
                    if r_text == z["PlateNumber"]:
                        print("Plaka Onaylandı..")
                        print ("Kapı Açılıyor...")
                        servo1.start(0)
                        servo1.ChangeDutyCycle(7)
                        time.sleep(30)
                        print ("Kapı Kapanıyor...")
                        servo1.ChangeDutyCycle(2)
                        time.sleep(0.5)
                        servo1.ChangeDutyCycle(0)
#                         continue
#                          print("Geçiş İzni Verildi")
#                          print("Kapı açılıyor")               
             data = {"PlakaNo": r_text, "entryTime": str(this_time)  }   
             db.child("plateDatas").child("entryDatas").push(data)
#              data2 = {"PlakaNo": r_text}
#              db.child("plateDatas").child("registeredPlates").push(data2)
#              cv2.imshow("Frame", image)
#              cv2.imshow('Cropped',Cropped)
             continue
#              my_data_file.close()
             cv2.waitKey(0)
#              break
             
cv2.destroyAllWindows()
