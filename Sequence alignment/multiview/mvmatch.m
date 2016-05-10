function [model] = match(model, data, mdl, qmdl, vmdl, qvmdl)
%%  Ideal multi-View object model
%   Matches object models with query object models
%   performance (object and view accuracy)
%   Author:         ldelange, 
%                   BMD Master Thesis multi-view object retrieval

clc;
display(strcat('Matching', {' '}, model.descriptor, {' '}, 'features', {' '}, int2str(length(mdl{1})), '-', int2str(length(qmdl{1}))));


%% constants
obj = length(vmdl);
qobj = length(qvmdl);


%% variables
scores = zeros(obj, qobj);
confus = zeros(obj, qobj);
distance = zeros(obj, qobj);
matches = {};
    
        
%% align each query map to all object maps
% start stopwatch
tic

% for each objectmap
for map = 1:obj
    
    % for each query objectmap
    for qmap = 1:qobj
                
        % align query object map with model map
        match = align(vmdl{map}, qvmdl{qmap});
      
        % update scores matrix with sequence ratio
        scores(map,qmap) = match.length/length(qvmdl{qmap});
        
        % update matches matrix if there exist an alignment
        if(scores(map,qmap) > 0)
            matches{map,qmap} = match;
        end
                
    end
            
end


%% Use true descriptors for each aligned sequence to measure distance
% set all distances to infinity
distance(distance == 0) = inf;

% for each query objectmap
for qmap = 1:qobj

    % for each objectmap
    for map = 1:obj
        
        % if match is found
        if(scores(map,qmap) > 0)
                                    
            % calculate euclidean of sequence alignment
            distance(qmap,map) = euclidean(mdl{map}, qmdl{qmap}, matches{map,qmap});
        
        end
        
    end
        
    % find minimal distance along all object maps
    [value idx] = find(distance(qmap,:) == min(distance(qmap,:)));
    
    % update confusion matrix
    confus(qmap,idx(1)) = 1;
    
end

% object accuracy
model.oaccuracy = sum(diag(confus))/sum(sum(confus)) * 100;

% descriptor matching time
model.mtime = toc;


function [dist] = euclidean(map, qmap, match)
%% calculates euclidean distance of aligned sequences
% pre   objectmap, queryobjectmap and information about alignment
% post  euclidean distance of alignment
  
% select alignement sequence from map
map = map([match.sequence]);

% initialize matches vector
distance = zeros(length(qmap),1);

% for each view in sequence
for view = 1:length(map)

    % calculate euclidean distance between two descriptors
    distance(view) = sqrt((map{view} - qmap{view}) * (map{view} - qmap{view})');

end

% return distance sequence alignment
dist = sum(distance);
