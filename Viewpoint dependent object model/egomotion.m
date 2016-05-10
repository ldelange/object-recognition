function [t1_state] = egomotion(t0_state, t0_d, t1_d, oldPoints, newPoints, ego)
%%  Kinect egomotion estimation
%   Author:  	    Leon de Lange 
%                   TuDelft, BMD Master Thesis
%                   Multi-view object retrieval
%   Last revision:  15 march 2016


%% constants
res = ego.res;              % [px] kinect resolution
mthresh = ego.mthresh;      % [m] threshold matching distance
ithresh = ego.ithresh;      % iteration threshold
maxiter = ego.maxiter;      % maximum iterations
iter = 1;                   % set iteraton counter
optimal = true;             % optimal alignment boolean

% seperate depth layers
t0_x = t0_d(:,:,1);
t0_y = t0_d(:,:,2);
t0_z = t0_d(:,:,3);
t1_x = t1_d(:,:,1);
t1_y = t1_d(:,:,2);
t1_z = t1_d(:,:,3);


%% Egomotion estimation
% get indices matched points
p0_ind = sub2ind([res(2) res(1)],floor(oldPoints(:,2)),floor(oldPoints(:,1)));
p1_ind = sub2ind([res(2) res(1)],floor(newPoints(:,2)),floor(newPoints(:,1)));

% obtain euclidean coordinates
p0_xyz = [t0_x(p0_ind) t0_y(p0_ind) t0_z(p0_ind)];
p1_xyz = [t1_x(p1_ind) t1_y(p1_ind) t1_z(p1_ind)];

% check if a depth is assigned for each point pair
mask = (p0_xyz(:,3) > 0)&(p1_xyz(:,3) > 0);
p0_xyz = p0_xyz(mask,:);
p1_xyz = p1_xyz(mask,:);

% check if distance of point pair is below treshold
mask2 = sqrt(sum((p0_xyz - p1_xyz).^2,2)) < mthresh;
p0 = p0_xyz(mask2,:);
p1 = p1_xyz(mask2,:);

% add a colom of ones to pointlists
p0(:,4) = 1;
p1(:,4) = 1;

% when there are enough points to solve the equations
if((size(p0,1) > 6)&&(size(p1,1) > 6))

    % initialize total point distance for iteration criterea
    dist = inf;

    % iterative update pose estimation
    while(dist > ithresh)

         % initialize stacked Jacobian
        J = [];

        % initialize stacked point differences
        Y = [];

        % for each pointpair
        for i = 1:size(p0,1)

            % construct Jacobian
            Jp = [  1   0   0   0           p0(i,3)     -p0(i,2);
                    0   1   0   -p0(i,3)    0           p0(i,1);
                    0   0   1   p0(i,2)     -p0(i,1)    0           ];

            % stack Jacobians
            J = [J; Jp];

            % calculate point difference
            Yp = [  p1(i,1) - p0(i,1);
                    p1(i,2) - p0(i,2);
                    p1(i,3) - p0(i,3)   ];

            % stack point differences
            Y = [Y; Yp]; 

        end

        % error of each point to its objective
        err = sqrt(sum((p0-p1).^2,2));

        % standard deviation of error
        std = sqrt(mean(sum((err - mean(err)).^2)));

        % obtain outlier weighting matrix using M-estimator
        W = diag(repelem((1-(err.^2)./(std.^2 + err.^2)),3));

        % estimate motion parameters
        B = (J'*W*J)\J'*W*Y;

%         % alternating for each iteration (optimal rotation then
%         % translation)
%         if(optimal)
%             B(1:3) = 0;
%             optimal = false;
%         else
%             B(4:6) = 0;
%             optimal = true;
%         end

        % estimated motion matrix
        M = [   1           -B(6)       B(5)        B(1);
                B(6)        1           -B(4)       B(2);
                -B(5)       B(4)        1           B(3);
                0           0           0           1       ];

        % calculate new estimated point list
        pe = (M * p0')';

        % calculate distance point list update (termination criterea)
        dist = sum(sqrt(sum((p0 - pe).^2,2)));

        % set estimate point list as new point list
        p0 = pe;

        % update estimated motion parameters
        t0_state = M * t0_state;

        % increase iteration (termination criterea)
        iter = iter + 1;
        if(iter > maxiter)
            break;
        end

    end

else

    display('too few points')
    
end

% set new motion matrix
t1_state = t0_state;    