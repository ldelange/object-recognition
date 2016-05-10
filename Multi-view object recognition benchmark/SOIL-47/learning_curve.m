function [cur] = learning_curve(data, model, mdl, qmdl)
%%  Ideal single-View object model
%   Obtains learning curve regarding the object recognition rate using
%   varying sequence size of query objectmaps
%   Author:         ldelange, 
%                   BMD Master Thesis multi-view object retrieval


%% variables
sqmdl = {};


%% select x random views of object maps as training model
% for each part of an objectmap
for x = 1:(length(data.views))
    
    % start with empty model
    sqmdl = {};
    
    % for each object
    for obj = 1:length(data.objects)

        % select random startpoint sequence
        seq_ = randperm(length(data.views)+1-x,1);
        
        % obtain sequence array
        seq = seq_:seq_-1+x;
        
        % update query sequence model with new object map
        sqmdl{end+1} = qmdl{obj}(seq);
        
    end
    
    % match query sequence models to the complete object models
    cur(x) = match(model, data, mdl, sqmdl);
    
end