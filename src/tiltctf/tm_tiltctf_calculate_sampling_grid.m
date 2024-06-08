function [grid_points,d_offsets] = tm_tiltctf_calculate_sampling_grid(image_size, pixelsize, ps_size, def_tol, xf, tilts,xaxistilt)
%% tomoman_tiltctf_calculate_sampling_grid
% A function to calculate a sampling grid across tilted images. The Y-step
% on the grid is half the power spectrum size while the X-step is
% determined from a given defocus tolerance. The minimum X-step is also
% half the power spectrum size. 
%
% The rectangular grid is inverse rotated using an IMOD transform file in
% order to map positions in the aligned stack back to the unaligned stack. 
% Grid points are thresholded to ensure that full images can be extracted.  
%
% An array containig defocus offsets is also returned.
%
% WW 07-2018


%% Intialize

% Check image size
if numel(image_size) == 1
    image_size = [image_size;image_size];
elseif size(image_size,1) == 1
    image_size = image_size';
end

% Number of tilts
n_tilts = size(tilts,1);
if size(xf,1) ~= n_tilts
    error('ACHTUNG!!!! Tilt angles and number of transforms do not match!!!1!');
end

% Calcualte Y-step as half ps_size
y_step = ps_size/2;

% Calculate Y-grid
[y_points,n_y_points] = determine_1d_gridpoints(image_size(2),y_step);

% Image centers
img_cen = floor(image_size./2)+1;

% Grid cells
grid_cell = cell(n_tilts,1);
d_off_cell = cell(n_tilts,1);

% Boundaries
min_x = floor(ps_size/2)+1;
max_x = image_size(1) - (ps_size-min_x);
min_y = floor(ps_size/2)+1;
max_y = image_size(2) - (ps_size-min_y);

% Convert defocus tolerance to pixels
def_tol_pix = (def_tol*10000)/pixelsize;




%% Calculate unaligned grid points


% Transform gridpoints (inverse of xf transform)
for i = 1:n_tilts
    
    % 1D grid points
    x_step = abs(floor(def_tol_pix/tand(tilts(i))));
    if x_step > y_step
        x_step = y_step;
    end
    [x_points,n_x_points] = determine_1d_gridpoints(image_size(1),x_step);
    
    % Calculate XY grids
    x_grid = repmat(x_points',[1,n_y_points]);
    y_grid = repmat(y_points,[n_x_points,1]);
    grid = cat(1,x_grid(:)',y_grid(:)');
    n_points = size(grid,2);
    
    % Calculate defocus offsets (in microns)
    % def = (x_grid(:)'*(pixelsize/10000)).*tand(tilts(i));
    def = tm_tiltctf_calculate_doff_xtilt(grid,tilts(i),xaxistilt,pixelsize);

    
    % Inverse rotation matrix
    rmat = [xf(i,1),xf(i,2);xf(i,3),xf(i,4)]';
    
    % Shifts
    shift = xf(i,5:6)';
    
    % Rotate and shift points
    shift_points = rmat*(grid - repmat(shift,[1,n_points]));

    % New points
    new_points = round(shift_points + repmat(img_cen,[1,n_points]));
    
    % Check for cutoffs
    x_cut = (new_points(1,:) >= min_x) & (new_points(1,:) <= max_x);
    y_cut = (new_points(2,:) >= min_y) & (new_points(2,:) <= max_y);
    cut_idx = x_cut & y_cut;
    np = sum(cut_idx);
    
    % Store points
    grid_cell{i} = cat(1,new_points(:,cut_idx),(ones(1,np).*i));
    d_off_cell{i} = def(cut_idx);

    
end

grid_points = [grid_cell{:}]';
d_offsets = [d_off_cell{:}];
% temp = grid_points;
% temp(:,3) = temp(:,3)-1;
% dlmwrite('grid_points.txt',temp,' ');    
% system('point2model -in grid_points.txt -ou grid_points.mod -sc -ci 8');

end


function [grid_points,n_grid_points] = determine_1d_gridpoints(image_size,step_size)
%% determine_1d_gridpoints
% A function to calcualte a centered 1D grid of points that fit within a
% given image size.
%
% WW 07-2018

% Image center
cen = floor(image_size/2)+1;

% Initial grid
temp_grid = 1:step_size:image_size;

% Find point closest to image center
[~,min_idx] = min(abs(temp_grid-cen));

% Shift to center and return
grid_points = temp_grid - temp_grid(min_idx);
n_grid_points = numel(grid_points);

end