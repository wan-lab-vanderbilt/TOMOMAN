function tomoman_rlntomocoord2_2_write(rlntomocoord2_2_name,rlntomocoord2_2)
%% sg_rlntomocoord2_2_write
%
% WW 05-2018

% rootdir = './';
% rlntomocoord2_2_name = 'test_rlntomocoord2_2.star';


%% Determine formating

% Parse fields
fields = fieldnames(rlntomocoord2_2);
n_rlntomocoord2_2 = numel(rlntomocoord2_2);

% Get field types
rlntomocoord2_2_fields = tomoman_get_rlntomocoord2_2_fields;
n_fields = size(rlntomocoord2_2_fields,1);
if size(fields,1) ~= n_fields
    error('ACHTUNG!!! Input struct has incorrect number of fields!!!');
end

% Check sorting
rlntomocoord2_2 = orderfields(rlntomocoord2_2,rlntomocoord2_2_fields(:,1));

% Write star file
stopgap_star_write(rlntomocoord2_2,rlntomocoord2_2_name,'particle_coords',[],4,2)


disp([rlntomocoord2_2_name,' written!!!1!']);

