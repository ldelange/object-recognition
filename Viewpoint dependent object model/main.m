%%  Obtaining multi-view object data via egomotion and plane extraction
%   Author:  	    Leon de Lange 
%                   TuDelft, BMD Master Thesis
%                   Multi-view object retrieval
%   Last revision:  15 march 2016

clc
clear all
close all

%% PATH TO OBJECT
obj = 'objxx';               % object name


%% constants
res = [640 480];            % [px] kinect resolution
state = eye(4);             % kinect motion matrix state
trace = [0 0 0]';           % kinect trace
aztrace = [];               % azimuth trace
eltrace = [];               % elevation trace
frame = 1;                  % frame number

% egomotion parameters
ego.res = res;              % [px] kinect resolution
ego.mthresh = 0.1;          % [m] threshold matching distance
ego.ithresh = 1e-3;         % iteration threshold
ego.maxiter = 15;           % maximum iterations


%% kinect RGB/IR camera intrinsic and extrinsic parameters
% intrinsic matrix ir-depth camera
intr_ir = [     572     0       315;
                0       542     240;
                0       0       1       ];
        
% intrinsic matrix rgb camera
intr_rgb = [    511     0       322;
                0       493     249;
                0       0       1       ];

% constants: linear relation disparity to inverse depth coordinates
k = [-0.00307   3.33095]; 

% image indices (x,y) based on kinect resolution
ind = [repmat((1:res(1))',[res(2),1]) repelem((1:res(2))',res(1)) ones(res(1)*res(2),1)]; 

