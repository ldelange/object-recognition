%%  Ideal multi-View object model based on sequence alignment
%   Main - Obtains object recognition performance from different feature
%   descriptors and noise settings
%   Author:  	    Leon de Lange 
%	  	    TuDelft, BMD Master Thesis
%                   Multi-view object retrieval
%   Last revision:  5-November-2015


%% start fresh
clear all
close all
clc


%% load rgbd-datset struct (rgbd2struct.m)
load('var/rgbd-dataset.mat');                


%% dataset
data.path = 'rgbd-dataset/';        % root path
data.objects = 1:50;                % used random objects from dataset (51 objects)
data.views = 1:40;                  % views per object (linear spaced 360 degrees)
data.dataset = {};                  % dataset containing paths to random data.objects with data.views


%% noise model
noise.descr = 'gaussian';           % noise model 'none', 'gaussian', 'affine'
noise.std = 0.01;                   % gaussian noise standard deviation
noise.affine = 10;                  % affine noise image rotation (degrees)


%% vocabulary model
vocab.words = 1.0;                  % part of all descriptors used as word in vocabulary
vocab.iter = 500;                   % maximum iterations k-d tree


%% model variables (dont change)
model.descriptor = '';          % descriptor name
model.cellsize = 100;           % window size for LBP & HOG descriptors
model.noise = '';               % used noise model
model.ctime = {};               % feature extracting time
model.mtime = {};               % feature matching time
model.oaccuracy = 0;            % percentage correct recognized objects
model.vaccuracy = 0;            % percentage correct recognized views


%% setup test dataset containing objects - instances - views
% select random training objects
robjects = randperm(length(rgbd_dataset),length(data.objects));

% for each random object
for i = 1:length(robjects)
    
    % select random instance
    inst_ = randperm(length(rgbd_dataset{robjects(i)}.instances),1);
    
    % select random height 30, 45 or 60 degrees (only one is used initially)
    band_ = randperm(3,1);
    
    % select linear spaced data.views for this instance using band_
    views_ = round(linspace(1,length(rgbd_dataset{robjects(i)}.instances{inst_,band_}),data.views(end)));
        
    % write path to training objects/views
    data.dataset{end+1} = rgbd_dataset{robjects(i)}.instances{inst_,band_}(views_)';
        
end


%% obtain (query)object models containing objectmaps of all objects
[ HSVmdl,  HSVqmdl,  HSV] = map_HSV(data, model, noise);
[ HOGmdl,  HOGqmdl,  HOG] = map_HOG(data, model, noise);
[ LBPmdl,  LBPqmdl,  LBP] = map_LBP(data, model, noise);
[ NNmdl,  NNqmdl,  NN] = map_NN(data, model, noise);


%% Multi-view object recognition learning curve
% obtain vocubalary from object models and return simplified models
[vHSVmdl, vHSVqmdl] = approximate(vocab, HSVmdl, HSVqmdl);
[vHOGmdl, vHOGqmdl] = approximate(vocab, HOGmdl, HOGqmdl);
[vLBPmdl, vLBPqmdl] = approximate(vocab, LBPmdl, LBPqmdl);
[vNNmdl, vNNqmdl] = approximate(vocab, NNmdl, NNqmdl);

% obtain learning curves
HOGcur = mvlearn(HOG, data, HOGmdl, HOGqmdl, vHOGmdl, vHOGqmdl);
HSVcur = mvlearn(HSV, data, HSVmdl, HSVqmdl, vHSVmdl, vHSVqmdl);
LBPcur = mvlearn(LBP, data, LBPmdl, LBPqmdl, vLBPmdl, vLBPqmdl);
NNcur = mvlearn(NN, data, NNmdl, NNqmdl, vNNmdl, vNNqmdl);

% concatenate all learning curves
cur_mv = [HOGcur, HSVcur, LBPcur, NNcur];

% plot learning curve
x = data.views;
y = reshape([cur_mv.oaccuracy],[data.views(end) 4]);

figure(1)
plot(x, y, 'LineWidth',2);
axis([1 data.views(end) 0 100]);
title(strcat('mv-Object recognition (', int2str(data.objects(end)), {' '}, 'objects,', {' '}, int2str(data.views(end)), {' '}, 'views) vs Sequence length'));
xlabel('Query sequence length (views/object)');
ylabel('Object recognition (%)')
legend('HOG', 'HSV', 'LBP', 'NN');


%% Single-view object recognition learning curve
% obtain learning curves
HOGcur = svlearn(HOG, data, HOGmdl, HOGqmdl);
HSVcur = svlearn(HSV, data, HSVmdl, HSVqmdl);
LBPcur = svlearn(LBP, data, LBPmdl, LBPqmdl);
NNcur = svlearn(NN, data, NNmdl, NNqmdl);

% concatenate all learning curves
cur_sv = [HOGcur, HSVcur, LBPcur, NNcur];

% plot learning curve
x = data.views;
y = reshape([cur_sv.oaccuracy],[data.views(end) 4]);

figure(2)
plot(x, y, 'LineWidth',2);
axis([1 data.views(end) 0 100]);
title(strcat('sv-Object recognition (', int2str(data.objects(end)), {' '}, 'objects,', {' '}, int2str(data.views(end)), {' '}, 'views) vs Sequence length'));
xlabel('Query sequence length (views/object)');
ylabel('Object recognition (%)')
legend('HOG', 'HSV', 'LBP', 'NN');


%% Single view match time comparrison
x = data.views ./ data.views(end) * 100;
y = reshape([cur_sv.mtime],[data.views(end) 4])./data.objects(end);

figure(3)
plot(x, y, 'LineWidth', 3);
title('Single-view match time');
axis([0 100 0 0.1]);
xlabel('Percentage of total query map (%)');
ylabel('Descriptor matching time (sec)');
legend('HOG', 'HSV', 'LBP', 'NN');


%% Multi view match time comparrison
x = data.views ./ data.views(end) * 100;
y = reshape([cur_mv.mtime],[data.views(end) 4])./data.objects(end) + reshape([cur_sv.mtime],[data.views(end) 4])./data.objects(end);

figure(4)
plot(x, y, 'LineWidth', 3);
title('Multi-view match time');
axis([0 100 0 0.1]);
xlabel('Percentage of total query map (%)');
ylabel('Descriptor matching time (sec)');
legend('HOG', 'HSV', 'LBP', 'NN');
