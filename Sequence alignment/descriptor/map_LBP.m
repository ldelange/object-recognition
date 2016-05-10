function [objmodels, qobjmodels, model] = map_LBP(data, model, noise)
%%  Ideal multi-View object model
%   Local Binary Pattern (GLOBAL DESCRIPTOR)
%   Author:         ldelange, 
%                   BMD Master Thesis multi-view object retrieval

% set model descriptor name
model.descriptor = 'LBP';
model.noise = noise.descr;

% local object model variables
objmodels = {};
qobjmodels = {};


%% create (query)object map
% for each object
for i = data.objects
        
    clc;
    display(strcat('Create LBP object map:', {' '}, int2str(i), '/', int2str(length(data.objects)))); 

    % create empty object map
    objmap = {};
    qobjmap = {};
    
    % for each view
    for j = data.views
    
        % read view and query (noise) view
        [im_, nim_] = read_view(data, noise, i, j);

        % convert image to single layer gray image
        im = im2single(rgb2gray(im_));
        nim = im2single(rgb2gray(nim_));

        % start descriptor computation stopwatch
        tic
        
            % extract lbp histogram feature
            descr = feature_lbp(im, model.cellsize);
        
        % stop stopwatch
        model.ctime{end+1} = toc;
        
        % extract lbp histogram from query view
        if(strcmp(model.noise,'none'))
            qdescr = descr;
        else
            qdescr = feature_lbp(nim, model.cellsize);
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


function [feature_vec] = feature_lbp(im, cellsize)
%% creates an LBP histogram of an input image
% pre   gray image
% post  LBP feature histogram

% extract features
lbp = vl_lbp(im, cellsize);

% remove third dimension
hist = reshape(lbp,[size(lbp,1)*size(lbp,2) size(lbp,3)]);

% concatenate all descriptors
feature_vec = reshape(hist', [size(hist,1) * size(hist,2), 1])';