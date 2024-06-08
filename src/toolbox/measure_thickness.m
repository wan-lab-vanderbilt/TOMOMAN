% Inputs
tomo_dir = '/fs/pool/pool-sagar/Sagar/Projects/project_arctis/yeast/tm/fas/sg_novactf_bin8/tomos/';
padding = 10;
thicknessfile = 'thickness.txt';

%% Calculate masks
files = dir([tomo_dir '*.mrc']);

script = fopen(thicknessfile,'w');


for i=1:numel(files)
    if isfile([tomo_dir, files(i).name])
        [~,name,~]=fileparts(files(i).name);
        disp(['Measuring thickness for for ', files(i).name ])
        boundaryfile = [tomo_dir,name,'_boundary.txt'];
        if isfile(boundaryfile)
            thickness = tm_measure_thickness([tomo_dir, files(i).name],boundaryfile);
            fprintf(script,[name '\t' num2str(thickness) '\n']);
        else
            warning([boundaryfile ' not found!!!'])
        end
    end
end

fclose(script);    
