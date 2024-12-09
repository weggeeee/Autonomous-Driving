clear all;
close all;

% Load Traffic Sign Model
load('C:\Users\Nico Weckardt\Desktop\Uni\OneDrive - Clemson University\Spring2022\ADT\FinalProject\models\rcnnAll.mat');

cam = webcam("HD Webcam C615")
next = 0;
% Start Traffic Sign Recognition
while true
    schoolSign = 0;
    stopSign = 0;
    
    img = snapshot(cam);
%     Run Detection
    [bboxes,score,label] = detect(rcnn,img,'MiniBatchSize',128);

    [score, idx] = max(score);
    if label(idx) == 'schoolSign' & score > 0.95
        schoolSign = 1;
    elseif label(idx) == 'stopSign' & score > 0.95
        stopSign = 1;
    end
    
    stopSign
    schoolSign
    
    next = next + 1
end