clear all;
close all;
cifar10Data = tempdir;
path = 'C:\Users\Mir\OneDrive\OneDrive - Clemson University\Spring2022\ADT\FinalProject\stopSignSchoolSignAll.mat';
load(path);

    options = trainingOptions('sgdm', ...
    'MiniBatchSize', 32, ...
    'InitialLearnRate', 1e-6, ...
    'MaxEpochs', 10, ...
    'Verbose', true,...
    'Plots','training-progress',...
    'ExecutionEnvironment', 'parallel');

    % Train an R-CNN object detector. This will take several minutes. 
    load('C:\Users\Mir\OneDrive\OneDrive - Clemson University\Spring2022\ADT\FinalProject\models\cifar10.mat')

    rcnn = trainRCNNObjectDetector(stopSignSchoolSignAll, cifar10Net, options, ...
    'NegativeOverlapRange', [0 0.3], 'PositiveOverlapRange',[0.5 1])
    rcnn;





