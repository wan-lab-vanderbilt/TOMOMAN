function [temptomostar,tempcoords] = tomoman_export2relion4_import_tomogram(t,motl,relion4dir,imod_stack)

% Parse stack name (always non dose weighted!!!)
[~,rlnTomoName,ext] = fileparts(t.stack_name);
temptomostar.rlnTomoName = rlnTomoName;

% Parse Imo/AreTomo alignment names
switch imod_stack
    case 'unfiltered'
        [~,imod_name,~] = fileparts(t.stack_name);
    case 'dose_filt'
        [~,imod_name,~] = fileparts(t.dose_filtered_stack_name);
    otherwise
        error('ACTHUNG!!! Unsuppored imod_stack... Only "unfiltered" and "dose_filt" supported!!!');
end


%% Check if the import tomo directory exists. Create new if necessary.
rlnTomoImportImodDir = [relion4dir,'/tomograms/',rlnTomoName];
temptomostar.rlnTomoImportImodDir = rlnTomoImportImodDir;


if ~exist(rlnTomoImportImodDir,'dir')
    mkdir(rlnTomoImportImodDir);
else
    system(['rm -r ',rlnTomoImportImodDir]);
    mkdir(rlnTomoImportImodDir);
end


if ~exist(relion4dir,'dir')
    error('Relion project directory not found!!!');
end

%% Check if tilt stack file exists and add relevant fields
stack_sourcefile = [t.stack_dir,t.stack_name];
stack_targetfile = [rlnTomoImportImodDir,'/',t.stack_name];
if exist(stack_sourcefile,'file')
    ln_cmd = ['ln -sf ',stack_sourcefile,' ',stack_targetfile];
    system(ln_cmd);
    switch ext
        case '.st'
            temptomostar.rlnTomoTiltSeriesName = ['tomograms/',rlnTomoName,'/',t.stack_name,':mrc'];
        case '.mrc'
            temptomostar.rlnTomoTiltSeriesName = ['tomograms/',rlnTomoName,'/',t.stack_name];
        otherwise
            error('Only .st or .mrc extensions are supported!!!')
    end
else 
    error('Tilt stack not found!!!');
end
    
%% Check if the ctfphaseflip file exists and add relevant fields
ctfphaseflip_sourcefile = [t.stack_dir,'/ctffind4/','diagnostic_',rlnTomoName,'.txt'];
ctfphaseflip_targetfile = [rlnTomoImportImodDir,'/ctfphaseflip_',t.ctf_determination_algorithm,'.txt'];

if exist(ctfphaseflip_sourcefile,'file')
    ln_cmd = ['ln -sf ',ctfphaseflip_sourcefile,' ',ctfphaseflip_targetfile];
    system(ln_cmd);
    
    temptomostar.rlnTomoImportCtfFindFile = ['tomograms/',rlnTomoName,'/ctfphaseflip_',t.ctf_determination_algorithm,'.txt'];
    
else
    error('ctfphaseflip file not found!!!');
end

%% Fractional dose. (Only works for constant exposure!!!)
temptomostar.rlnTomoImportFractionalDose = t.dose(1);


%% Link necessary file for IMOD

% Tlt file
tlt_sourcefile = [t.stack_dir,'/',imod_name,'.tlt'];
tlt_targetfile = [rlnTomoImportImodDir,'/',rlnTomoName,'.tlt'];
if exist(tlt_sourcefile,'file')
    ln_cmd = ['ln -sf ',tlt_sourcefile,' ',tlt_targetfile];
    system(ln_cmd);
else
    error('.tlt file not found!!!');
end


% Xf file
xf_sourcefile = [t.stack_dir,'/',imod_name,'.xf'];
xf_targetfile = [rlnTomoImportImodDir,'/',rlnTomoName,'.xf'];
if exist(xf_sourcefile,'file')
    ln_cmd = ['ln -sf ',xf_sourcefile,' ',xf_targetfile];
    system(ln_cmd);
else
    error('.xf file not found!!!');
end


