function tomoman_rescale_imodxf(input_xf,output_xf,scale_factor)

% %debug
% input_xf = '/fs/pool/pool-plitzko/Sagar/Projects/project_tomo200k/invitro/apof_nnp/relion4/run_1/tomograms/ApoF_glaciosNNP_21122021_Position_43/ApoF_glaciosNNP_21122021_Position_43.xf';
% output_xf = '/fs/pool/pool-plitzko/Sagar/Projects/project_tomo200k/invitro/apof_nnp/relion4/run_1/tomograms/ApoF_glaciosNNP_21122021_Position_43/ApoF_glaciosNNP_21122021_Position_43_8k.xf';
% scale_factor = 2;
% 
% Read Xf file

inxf = dlmread(input_xf);

% newxf = inxf;
inxf(:,5:6) = inxf(:,5:6).*scale_factor;

dlmwrite(output_xf,inxf,'delimiter','\t','precision','%10.7f');


end