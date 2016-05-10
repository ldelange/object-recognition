function [dmdl, dqmdl] = discretize(data, mdl, qmdl)
%%  Ideal single-View object model
%   Discretizes (query)object models by resampleling
%   Author:         ldelange, 
%                   BMD Master Thesis multi-view object retrieval


%% variables
dmdl = {};
dqmdl = {};


%% resample (query)object models
% for each object model map
for obj = 1:data.objects(end)
       
    % select discretized views from that object
    dmdl{end+1} = mdl{obj}(data.discretize);
        
    % select discretized views from that (query)object
    dqmdl{end+1} = qmdl{obj}(data.discretize);
    
end
