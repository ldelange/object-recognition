function [vmdl, vqmdl] = approximate(vocab, mdl, qmdl)
%%  Ideal multi-View object model
%   extracts a bag of words from all object model descriptors and returns
%   objectmaps approximated by vocabulary words
%   Author:         ldelange, 
%                   BMD Master Thesis multi-view object retrieval


%% variables
vmdl = {};
vqmdl = {};


%% create vocabulary using vocab
% concatenate all objects
descr = cat(2,mdl{:});

% concatenate descriptors
vdescr = cat(1,descr{:})';

% create vocabulary
words_ = randperm(size(vdescr,2),round(size(vdescr,2)*vocab.words));
words = single(vdescr(:,words_));

% calculate k-d tree in order to speed up matching
kdtree = vl_kdtreebuild(words);


%% approximate object models using vocabulary
% for each object in model
for obj = 1:length(mdl)
    
    % initialize empty approximation map
    map = [];
    
    % for each view
    for view = 1:length(mdl{obj})
                
        % calculate closest word in vocabulary
        map(view) = double(vl_kdtreequery(kdtree,words,single(mdl{obj}{view})','MaxComparisons', vocab.iter));
        
    end
    
    % add approximated object map to vocabulary model
    vmdl{end+1} = map;
    
end


%% approximate query models using vocabulary
% for each query object in query model
for qobj = 1:length(qmdl)
    
    % initialize empty approximation query map
    qmap = [];
    
    % for each view
    for qview = 1:length(qmdl{qobj})
                
        % calculate closest word in vocabulary
        qmap(qview) = double(vl_kdtreequery(kdtree,words,single(qmdl{qobj}{qview})','MaxComparisons', vocab.iter));
        
    end
    
    % add approximated query object map to query vocabulary model
    vqmdl{end+1} = qmap;
    
end

