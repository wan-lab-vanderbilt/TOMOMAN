% Inputs
tomo_dir = '/ptmp/skhavnek/pool-chlamy/common/reconstructions/sirt15_bin8/';
thicknessfile = 'cenmass_bin1.txt';
binning = 8; 

%% Calculate masks
files = dir([tomo_dir '*.rec']);

script = fopen([tomo_dir,thicknessfile],'w');


for i=1:numel(files)
    if isfile([tomo_dir, files(i).name])
        [~,name,~]=fileparts(files(i).name);
        disp(['Measuring thickness for for ', files(i).name ])
        boundaryfile = [tomo_dir,name,'_boundary.txt'];
        
        if isfile(boundaryfile)
            s=dir(boundaryfile);
            if s.bytes ~= 0 
                cenmass = tm_cenmass_from_boundary([tomo_dir, files(i).name],boundaryfile);
                fprintf(script,[name '\t' num2str(cenmass.*binning) '\n']);
            end
        else
            warning([boundaryfile ' not found!!!'])
        end
    end
end

fclose(script);    