% Newst.com
newstcom_sourcefile = [t.stack_dir,'/newst.com'];
newstcom_targetfile = [rlnTomoImportImodDir,'/newst.com'];
if exist(newstcom_sourcefile,'file')
    %newstcom = tomoman_imod_parse_newstcom(newstcom_sourcefile);
    newstcomfile = fopen(newstcom_targetfile,'w');
    fprintf(newstcomfile,['$newstack -StandardInput\n',...
        'InputFile	',t.stack_name,'\n',...
        'OutputFile	',rlnTomoName,'.ali\n',...
        'TransformFile	',rlnTomoName,'.xf\n',...
        'TaperAtFill	1,0\n',...
        'AdjustOrigin	\n',...
        'OffsetsInXandY	0.0,0.0\n',...
        'ImagesAreBinned	1.0\n',...
        'BinByFactor	1\n',...
        'AntialiasFilter	-1\n',...
        '$if (-e ./savework) ./savework\n']);                      

    fclose(newstcomfile);
end

% Tilt.com
tiltcom_sourcefile = [t.stack_dir,'/tilt.com'];
tiltcom_targetfile = [rlnTomoImportImodDir,'/tilt.com'];
if exist(tiltcom_sourcefile,'file')
    tiltcom = tomoman_imod_parse_tiltcom(tiltcom_sourcefile);
    % check for shift
    if ~isempty(tiltcom.SHIFT)
        shiftstr = ['SHIFT	',num2str(tiltcom.SHIFT(1)),' ', num2str(tiltcom.SHIFT(2))];
        
    else 
        shiftstr = ' ';
    end
        
    tiltcomfile = fopen(tiltcom_targetfile,'w');
    fprintf(tiltcomfile,['$tilt -StandardInput\n',...
                'InputProjections	', rlnTomoName,'.ali\n',...
                'OutputFile	', rlnTomoName,'.rec\n',...
                'IMAGEBINNED	1\n',...
                'TILTFILE	',rlnTomoName ,'.tlt\n',...
                'THICKNESS	',num2str(tiltcom.THICKNESS),' \n',...                %'-RADIAL ',num2str(tiltcom.RADIAL(1)),',', num2str(tiltcom.RADIAL(2)),' ',...                '-FalloffIsTrueSigma 1 ',...
                'XAXISTILT	',num2str(tiltcom.XAXISTILT),' \n',...
                'PERPENDICULAR	\n',...
                'MODE	2 \n',...
                'FULLIMAGE	',num2str(tiltcom.FULLIMAGE(1)),' ', num2str(tiltcom.FULLIMAGE(2)),' \n',...
                'SUBSETSTART ',num2str(tiltcom.SUBSETSTART(1)),' ', num2str(tiltcom.SUBSETSTART(2)),' \n',...
                'AdjustOrigin	\n',...
                'OFFSET	',num2str(tiltcom.OFFSET),' \n',...
                shiftstr,'\n']);
    fclose(tiltcomfile);
    
end


% generate Order list file
OrderList_name = [rlnTomoImportImodDir,'/',rlnTomoName,'.order'];
[tilts,tilt_idx] = setdiff(t.collected_tilts,t.removed_tilts); 
n_tilts = numel(tilts);

aligned_tilts = dlmread(tlt_targetfile);
n_alitilts = numel(aligned_tilts);

if n_alitilts == n_tilts
    order_array = zeros(n_tilts,3);
    order_array(:,3) = tilts;
    order_array(:,1) = tilt_idx;
    order_array(:,2) = aligned_tilts;
    sort_order_array = sortrows(order_array,1);
    dlmwrite(OrderList_name,sort_order_array(:,1:2));
else
    error('Something is seriously wrong with tilt angles!! Check whether number of tilts match between cleaned and aligned stack!!')
end

temptomostar.rlnTomoImportOrderList = ['tomograms/',rlnTomoName,'/',rlnTomoName,'.order'];

% generate tomogram particle list
rlntomocoord2_2 = tomoman_motl_stopgap_to_rlntomocoord2_2(motl);

rlntomocoord2_2_name = [rlnTomoImportImodDir,'/particle_coords.star'];
tomoman_rlntomocoord2_2_write(rlntomocoord2_2_name,rlntomocoord2_2);

% update tempcoords
tempcoords.rlnTomoName = rlnTomoName;
tempcoords.rlnTomoImportParticleFile = ['tomograms/',rlnTomoName,'/particle_coords.star'];




end

