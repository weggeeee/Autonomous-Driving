clear all;
close all;

load('C:\models\rcnnAll.mat');

filePattern = fullfile('C:\Users\Mir\OneDrive\OneDrive - Clemson University\Spring2022\ADT\FinalProject\Road Sign Images\PositiveImages_stopSign\*.jpg'); % Change to whatever pattern you need.
theFiles = dir(filePattern);

for k = 1 : length(theFiles)
    baseFileName = theFiles(k).name;
    fullFileName = fullfile(theFiles(k).folder, baseFileName);
    fprintf(1, 'Now reading %s\n', fullFileName);
 
    testImage = imread(fullFileName);
    
    % Detect stop signs
    [bboxes,score,label] = detect(rcnn,testImage,'MiniBatchSize',128);

    [score, idx] = max(score);
    if label(idx) == 'stopSign' & score > 0.9
        result(k) = 1;
    else
        result(k) = 0;
    end
% Look at boundingbox
    bbox = bboxes(idx, :);
    annotation = sprintf('%s: (Confidence = %f)', label(idx), score);
    outputImage = insertObjectAnnotation(testImage, 'rectangle', bbox, annotation);
    figure()
    imshow(outputImage)
end

%Calc Accuracy
acc = sum(result(:) == 1)/length(result)





