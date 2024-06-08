function new_stack = tm_resize_stack(stack,x,y,edgepadding)
%% tm_resize_stack
% A function to resize an image stack to target XY dimensions. If the size
% is smaller, the image will be cropped. If the size is larger, the image
% can be padded with the edge pixels or set to the image mean grey values. 
%
% WW 01-2018

%% Check check

% Pad edges with edge pixels
if nargin == 3
    edgepadding = false;
end

% Get input image size
[in_x, in_y, n_img] = size(stack);

% Check dimensions
if (in_x == x) && (in_y == y)
    new_stack = stack;
    return
end


%% Initialize 

% Initialize new stack
new_stack = zeros(x,y,n_img,'like',stack);

% Generate start and end pixels for new and old stack. 
pad_x = false;
if in_x == x
    nx1 = 1; nx2 = x; ox1 = 1; ox2 = x;
elseif in_x > x;
    nx1 = 1; nx2 = x; ox1 = ((in_x-x)/2)+1; ox2 = ox1+x-1;    
elseif in_x < x    
    nx1 = ((x-in_x)/2)+1; nx2 = nx1+in_x-1; ox1 = 1; ox2 = in_x; pad_x = true;
end
pad_y = false;
if in_y == y
    ny1 = 1; ny2 = x; oy1 = 1; oy2 = y;
elseif in_y > y;
    ny1 = 1; ny2 = y; oy1 = ((in_y-y)/2)+1; oy2 = oy1+y-1;    
elseif in_y < y
    ny1 = ((y-in_y)/2)+1; ny2 = ny1+in_y-1; oy1 = 1; oy2 = in_y; pad_y = true;
end


%% Resize stacks

for i = 1:n_img
    
    % Parse old image
    old_img = stack(ox1:ox2,oy1:oy2,i);
    
    % Initialize new image
    new_img = ones(x,y,'like',stack).*mean(old_img(:));
    new_img(nx1:nx2,ny1:ny2) = old_img;
    
    % If padding
    if edgepadding
        % Check pad on X
        if pad_x
            % Pad left
            if nx1 > 1
                new_img(1:nx1-1,ny1:ny2) = repmat(old_img(1,:),nx1-1,1);
            end
            % Pad right
            if nx2 < x
                new_img(nx2+1:end,ny1:ny2) = repmat(old_img(end,:),x-nx2,1);
            end
        end

        if pad_y
            % Pad top
            if ny1 > 1
                new_img(nx1:nx2,1:ny1-1) = repmat(old_img(:,1),1,ny1-1);
            end
            % Pad bottom
            if ny2 < y
                new_img(nx1:nx2,ny2+1:end) = repmat(old_img(:,end),1,y-ny2);
            end
        end
    end
    
    % Store image
    new_stack(:,:,i) = new_img;
end


    


