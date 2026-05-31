function tm_novactf_flip_hand(def_dir,n_stacks)
%% tm_novactf_flip_hand
% NovaCTF assumes a defocus hand of -1. If the defocus hand is +1, the
% defocus offsets from the center needs to be flipped. 
%
% This script reads the ctfphaseflip file from CTF estimation, subtracts
% them from the novaCTF defocus files, flips the shifts, and adds the
% central CTF. 
%
% WW 01-2026

% % % % DEBUG
% def_dir = './';
% n_stacks = 29;


%% Initialize

% Read central file
cen_def = readmatrix([def_dir,'ctfphaseflip.txt']);

% Parse tilts
tilts = cen_def(:,3);

%% Flip defocus shifts

for i = 1:n_stacks
    
    % Read parallel file
    temp_def = readmatrix([def_dir,'ctfphaseflip.txt_',num2str(i-1)],'FileType','text');
    
    % Flipped defocii
    flip_defocii = -(temp_def(:,5:6) - cen_def(:,5:6)) + cen_def(:,5:6);
    
    
    % Write new file
    name = [def_dir,'ctfphaseflip.txt_',num2str(i-1)];
    tm_write_ctfphaseflip_file(name,tilts,cat(2,flip_defocii./1000,temp_def(:,7)));
    
    
end




