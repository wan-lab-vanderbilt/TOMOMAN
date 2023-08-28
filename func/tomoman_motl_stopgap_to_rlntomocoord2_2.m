function rlntomocoord2_2 = tomoman_motl_stopgap_to_rlntomocoord2_2(motl,pixelsize)
%% sg_motl_dynamo_to_stopgap
% Convert a stopgap .star motivelist to a Relion formated star file for particles in a SINGLE tomogram.
%
% Angular conversions follow the convention after dynamo 0.8, as defined in
% dynamo__motl2table.m
%
% WW 02-2019

%% Convert!!!
n_motls = numel(motl);

% Initialize table
rlntomocoord2_2 = tomoman_initialize_rlntomocoord2_2(n_motls);

% Convert STOPGAP angles to RELION angles
sgangle_array = [[motl.phi];[motl.psi];[motl.the]]';
sgangle_cell = num2cell(sgangle_array,2);
rlnangles_cell = cellfun(@tomoman_angles_sg2relion,sgangle_cell,'UniformOutput',false);
rlnangles_array = cell2mat(rlnangles_cell);


% Fill table with motivelist parameters
rlntomocoord2_2 = tomoman_rlntomocoord2_2_fill_field(rlntomocoord2_2,'rlnCoordinateX',[motl.orig_x]);
rlntomocoord2_2 = tomoman_rlntomocoord2_2_fill_field(rlntomocoord2_2,'rlnCoordinateY',[motl.orig_y]);
rlntomocoord2_2 = tomoman_rlntomocoord2_2_fill_field(rlntomocoord2_2,'rlnCoordinateZ',[motl.orig_z]);
rlntomocoord2_2 = tomoman_rlntomocoord2_2_fill_field(rlntomocoord2_2,'rlnOriginXAngst',[motl.x_shift].*pixelsize);
rlntomocoord2_2 = tomoman_rlntomocoord2_2_fill_field(rlntomocoord2_2,'rlnOriginYAngst',[motl.y_shift].*pixelsize);
rlntomocoord2_2 = tomoman_rlntomocoord2_2_fill_field(rlntomocoord2_2,'rlnOriginZAngst',[motl.z_shift].*pixelsize);
rlntomocoord2_2 = tomoman_rlntomocoord2_2_fill_field(rlntomocoord2_2,'rlnAngleRot',rlnangles_array(:,1));
rlntomocoord2_2 = tomoman_rlntomocoord2_2_fill_field(rlntomocoord2_2,'rlnAngleTilt',rlnangles_array(:,2));
rlntomocoord2_2 = tomoman_rlntomocoord2_2_fill_field(rlntomocoord2_2,'rlnAnglePsi',rlnangles_array(:,3));








% 
%     
% 
% 
% 
% 
% 
