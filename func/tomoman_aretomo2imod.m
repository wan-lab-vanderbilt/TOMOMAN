function tomoman_aretomo2imod(t,p,VolZ)

% Parse imod name
switch p.imod_stack
    case 'unfiltered'
        imod_name = t.stack_name;
    case 'dose_filt'
        imod_name = t.dose_filtered_stack_name;
    otherwise
        error('ACTHUNG!!! Unsuppored imod_stack... Only "unfiltered" and "dose_filt" supported!!!');
end

[dir,name,~] = fileparts(imod_name);
if ~isempty(dir)
    dir = [dir,'/']; %#ok<AGROW>
end


% Alignment file from aretomo
alignfile_name = [t.stack_dir,'/AreTomo/',name,'.st.aln'];

% InMrc_name = [t.stack_dir,name,'.preali'];
[xf,tlt] = tomoman_aretomo_alnfile2tltxf(alignfile_name,p.aretomo_inbin);

% Filenames to writeconverted data to!
xf_file = [t.stack_dir,name,'.xf'];
tlt_file = [t.stack_dir,name,'.tlt'];
fidxf_file = [t.stack_dir,name,'_fid.xf'];

% (added support for areTomo with prealigned stack)
prexg_file = [t.stack_dir,name,'.prexg'];
tltxf_file = [t.stack_dir,name,'.tltxf'];

% write xf, tltxf and tlt file in Imod folder (Added support for AreTomo on prealigned stacks! )

if p.imod_preali
    %dlmwrite(fidxf_file,xf,'delimiter','\t'); % CHECK (CAN BE REMOVED)
    dlmwrite(tltxf_file,xf,'delimiter','\t')
    xfproduct_cmd = ['xfproduct -in1 ' , prexg_file, ' -in2 ', tltxf_file , ' -output ', fidxf_file ];
    system(xfproduct_cmd);
    xfcopy_cmd = ['b3dcopy -p ', fidxf_file, ' ',xf_file];
    system(xfcopy_cmd);
    
else    
    dlmwrite(xf_file,xf,'delimiter','\t');
    %dlmwrite(fidxf_file,xf,'delimiter','\t'); % CHECK (CAN BE REMOVED)
    
end

% write tlt file
dlmwrite(tlt_file,tlt);

% newst and tilt comfile names
newstcom_name = [t.stack_dir,'newst.com'];
tiltcom_name = [t.stack_dir,'tilt.com'];

% Filenames for newst and tilt comfiles
imod_stack_name = [name,'.st'];
xf_name = [name,'.xf'];
tlt_name = [name,'.tlt'];
ali_name = [name,'.ali'];
tomo_name = [t.stack_dir,name,'_full.rec'];

% newst com script
newstcom = fopen(newstcom_name,'w');
fprintf(newstcom,['$newstack -StandardInput\n',...
    'InputFile	',imod_stack_name,'\n',...
    'OutputFile	',ali_name,'.ali\n',...
    'TransformFile	',xf_name,'\n',...
    'TaperAtFill	1,0\n',...
    'AdjustOrigin	\n',...
    'OffsetsInXandY	0.0,0.0\n',...
    'ImagesAreBinned	1.0\n',...
    'BinByFactor	',num2str(p.aretomo_outbin),'\n',...
    'AntialiasFilter	-1\n',...
    '$if (-e ./savework) ./savework\n']);                      

fclose(newstcom);

% tilt com script
tiltcom = fopen(tiltcom_name,'w');
fprintf(tiltcom,['$tilt -StandardInput\n',...
    'InputProjections ',ali_name,'.ali\n',...
    'OutputFile ',tomo_name,'\n',...
    'IMAGEBINNED ',num2str(p.aretomo_outbin),'\n',...
    'TILTFILE ',tlt_name,'\n',...
    'THICKNESS ',num2str(VolZ),'\n',...
    'RADIAL 0.35 0.035\n',...
    'FalloffIsTrueSigma 1\n',...
    'XAXISTILT 0.0\n',...
    'SCALE 0.0 1.0 \n',...
    'PERPENDICULAR\n',...
    'MODE 2\n',...
    'FULLIMAGE ',num2str(p.fullimage(1)),' ',num2str(p.fullimage(2)),'\n',...
    'SUBSETSTART 0 0\n',...
    'AdjustOrigin \n',...
    'ActionIfGPUFails 1,2\n',...
    'OFFSET 0\n',...
    'SHIFT 0.0 0.0\n',...
    'UseGPU 0\n',...
    '$if (-e ./savework) ./savework\n']);                      

fclose(tiltcom);

end


