function d_off = tm_tiltctf_calculate_doff_xtilt(grid,tiltangle,xtiltangle,pixelsize)
%TOMOMAN_TILTCTF_CALCULATE_DOFF_XTILT Summary of this function goes here
%   Detailed explanation goes here
%% debug
% tiltangle = 60;
% xtiltangle = 2;
% pixelsize = 1.79;
% 
% grid = [928,464,128;928,464,128];
% 
% n_points = size(grid,2)


% % Calculate defocus offsets (in microns) (without xtilt --> will's
% % implementation)
% d_off = (grid(1,:)'*(pixelsize/10000)).*tand(tiltangle);


%% calculate

normal = [0;0;1];

% Calculate rotation matrix (Keeping them separate for now, must combine to
% one rmat)
q = sg_axisangle2quaternion([0,1,0],tiltangle);
rmat = sg_quaternion2matrix(q);

q_xtilt = sg_axisangle2quaternion([1,0,0],xtiltangle);
rmat_xtilt = sg_quaternion2matrix(q_xtilt);



% Rotate positions
xtilt_normal = rmat_xtilt*normal;
new_normal = rmat*xtilt_normal;


% dist = dot(new_normal,grid);
% 
% proj = grid - dist.*new_normal;
% 
% d_off = proj*(pixelsize/10000);

d_off  = ((grid(1,:).*new_normal(1) + grid(2,:).*new_normal(2))/new_normal(3))*(pixelsize/10000);

end

