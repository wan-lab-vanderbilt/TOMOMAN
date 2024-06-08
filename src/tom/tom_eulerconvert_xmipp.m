function [rotmatrix,euler_out] = tom_eulerconvert_xmipp(rot, tilt, psi,flag)
%TOM_EULERCONVERT_XMIPP converts euler angles from xmipp to the TOM
%convention and inverse
%
%   [rotmatrix,euler_out] = tom_eulerconvert_xmipp(rot, tilt, psi)
%   
%
%PARAMETERS
%
%  INPUT
%   rot                 input xmipp angle rot (or phi on tom2xmipp)
%   tilt                input xmipp angle tilt (or psi on tom2xmipp)
%   psi                 input xmipp angle psi (or theta on tom2xmipp)
%   flag                (xmipp2tom) flag for direction use tom2xmipp for inverse transform 
%   
%  OUTPUT
%
%   rotmatrix           resulting rotation matrix
%   euler_out           resulting Euler angles 
%                       on tom2xmipp its euler(1)=rot; 
%                                        euler(2)=tilt; 
%                                        euler(3)=psi;
%
%
%EXAMPLE
%   [rotmatrix,euler_out] = tom_eulerconvert_xmipp(10,20,30);
%
%
%
%  %unit test: rot_mat should be the same
%   
%  [rot_mat_tom euler_tom]=tom_eulerconvert_xmipp(10,20,30); %xmipp2tom
%  [rot_mat_xmipp euler_out]=tom_eulerconvert_xmipp(euler_tom(1),euler_tom(2),euler_tom(3),'tom2xmipp'); %tom2xmipp
%  rot_mat_tom-rot_mat_xmipp
%
%  %check tom2xmipp
%       
%   
%   ang_tom=[255 -83 -85];
%   cyl=tom_cylindermask(ones(64,64,64),10);  
%   tom_spiderwrite('my_cyl.vol',cyl);
%    
%   [rotmatrix,ang_xmipp] = tom_eulerconvert_xmipp(ang_tom(1),ang_tom(2),ang_tom(3),'tom2xmipp');       
%
%   cyl_rot_tom=tom_rotate(cyl,ang_tom); 
%   unix(['xmipp_rotate -i my_cyl.vol -euler ' num2str(ang_xmipp) ' -o my_cyl_xmipp_rot.vol']);   
%   cyl_rot_xmipp=tom_spiderread('my_cyl_xmipp_rot.vol');
%      
%   figure; tom_dspcub(cyl_rot_tom); set(gcf,'Name','ROT-TOM');
%   figure; tom_dspcub(cyl_rot_xmipp); set(gcf,'Name','ROT-XMIPP');
%   figure; tom_dspcub(tom_norm(cyl_rot_xmipp.Value,'mean0+1std')-tom_norm(cyl_rot_tom,'mean0+1std')); set(gcf,'Name','ROT-TOM-ROT-XMIPP');
%
%   For more information about 3d Euler rotation visit:
%   wiki -> Definitions -> Overview 3d Euler rotation -> 
%   Rotation matrices, zxz and zyz conventions
%   (ps: rotmatrix indices are transposed !! have fun)
%
%REFERENCES
%
%SEE ALSO
%   tom_sum_rotation
%
%   created by AK 04/05/07
%   updated by FB  
%
%   Nickell et al., 'TOM software toolbox: acquisition and analysis for electron tomography',
%   Journal of Structural Biology, 149 (2005), 227-234.
%
%   Copyright (c) 2004-2007
%   TOM toolbox for Electron Tomography
%   Max-Planck-Institute of Biochemistry
%   Dept. Molecular Structural Biology
%   82152 Martinsried, Germany
%   http://www.biochem.mpg.de/tom



if (nargin < 4)
    flag='xmipp2tom';
end;

if (strcmp(flag,'xmipp2tom'))
    
    rot2=-psi.*pi./180;
    tilt=-tilt.*pi./180;
    psi=-rot.*pi./180;
    rot = rot2;
    
    rotmatrix = [cos(rot) -sin(rot) 0; sin(rot) cos(rot) 0; 0 0 1] * ...
                [cos(tilt) 0 sin(tilt); 0 1 0; -sin(tilt) 0 cos(tilt)] * ...
                [cos(psi) -sin(psi) 0; sin(psi) cos(psi) 0; 0 0 1];
    
    %extract euler angles
    euler_out(1)=atan2(rotmatrix(3,1),rotmatrix(3,2));
    euler_out(2)=atan2(rotmatrix(1,3),-rotmatrix(2,3));
    euler_out(3)=acos(rotmatrix(3,3));
    euler_out=euler_out.*180./pi;
    
    if -(rotmatrix(3,3)-1)<10e-8
        euler_out(3)=0;
        euler_out(2)=0;
        euler_out(1)=atan2(rotmatrix(2,1),rotmatrix(1,1)).*180./pi;
    end
    
    
else
  
    tom_phi=rot.*pi./180;
    tom_psi=tilt.*pi./180;
    tom_theta=psi.*pi./180;
    
    rotmatrix=[cos(tom_psi) -sin(tom_psi) 0; sin(tom_psi) cos(tom_psi) 0; 0 0 1]*...
              [1 0 0; 0 cos(tom_theta) -sin(tom_theta); 0 sin(tom_theta) cos(tom_theta)]*...
              [cos(tom_phi) -sin(tom_phi) 0; sin(tom_phi) cos(tom_phi) 0; 0 0 1];
    
    if -(rotmatrix(3,3)-1)<10e-8
        euler_out(1)=0;
        euler_out(2)=0;
        euler_out(3)=atan2(rotmatrix(1,2),rotmatrix(1,1))*180./pi;
    else
        euler_out(1)=atan2(rotmatrix(3,2),rotmatrix(3,1))*180./pi;
        euler_out(2)=acos(rotmatrix(3,3))*180./pi;
        euler_out(3)=atan2(rotmatrix(2,3),-rotmatrix(1,3))*180./pi; 
    end;
    
    
end;







