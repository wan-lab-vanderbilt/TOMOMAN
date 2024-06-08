function f_array = tm_frequencyarray(image,pixelsize)

%% tm_frequencyarray
% A function to take a volume and a pixelsize and generate an array with
% Fourier space frequencies. 
%
% WW 12-2015

% % % Debug
% image = zeros(128,128,128);
% pixelsize = 1.78;

% Get size of image
[dimx, dimy, dimz] = size(image);

% Euclidean pixel distances
[x,y,z] = ndgrid(-floor(dimx/2):-floor(dimx/2)+dimx-1,-floor(dimy/2):-floor(dimy/2)+dimy-1,-floor(dimz/2):-floor(dimz/2)+dimz-1);

% Projected reciprocal distance array
rx = x./(dimx*pixelsize);
ry = y./(dimy*pixelsize);
rz = z./(dimz*pixelsize);
f_array = sqrt((rx.^2)+(ry.^2)+(rz.^2));