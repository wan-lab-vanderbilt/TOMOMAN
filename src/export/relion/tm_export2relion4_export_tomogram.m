function [temptomostar,tempcoords] = tm_export2relion4_export_tomogram(t,motl,export)


relion4dir = export.output_dir;
imod_stack = export.process_stack;

[~,rlnTomoName,ext] = fileparts(t.stack_name);
% end
temptomostar.rlnTomoName = rlnTomoName;

% Parse Imod/AreTomo alignment names
switch imod_stack
    case 'unfiltered'
        [~,imod_name,~] = fileparts(t.stack_name);
    case 'dose-filtered'
        [~,imod_name,~] = fileparts(t.dose_filtered_stack_name);
    otherwise
        error('ACTHUNG!!! Unsuppored imod_stack... Only "unfiltered" and "dose-filtered" supported!!!');
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
stack_targetfile = [rlnTomoImportImodDir,'/',rlnTomoName,ext];
if exist(stack_sourcefile,'file')
    ln_cmd = ['ln -sf ',stack_sourcefile,' ',stack_targetfile];
    system(ln_cmd);
    switch ext
        case '.st'
            temptomostar.rlnTomoTiltSeriesName = ['tomograms/',rlnTomoName,'/',rlnTomoName,ext,':mrc'];
        case '.mrc'
            temptomostar.rlnTomoTiltSeriesName = ['tomograms/',rlnTomoName,'/',rlnTomoName,ext];
        otherwise
            error('Only .st or .mrc extensions are supported!!!')
    end
else 
    error('Tilt stack not found!!!');
end
    
%% Check if the ctfphaseflip file exists and add relevant fields
% failsafe for 8k transfer 

switch t.ctf_determination_algorithm
    case 'ctffind4'
        ctfphaseflipname = 'ctffind4/ctfphaseflip_ctffind4.txt'; 
    case 'tiltctf'
        ctfphaseflipname = 'tiltctf/ctfphaseflip_tiltctf.txt';
    otherwise
        warning([p.name,'ACHTUNG!!! Unsupported ctf_determination_algorithm']);
end

ctfphaseflip_sourcefile = [t.stack_dir,'/',ctfphaseflipname];
[~,filename,ext] = fileparts(ctfphaseflipname);
ctfphaseflip_targetfile = [rlnTomoImportImodDir,'/',filename,ext];

if exist(ctfphaseflip_sourcefile,'file')
    ln_cmd = ['ln -sf ',ctfphaseflip_sourcefile,' ',ctfphaseflip_targetfile];
    system(ln_cmd);
    
    temptomostar.rlnTomoImportCtfPlotterFile = ['tomograms/',rlnTomoName,'/ctfphaseflip_',t.ctf_determination_algorithm,'.txt'];
    
else
    error('ctfphaseflip file not found!!!');
end

%% Fractional dose. (Only works for constant exposure!!!)
temptomostar.rlnTomoImportFractionalDose = t.dose(1);


%% Link necessary file for IMOD
% Parse IMOD-formatted Alignment Filenames
switch t.alignment_software
    case 'AreTomo'
        subfolder = 'AreTomo/';
    case 'imod'
        subfolder = 'imod/';
    otherwise  % Assume IMOD
        subfolder = 'imod/';
end
[~,name,~] = fileparts(t.dose_filtered_stack_name);         % Assume alignment using dose filtered stack
tlt_sourcefile = [t.stack_dir,subfolder,name,'.tlt'];
xf_sourcefile = [t.stack_dir,subfolder,name,'.xf'];

% Tlt file
% tlt_sourcefile = [t.stack_dir,'/',imod_name,'.tlt'];
tlt_targetfile = [rlnTomoImportImodDir,'/',rlnTomoName,'.tlt'];
if exist(tlt_sourcefile,'file')
    ln_cmd = ['ln -sf ',tlt_sourcefile,' ',tlt_targetfile];
    system(ln_cmd);
else
    error('.tlt file not found!!!');
end


% Xf file
% xf_sourcefile = [t.stack_dir,'/',imod_name,'.xf'];
xf_targetfile = [rlnTomoImportImodDir,'/',rlnTomoName,'.xf'];
if exist(xf_sourcefile,'file')
    ln_cmd = ['cp ',xf_sourcefile,' ',xf_targetfile]; % changed "ln -sf" to "cp" in order to accomodate 8k export.
    system(ln_cmd);
else
    error('.xf file not found!!!');
end

% % check whether to rescale the xf file for superres or 8k. 
% if p.if_superres
%     tomoman_rescale_imodxf(xf_targetfile,xf_targetfile,2);
% end


% Newst.com
newstcom_sourcefile = [t.stack_dir,subfolder,'/newst.com'];
newstcom_targetfile = [rlnTomoImportImodDir,'/newst.com'];
if exist(newstcom_sourcefile,'file')
    %newstcom = tomoman_imod_parse_newstcom(newstcom_sourcefile);
    newstcomfile = fopen(newstcom_targetfile,'w');
    fprintf(newstcomfile,['$newstack -StandardInput\n',...
        'InputFile	',rlnTomoName,ext,'\n',...
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
tiltcom_sourcefile = [t.stack_dir,subfolder,'/tilt.com'];
tiltcom_targetfile = [rlnTomoImportImodDir,'/tilt.com'];






if exist(tiltcom_sourcefile,'file')
    tiltcom = tm_imod_parse_tiltcom(tiltcom_sourcefile);
    
    thickness = (tiltcom.THICKNESS);
    fullimage1 = (tiltcom.FULLIMAGE(1));
    fullimage2 = (tiltcom.FULLIMAGE(2));
    offset = (tiltcom.OFFSET);


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
                'THICKNESS	',num2str(thickness),' \n',...                %'-RADIAL ',num2str(tiltcom.RADIAL(1)),',', num2str(tiltcom.RADIAL(2)),' ',...                '-FalloffIsTrueSigma 1 ',...
                'XAXISTILT	',num2str(tiltcom.XAXISTILT),' \n',...
                'PERPENDICULAR	\n',...
                'MODE	2 \n',...
                'FULLIMAGE	',num2str(fullimage1),' ', num2str(fullimage2),' \n',...
                'SUBSETSTART ',num2str(tiltcom.SUBSETSTART(1)),' ', num2str(tiltcom.SUBSETSTART(2)),' \n',...
                'AdjustOrigin	\n',...
                'OFFSET	',num2str(offset),' \n',...
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


rlntomocoord2_2_name = [rlnTomoImportImodDir,'/particle_coords.star'];

% generate tomogram particle list
if sg_check_param(export,'sg_motl')
    rlntomocoord2_2 = tm_motl_stopgap_to_rlntomocoord2_2(motl);
    tm_rlntomocoord2_2_write(rlntomocoord2_2_name,rlntomocoord2_2);
end

% update tempcoords
tempcoords.rlnTomoName = rlnTomoName;
tempcoords.rlnTomoImportParticleFile = ['tomograms/',rlnTomoName,'/particle_coords.star'];


disp(['Export finished for tomogram: ' imod_name]);


end

