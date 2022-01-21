function fourier_crop_stack(stack_name, new_name, binning)
%% fourier_crop_stack
% A function to bin an image stack by fourier cropping. Image stacks are
% assumed to be in .mrc format.
%
% If the image size is not evenly divisible by the binning factor, the
% edges of the image are padded using the edge pixels. If there are also
% unpadded corners, these are set to the mean value of the image. This
% should help prevent artifacts in Fourier space. 
%
% WW 01-2018

%% Initialize

% Evaulate numeric input
if (ischar(binning)); binning=eval(binning); end

% Read in stack
disp(['Reading in stack: ',stack_name]);
stack = tom_mrcread(stack_name);
stack = stack.Value;
[x,y,n_img] = size(stack);

% Check for padding
if mod(x,(binning*2)) || mod(y,(binning*2))     % binning*2 ensures an even-dimensioned binned output
    disp('Image will be padded prior to Fourier cropping...');
    
    % Image needs to be padded
    pad = true;
    
    % Padding indices
    x_old = x;                       % Store old x
    x = ceil(x/(binning*2))*(binning*2);     % New x
    px1 = floor((x-x_old)/2)+1;              % Where old image starts in padded image
    px2 = px1 + x_old -1;                    % Where the old image ends in padded image
    y_old = y;                               % Store old y
    y = ceil(y/(binning*2))*(binning*2);     % New y
    py1 = floor((y-y_old)/2)+1;              % Where old image starts in padded image
    py2 = py1 + y_old -1;                    % Where the old image ends in padded image
    
else
    pad = false;    
end

% Calculate Fourier cropping parameters
nx = x/binning;             % Binned X size
ny = y/binning;             % Binned Y size
cx1 = floor((x-nx)/2)+1;    % Cropping X start
cx2 = cx1 + nx - 1;         % Cropping X end
cy1 = floor((y-ny)/2)+1;    % Cropping X start
cy2 = cy1 + ny - 1;         % Cropping X end
    
% Initialize new stack
newstack = zeros(nx,ny,n_img,'like',stack);


%% Fourier crop

for i  = 1:n_img
    
    % Parse image
    if pad
        
        % Parse old image
        old_img = stack(:,:,i);
        
        % Initialize image
        img = ones(x,y,'like',stack).*mean(old_img(:));     % Corners will be set to mean greyvalue
        
        % Insert old image
        img(px1:px2,py1:py2) = old_img;
        
        % Pad left
        if px1 > 1
            img(1:px1-1,py1:py2) = repmat(old_img(1,:),px1-1,1);
        end
        % Pad right
        if px2 < x
            img(px2+1:end,py1:py2) = repmat(old_img(end,:),x-px2,1);
        end
        % Pad top
        if py1 > 1
            img(px1:px2,1:py1-1) = repmat(old_img(:,1),1,py1-1);
        end
        % Pad bottom
        if py2 < y
            img(px1:py2,py2+1:end) = repmat(old_img(:,end),1,y-py2);
        end
        
        clear old_img
                
    else
        
        % Parse image
        img = stack(:,:,i);
        
    end
    
    % Transform image
    ft_img = fftshift(fft2(img));
    
    % Store cropped image
    newstack(:,:,i) = ifft2(ifftshift(ft_img(cx1:cx2,cy1:cy2)));
    
end
        
% Write stack
disp('Cropping complete... Writing stack...');
tom_mrcwrite(newstack,'name',new_name);
disp('Stack written!!!');





