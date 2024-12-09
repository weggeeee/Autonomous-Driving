clear all;
close all;

% Load Traffic Sign Model
load('C:\Users\models\rcnnAll.mat');

cam = webcam("HD Webcam C615")
next = 0;
% Start Traffic Sign Recognition
while true
    schoolSign = 0;
    stopSign = 0;
    
    img = snapshot(cam);
%     Run Detection
    [bboxes,score,label] = detect(rcnn,img,'MiniBatchSize',128);

% Set confidence threshold
    [score, idx] = max(score);
    if label(idx) == 'schoolSign' & score > 0.95
        schoolSign = 1;
    elseif label(idx) == 'stopSign' & score > 0.95
        stopSign = 1;
    end
% Write progress and result on console    
    stopSign
    schoolSign
    
    next = next + 1
end
