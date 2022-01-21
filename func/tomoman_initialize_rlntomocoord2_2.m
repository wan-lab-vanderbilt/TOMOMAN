function tomocoords = tomoman_initialize_rlntomocoord2_2(n_motls,tomocoords_fields)
%% intialize_motl
% Intitialize a new stopgap motivelist with empty values.
%
% WW 05-2018

%% Generate motl

if nargin == 1
    tomocoords_fields = tomoman_get_rlntomocoord2_2_fields;
end

% Initalize struct array
for i = 1:size(tomocoords_fields,1)   
    tomocoords(n_motls).(tomocoords_fields{i,1}) = [];
end
tomocoords = tomocoords';

