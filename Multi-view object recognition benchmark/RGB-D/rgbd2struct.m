%%  Single-View object model RGBD object dataset
%   converts rgbd-dataset to struct
%   Author:         ldelange, 
%                   BMD Master Thesis multi-view object retrieval

clear all
close all
clc

%% variables
data.path = 'rgbd-dataset';     % path to rgbd-database


%% Construct path database
% grab all categories from rgbd-dataset
cat = dir(data.path);
dataset = {cat(~ismember({cat.name},{'.','..'})).name};

% for each dataseting object
for i = 1:length(dataset)
   
    % grab instances
    instance_ = dir(strcat(data.path, '/', dataset{1,i}));
    dataset{2,i} = {instance_(~ismember({instance_.name},{'.','..'})).name}';
    
    % grab instance views first band (low)
    clear('v');
    for j = 1:length(dataset{2,i})
        views_ = dir(strcat(data.path, '/', dataset{1,i}, '/', dataset{2,i}{j,1}, '/', dataset{2,i}{j,1}, '_1_*_crop.png'));
        
        % grab the view number for sorting
        str_ = [];
        for x = 1:length(views_)
            no = strsplit(views_(x).name,'_');
            str_ = [str_ str2num(no{end-1})];
        end
                
        % sort string on view number
        sort_str = sort(str_);
        
        % construct instance data path
        path = {};
        for y = 1:length(views_)
            path{y,1} = strcat(dataset{1,i}, '/', dataset{2,i}{j,1}, '/', dataset{2,i}{j,1}, '_1_', int2str(sort_str(y)));  
        end
                     
        % add instance to struct
        v{j,1} = path;
                
    end
    
    % grab instance views second band (middle)
    for j = 1:length(dataset{2,i})
        views_ = dir(strcat(data.path, '/', dataset{1,i}, '/', dataset{2,i}{j,1}, '/', dataset{2,i}{j,1}, '_2_*_crop.png'));
        
        % grab the view number for sorting
        str_ = [];
        for x = 1:length(views_)
            no = strsplit(views_(x).name,'_');
            str_ = [str_ str2num(no{end-1})];
        end
        
        % sort string on view number
        sort_str = sort(str_);
        
        % construct instance data path
        path = {};
        for y = 1:length(views_)
            path{y,1} = strcat(dataset{1,i}, '/', dataset{2,i}{j,1}, '/', dataset{2,i}{j,1}, '_2_', int2str(sort_str(y)));  
        end
                     
        % add instance to struct
        v{j,2} = path;
                
    end
    
    % grab instance views third band (high)
    for j = 1:length(dataset{2,i})
        views_ = dir(strcat(data.path, '/', dataset{1,i}, '/', dataset{2,i}{j,1}, '/', dataset{2,i}{j,1}, '_4_*_crop.png'));
        
        % grab the view number for sorting
        str_ = [];
        for x = 1:length(views_)
            no = strsplit(views_(x).name,'_');
            str_ = [str_ str2num(no{end-1})];
        end
        
        % sort string on view number
        sort_str = sort(str_);
        
        % construct instance data path
        path = {};
        for y = 1:length(views_)
            path{y,1} = strcat(dataset{1,i}, '/', dataset{2,i}{j,1}, '/', dataset{2,i}{j,1}, '_4_', int2str(sort_str(y)));  
        end
                     
        % add instance to struct
        v{j,3} = path;
                
    end
    
    dataset{2,i} = v;
        
end

% construct database
rgbd_dataset = {};
for i = 1:length(dataset)
   
    rgbd_dataset{i}.category = dataset{1,i};
    rgbd_dataset{i}.instances = dataset{2,i};

end

save('var/rgbd-dataset.mat','rgbd_dataset');


%% Example imread from struct
% object = x; view = y; band = z;
% im = imread(strcat(data.path, rgbd_dataset{x}.instances{y,z}, '_crop.png'));
