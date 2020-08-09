import cv2 as cv
import argparse
import sys
import numpy as np
import os.path
import re
import pytesseract as tess
tess.pytesseract.tesseract_cmd = r'C:\Users\Samet\AppData\Local\Tesseract-OCR\tesseract.exe'

# Confidence threshold , eğer ağ tarafından geri döndürülen sonuç %50 nin altında ise, bunu kullanıcıya göstermemek için 0.5 verildi.
confThreshold = 0.5
nmsThreshold = 0.4  # Non-maximum suppression threshold bu değer şu şekilde açıklanabilir, deeplearning ağı %40 ve üzeri ihtimalle 5 tane noktayı detect eder deetect ettikten sonra hepsini kare içine alır
# kare içine aldığı alanların kesişimlerinden oluşan alanı bulmamız bizi tek bir noktaya yoğunlaştıracaktır. ve en yüksek doğruluk değerine ulaşmamıza sağlayacaktır bunun için kullanıyoruz

inpWidth = 416  # 608     #Width of network's input image Deep learning ağına girecek tek boyutlu hale getirilmeye çalışan input değerimizin genişliği
inpHeight = 416  # 608     #Height of network's input image Deep learning ağına girecek tek boyutlu hale getirilmeye çalışan input değerimizin yüksekliği

parser = argparse.ArgumentParser(
    description='Object Detection using YOLO in OPENCV')
parser.add_argument('--image', help='Path to image file.')
parser.add_argument('--video', help='Path to video file.')
# add_argument tarafına yazılan kodlarla, bu kod dosyasını console üzerinde çalıştırabiliyoruz
args = parser.parse_args()

# Load names of classes
classesFile = "classes.names"  # Deeplearning ağımızda, plaka yeri eğitilmiş verilerinden oluştuğunu biliyotuz, ve bu tek bir sınıf içeriyor. bu yüzden detect ettiği alana yazdırdığı LP burdan gelmekte LicencePlate'in kısaltılmışıdır

classes = None
with open(classesFile, 'rt') as f:
    classes = f.read().rstrip('\n').split('\n')

# Aşağıdaki kod parçacığında eğitilmiş verileri içeren .weighht dosyamı ve yukarda 416 * 415 piksel şeklinde input verdiğimiz deeplearning ağının configurasyon dosylaraı yüklenmiştir.
modelConfiguration = "darknet-yolov3.cfg"
modelWeights = "licenceplate.weights"

net = cv.dnn.readNetFromDarknet(modelConfiguration, modelWeights)
net.setPreferableBackend(cv.dnn.DNN_BACKEND_OPENCV)
net.setPreferableTarget(cv.dnn.DNN_TARGET_CPU)


def character_det(string):
    n_str = ""
    if len(string) >= 7 & len(string) < 9:
        x = re.findall("\w", string)
        for i in x:
            n_str = n_str+i

    n_str = n_str.upper()
    return n_str


def getOutputsNames(net):
    # Get the names of all the layers in the network
    layersNames = net.getLayerNames()
    # Get the names of the output layers, i.e. the layers with unconnected outputs
    return [layersNames[i[0] - 1] for i in net.getUnconnectedOutLayers()]

# Draw the predicted bounding box


def drawPred(classId, conf, left, top, right, bottom, text):
    # Draw a bounding box.
    #    cv.rectangle(frame, (left, top), (right, bottom), (255, 178, 50), 3)
    cv.rectangle(frame, (left, top), (right, bottom), (0, 255, 0), 3)

    label = '%.2f' % conf + "  Plate :" + text

    # Get the label for the class name and its confidence
    if classes:
        assert(classId < len(classes))
        label = '%s:%s' % (classes[classId], label)

    # Display the label at the top of the bounding box
    labelSize, baseLine = cv.getTextSize(
        label, cv.FONT_HERSHEY_SIMPLEX, 0.5, 1)
    top = max(top, labelSize[1])
    cv.rectangle(frame, (left, top - round(1.5*labelSize[1])), (left + round(
        1.5*labelSize[0]), top + baseLine), (0, 0, 255), cv.FILLED)
    #cv.rectangle(frame, (left, top - round(1.5*labelSize[1])), (left + round(1.5*labelSize[0]), top + baseLine),    (255, 255, 255), cv.FILLED)
    cv.putText(frame, label, (left, top),
               cv.FONT_HERSHEY_SIMPLEX, 0.75, (0, 0, 0), 2)


# Remove the bounding boxes with low confidence using non-maxima suppression

# ana fonksiyonumuz olarak aşağıdaki yapıyı kullanıyoruz bu yapı global bir kullanıma sahiptir eğitilmiş her türlü veriyi aşağıdaki algoritmadan geçirerek detect edebiliriz
# yaptığımız iş minimum güven deeğeri olarak kodun başında tanıladığımız değere göre, ağın detect ettiği ve etrafına kutu çizerek geri döndürdüğü her türlü veri taranır
# güven değerine göre en yüksek skoru alanlar, işlem sürecine girer.


