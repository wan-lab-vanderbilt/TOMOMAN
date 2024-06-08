%% Inputs

tomolist_name = '/fs/pool/pool-sagar/Sagar/Depositions/arctis/yeast/empiar/data/tomoman_minimal_project/tomolist.mat';
star_name = '/fs/pool/pool-briggs-scratch/sagar/yeast_arctis/tomodrgn/job126_fromM_119k_bin1_fix_sel32_ind0.star';

newstar_suffix = '80S_bin1_cryoDRGN-ET_clean_tomo_';
%% Initialize
star = stopgap_star_read(star_name);
load(tomolist_name)

%% get miccrograph names
[~,tnamelist,~] = cellfun(@fileparts,{star.rlnMicrographName},'UniformOutput',false);

%% create thickness subset
for i=1:numel(tomolist)
    [~,tomoname,~] = fileparts({tomolist(i).stack_name});
    if ismember(tomoname,tnamelist)

        %% find subset in star
        starndx = strncmp(tomoname,tnamelist,numel(tomoname));
        metadata_dir = [tomolist(i).stack_dir '/metadata/'];
        if exist(metadata_dir,'dir')
            disp(['Metadata directory: ' metadata_dir ' exists!! will continue']);
        else 
            mkdir(metadata_dir);
        end
        particle_metadir = [metadata_dir '/particles/'];
        if exist(particle_metadir,'dir')
            disp(['Particle Metadata directory: ' particle_metadir ' exists!! will continue']);
        else 
            mkdir(particle_metadir);
        end
        newstar_name = [particle_metadir newstar_suffix num2str(tomolist(i).tomo_num) '.star'];
        newstar = star(starndx);
        %remove fields
        newstar = rmfield(newstar,{'rlnDetectorPixelSize','rlnCtfImage','rlnImageName','rlnMicrographName','rlnMagnification'});
        %add fields
        rep_val = numel(newstar);
        tomoname = repmat({tomoname},[rep_val,1]);
        tomonum = repmat(num2cell(single(tomolist(i).tomo_num)),[rep_val,1]);
        [newstar.('rlnTomoName')] = tomoname{:};
        [newstar.('rlnTomoNumber')] = tomonum{:};
        % Write star
        stopgap_star_write(newstar,newstar_name);
        disp(['Wrote metadata for ' num2str(numel(newstar)) ' as star : ' newstar_name]);
    end
end

