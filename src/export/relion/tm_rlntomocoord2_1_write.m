function tomoman_rlntomocoord2_1_write(rlntomocoord2_1_name,rlntomocoord2_1)
%% sg_rlntomocoord2_1_write
%
% WW 05-2018

% rootdir = './';
% rlntomocoord2_1_name = 'test_rlntomocoord2_1.star';


%% Determine formating

% Parse fields
fields = fieldnames(rlntomocoord2_1);
n_rlntomocoord2_1 = numel(rlntomocoord2_1);

% Get field types
rlntomocoord2_1_fields = tm_get_rlntomocoord2_1_fields;
n_fields = size(rlntomocoord2_1_fields,1);
if size(fields,1) ~= n_fields
    error('ACHTUNG!!! Input struct has incorrect number of fields!!!');
end

% Check sorting
rlntomocoord2_1 = orderfields(rlntomocoord2_1,rlntomocoord2_1_fields(:,1));

% Write star file
stopgap_star_write(rlntomocoord2_1,rlntomocoord2_1_name,'particles',[],4,2)


disp([rlntomocoord2_1_name,' written!!!1!']);

