function tomolist = tm_store_ctf_param(tomolist,ctf_param,ctf_determination_method)
%% tm_store_ctf_param
% A function to update a tomolist and store determined CTF parameters.
%
% WW 07-2018

%% Store parameters

% Update tomolist
tomolist.ctf_determined = true;
tomolist.ctf_determination_algorithm = ctf_determination_method;

%  Number of tilts
n_tilts = numel(ctf_param);

% Initialize array
if isfield(ctf_param,'pshift')
    det_ctf = zeros(n_tilts,4);
    det_ctf(:,4) = [ctf_param.pshift];
else
    det_ctf = zeros(n_tilts,3);
end

% Store parameters
det_ctf(:,1) = [ctf_param.defocus_1];
det_ctf(:,2) = [ctf_param.defocus_2];
det_ctf(:,3) = [ctf_param.astig_angle];

% Save to tomolist
tomolist.determined_defocii = det_ctf;

