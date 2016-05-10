function [cur] = mvlearn(model, data, mdl, qmdl, vmdl, vqmdl)
%%  Ideal single-View object model
%   Obtains learning curve regarding the object recognition rate using
%   varying sequence size of query objectmaps
%   Author:         ldelange, 
%                   BMD Master Thesis multi-view object retrieval


%% variables
sqmdl = {};
svqmdl = {};


%% Obtain learning curve for varying sequence size
% for view sequence length
for x = 1:(length(data.views))
    
    % initialize empty sequence (vocabulary) query model
    sqmdl = {};
    svqmdl = {};
    
    % for each object
    for obj = 1:length(data.objects)

        % select random startpoint sequence
        seq_ = randperm(length(data.views)+1-x,1);
        
        % obtain sequence array
        seq = seq_:seq_-1+x;
        
        % update query sequence model with new object map
        sqmdl{end+1} = qmdl{obj}(seq);
        
        % update query sequence vocabulary model with new object map
        svqmdl{end+1} = vqmdl{obj}(seq);
        
    end
           
    % match query sequence models to the complete object models
    cur(x) = mvmatch(model, data, mdl, sqmdl, vmdl, svqmdl);
    
end