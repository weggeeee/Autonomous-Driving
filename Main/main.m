clear all;
close all;

% Initialization
a = arduino();
v = servo(a,'D12','MinPulseDuration',1e-3,'MaxPulseDuration',2e-3);
s = servo(a,'D13','MinPulseDuration',1e-3,'MaxPulseDuration',2e-3);

load calibrationSession.mat
instrinsicParams = calibrationSession.CameraParameters.IntrinsicMatrix; 
extrinsicParams = [calibrationSession.CameraParameters.RotationMatrices(1:2,:,20); calibrationSession.CameraParameters.TranslationVectors(20,:)];

cam = webcam('HD Webcam C615');
cam.Resolution = '1280x720';

% SPEED CONTROL 
velo        = 0.525;
stopVelo    = 0.49;
% speed control before school sign
goTime = 1.5e-1;
stopTime = 2.5e-1;
% speed control after shool sign
schoolGoTime = 1.5e-1;

schoolStopTime = 5e-1;
% pause at stop sign

% LineDetection Params
angThresh    = 1; 

% controller gains (steeringangle = k1*departureangle + k2*efa)
% steering control before shool sign
k1 = -.6;
% k2 = 1.5;
k2 = 0.4;
offsetCam = 7; %Should be 0

schoolSignLoop = 100;
% efa = 0;

 fclose(instrfindall)
%% Define computer-specific variables
% Modify these values to be those of your first computer:
ipA = '198.21.195.234';   portA = 9090;   
% Modify these values to be those of your second computer:
ipB = '198.21.247.26';  portB = 9091;  
%% Create UDP Object
udpB = udp(ipA,portA,'LocalPort',portB);
%% Connect to UDP Object
fopen(udpB)


data(1) = 0;
data(2) = 0;

counter = 1;
loopThresh = 32; 

while (1)

%     if mod(counter,5) == 1
%         writePosition(v,.5125);
%     else
%         writePosition(v, .49);
%     end
    if udpB.BytesAvailable > 0
            data = fread(udpB, udpB.BytesAvailable);
            flushinput(udpB);
    end


    schoolSign = data(1)
    stopSign = data(2)
    
    if(stopSign == 1 & schoolSignLoop > loopThresh)
        writePosition(v,stopVelo);
        pause(2);
    elseif(schoolSign == 1)
        writePosition(v,velo);
        pause(schoolGoTime);
        schoolGoTime
        writePosition(v,stopVelo);
        pause(schoolStopTime);
        schoolSignLoop = 0;
    elseif schoolSignLoop <= loopThresh
        writePosition(v,velo);
        pause(schoolGoTime);
        schoolGoTime
        writePosition(v,stopVelo);
        pause(schoolStopTime);
    elseif schoolSignLoop > loopThresh
        writePosition(v,velo);
        pause(goTime);
        goTime
        writePosition(v,stopVelo);
        pause(stopTime);
    end


    schoolSignLoop = schoolSignLoop + 1
