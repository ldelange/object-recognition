function [match] = align(seq, qseq)
%%  Ideal multi-View object model
%   Local sequence alignment via Smith-Waterman algorithm
%   Author:         ldelange, 
%                   BMD Master Thesis multi-view object retrieval


%% score variables
score.match = length(qseq);
score.mismatch = -1;


%% initialize match struct
match.length = 0;               % length alignment
match.sequence = [];            % array of views from seq which are matched
match.mismatch = {};            % location mismatches


%% if qseq is longer than seq return empty match
if(length(qseq) > length(seq))
    return;
end


%% construct score matrix for each position
% initialize global score matrix
scores = zeros(length(qseq)+1,length(seq)+1);

% for each position in scores matrix
for i = 2:length(qseq)+1
    
    for j = 2:length(seq)+1
   
        % initialize local matches
        m = [0 0];
        
        % match/mismatch
        if(qseq(i-1) == seq(j-1))
            m(2) = scores(i-1,j-1) + score.match;
        else
            m(2) = scores(i-1,j-1) + score.mismatch;
        end
        
        scores(i,j) = max(m);
        
    end
    
end


%% Match sequences using score and traceback
% find scores index containing max value
[value, idx] = max(scores(:));

% find x and y positions corresponding to index in scores
[y, x] = ind2sub(size(scores), idx);

% start alignment at max score
p = [y x];

% loop until traceback is at origin of sequence
while ((p(1) > 1) && (p(2) > 1))
        
        % traceback, one direction no gaps
        p = [p(1)-1 p(2)-1];
                
        % if score is zero exit loop
        if(scores(p(1),p(2)) == 0)
            break;
        end
                
end

% start position sequence alignment
pos = (p(2)-1) - (p(1)-1);

% update match struct using sequences
for i = 1:length(qseq)
    
    % update alignment position
    view = pos + i;
    
    % add view to match sequence
    if(view < 1)
        match.sequence(i) = view + length(seq);
    elseif(view > length(seq))
        match.sequence(i) = view - length(seq);
    else
        match.sequence(i) = view;
    end
    
    % match or mismatch
    if(seq(match.sequence(i)) == qseq(i))
        match.length = match.length + 1; 
    else
        match.mismatch{end+1} = i;
    end
        
end