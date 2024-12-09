clear all;
close all;

% Load Traffic Sign Model
load('rcnnAll.mat');

cam = webcam("HD Webcam C615")
next = 0;

fclose(instrfindall)
%% Define computer-specific variables
% Modify these values to be those of your first computer.
ipA = '198.21.192.130';   portA = 9090; 
% Modify these values to be those of your second computer.
ipB = '198.21.245.249';  portB = 9091; 
%% Create UDP Object
udpA = udp(ipB,portB,'LocalPort',portA);
%% Connect to UDP Object
fopen(udpA)

next = 1
% Start Traffic Sign Recognition
while true
    schoolSign = 0;
    stopSign = 0;
    
    img = snapshot(cam);
    img = imresize(img, .5);
%     Run Detection
    [bboxes,score,label] = detect(rcnn,img,'MiniBatchSize',128);

    [score, idx] = max(score);
%     saveScore(next) = score;
%     saveIdx(next) = idx;
    bbox_focus = bboxes(idx, :);
%     saveFocus{next} = bbox_focus

    if label(idx) == 'schoolSign' & score > 0.97% & bbox_focus(3) > 100 & bbox_focus(4) > 150
        schoolSign = 1;
        data = [schoolSign, stopSign]
        fwrite(udpA, data);
           pause(5)
        for i = 0 : 1000
        schoolSign = 0;
        data = [schoolSign, stopSign]
        fwrite(udpA, data);
%         pause(30)
        end

    elseif label(idx) == 'stopSign' & score > 0.95% & bbox_focus(3) > 100 & bbox_focus(4) > 150
        stopSign = 1;
        data = [schoolSign, stopSign]
        fwrite(udpA, data);
        pause(5);
        for i = 0 : 1000
            stopSign = 0;
            data = [schoolSign, stopSign]
            fwrite(udpA, data);
%         pause(30)
        end

    end
    
    
    data = [schoolSign, stopSign];
%     fwrite(udpA, data);

    data
 
    next = next + 1
end