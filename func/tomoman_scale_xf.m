function tomoman_scale_xf(xf_file_in,xf_file_out,scale_factor)

%% debug 

% %xf_file_in = '/fs/gpfs41/lv06/fileset01/pool/pool-visprot/Sagar/project_arctis/chlamy/tomo/all/15042022_BrnoKrios_Arctis_grid9_Position_47/15042022_BrnoKrios_Arctis_grid9_Position_47-dose_filt.xf';
% scale_factor = 4;
% xf_file_out=xf_file_in;

%% Actual
xf_in = dlmread(xf_file_in);

% scale shifts (Rotations are scale invarient)
xf_in(:,5) = xf_in(:,5).*scale_factor;
xf_in(:,6) = xf_in(:,6).*scale_factor;

% write xf file
dlmwrite(xf_file_out,xf_in,'delimiter','\t','precision','%10.7f');

end
