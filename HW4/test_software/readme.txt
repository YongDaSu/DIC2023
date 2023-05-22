# Python version 3.10.11

Step1. Change the image file name into image.png or image.jpg

Step2. Put the image in the same folder with the program

Step3. Open command line at the program folder

Step4. Execute the python program, type "python ./image.py"

Step5. The program will generate following output:
	1. img.dat
	2. layer0_golden.dat
	3. layer1_golden.dat
	4. layer0_outputImg.png or layer0_outputImg.jpg
	5. layer1_outputImg.png or layer1_outputImg.jpg

***Notice***
make sure you import following python module:

import cv2
import numpy as np
import math
import torch
import torch.nn as nn
import torch.nn.functional as F

#