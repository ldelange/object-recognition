function [objmodels, qobjmodels, model] = map_HSV(model, noise, data)
%%  Ideal single-View object model
%   HSV_HISTOGRAM-MODEL (GLOBAL DESCRIPTOR)
%   Author:         ldelange, 
%                   BMD Master Thesis multi-view object retrieval

% set model descriptor name
model.descriptor = 'HSV';
model.noise = noise.descr;

% local object model variables
objmodels = {};
qobjmodels = {};


%% create (query)object map
% for each object
for i = data.objects
        
    clc;
    display(strcat('Create HSV object map:', {' '}, int2str(i), '/', int2str(length(data.objects)))); 
        
    % create empty object map
    objmap = {};
    qobjmap = {};

    % for each view
    for j = data.views
    
        % read view and query (noise) view
        [im_, nim_] = read_view(data, noise, i, j);

        % convert to hsv
        im = rgb2hsv(im_);
        nim = rgb2hsv(nim_);
        
        % start descriptor computation stopwatch
        tic
        
            % extract HSV histogram from view
            descr = feature_hsv_hist(im);
            
        % stop stopwatch
        model.ctime{end+1} = toc;
        
        % extract HSV histogram from query view
        if(strcmp(model.noise,'none'))
            qdescr = descr;
        else
            qdescr = feature_hsv_hist(nim);
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


function [feature_vec] = feature_hsv_hist(im)
%% creates an HSV color histogram of an input image
% pre   HSV image
% post  HSV feature histogram

% default bins
h_bins = 18;
s_bins = 3; 
v_bins = 3;

% histogram dimension
dim = h_bins * s_bins * v_bins;

% do quantization over H S and V
color_quant = round(im(:,:,1) * (h_bins -1))*(s_bins*v_bins) + round(im(:,:,2)*(s_bins - 1))*v_bins  + round(im(:,:,3)*(v_bins -1)) + 1;
color_quant = color_quant(:);

% create hsv histogram
hsv_hist = hist(color_quant, 1:dim);

% Append the information about the statistics of the histogram 
feature_vec = [hsv_hist mean(hsv_hist) std(hsv_hist)];