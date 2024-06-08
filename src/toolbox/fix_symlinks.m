 
tomolist = '/fs/pool/pool-sagar/Sagar/Depositions/arctis/yeast/empiar/data/tomoman_minimal_project/tomolist.mat';
raw_data_dir = '/fs/pool/pool-sagar/Sagar/Data/fromTFS/Arctis/yeast/';
load(tomolist);

n_tomos = numel(tomolist);

for i = 1:n_tomos
    frames_date = extractBetween(tomolist(i).mdoc_name,'ay','_');
    raw_frame_dir = [raw_data_dir,frames_date{:},'/frames/'];

    n_tilts = numel(tomolist(i).frame_names);
    tomo_dir = tomolist(i).stack_dir;
    
    frame_names = tomolist(i).frame_names;

    for j = 1:n_tilts
        try
            system(['cp ' raw_frame_dir frame_names{j} ' ' tomo_dir 'frames/' frame_names{j}]);
        catch
            warning(['ACHTUNG!!! Error moving ',raw_frame_dir,frame_names{j}]);
        end
        
    end   
    disp(['Done copying ' tomo_dir]);
end

