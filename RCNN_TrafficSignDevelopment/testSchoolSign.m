clear all;
close all;

load('C:\Users\Mir\models\rcnnSchoolSign.mat');

filePattern = fullfile('C:\Users\Road Sign Images\PositiveImages_stopSign\*.jpg'); % Change to whatever pattern you need.
theFiles = dir(filePattern);

for k = 1 : length(theFiles)
    baseFileName = theFiles(k).name;
    fullFileName = fullfile(theFiles(k).folder, baseFileName);
    fprintf(1, 'Now reading %s\n', fullFileName);
    % Now do whatever you want with this file name,
    % such as reading it in as an image array with imread()
    testImage = imread(fullFileName);
    % Detect stop signs
    [bboxes,score,label] = detect(rcnn,testImage,'MiniBatchSize',128);

    [score, idx] = max(score);
    if label(idx) == 'schoolSign' & score > 0.9
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


acc = sum(result(:) == 1)/length(result)




