Written:	11 May 2023
		Pritish Chakravarty


This text file provides brief descriptions of the code accompanying Chakravarty et al. 2023, a study that provides a method to estimate an animal's daily energy expenditure in Joule by combining accelerometry with allometry.

1. 'speed_strapdownIntegration.m': A script to compute locomotion speed given accelerometer and gyroscope data. This code is divided into two sections. Section 1 describes how to compute the domain of integration of the acceleration signal from a bout of locomotion behaviour padded on both sides (before and after) by static behaviour. Section 2 describes how to compute strapped-down locomotion speed in the global coordinate frame through sensor fusion, followed by gravity compensation using orientation quaternions (see function called 'gravRemov_imufilter.m' below), and finally integration of the 3D acceleration within the domain of integration found in Section 1.

2. 'gravRemov_imufilter.m': A function to remove gravitational acceleration from the input acceleration signal using quaternions computed from simultaneous acceleration and angular velocity data using MATLAB's 'imufilter' function.

3. 'dee_actiwake_actirest24.m': Script to compute daily energy expenditure for meerkats in Joules using the ACTIWAKE (Section 1 of script) and ACTIREST24 (Section 2 of script) models given 24-hour triaxial acceleration data and body mass of the animal.