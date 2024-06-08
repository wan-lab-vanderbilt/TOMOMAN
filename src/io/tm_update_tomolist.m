function new_tomolist = tm_update_tomolist(old_tomolist)
%% tm_update_tomolist
% Occasionally the format of the tomolist is udpated to add new fields. 
% This function reads in old tomolists and updates them by adding the new 
% fields. 
%
% WW 08-2022

%% Update tomolist

% Determine number of tomograms
n_tomos = numel(old_tomolist);

% Parse fields
fields = fieldnames(old_tomolist);
n_fields = numel(fields);

% Generate new tomolist
new_tomolist = tm_generate_tomolist(n_tomos);

% Fill fields
for i = 1:n_tomos
    for j = 1:n_fields
        new_tomolist(i).(fields{j}) = old_tomolist(i).(fields{j});
    end
end