%     Lane Detection
    pic = snapshot(cam);
    oriPic = pic;
    shape = size(pic);
    pic = rgb2hsv(pic);

    rgb1 = pic(:,:,1) > 0.50;
    rgb2 = pic(:,:,2) > 0.20;
    rgb3 = pic(:,:,3) > 0.4 & pic(:,:,3) < 0.98;
    mask = rgb1 & rgb2 & rgb3;
    BW = bwareafilt(mask,[30 1e5]);
    filtered_RGB = oriPic .* uint8(BW);
    pic = filtered_RGB;

    gray_pic = rgb2gray(pic);
    edge_pic = edge(gray_pic, 'canny', [0.2, 0.22]);

    x_val = [shape(2)*0.2, shape(2)*0.8, shape(2), 0]; 
    y_val = [shape(1)*0.2, shape(1)*0.2, shape(1), shape(1)];
    bw = roipoly(pic, x_val, y_val);
    BW = (edge_pic(:,:,1)&bw);
    
    [H,T,R] = hough(BW,'RhoResolution',0.75,'Theta',-90:1:89.9);
    P = houghpeaks(H,100,'threshold',0);
    lines = houghlines(BW,T,R,P,'FillGap',20,'MinLength',100);
    
    leftlines   = []; 
    rightlines  = []; 

    temp = 0;
    for k = 1:length(lines)
        temp = temp + lines(k).point2(1);
    end
    
    temp = temp/length(lines);
    for k = 1:length(lines)
        x1 = lines(k).point1(1);
        y1 = lines(k).point1(2);
        x2 = lines(k).point2(1);
        y2 = lines(k).point2(2);
        
        if (x2>=shape(2)/2) && ((y2-y1)/(x2-x1)>angThresh || (x2-temp>0 && y2>500) )
            rightlines = [rightlines;x1,y1;x2,y2];
        elseif (x2<=shape(2)/2) && ((y2-y1)/(x2-x1)<(-angThresh) || (x2-temp<0 && y2>500) )
            leftlines = [leftlines;x1,y1;x2,y2];
        end
    end
    
    draw_y = [shape(1)*0.6, shape(1)]; 
    
%     Check if left line was detected and polyfit
    if numel(leftlines)>0
        PL = polyfit(leftlines(:,2), leftlines(:,1), 1);
        draw_lx = polyval(PL,draw_y);   
    end
    
%     Check if right line was detected and polyfit
    if numel(rightlines)>0
        PR = polyfit(rightlines(:,2), rightlines(:,1), 1);
        draw_rx = polyval(PR,draw_y);   
    end
    
%     If both lines were fitted perform extraction and controller
    if numel(rightlines)>0 && numel(leftlines)>0 
        u = [draw_rx draw_lx];
        vv = repmat(draw_y,1,2);
        
        for i=1:4
            PP = [u(i), vv(i), 1];
            t = PP*pinv(instrinsicParams)*pinv(extrinsicParams);
            ss = 1/t(3);
            point(i,:) = t*ss;
        end

        Xc = point(:,1);
        Zc = point(:,2);

        Xc = Xc - 13;
        Zc = -(Zc - 43);
        
        x_cf = (Xc(1) + Xc(3))/2;
        x_cn = (Xc(2) + Xc(4))/2;
        z_cf = (Zc(1) + Zc(3))/2;
        z_cn = (Zc(2) + Zc(4))/2;

        departureangle = -atand((x_cf-x_cn)/(z_cf-z_cn));
        efa = x_cn - z_cn*((x_cf-x_cn)/(z_cf-z_cn)) + offsetCam;

        steeringangle = k1*departureangle + k2*efa;
        
        if abs(steeringangle)<90
            writePosition(s,steeringangle/180 + 0.5);
        else
            writePosition(s,sign(steeringangle)/2 + 0.5);
        end
        
% If just one line was detected
    elseif numel(rightlines)>0 || numel(leftlines)>0
        if numel(rightlines)>0
            u = draw_rx;
        else
            u = draw_lx;
        end
        vv = draw_y;
        for i=1:2
            PP = [u(i), vv(i), 1];
            t = PP*pinv(instrinsicParams)*pinv(extrinsicParams);
            ss = 1/t(3);
            point(i,:) = t*ss;
        end

        Xc = point(:,1);
        Zc = point(:,2);

        Xc = Xc - 13;
        Zc = -(Zc - 43);
        
        x_cf = Xc(1);
        x_cn = Xc(2);
        z_cf = Zc(1);
        z_cn = Zc(2);

        departureAngle = -atand((x_cf-x_cn)/(z_cf-z_cn))

        steeringAngle = k1*departureAngle + k2*efa;
        
        if abs(steeringAngle)<90
            writePosition(s,steeringAngle/180 + 0.5);
        else
            writePosition(s,sign(steeringAngle)/2 + 0.5);
        end
    end
end