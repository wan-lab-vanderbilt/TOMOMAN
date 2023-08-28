function relion_eulers = tomoman_angles_sg2relion(sg_euler)

%sg_eulers = [phi, psi, the];

phi = sg_euler(1);
psi = sg_euler(2);
the = sg_euler(3);

tom_phi=phi.*pi./180;
tom_psi=psi.*pi./180;
tom_theta=the.*pi./180;

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
end

relion_eulers = euler_out;
