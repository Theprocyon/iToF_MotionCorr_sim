
Camera parameters:
==================
Focal length - 24mm
Format - 1024x512
Sensor width - 32mm
Baseline - 100mm

Functions:
==========

Read/Write '.dpt files:
-----------------------
depth_read.m
depth_write.m

Read/Write disparity files:
-----------------------------
disparity_read.m
disparity_write.m

Depth2Disparity.m:
------------------
Use this function to create:
'Disparity' - saved as a '.png' file using 'disparity_write.m' function
'DisparityVisual' - low-res visual disparity images.
'Occlusions' - binary mask of pixels in the left image that are occluded from the right one.
'OutOfFrame' - binary mask of pixels in the left image that are outside the field of view of the right image.

