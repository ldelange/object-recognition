function [model] = match(model, data, mdl, qmdl)
%%  Ideal single-View object model
%   Matches object model with query model features and returns object recognition
%   performance (object and view accuracy)
%   Author:         ldelange, 
%                   BMD Master Thesis multi-view object retrieval

clc;
display(strcat('Matching', {' '}, model.descriptor, {' '}, 'features', {' '}, int2str(length(mdl{1})), '-', int2str(length(qmdl{1}))));


%% variables
objects = length(data.objects);
views = length(data.views);
objconfus = zeros(objects);
viewconfus = zeros(objects * views);
    
        
%% create kdtree for fast descriptor matching
% start stopwatch
tic

% find closest object and view match
if~(strcmp(model.descriptor, 'SIFT'))
            
    % concatenate all objects
    descrs_ = cat(2,mdl{:});

    % concatenate all descriptors
    descrs = single(cat(1,descrs_{:})');

    % construct kdtree
    kdtree = vl_kdtreebuild(descrs);

end

%% Create confusion matrices based on matches
% for each query object model
for obj = 1:length(qmdl)

    % for each view inside query object
    for view = 1:length(qmdl{obj})
            
        % find closest object and view match
        if(strcmp(model.descriptor, 'SIFT'))
            
            % mach descriptors using vl_ubcmatch
            [objmatch, viewmatch] = matchSIFT(mdl, qmdl{obj}{view});
            
        else
            
            % find descriptor index of best match (euclidean)
            idx = double(vl_kdtreequery(kdtree,descrs,single(qmdl{obj}{view})'));

            % using index find corresponding object and view
            [viewmatch, objmatch] = ind2sub([data.views(end), data.objects(end)],idx);

        end

        % update matches object matrix
        objconfus(obj,objmatch) = objconfus(obj,objmatch) + 1;

        % update matches views matrix
        viewconfus(views * (obj - 1) + view, views * (objmatch - 1) + viewmatch) =+ 1;

    end

end
 
% view accuracy
model.vaccuracy = sum(diag(viewconfus))/sum(sum(viewconfus)) * 100;

% object accuracy
model.oaccuracy = sum(diag(objconfus))/sum(sum(objconfus)) * 100;

% descriptor matching time
model.mtime = toc;


function [objmatch, viewmatch] = matchSIFT(mdl, qdescr)
%% calculates matching SIFT descriptors
% pre   SIFT object models and query SIFT descriptor
% post  returns closest object and view from the object models
  
% initialize matches vector
matches = zeros(length(mdl),length(mdl{1}));

% for each object model
for obj = 1:length(mdl)
    
    % for each view inside object
    for view = 1:length(mdl{obj})
                
        % calculate euclidean distance between two descriptors
        matches(obj,view) = length(vl_ubcmatch(mdl{obj}{view},qdescr));
        
    end
    
end

% return best match indexes
[objmatch, viewmatch] = find(matches == max(max(matches)));
