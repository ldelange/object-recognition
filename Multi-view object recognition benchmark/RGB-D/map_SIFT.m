function [objmodels, qobjmodels, model] = map_SIFT(model, noise, data)
%%  Ideal single-View object model
%   dSIFT-MODEL (LOCAL DESCRIPTOR)
%   Author:         ldelange, 
%                   BMD Master Thesis multi-view object retrieval

% set model descriptor name
model.descriptor = 'SIFT';
model.noise = noise.descr;

% local object model variables
objmodels = {};
qobjmodels = {};


%% create (query)object map
% for each object
for i = data.objects
        
    clc;
    display(strcat('Create SIFT object map:', {' '}, int2str(i), '/', int2str(length(data.objects)))); 
        
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
        
            % extract SIFT descriptor
            [frames, descr] = vl_sift(im);
        
        % stop stopwatch
        model.ctime{end+1} = toc;
        
        % extract HSV histogram from query view
        if(strcmp(model.noise,'none'))
            qdescr = descr;
        else
            [frames, qdescr] = vl_sift(nim);
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