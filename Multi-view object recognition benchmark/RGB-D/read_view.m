function [im, nim] = read_view(data, noise, obj, view)
%%  Implementation of different noise models
%   none, gaussian and affine transformation
%   returns plain and noise image
%   Author:         ldelange, 
%                   BMD Master Thesis multi-view object retrieval

% read image
im_ = imread(strcat(data.path, data.dataset{obj}{view}, '_crop.png'));

% read mask
mask_ = imread(strcat(data.path, data.dataset{obj}{view}, '_maskcrop.png'));

% convert to uint8
mask_ = im2uint8(mask_) ./ 255;
    
% resize for faster calculation
im = imresize(im_,0.6);
mask = imresize(mask_,0.6);

% image center
im_c = 150 - round(size(im)/2);

% create blank canvas with fixed height and width
canvas = im2uint8(zeros([300 300 3]));

% place image in canvas
canvas(im_c(1):(im_c(1)+size(im,1)-1),im_c(2):(im_c(2)+size(im,2)-1),:) = im;
im = canvas;

% create blank canvas with fixed height and width
canvas = im2uint8(zeros([300 300]));

% place mask in canvas
canvas(im_c(1):(im_c(1)+size(mask,1)-1),im_c(2):(im_c(2)+size(mask,2)-1)) = mask;
mask = canvas;

% apply mask
im = im .* repmat(mask,[1,1,3]);
        
% switch noisemodels
switch noise.descr

    case 'none'

        % no noise
        nim = im;
        
        
    case 'gaussian'
                     
        % add gaussian noise to image
        nim_ = imnoise(im,'gaussian',0,noise.std);
                
        % apply mask
        nim = nim_ .* repmat(mask,[1,1,3]);
                                    
        
    case 'affine'
    
        % rotate image
        nim_ = imrotate(im,noise.affine,'bilinear','crop');
                                        
        % resize for equal descriptors
        nim = imresize(nim_,[300 300],'bilinear');
        
        
    otherwise
        
        % wrong noisemodel
        im = null;
        nim = null;
    
end