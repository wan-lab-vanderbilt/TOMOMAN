function p = tm_novactf_prepare_motl(p,tomo_row)
%% will_novactf_prepare_motl
% Read in motive list and parse positions.
%
% WW 07-2022

%% Check check
if nargin == 1
    tomo_row = 7;
end

%% Calculate mean Z

% Parse extension
[~,~,ext] = fileparts(p.motl_name);

switch ext
    
    % AV3-style motivelist
    case '.em'
        allmotl = tom_emread(p.motl_name); allmotl = allmotl.Value;
        tomo_idx = allmotl(tomo_row,:);
        z = (allmotl(10,:) + allmotl(13,:)).*p.motl_binning;
        
        
    % stopgap .star
    case '.star'
        allmotl = sg_motl_read(p.motl_name);
        tomo_idx = [allmotl.tomo_num];
        z = ([allmotl.orig_z] + [allmotl.z_shift]).*p.motl_binning;
        
end

% Parse tomogram numbers
tomos = unique(tomo_idx);
n_tomos = numel(tomos);

% Calculate mean Z per tomogram
p.mean_z = zeros(2,n_tomos);
p.mean_z(1,:) = tomos;
for i = 1:n_tomos
    
    % Tomogram indices
    idx = tomo_idx == tomos(i);
    
    % Mean Z
    p.mean_z(2,i) = mean(z(idx));
end


    
