% Script to compute daily energy expenditure for meerkats in Joules using
% the ACTIWAKE (Section 1) and ACTIREST24 (Section 2) models given 24-hour
% triaxial acceleration data and body mass of the animal.
%
% Written:  28 Nov 2022
%           Pritish Chakravarty
%           MPI-AB, Konstanz



%% SECTION 0: Initialisations common to both ACTIWAKE and ACTIREST24

fs = 50; % Hz. Sampling frequency of the CDD accelerometer in Hertz
winDur = 2; % length of window in seconds over which VeDBA will be computed
wL = round(winDur*fs); % samples. Length of window in number of samples

% "bodymass" is the body mass of the animal, in grams.



%% SECTION 1: Compute DEE using the ACTIWAKE model

% specifying Power-VeDBA calibration relationship: Power = slope * VeDBA + intcpt.
        % where VeDBA is in m/s^2 and is computed in a window of size 2
        %       seconds from triaxial acceleration (fs = 50 Hz).
slope_actiwake = 0.64118; % Js/m
intcpt_actiwake = 6.44339; % J/s


% COMPUTING NIGHTTIME ENERGY EXPENDITURE (EE)------------------
    % computing RMR (J/s)
rmr = 300.4 * (bodymass/1000)^0.75 / (24*60*60) * 1000; % RMR in J/s computed according to Kleiber's law. "bodymass" is the body mass of the animal, in grams.
    % computing nighttime energy expenditure
nightEE = rmr * nightDur; % J. Energy expended during the night is at the rate of RMR J/s.
                                % "nightDur" is duration of the night, in
                                %   seconds, and has been computed from
                                %   sunrise and sunset data as described in
                                %   Section 2.2 of the manuscript. Meerkats
                                %   sleep during the night, and are active
                                %   during the day. So, a rate of energy
                                %   expenditure of RMR was assumed to apply
                                %   throughout the night.


% COMPUTING DAYTIME ENERGY EXPENDITURE-------------------------
            % Note that the daytime portion (sunrise to sunset) of
            %   acceleration data ("accWake") is used to calculate daytime
            %   energy expenditure in the ACTIWAKE model.
    % finding start and end indices for two-sec windows over which
    %       VeDBA will be computed
sIdx = 1:wL:size(accWake,1); % starting index of each window
eIdx = wL:wL:size(accWake,1); % ending index of each window
if numel(sIdx)>numel(eIdx)
    sIdx(end) = [];
        % this is a correction measure for the case where the
        %       last window is shorter than "wL"
end
daytimeEE = 0; % J. Cumulative EE (added across all two-second windows) for this day
for ii=1:length(sIdx)
    thiswin_acc = accWake(sIdx(ii):eIdx(ii),:); % acceleration corresponding to this window
    if isempty(find(isnan(thiswin_acc(:)),1))       % if there are no NaNs in this window
        thiswin_vedba = 9.81*mean(sqrt(sum((thiswin_acc - mean(thiswin_acc,1)).^2,2))); % VeDBA for this window in m/s^2
    else                                            % if there are NaNs in this window
        thiswin_vedba = 0; % i.e. if acceleration data has NaNs, make the EE calculation default to the intercept of the EE vs VeDBA equation
    end
    thiswin_EE = winDur * (slope_actiwake*thiswin_vedba + intcpt_actiwake); % estimating EE (J) for this window
    daytimeEE = daytimeEE + thiswin_EE; % J
end


% COMPUTING EE (kJ) FOR THE 24-HOUR PERIOD--------------------
dee_actiwake = (daytimeEE + nightEE) / 1000; % kJ



%% SECTION 2: Compute DEE using the ACTIREST24 model

% specifying Power-VeDBA relationship: Power = slope * VeDBA + intcpt.
        % where VeDBA is in m/s^2 and is computed in a window of size 2
        %       seconds from triaxial acceleration (fs = 50 Hz).
slope_actirest24 = 0.90565; % Js/m
intcpt_actirest24 = 3.10448; % J/s


% COMPUTING EE (kJ) FOR THE 24-HOUR PERIOD--------------------
            % Note that 24-hour acceleration data ("acc24") is used to
            %       calculate DEE in the ACTIREST24 model.
sIdx = 1:wL:size(acc24,1); % starting index of each window
eIdx = wL:wL:size(acc24,1); % ending index of each window
if numel(sIdx)>numel(eIdx)
    sIdx(end) = [];
        % this is a correction measure for the case where the
        %       last window isn't long enough
end
ee24 = 0; % J. Cumulative energy expenditure (added across all two-second windows) for this day
for ii=1:length(sIdx)
    thiswin_acc = acc24(sIdx(ii):eIdx(ii),:); % acceleration corresponding to this window
    if isempty(find(isnan(thiswin_acc(:)),1))       % if there are no NaNs in this window
        thiswin_vedba = 9.81*mean(sqrt(sum((thiswin_acc - mean(thiswin_acc,1)).^2,2))); % VeDBA for this window in m/s^2
    else                                            % if there are NaNs in this window
        thiswin_vedba = 0; % i.e. if acceleration data has NaNs, make the EE calculation default to the intercept of the EE vs VeDBA equation
    end
    thiswin_EE = winDur * (slope_actirest24*thiswin_vedba + intcpt_actirest24); % estimating EE (J) for this window
    ee24 = ee24 + thiswin_EE;
end
ee24 = ee24 + intcpt_actirest24*floor(60/winDur)*winDur; % this is added to fill in the missing minute from 23:59:00 to 23:59:59, which could not be specified in the call to 'getIMUinRange'
                  % During these 60 seceonds, the meerkat is assumed to be
                  %     'perfectly resting' (i.e. VeDBA = 0, and therefore
                  %     a rate of EE equalling the intercept of the EE vs
                  %     VeDBA line) during these 60 seconds, which is
                  %     reasonable because they are very probably asleep at
                  %     midnight.

% converting DEE to kJ
dee_actirest24 = ee24 / 1000; % kJ. Energy expended during the entire 24-hour period