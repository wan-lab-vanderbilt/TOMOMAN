function tomoman_rlntomostar_write(rlntomostar_name,rlntomostar)
%% sg_rlntomostar_write
%
% WW 05-2018

% rootdir = './';
% rlntomostar_name = 'test_rlntomostar.star';


%% Determine formating

% Parse fields
fields = fieldnames(rlntomostar);
n_rlntomostars = numel(rlntomostar);

% Get field types
rlntomostar_fields = tomoman_get_rlntomostar_fields;
n_fields = size(rlntomostar_fields,1);
if size(fields,1) ~= n_fields
    error('ACHTUNG!!! Input struct has incorrect number of fields!!!');
end

% Check sorting
rlntomostar = orderfields(rlntomostar,rlntomostar_fields(:,1));

% Write star file
stopgap_star_write(rlntomostar,rlntomostar_name,'tomostar',[],4,2)


disp([rlntomostar_name,' written!!!1!']);

