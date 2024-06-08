function thickness = tm_measure_thickness(tomo,boundary)
%% sg_tm_create_boundary_mask
% Create a boundary mask for a tomogram. The boundary mask is a mask to
% defined the boundaries of the specimen, assuming a slab geometry. The
% required inputs are the tomogram to be masked and a boundary file. 
%
% The boundary file is a plain-text file containing points that define the
% slab geometry in sets of 4; the first two points define the top of the
% slab while the third and fourth point define the bottom of the slab.
% Arbitrary sets of points along the slab are allowed, though 3 sets are
% sufficient.
% 
% The boundary file can be easily produced using 3DMOD, viewing down the
% XZ-planes. In this case, the IMOD model file can be converted to
% plain-text using IMOD's model2point function. 
%
% The xy_border is a parameter for masking the edge of the tomograms. The
% xy_border value is the number of voxels to mask on each edge.
%
%
% This function uses the "affine_fit.m" function 
%
% WW 02-2019

% % % % % DEBUG
% tomo = '/fs/pool/pool-plitzko/will_wan/jonathan/Good_Tomo_OE_20180814_tomo_14/links/14.rec';
% boundary = '14_boundary.txt';

%% Check check

% Check for tomogram
if ischar(tomo)
    tomo = sg_mrcread(tomo);
end
dims = size(tomo);

% Check for boundary
if ischar(boundary)
    boundary = dlmread(boundary);
end

% Check for border
if nargin == 2
    xy_border = 0;
end



%% Parse top and bottom points

% Number of points
n_points = size(boundary,1);
n_sets = n_points/4;
if mod(n_points,4)
    error('ACHTUNG!!! Input boundary coordinates must be supplied in sets of 4!!!');
end

% Intitialize array for top and bottom points
top = zeros(n_sets*2,3);
bottom = zeros(n_sets*2,3);

% Fill arrays
for i = 1:n_sets
    top((2*(i-1))+1,:) = boundary((4*(i-1))+1,:);
    top((2*(i-1))+2,:) = boundary((4*(i-1))+2,:);
    bottom((2*(i-1))+1,:) = boundary((4*(i-1))+3,:);
    bottom((2*(i-1))+2,:) = boundary((4*(i-1))+4,:);
end

% check for top is top!

if median(top(:,3)) < median(bottom(:,3))
    warning('Top is inverted!! Top is not Top!!!');
    [top,bottom] = deal(bottom, top);
end
%% Generate boundaries

% Calculate 2D grids
[X,Y] = ndgrid(1:dims(1),1:dims(2));

% Fit ponts
[n_1,~,p_1] = affine_fit(top);
[n_2,~,p_2] = affine_fit(bottom);

% Calculate 
Z_top =  - (n_1(1)/n_1(3)*X+n_1(2)/n_1(3)*Y-dot(n_1,p_1)/n_1(3));
Z_bottom =  - (n_2(1)/n_2(3)*X+n_2(2)/n_2(3)*Y-dot(n_2,p_2)/n_2(3));


thickness = median(Z_top(:) - Z_bottom(:));
% 
% %failsafe
% ndx = Z_top > dims(3);
% Z_top(ndx) =  dims(3);
% 
% ndx = Z_bottom < 1;
% Z_bottom(ndx) = 1;
% 

end


function [n,V,p] = affine_fit(X)
    %Computes the plane that fits best (lest square of the normal distance
    %to the plane) a set of sample points.
    %INPUTS:
    %
    %X: a N by 3 matrix where each line is a sample point
    %
    %OUTPUTS:
    %
    %n : a unit (column) vector normal to the plane
    %V : a 3 by 2 matrix. The columns of V form an orthonormal basis of the
    %plane
    %p : a point belonging to the plane
    %
    %NB: this code actually works in any dimension (2,3,4,...)
    %Author: Adrien Leygue
    %Date: August 30 2013
    
    %the mean of the samples belongs to the plane
    p = mean(X,1);
    
    %The samples are reduced:
    R = bsxfun(@minus,X,p);
    %Computation of the principal directions if the samples cloud
    [V,D] = eig(R'*R);
    %Extract the output from the eigenvectors
    n = V(:,1);
    V = V(:,2:end);
end

