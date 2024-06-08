clear all


load('/fs/pool/pool-visprot/archival/4empiar/prototyping/data/tomoman_minimal_project/tomolist.mat');
tomostar = tm_generate_tomolist(numel(tomolist));
tomolist = rmfield(tomolist,{'tomo_recons','tomo_recons_algorithm','metadata'});
tomostar = rmfield(tomostar,{'tomo_recons','tomo_recons_algorithm','metadata'});

tomolist_fieldnames = fieldnames(tomolist);


numel(tomolist_fieldnames);
   
tomostar_name = [tomolist(1).root_dir '/tomolist.star'];

for j = 1:numel(tomolist)
    % create star files in the metadata folder 
    metadata_dir = [tomolist(j).stack_dir '/metadata/'];
    if exist(metadata_dir,'dir')
        disp(['Metadata directory: ' metadata_dir ' exists!! will continue']);
    else 
        mkdir(metadata_dir);
    end
    tomolist_metadir = [metadata_dir '/tomolist/'];
    if exist(tomolist_metadir,'dir')
        disp(['Metadata directory: ' tomolist_metadir ' exists!! will continue']);
    else 
        mkdir(tomolist_metadir);
    end        

    for i=1:numel(tomolist_fieldnames)
        if ischar(tomolist(1).(tomolist_fieldnames{i}))    
            tomostar(j).(tomolist_fieldnames{i}) = tomolist(j).(tomolist_fieldnames{i});
        elseif islogical(tomostar(1).(tomolist_fieldnames{i}))
            tomostar(j).(tomolist_fieldnames{i}) = logical(tomolist(j).(tomolist_fieldnames{i})); 
        elseif (isnumeric(tomolist(1).(tomolist_fieldnames{i}))) & (numel(tomolist(1).(tomolist_fieldnames{i})) < 2)
                tomostar(j).(tomolist_fieldnames{i}) = tomolist(j).(tomolist_fieldnames{i});
        else
            switch tomolist_fieldnames{i}
                case 'frame_names' 
                    star_name = [tomolist_metadir 'frame_names.star'];
                    for k = 1:numel(tomolist(j).('frame_names'))
                        frames_star(k).('frame_names') = tomolist(j).('frame_names'){k};
                    end
                    stopgap_star_write(frames_star,star_name,'tomolist_frame_names');
                    tomostar(j).(tomolist_fieldnames{i}) = star_name;
                case 'ctf_parameters'
                    star_name = [tomolist_metadir 'ctf_parameters.star'];
                    ctf_param_star = tomolist(j).('ctf_parameters');
                    stopgap_star_write(ctf_param_star,star_name,'tomolist_ctf_parameters');
                    tomostar(j).(tomolist_fieldnames{i}) = star_name;
                case 'determined_defocii'
                    star_name = [tomolist_metadir 'determined_defocii.star'];
                    for k = 1:size(tomolist(j).('determined_defocii'),1)
                        defocii_star(k).('defocus1') = tomolist(j).('determined_defocii')(k,1);
                        defocii_star(k).('defocus2') = tomolist(j).('determined_defocii')(k,2);
                        defocii_star(k).('ast') = tomolist(j).('determined_defocii')(k,3);
                    end
                    stopgap_star_write(ctf_param_star,star_name,'tomolist_determined_defocii');
                    tomostar(j).(tomolist_fieldnames{i}) = star_name;
                case {'tomo_recons_algorithm','metadata'}
                    disp('skipping...')
                    continue
                otherwise
                    star_name = [tomolist_metadir tomolist_fieldnames{i} '.star'];
                    data = repmat(num2cell(double([tomolist(j).(tomolist_fieldnames{i})])),[1,1]);
                    star = cell2struct(repmat({[]},[numel(data),1]),tomolist_fieldnames{i},2)';
                    [star.(tomolist_fieldnames{i})] = data{:};
                    stopgap_star_write(star,star_name,['tomolist_' tomolist_fieldnames{i}]);
                    tomostar(j).(tomolist_fieldnames{i}) = star_name;
            end
        end
    end
end

% logic for removed tilts is broken bcs it can happen that it's empty!!
% make a case based logic for all 44 fields!!!!(TODO)

stopgap_star_write(tomostar,tomostar_name,'tomoman_tomolist','tomoman_')
        



   