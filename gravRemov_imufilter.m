function [accNoGrav_gcf,accNoGrav_imu,grav_imu] = gravRemov_imufilter(acc,gyr,fs)

% The function GRAVREMOV_IMUFILTER is a function to remove gravitational
% acceleration from the input acceleration signal using quaternions
% computed from simultaneous acceleration and angular velocity data using
% MATLAB's 'imufilter' function.
%
% Note that the beginning of the inputsignal should correspond to a static
% behaviour.
%
% Further notes from MATLAB documentation of the Sensor Fusion and Tracking
% toolbox (Pg 268 of 1158):
%       "Although the imufilter and complementaryFilter algorithms
% produce significantly smoother estimates of the motion, compared to the
% ecompass, they do not correctly estimate the direction of north. The
% imufilter does not process magnetometer data, so it simply assumes the
% device's X-axis is initially pointing northward. The motion estimate
% given by imufilter is relative to the initial estimated orientation. The
% complementaryFilter makes the same assumption when the HasMagnetometer
% property is set to false."
%
%
% INPUTS:
% acc:  mx3 matrix containing triaxial acceleration in units of m/s^2 (NOT
%       g!).
% gyr:  mx3 matrix containing triaxial angular velocity in rad/s (NOT
%       deg/s).
% fs:   scalar denoting sampling frequency in Hertz of accelerometer and
%       gyroscope.
%
% OUTPUTS:
% accNoGrav_gcf:    mx3 matrix containing gravity-compensated triaxial
%                   acceleration (in global coordinate frame) in m/s^2.
% accNoGrav_imu:    mx3 matrix containing gravity-compensated triaxial
%                   acceleration (in IMU frame) in m/s^2.
% grav_imu:         mx3 matrix containing estimated gravity vector in IMU
%                   frame in units of m/s^2.
%
% Written:  9 Sep-30 Oct 2022
%           Pritish Chakravarty


% create imufilter object
imufiltobj = imufilter('SampleRate',fs,'ReferenceFrame','NED');
            % "FUSE = imufilter('ReferenceFrame',RF) returns an imufilter
            % filter System object that fuses accelerometer and gyroscope
            % data to estimate device orientation relative to the reference
            % frame RF. Specify RF as 'NED' (North-East-Down) or 'ENU'
            % (East-North-Up). The default value is 'NED'."

% pass acc and gyr data to imufilter object to estimate orientation
q_gcf2imu = imufiltobj(acc,gyr); % output will be in the form of quaternions that rotate vectors FROM the global coordinate frame TO the IMU frame.

% rotate gravity from global coordinate frame to IMU frame
grav_imu = rotateframe(q_gcf2imu,9.81*[0 0 1]); % note that the gravity vector (second argument) must be specified in units of m/s^2 (NOT g).

% subtract gravity from the input acceleration signal
accNoGrav_imu = acc - grav_imu; % gravity-compensated acceleration in IMU frame



%% Compute accelerations in global coordinate frame

% arranging the computed quaternions for input to function 'quatinv'
[qa,qb,qc,qd] = parts(q_gcf2imu); % extracts scalar values from the 4D complex quaternion
qvec = [qa,qb,qc,qd]; % concatenating into one matrix

% computing inverted quaternions (IMU frame to GCF frame)
q_imu2gcf = quaternion(quatinv(qvec)); % computing the inverse of the quaternions and converting to 4D complex format
clearvars qa qb qc qd qvec

% computing gravity-compensated acceleration in global coordinate frame
accNoGrav_gcf = rotateframe(q_imu2gcf,accNoGrav_imu);