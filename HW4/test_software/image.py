import cv2
import numpy as np
import math
import torch
import torch.nn as nn
import torch.nn.functional as F

#Read the image
image_path = "./image.png" or "./image.jpg"
image = cv2.imread(image_path)
#cv2.imshow('original image', image)

#Convert to grayscale and resize
gray_image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
resized_image = cv2.resize(gray_image, (64, 64))

#Output image data as img.dat
data_file = open("img.dat", "w")
i = 0

for row in resized_image:
    for pixel in row:
        pixel_value = float(pixel)
        pixel_f = '{0:09b}'.format(pixel)
        data_file.write(pixel_f+"0000")
        data_file.write(" //data "+str(i)+": "+f"{pixel_value:.1f}""\n")
        i = i+1
data_file.close()

#Padding the image to 68x68
padded_image = cv2.copyMakeBorder(resized_image, 2, 2, 2, 2, cv2.BORDER_REPLICATE)

#Astrous convolution
kernel = torch.tensor([[-0.0625, -0.125, -0.0625],
                       [-0.25, 1, -0.25],
                       [-0.0625, -0.125, -0.0625]], dtype=torch.float32).unsqueeze(0).unsqueeze(0)
bias = -0.75
#Convert the image to a tensor and add dimensions for batch and channel
input_tensor = torch.from_numpy(padded_image).unsqueeze(0).unsqueeze(0).float()

#Perform astrous convolution
convolved_tensor = F.conv2d(input_tensor, kernel, stride=1, padding=0, dilation=2) + bias

#Convert the convolved tensor back to a numpy array
convoluted_image = convolved_tensor.squeeze(0).squeeze(0).numpy()

#ReLU activation
relu_image = np.maximum(convoluted_image, 0)
cv2.imwrite("layer0_outputImg.png", relu_image)

data_file = open("layer0_golden.dat", "w")
i = 0
for row in relu_image:
    for pixel in row:
        pixel_value = float(pixel)
        pixel_f = int(pixel_value * 16)
        pixel_f = '{0:013b}'.format(pixel_f)
        data_file.write(pixel_f)
        data_file.write(" //data "+str(i)+": "+f"{pixel_value}""\n")
        i = i+1
data_file.close()

#Maxpooling
pooling_kernel = (2, 2)
stride = 2
pooling_image = torch.from_numpy(relu_image).unsqueeze(0).unsqueeze(0).float()
pooling_output = nn.MaxPool2d(pooling_kernel, stride, ceil_mode = True)(pooling_image)
pooling_result = pooling_output.squeeze(0).squeeze(0).numpy()

## filter the float number
data_file = open("layer1_golden.dat", "w")
i = 0
for row in pooling_result:
    for pixel in row:
        pixel_value = float(pixel)
        pixel_value = math.ceil(pixel_value)
        pixel_f = '{0:09b}'.format(pixel_value)
        data_file.write(pixel_f+"0000")
        data_file.write(" //data "+str(i)+": "+f"{pixel_value:.1f}""\n")
        i = i+1
data_file.close()
cv2.imwrite("layer1_outputImg.png", pooling_result)

print("final image size = " + str(pooling_result.shape) + "\n")
print("Finish.")