def postprocess(frame, outs):
    frameHeight = frame.shape[0]
    frameWidth = frame.shape[1]

    classIds = []
    confidences = []
    boxes = []
    # Scan through all the bounding boxes output from the network and keep only the
    # ones with high confidence scores. Assign the box's class label as the class with the highest score.
    classIds = []
    confidences = []
    boxes = []
    for out in outs:
        print("out.shape : ", out.shape)
        for detection in out:
            # if detection[4]>0.001:
            scores = detection[5:]
            classId = np.argmax(scores)
            # if scores[classId]>confThreshold:
            confidence = scores[classId]
            if detection[4] > confThreshold:
                print(detection[4], " - ", scores[classId],
                      " - th : ", confThreshold)
                print(detection)
            if confidence > confThreshold:
                center_x = int(detection[0] * frameWidth)
                center_y = int(detection[1] * frameHeight)
                width = int(detection[2] * frameWidth)
                height = int(detection[3] * frameHeight)
                left = int(center_x - width / 2)
                top = int(center_y - height / 2)
                classIds.append(classId)
                confidences.append(float(confidence))
                boxes.append([left, top, width, height])
                crop_img = frame[top:top+height, left:left+width]
                cv.imshow("cropped", crop_img)
                text = tess.image_to_string(crop_img)
                n_text = character_det(text)
                print(n_text)
    # Perform non maximum suppression to eliminate redundant overlapping boxes with
    # lower confidences.
    # ağda biz görmesek bile birden çok detect edilen kutu vardır fakat yukarda verdiğimiz güven eşik değeri ve minimum tanılama değerine göre gereksiz kutuların kaldırıldığı nokta aşağıdaki döngüdür.
    indices = cv.dnn.NMSBoxes(boxes, confidences, confThreshold, nmsThreshold)
    for i in indices:
        i = i[0]
        box = boxes[i]
        left = box[0]
        top = box[1]
        width = box[2]
        height = box[3]
        drawPred(classIds[i], confidences[i], left,
                 top, left + width, top + height, n_text)


# Process inputs
winName = 'Deep learning object detection in OpenCV'
cv.namedWindow(winName, cv.WINDOW_NORMAL)

outputFile = "yolo_out_py.avi"
if (args.image):
    # Open the image file
    if not os.path.isfile(args.image):
        print("Input image file ", args.image, " doesn't exist")
        sys.exit(1)
    cap = cv.VideoCapture(args.image)
    outputFile = args.image[:-4]+'_yolo_out_py.jpg'
elif (args.video):
    # Open the video file
    if not os.path.isfile(args.video):
        print("Input video file ", args.video, " doesn't exist")
        sys.exit(1)
    cap = cv.VideoCapture(args.video)
    outputFile = args.video[:-4]+'_yolo_out_py.avi'
else:
    # Webcam input
    cap = cv.VideoCapture(0)

# Get the video writer initialized to save the output video
# video şeklinde dışarı aktarımı sağlanan bu kod parçacığı VideoWriter_forucc nesnesini kullanır. FFMPEG open source mimarisini kuılllanan bu yapı, istenilen değere göre
# yani bizim verdiğimiz fps = 5 ve bizim belirlediğimiz boyutlarda tanılama sağlamaktadır.
if (not args.image):
    vid_writer = cv.VideoWriter(outputFile, cv.VideoWriter_fourcc('M', 'J', 'P', 'G'), 30, (round(
        cap.get(cv.CAP_PROP_FRAME_WIDTH)), round(cap.get(cv.CAP_PROP_FRAME_HEIGHT))))

while cv.waitKey(1) < 0:

    # get frame from the video
    hasFrame, frame = cap.read()

    # cv.imshow(winName, frame)

    # Stop the program if reached end of video
    if not hasFrame:
        print("Done processing !!!")
        print("Output file is stored as ", outputFile)
        cv.waitKey(3000)
        break

    # Create a 4D blob from a frame.
    blob = cv.dnn.blobFromImage(
        frame, 1/255, (inpWidth, inpHeight), [0, 0, 0], 1, crop=False)

    # Sets the input to the network
    net.setInput(blob)

    # Runs the forward pass to get output of the output layers
    outs = net.forward(getOutputsNames(net))

    # Remove the bounding boxes with low confidence
    postprocess(frame, outs)

    # Put efficiency information. The function getPerfProfile returns the overall time for inference(t) and the timings for each of the layers(in layersTimes)
    t, _ = net.getPerfProfile()
    label = 'Inference time: %.2f ms' % (t * 1000.0 / cv.getTickFrequency())
    # cv.putText(frame, label, (0, 15), cv.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 255))

    cv.imshow(winName, frame)

    # Write the frame with the detection boxes
    if (args.image):
        cv.imwrite(outputFile, frame.astype(np.uint8))
    else:
        vid_writer.write(frame.astype(np.uint8))
