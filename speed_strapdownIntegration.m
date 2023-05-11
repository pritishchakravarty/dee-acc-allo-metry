% This script is divided into two sections:
%   Section 1 describes how to compute the domain of integration of the
%       acceleration signal given accelerometer ("acc", in units of g) and
%       gyroscope ("gyr", in units of deg/s) data from a locomotion bout
%       padded on both sides by static behaviour.
%   Section 2 describes how to compute strapped-down speed in the global
%       coordinate frame by integrating 3D acceleration within the domain
%       of integration found in Section 1.
%
% Written:  27 Jul-30 Oct 2022
%           Pritish Chakravarty



%% SECTION 1: Find domain of integration of acceleration using standard-deviation criterion

% Note that for speed estimation, we selected locomotion (walking/running)
% bouts that were preceded and followed by a minimum duration (one second)
% of static behaviour (resting/vigilance). The accelerometer and gyroscope
% data for the whole locomotion bout padded by static behaviour on either
% side was arranged as:
%   {one second of static behaviour before locomotion bout,
%    full locomotion bout of variable length,
%    one second of static behaviour after locomotion bout}

% basic initialisations that were used to select locomotion bouts preceded
%       and followed by static behaviour
fs = 100; % Hz. Sampling frequency of accelerometer
minDynDur = 2; % seconds. Minimum required duration of bout of dynamic behaviour
minStatPadDur = 1; % seconds. Minimum required duration of bouts of static behaviour on either side of the dynamic behaviour, kept as 'padding'.
minStatLen = round(minStatPadDur*fs); % samples. Length of static-behaviour padding (on either side of the locomotion bout) in samples.

% user parameters for computing domain of integration of acceleration
wstd = 0.1; % seconds. Length of window within which moving std will be computed
accthresh = 0.02; % g. Threshold of moving std of acc norm below which sensor is deemed to be 'still' (speed = 0)
gyrthresh = 5; % deg/s. Threshold of moving std of gyr norm below which sensor is deemed to be 'still' (speed = 0)
refineHalfLen = round(0.5*fs); % samples. Half-length of window centred around
                               % start (and end) of dynamic behaviour in
                               % which initial (and final) points of
                               % integration will be found using std
                               % threshold criteria.
                               % Note that this should be less than
                               % "minStatLen"

% initialising, and doing basic computations
wLen = round(wstd*fs); % length of moving-std window in samples
integIdx = nan(1,2); % starting and ending indices in bout within which integration of acceleration is done to compute velocity


% computing vectorial norm of acceleration and angular velocity
accnorm = vecnorm(acc')'; % vectorial norm of acceleration (units: g)
gyrnorm = vecnorm(gyr')'; % vectorial norm of angular velocity (units: deg/s)

% computing std of accnorm
accstd = movstd(accnorm,wLen);

% computing std of gyrnorm
gyrstd = movstd(gyrnorm,wLen);

% find starting point of integration
        % (last moment before labelled commencement of dynamic behaviour
        %       when sensor is still motionless)
idxRange = minStatLen-refineHalfLen:minStatLen+refineHalfLen; % search for starting point of integration within this index range
startPt = find(accstd(idxRange)<=accthresh & gyrstd(idxRaccange)<=gyrthresh,1,'last');
if ~isempty(startPt)
    integIdx(1,1) = startPt + minStatLen - refineHalfLen - 1;
else
    rmvBout = true; % remove this bout, since a suitable starting point for the integration could not be found
end

% find ending point of integration
        % (first moment after labelled end of dynamic behaviour when
        %       sensor becomes motionless)
idxRange = size(acc,1)-minStatLen+1-refineHalfLen:size(acc,1)-minStatLen+1+refineHalfLen; % search for ending point of integration within this index range
endPt = find(accstd(idxRange)<=accthresh & gyrstd(idxRange)<=gyrthresh,1,'first');
if ~isempty(endPt)
    integIdx(1,2) = endPt + size(acc,1) - minStatLen + 1 - refineHalfLen - 1; % the +1 and -1 are left in there for ease of understanding how indices were computed
else
    rmvBout = true; % remove this bout, since a suitable ending point for the integration could not be found
end



%% SECTION 2: Compute strapped-down speed in the global coordinate frame

% removing mean from acceleration in domain of integration
[accNoGrav_gcf,accNoGrav_imu,grav_imu] = gravRemov_imufilter(9.81*acc(integIdx(1,1):integIdx(1,2),:),pi/180*gyr(integIdx(1,1):integIdx(1,2),:));
        % note that "accNoGrav" and "grav" both have units of m/s^2
        %       (conversion factor: 1g = 9.81 m/s^2).
        % "accNoGrav_gcf" contains gravity-compensated triaxial
        %       acceleration in the global coordinate frame.

%----------------------------------------------------------------------
% computing unstrapped 3D velocity in global coordinate frame (in m/s)
tempVel = 1/fs*cumtrapz(accNoGrav_gcf); % unstrapped 3D velocity

% strapping down each component of velocity (because if speed is zero,
%       each component of velocity must be zero). Units are m/s
strapVel = zeros(size(tempVel)); % initialising 3D strapped velocity
for ax=1:3      % for each axis of the accelerometer
    strapVel(:,ax) = tempVel(:,ax) - tempVel(end,ax)*(0:size(tempVel,1)-1)'./(size(tempVel,1)-1);
    strapVel(end,ax) = 0; % because last value may now be a very small positive number because of the division, e.g. 1e-19.
end

% computing strapped-down speed in horizontal plane (in m/s)
strapSpeed = sqrt(sum(strapVel(:,[1,2]).^2,2)); % strapped-down speed in horizontal plane in m/s