function tm_aretomo2imod(t,are,volZ)
%% tm_aretomo2imod
% Function for converting AreTomo outputs to IMOD format. 
%
% SK, WW 06-2022

%% Gather initial information

disp(['TOMOMAN: Coverting AreTomo files to IMOD for stack: ',t.stack_name]);
        
% Parse stack name
switch are.process_stack
    case 'unfiltered'
        stack_name = t.stack_name;
    case 'dose-filtered'
        stack_name = t.dose_filtered_stack_name;
    otherwise
        error(['TOMOMAN: ACHTUNG!!! ',are.process_stack,' is an unsupported stack type!!! Allowed types are either "unfiltered" or "dose-filtered"']);
end
[~,name,ext] = fileparts(stack_name);



% Parse stack name used for AreTomo alignment
if are.InBin > 1
    % Parse binned stack name
    InMrc_name = [t.stack_dir,'AreTomo/',name,'_bin',num2str(are.InBin),ext];
else
    % Parse input stack name
    InMrc_name = [t.stack_dir,stack_name];
end

% Hack for .mrc extension (AreTomo removes those)
if strcmp(ext,'.mrc')
    InMrc_name = InMrc_name(1:end-4);
end


%% Convert .aln file

% Parse .aln file
aln_name = [InMrc_name,'.aln'];
[xf,tlt,rotation] = tm_aretomo_aln2tltxf(aln_name,are.InBin);

% Size of aligned stack
if (abs(rotation) > 45) && (abs(rotation) < 135)
    img_size = flip(t.image_size);
else
    img_size = t.image_size;
end

% Parse IMOD output names
xf_name = [t.stack_dir,'AreTomo/',name,'.xf'];
fidxf_name = [t.stack_dir,'AreTomo/',name,'_fid.xf'];
tlt_name = [t.stack_dir,'AreTomo/',name,'.tlt'];

% Write IMOD outputs to stack directory
tm_write_xf(xf_name,xf);
tm_write_xf(fidxf_name,xf);
dlmwrite(tlt_name,tlt);





%% Write newstack .com script

% Open file
newstcom = fopen([t.stack_dir,'AreTomo/','newst.com'],'w');

% Write file
fprintf(newstcom,['$newstack -StandardInput\n',...
    'InputFile	',t.stack_dir,stack_name,'\n',...
    'OutputFile	',t.stack_dir,name,'.ali\n',...
    'TransformFile	',xf_name,'\n',...
    'TaperAtFill	1,0\n',...
    'AdjustOrigin	\n',...
    'OffsetsInXandY	0.0,0.0\n',...
    'ImagesAreBinned	1.0\n',...
    'BinByFactor	',num2str(are.OutBin),'\n',...
    'AntialiasFilter	-1\n',...
    '$if (-e ./savework) ./savework\n']);                      

% Close file
fclose(newstcom);

%% Write tilt .com script

% Check for thickness overrides
if sg_check_param(are,'ovZ')
    thickness = are.ovZ;
elseif nargin == 3
    thickness = volZ;
else
    thickness = are.VolZ;
end
    

% Open file
tiltcom = fopen([t.stack_dir,'AreTomo/','tilt.com'],'w');

% Write file
fprintf(tiltcom,['$tilt -StandardInput\n',...
    'InputProjections ',t.stack_dir,name,'.ali\n',...
    'OutputFile ',t.stack_dir,name,'_full.rec\n',...
    'IMAGEBINNED ',num2str(are.OutBin),'\n',...
    'TILTFILE ',tlt_name,'\n',...
    'THICKNESS ',num2str(thickness),'\n',...
    'RADIAL 0.35 0.035\n',...
    'FalloffIsTrueSigma 1\n',...
    'XAXISTILT 0.0\n',...
    'SCALE 0.0 1.0 \n',...
    'PERPENDICULAR\n',...
    'MODE 2\n',...
    'FULLIMAGE ',num2str(img_size(1)),' ',num2str(img_size(2)),'\n',...
    'SUBSETSTART 0 0\n',...
    'AdjustOrigin \n',...
    'ActionIfGPUFails 1,2\n',...
    'OFFSET 0\n',...
    'SHIFT 0.0 0.0\n',...
    'UseGPU 0\n',...
    '$if (-e ./savework) ./savework\n']);                      

% Close file
fclose(tiltcom);

end


