%%  Ideal single-View object model
%   Main - Obtains object recognition performance from different feature
%   descriptors and noise settings
%   Author:  	    Leon de Lange 
%	  	    TuDelft, BMD Master Thesis
%                   Multi-view object retrieval
%   Last revision:  22-october-2015


%% start fresh
clear all
close all
clc


%% dataset
data.path = '/soil-47/';            % root path
data.masks = '/soil-47-masks/';     % path dataset masks
data.objects = 1:17;                % used random objects from dataset (17 objects)
data.views = 1:20;                  % views per object (20 linear spaced 180 degrees)
data.discretize = [];               % discretized objectmap (views)
data.dataset = {};                  % dataset containing paths to random data.objects with data.views


%% noise model
noise.descr = 'illumination';       % noise model: 'none', 'illumination', 'gaussian', 'affine'
noise.std = 0.01;                   % gaussian noise standard deviation
noise.affine = 10;                  % affine noise image rotation (degrees)


%% model variables (dont change)
model.descriptor = '';          % descriptor name
model.cellsize = 100;           % window size for LBP & HOG descriptors
model.noise = '';               % used noise model
model.ctime = {};               % feature extracting time
model.mtime = {};               % feature matching time
model.oaccuracy = 0;            % percentage correct recognized objects
model.vaccuracy = 0;            % percentage correct recognized views


%% obtain (query)object models containing objectmaps of all objects
[ HOGmdl,  HOGqmdl,  HOG] = map_HOG(model, noise, data);
[ HSVmdl,  HSVqmdl,  HSV] = map_HSV(model, noise, data);
[ LBPmdl,  LBPqmdl,  LBP] = map_LBP(model, noise, data);
[ NNmdl,  NNqmdl,  NN] = map_NN(model, noise, data);
[ SIFTmdl,  SIFTqmdl,  SIFT] = map_SIFT(model, noise, data);


%% single-view object recognition learning curve
HOGcur = learning_curve(data, HOG, HOGmdl, HOGqmdl);
HSVcur = learning_curve(data, HSV, HSVmdl, HSVqmdl);
LBPcur = learning_curve(data, LBP, LBPmdl, LBPqmdl);
NNcur = learning_curve(data, NN, NNmdl, NNqmdl);
SIFTcur = learning_curve(data, SIFT, SIFTmdl, SIFTqmdl);

% concatenate all learning curves
cur_X = [HOGcur, HSVcur, LBPcur, NNcur, SIFTcur];

% learning curve data
x = data.views;
y = reshape([cur_X.oaccuracy],[data.views(end) 5]);

% plot learning curve
figure(1)
plot(x, y, 'LineWidth',2);
axis([data.views(1) data.views(end) 0 100]);
title(strcat('sv-Object recognition (', int2str(data.objects(end)), {' '}, 'objects,', {' '}, int2str(data.views(end)), {' '}, 'views) vs Sequence length'));
xlabel('Query sequence length (views/object)');
ylabel('Object recognition (%)')
legend('HOG', 'HSV', 'LBP', 'NN', 'SIFT');


%% single-view object recognition performance
% create alternative discretized dataset
ddata = data;

% discretize all (query)object maps from object models in views/x parts
for x = 1:data.views(end)  
    
    % set discretization views
    ddata.discretize = round(linspace(data.views(1),data.views(end),data.views(end)+1-x));
        
    % adjust views in dataset
    ddata.views = 1:length(ddata.discretize); 
    
    % performance HSV descriptor
    [mdl_, qmdl_] = discretize(ddata, HSVmdl, HSVqmdl);
    HSVrun(x) = match(HSV, ddata, mdl_, qmdl_);
        
    % performance HOG descriptor
    [mdl_, qmdl_] = discretize(ddata, HOGmdl, HOGqmdl);
    HOGrun(x) = match(HOG, ddata, mdl_, qmdl_);
            
    % performance LBP descriptor
    [mdl_, qmdl_] = discretize(ddata, LBPmdl, LBPqmdl);
    LBPrun(x) = match(LBP, ddata, mdl_, qmdl_);
    
    % performance NN descriptor
    [mdl_, qmdl_] = discretize(ddata, NNmdl, NNqmdl);
    NNrun(x) = match(NN, ddata, mdl_, qmdl_);
    
        % performance LBP descriptor'NN', 'SIFT'
    [mdl_, qmdl_] = discretize(ddata, SIFTmdl, SIFTqmdl);
    SIFTrun(x) = match(SIFT, ddata, mdl_, qmdl_);
            
end

% remove discretized dataset
clear('ddata');

% concatenate all models (use result for plots.m)
run_X = [HOGrun, HSVrun, LBPrun, NNrun, SIFTrun];

% degrees between views
x = 180./data.views;

% plot ratio view / object accuracy
y = reshape([run_X.vaccuracy] ./ [run_X.oaccuracy],[data.views(end) 5])';

figure(2)
plot(flip(x), y, 'LineWidth',2);
title(strcat('View recognition', {' ('}, run_X(1).noise, ')'));
axis([x(end) 180 0 1]);
xlabel('Discretized views (deg)');
ylabel('Ratio correct views/objects');
legend('HOG', 'HSV', 'LBP', 'NN', 'SIFT', 'location', 'southeast');


%% Single/Multi view match time comparrison
x = data.views ./ data.views(end) * 100;
y = reshape([cur_X.mtime],[data.views(end) 5])./data.objects(end);

figure(3)
plot(x, y, 'LineWidth', 3);
title('Single-view match time');
axis([0 100 0 1]);
xlabel('Percentage of total query map (%)');
ylabel('Descriptor matching time (sec)');
legend('HOG', 'HSV', 'LBP', 'NN', 'SIFT');
