function [im, nim] = read_view(data, noise, obj, view)
%%  Implementation of different noise models
%   gaussian, illumination and affine transformation
%   returns plain and noise image
%   Author:         ldelange, 
%                   BMD Master Thesis multi-view object retrieval


% read image from set A
im = imread(strcat(data.path, 'obj', int2str(obj), 'A_', int2str(view), '.png'));

% read mask from set A
mask = imread(strcat(data.masks, 'obj', int2str(obj), 'A_', int2str(view), '_mask.pgm'));

% resize to fit mask
mask = imresize(mask, 2)./255;

% horizontal object boundaries in mask
cropx = [];
for x = 1:size(mask,2)
    if (sum(mask(:,x)) ~= 0)
        cropx = [cropx x];
    end
end

% set crop x value based on 350 pixel canvas
cropx = round((cropx(1)+cropx(end))/2-175);

% vertical object boundaries in mask
cropy = [];
for y = 1:size(mask,1)
    if (sum(mask(y,:)) ~= 0)
        cropy = [cropy y];
    end
end

% set crop y value based on 350 pixel canvas
cropy = round((cropy(1)+cropy(end))/2-175);

% crop image
im = imcrop(im,[cropx cropy 349 349]);

% crop mask
mask = imcrop(mask,[cropx cropy 349 349]);

% apply mask
im = im .* repmat(mask,[1,1,3]);
        
% switch noisemodels
switch noise.descr

    case 'none'
        
        % no noise
        nim = im;
        
        
    case 'gaussian'

        % add gaussian noise to image
        nim = imnoise(im,'gaussian',0,noise.std);
                     
        % apply mask
        nim = nim .* repmat(mask,[1,1,3]);
                  
        
    case 'illumination'
        
        % read image from set B
        nim = imread(strcat(data.path, 'obj', int2str(obj), 'B_', int2str(view), '.png'));
                            
        % read mask from set B
        mask = imread(strcat(data.masks, 'obj', int2str(obj), 'B_', int2str(view), '_mask.pgm'));
        
        % resize to fit mask
        mask = imresize(mask, 2)./255;

        % horizontal object boundaries in mask
        cropx = [];
        for x = 1:size(mask,2)
            if (sum(mask(:,x)) ~= 0)
                cropx = [cropx x];
            end
        end

        % set crop x value based on 350 pixel canvas
        cropx = round((cropx(1)+cropx(end))/2-175);

        % vertical object boundaries in mask
        cropy = [];
        for y = 1:size(mask,1)
            if (sum(mask(y,:)) ~= 0)
                cropy = [cropy y];
            end
        end

        % set crop y value based on 350 pixel canvas
        cropy = round((cropy(1)+cropy(end))/2-175);

        % crop image
        nim = imcrop(nim,[cropx cropy 349 349]);

        % crop mask
        mask = imcrop(mask,[cropx cropy 349 349]);

        % apply mask
        nim = nim .* repmat(mask,[1,1,3]);
    
        
    case 'affine'
        
        % rotate image
        nim = imrotate(im,noise.affine,'bilinear','crop');
                
        % resize for equal descriptors
        nim = imresize(nim,[350 350],'bilinear');
        
    otherwise
        
        % wrong noisemodel
        im = null;
        nim = null;
        
        return;
    
end