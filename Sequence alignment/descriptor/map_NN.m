function [objmodels, qobjmodels, model] = map_NN(data, model, noise)
%%  Ideal multi-View object mode
%   Neural Network (GLOBAL DESCRIPTOR)
%   Author:         ldelange, 
%                   BMD Master Thesis multi-view object retrieval

% set model descriptor name
model.descriptor = 'NN';
model.noise = noise.descr;

% local object model variables
objmodels = {};
qobjmodels = {};


%% load neural network
if(~exist('net','var'))
    vl_setupnn
    clc
    net = load('/var/imagenet-vgg-verydeep-16.mat');
end


%% create (query)object map
% for each object
for i = data.objects
        
    clc;
    display(strcat('Create NN  object map:', {' '}, int2str(i), '/', int2str(length(data.objects)))); 
           
    % create empty object map
    objmap = {};
    qobjmap = {};

    % for each view
    for j = data.views
    
        % read view and query (noise) view
        [im_, nim_] = read_view(data, noise, i, j);

        % singles
        im = im2single(im_);
        nim = im2single(nim_);

        % start descriptor computation stopwatch
        tic
        
            % extract descriptor
            descr = feature_nn(net, im);
   
        % stop stopwatch
        model.ctime{end+1} = toc;
        
        % extract HSV histogram from query view
        if(strcmp(model.noise,'none'))
            qdescr = descr;
        else
            qdescr = feature_nn(net, nim);
        end
                    
        % add descriptor to object map
        objmap{end+1} = descr;
        qobjmap{end+1} = qdescr;

    end
    
    % add object map to model database
    objmodels{end+1} = objmap;
    qobjmodels{end+1} = qobjmap;
    
end

% average descriptor extraction time
model.ctime = mean(cat(1,model.ctime{:}));


function [feature_vec] = feature_nn(net, im)
%% convolutes the input image via a pretrained deep neural network
% pre   3-layer image and neureal network
% post  1000 (classes) x 1 feature vector

% resize image to match convnn input layer
im = imresize(im, net.normalization.imageSize(1:2));

% convolute the nn
res = vl_simplenn(net,im);

% return the output vector 
feature_vec = squeeze(res(end-5).x)';