% inverse depth coordinates
ir_uv = (intr_ir\ind')';

% extrinsic camera parameters
R = [   0.9998      0.0013      -0.0175;
        -0.0015     0.9999      -0.0123;
        0.0175      0.0123      0.9998      ];

t = [   0.0200      -0.0007     -0.0109     ]';

extr = [R t; [0 0 0 1]];

% registration parameters
reg.res = res;              % [px] kinect resolution
reg.k = k;                  % linear relation disparty and inverse depth
reg.ir_uv = ir_uv;          % inverse depth coordinates
reg.intr_rgb = intr_rgb;    % intrinsic parameters rgb camera
reg.extr = extr;            % extrinsic parameters


%% create listener for kinect camera
fprintf('Making first call to initalize the kinect driver and listening thread\n');
kinect_mex();
pause(1)

fprintf('Making second call starts getting data\n');
kinect_mex();
pause(2)


%% create video player
videoPlayer  = vision.VideoPlayer('Position',[100 100 [res(1), res(2)]]);
videoPlayer2  = vision.VideoPlayer('Position',[100 100 [res(1), res(2)]]);


%% create a point tracker
pointTracker = vision.PointTracker('NumPyramidLevels',7,'MaxBidirectionalError', 8, 'MaxIterations',50,'BlockSize',[5 5]);

points.Count = 0;
while(points.Count < 1)
    
    % grab frame
    [unreg_d, rgb] = kinect_mex();

    % reshape datastream to form an image
    rgb = permute(reshape(rgb,[3 res]),[3 2 1]);

    % extract SURF corners
    points = detectSURFFeatures(rgb2gray(rgb));
    
end

% initialize tracker
initialize(pointTracker,points.Location,rgb);

% initialize egomotion trace plot
figure(1)
hold on


%% forever loop
while (1 == 1)
            
    % calculate frames per second
    tic
    
    % grab frame
    [unreg_d, rgb] = kinect_mex();
              
    % reshape datastream using kinect resolution
    rgb = permute(reshape(rgb,[3 res]),[3 2 1]);
    unreg_d = im2double(unreg_d, 'indexed');
    
    % obtain registered depth point cloud
    t1_d = registration(unreg_d, reg);
    
    % extract SURF corners
    points = detectSURFFeatures(rgb2gray(rgb));

    % add points to tracker
    setPoints(pointTracker, points.Location);

    % update tracking step
    [isPoints, isFound] = step(pointTracker, rgb);

    % matched points in both frames
    oldPoints = points.Location(isFound, :);
    newPoints = isPoints(isFound, :);
           
    % In case previous frame exist
    if(exist('t0_d','var'))
        
        % clear plot and matlab display
        clf;
        clc;
        
        % estimate kinect motion
        state = egomotion(state, t0_d, t1_d, oldPoints, newPoints, ego);
    
        % dominant plane detection
        [distance, dnorm] = detect_plane(t1_d);
                
        % location estimate
        wstate = inv(state);
        
        % rewrite pointcloud in dominant plane coordaintes
        t1_dp = t1_d(:,:,1).*dnorm(1) + t1_d(:,:,2).*dnorm(2) + t1_d(:,:,3).*dnorm(3) - distance;

        % mask all points below 2 cm above the ground plane
        mask_d = (t1_dp < -0.01);

        % perform some morpholical filters to grab the object
        mask_d = imfill(~mask_d,1);                 % floodfill borders
        mask_d = bwmorph(~mask_d,'open');           % close operation for smooth borders
    
        % labeled objects
        mask_l = bwlabel(mask_d);
                
        % make a histogram of labeled pixels
        [a, val] = hist(mask_l(:),0:max(mask_l(:)));
        
        % set largest histogram bin (background) to zero
        a = a.*(a ~= max(a));
        
        % find second largest label
        label = val(a == max(a));
        
        % region of interest
        mask_d = (mask_l == label);
        
        % show masked object
        step(videoPlayer, im2double(rgb).*repmat(mask_d,[1 1 3]));
        step(videoPlayer2, im2double(rgb));
        
        if(frame == 2)
            pause(20);
        end
        
        % align camera orientation with dominant plane orientation
        if(frame == 5)
            
            % find elevation angle between plane normal and world y-axis
            phi = acos(dot(dnorm,[0 1 0]'));
            
            % construct rotation axis
            ax = cross(dnorm,[0 1 0]');
            ax = ax./norm(ax);
            
            % obtain rotation matrix
            ax = [0 -ax(3) ax(2); ax(3) 0 -ax(1); -ax(2) ax(1) 0];
            roderigues = eye(3) + ax.*sin(phi) + ax.^2.*(1-cos(phi));
           
            % set new camera state
            state = [inv(roderigues) [0 distance 0]'; 0 0 0 1];

            % obtain new world state
            wstate = inv(state);

        end

        % update kinect egmotion
        trace = [trace wstate(1:3,4)];
        
        % draw egmotion
        subplot(1,2,1)
        plot3(trace(1,:),trace(2,:),trace(3,:),'.')
        xlabel('x')
        ylabel('y')
        zlabel('z')
        hold on
        cam = plotCamera('Location',wstate(1:3,4),'Orientation',state(1:3,1:3),'Opacity',0,'Size',0.05);
        hold off
        view(0,0);
        axis('equal');         
         
        % get camera orientation vector
        vec = cam.Orientation*[0 0 1]';
        
        % obtain azimuth angle from camera orientation
        vec = [vec(1) 0 vec(3)]./norm([vec(1) 0 vec(3)]);
        theta = acos(dot(vec,[0 0 1]))*360/(2*pi);
        if(vec(1) > 0)
            theta = 360-theta;
        end
        
        % obtain elevation angle from dominant plane orientation
        phi = acos(dot(dnorm,[0 1 0]))*360/(2*pi);
                
        % update traces
        aztrace = [aztrace theta];                 
        eltrace = [eltrace phi];
               
        % discretize angles to object data
        objaz = floor(theta/20);
        objel = round(phi/15);
        
        % if directory does not exist
        if(~exist(obj,'dir'))
            mkdir(obj)
        end
        
        if(~exist(strcat(obj,'/',obj,'_',int2str(objel),'_',int2str(objaz),'.png'),'file'))
            imwrite(im2double(rgb).*repmat(mask_d,[1 1 3]),strcat(obj,'/',obj,'_',int2str(objel),'_',int2str(objaz),'.png'));
        end
        
        subplot(1,2,2)
        plot(aztrace,eltrace,'.k')
        xlabel('Azimuth')
        ylabel('Elevation')
        ylim([0 90]);
        xlim([0 360]);
         
        drawnow
        
    end
    
    % set current frame to previous frame
    t0_d = t1_d;

    % frame rate
    fps = 1/toc;
    frame = frame + 1;
    display(fps);

end

%% close listener
kinect_mex('q');


%% release videoplayer
release(videoPlayer);