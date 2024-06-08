%% Inputs

tomolist_name = '/fs/pool/pool-visprot/archival/4empiar/prototyping/data/tomoman_minimal_project//tomolist.mat';
motl_name = '/fs/pool/pool-visprot/Sagar/project_arctis/chlamy/stopgap/empiar_prototype/rubisco/bin4/lists/allmotl_1_bin1.star';

newstar_suffix = 'rubisco_bin1_tomo_';

write_rln_star =  1; % Whether to write out particle metadata in relion format as well!! 0 = no, 1 = yes.

%% Initialize
motl = sg_motl_read(motl_name);
load(tomolist_name)

%% get miccrograph names
% [~,tnamelist,~] = cellfun(@fileparts,{star.rlnMicrographName},'UniformOutput',false);
tnumlist = [motl.tomo_num];


%% create thickness subset
for i=1:numel(tomolist)
    tomo_num = tomolist(i).tomo_num;
    [~,tomoname,~] = fileparts({tomolist(i).stack_name});

    if ismember(tomo_num,tnumlist)

        %% find subset in star
        motlndx = tnumlist == tomo_num;
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
        newmotl_name = [particle_metadir newstar_suffix num2str(tomolist(i).tomo_num) '.star'];
        newmotl = motl(motlndx);
%         %remove fields
%         newstar = rmfield(newstar,{'rlnDetectorPixelSize','rlnCtfImage','rlnImageName','rlnMicrographName','rlnMagnification'});
%         %add fields
%         rep_val = numel(newstar);
%         tomoname = repmat({tomoname},[rep_val,1]);
%         tomonum = repmat(num2cell(single(tomolist(i).tomo_num)),[rep_val,1]);
%         [newstar.('rlnTomoName')] = tomoname{:};
%         [newstar.('rlnTomoNumber')] = tomonum{:};
        % Write star
        sg_motl_write(newmotl_name,newmotl);
        disp(['Wrote metadata for ' num2str(numel(newmotl)) ' as star : ' newmotl_name]);

        if write_rln_star
            rlnstar_name = [particle_metadir '/rln_' newstar_suffix num2str(tomolist(i).tomo_num) '.star'];
            tm_sgmotl2relion3(newmotl, tomolist(i), rlnstar_name, tomolist(i).pixelsize);
            %remove fields
            rlnstar = stopgap_star_read(rlnstar_name);
            rlnstar = rmfield(rlnstar,{'rlnDetectorPixelSize','rlnCtfImage','rlnImageName','rlnMicrographName','rlnMagnification'});
            %add fields
            rep_val = numel(rlnstar);
            tomoname = repmat({tomoname},[rep_val,1]);
            tomonum = repmat(num2cell(single(tomolist(i).tomo_num)),[rep_val,1]);
            [rlnstar.('rlnTomoName')] = tomoname{:};
            [rlnstar.('rlnTomoNumber')] = tomonum{:};
            % Write star
            stopgap_star_write(rlnstar,rlnstar_name);
            disp(['Wrote metadata for ' num2str(numel(rlnstar)) ' as star : ' rlnstar_name]);
        end

    end
end

