% ==== PCANet Demo =======
% T.-H. Chan, K. Jia, S. Gao, J. Lu, Z. Zeng, and Y. Ma,
% "PCANet: A simple deep learning baseline for image classification?" submitted to IEEE TIP.
% ArXiv eprint: http://arxiv.org/abs/1404.3606

% Tsung-Han Chan [thchan@ieee.org]
% Please email me if you find bugs, or have suggestions or questions!
% ========================

clear all; close all; clc;
addpath('./Utils');
addpath('./Liblinear');
addpath('./piotrstoolbox/classify');

CATEGORIES = {
  'agricultural';
  'airplane';
  'baseballdiamond';
  'beach';
  'buildings';
  'chaparral';
  'denseresidential';
  'forest';
  'freeway';
  'golfcourse';
  'harbor';
  'intersection';
  'mediumresidential';
  'mobilehomepark';
  'overpass';
  'parkinglot';
  'river';
  'runway';
  'sparseresidential';
  'storagetanks';
  'tenniscourt'
};


load('../datasets/UCMerced_LandUse');

TrnSize = size(X, 2);
ImgSize = 256; %28;
ImgFormat = 'color'; %'color' or 'gray'

TrnData = X;
TrnLabels = y;
clear X;
clear y;

TestData = X_t;
TestLabels = y_t;
clear X_t;
clear y_t;

StandardMappingMatrices = loadStandardMappingMatrices();

% ==== Subsampling the Training and Testing sets ============
% (comment out the following four lines for a complete test)
% every_nth_example = 80;
% TrnData = TrnData(1:every_nth_example:end,:);
% TrnLabels = TrnLabels(1:every_nth_example:end);
% TestData = TestData(1:every_nth_example:end,:);
% TestLabels = TestLabels(1:every_nth_example:end);
% ===========================================================

nTestImg = length(TestLabels);
numClasses = 21;

%% PCANet parameters (they should be funed based on validation set; i.e., ValData & ValLabel)
% We use the parameters in our IEEE TPAMI submission
PCANet.NumStages = 2;
PCANet.PatchSize = [7 7];
PCANet.PatchingStep = [1 1];
PCANet.PoolingPatchSize = [2 2];
PCANet.NumFilters = [32 20];
PCANet.HistBlockSize = [64 64];
PCANet.BlkOverLapRatio = 0.0;
PCANet.Pyramid = [];
PCANet.MappingMatrices = {
  StandardMappingMatrices{32}
};

fprintf('\n ====== PCANet Parameters ======= \n')
PCANet

%% PCANet Training with 10000 samples
fprintf('\n ====== PCANet Training ======= \n')
TrnData_ImgCell = mat2imgcell(TrnData,ImgSize,ImgSize,ImgFormat); % convert columns in TrnData to cells
clear TrnData;


fprintf('Number of training samples: %d \n', length(TrnData_ImgCell))
tic;
[ftrain V BlkIdx] = PCANet_train(TrnData_ImgCell,PCANet,1,ImgFormat); % BlkIdx serves the purpose of learning block-wise DR projection matrix; e.g., WPCA
PCANet_TrnTime = toc;
clear TrnData_ImgCell;

fprintf('\n ====== Training Linear SVM Classifier ======= \n')
tic;
models = train(TrnLabels, ftrain', '-s 1 -q'); % we use linear SVM classifier (C = 1), calling libsvm library
LinearSVM_TrnTime = toc;
[predict_labels] = predict(TrnLabels, ftrain', models, '-q');
clear ftrain;

trn_accuracy = sum(predict_labels == TrnLabels) / length(TrnLabels);
fprintf('Accuracy for trainging set is %g.\n', trn_accuracy);


%% PCANet Feature Extraction and Testing

TestData_ImgCell = mat2imgcell(TestData,ImgSize,ImgSize,ImgFormat); % convert columns in TestData to cells
clear TestData;

fprintf('\n ====== PCANet Testing ======= \n')

nCorrRecog = 0;
RecHistory = zeros(nTestImg,1);

predLabels = zeros(1, nTestImg);
confusionMatrix = zeros(numClasses, numClasses);
% cmTargets = zeros(numClasses, nTesImg);
%
% for i = 1:nTesImg^M
%     cmTargets(TestLabels(i), i) = 1
% end^M

% cmOutputs= zeros(numClasses, nTesImg);



tic;
for idx = 1:1:nTestImg

    ftest = PCANet_FeaExt(TestData_ImgCell(idx),V,PCANet, ImgFormat); % extract a test feature using trained PCANet model

    [xLabel_est, accuracy, decision_values] = predict(TestLabels(idx),...
        sparse(ftest'), models, '-q'); % label predictoin by libsvm

    predLabels(idx) = xLabel_est;

    if xLabel_est == TestLabels(idx)
        RecHistory(idx) = 1;
        nCorrRecog = nCorrRecog + 1;
    end

    confusionMatrix(TestLabels(idx), xLabel_est) = confusionMatrix(TestLabels(idx), xLabel_est) + 1;
    % cmOutputs(TestLabels(idx), idx) = 1;

    if 0==mod(idx,nTestImg/100);
        fprintf('Accuracy up to %d tests is %.2f%%; taking %.2f secs per testing sample on average. \n',...
            [idx 100*nCorrRecog/idx toc/idx]);
    end

    TestData_ImgCell{idx} = [];

end
Averaged_TimeperTest = toc/nTestImg;
Accuracy = nCorrRecog/nTestImg;
ErRate = 1 - Accuracy;

%% Results display
fprintf('\n ===== Results of PCANet, followed by a linear SVM classifier =====');
fprintf('\n     PCANet training time: %.2f secs.', PCANet_TrnTime);
fprintf('\n     Linear SVM training time: %.2f secs.', LinearSVM_TrnTime);
fprintf('\n     Testing error rate: %.2f%%', 100*ErRate);
fprintf('\n     Average testing time %.2f secs per test sample. \n\n',Averaged_TimeperTest);
fprintf('\n     Confusion Matrix (each row represents single actuall class, and each element in row respresents number of predictions for that class) \n\n');
confusionMatrix;
%plotconfusion(cmTargets, cmOutputs, 'Test results')
CM = confMatrix(TestLabels, predLabels, numClasses);
confMatrixShow(CM, CATEGORIES, {'FontSize', 16});
