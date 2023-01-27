function t = tomoman_export2EMPIAR_tomogram(p,t)

if t.skip == 1
    warning(['Achtung!! The tilt series numbered ' num2str(t.tomo_num) ' was skipped during preprocessing!!!!']);
end

% Parse stack name (always non dose weighted!!!)
[~,rlnTomoName,stkext] = fileparts(t.stack_name);

if strcmp(rlnTomoName,'none')
   [~,rlnTomoName,~] =  fileparts(t.mdoc_name);
end

% Parse Imod/AreTomo alignment names
switch p.imod_stack
    case 'unfiltered'
        [~,imod_name,~] = fileparts(t.stack_name);
    case 'dose_filt'
        [~,imod_name,~] = fileparts(t.dose_filtered_stack_name);
    otherwise
        error('ACTHUNG!!! Unsuppored imod_stack... Only "unfiltered" and "dose_filt" supported!!!');
end


%% Check if the import tomo directory exists. Create new if necessary.

if ~exist(p.empiar_dir,'dir')
    error('EMPIAR project directory not found!!!');
end

rlnTomoImportImodDir = [p.empiar_dir,'/',rlnTomoName];


if ~exist(rlnTomoImportImodDir,'dir')
    mkdir(rlnTomoImportImodDir);
else
    system(['rm -r ',rlnTomoImportImodDir]);
    mkdir(rlnTomoImportImodDir);
end


%% Check if frames folder exists and add relevant fields
frames_source = t.frame_dir;
frames_target = [rlnTomoImportImodDir,'/'];

if exist(frames_source,'dir')
    % update symbolic links
    frames = t.frame_names;
    for i =1:numel(frames)
        frame_name = [t.frame_dir,'/',frames{i}];
        [~,~,frameext] = fileparts(frame_name);
        [~,linkstr] = system(['ls -ls ',frame_name]);
        link = extractBetween(linkstr,'-> ''',frameext);
        newlink = strrep(link{1},'/pool-plitzko/Sagar/','/pool-sagar/Sagar/');
        newlink_cmd = ['ln -sf ', newlink,frameext, ' ', frame_name];
        system(newlink_cmd);
    end
    
    ln_cmd = ['cp -L -r ',frames_source,' ',frames_target];
    system(ln_cmd);
else 
    error('frames not found!!!');
end

t.frame_dir = strrep(t.frame_dir,p.root_dir,p.empiar_dir);

%% Check if mdoc file exists and add relevant fields
mdoc_sourcefile = [t.stack_dir,t.mdoc_name];
mdoc_targetfile = [rlnTomoImportImodDir,'/',t.mdoc_name];
% fix link
[~,linkstr] = system(['ls -ls ',mdoc_sourcefile]);
link = extractBetween(linkstr,'-> ','.mdoc');
newlink = strrep(link{1},'/pool-plitzko/Sagar/','/pool-sagar/Sagar/');
if exist([newlink,'.mdoc'],'file')
    ln_cmd = ['cp -L -r ',newlink,'.mdoc',' ',mdoc_targetfile];
    system(ln_cmd);
else 
    error('mdoc file not found!!!');
end

%% Check if rawtlt file exists and add relevant fields
rawtlt_sourcefile = [t.stack_dir,'/',rlnTomoName,'.rawtlt'];
rawtlt_targetfile = [rlnTomoImportImodDir,'/',rlnTomoName,'.rawtlt'];
if exist(rawtlt_sourcefile,'file')
    ln_cmd = ['cp -L -r ',rawtlt_sourcefile,' ',rawtlt_targetfile];
    system(ln_cmd);
else 
    warning('rawtlt file not found!!!');
end
%% Check if gainref exists and copy it/update tomolist 
[~,gain,gainext] = fileparts(t.gainref);
gain_sourcefile = t.gainref;
gain_targetfile = [rlnTomoImportImodDir,'/',gain,gainext];
if exist(gain_sourcefile,'file')
    ln_cmd = ['cp -H -r ',gain_sourcefile,' ',gain_targetfile];
    system(ln_cmd);
else 
    error('gain not found!!!');
end
t.gainref = gain_targetfile;

%% Check if tilt stack file exists and add relevant fields
stack_sourcefile = [t.stack_dir,t.stack_name];
stack_targetfile = [rlnTomoImportImodDir,'/',rlnTomoName,stkext];
if exist(stack_sourcefile,'file')
    ln_cmd = ['cp -L -r ',stack_sourcefile,' ',stack_targetfile];
    system(ln_cmd);
else 
    [~,linkstr] = system(['ls -ls ',stack_sourcefile]);
    link = extractBetween(linkstr,'-> ',stkext);
    if ~isempty(link)
        newlink = strrep(link{1},'/pool-plitzko/Sagar/','/pool-sagar/Sagar/');
        if exist([newlink,stkext],'file')
            ln_cmd = ['cp -L -r ',newlink,stkext,' ',stack_targetfile];
            system(ln_cmd);
        else 
            warning('Tilt stack not found!!!');
        end
    else
        warning('Tilt stack not found!!!');
    end
end
    
%% Check if the ctfphaseflip file exists and add relevant fields
% failsafe for 8k transfer 
ctfphaseflip_sourcefile = [t.stack_dir,'/ctfphaseflip_',t.ctf_determination_algorithm,'.txt'];
ctfphaseflip_targetfile = [rlnTomoImportImodDir,'/ctfphaseflip_',t.ctf_determination_algorithm,'.txt'];

if exist(ctfphaseflip_sourcefile,'file')
    ln_cmd = ['cp -L -r ',ctfphaseflip_sourcefile,' ',ctfphaseflip_targetfile];
    system(ln_cmd);
        
else
    warning('ctfphaseflip file not found!!!');
end


%% Link necessary files for IMOD

% Tlt file
tlt_sourcefile = [t.stack_dir,'/',imod_name,'.tlt'];
tlt_targetfile = [rlnTomoImportImodDir,'/',imod_name,'.tlt'];
if exist(tlt_sourcefile,'file')
    ln_cmd = ['cp -L -r ',tlt_sourcefile,' ',tlt_targetfile];
    system(ln_cmd);
else
    warning('.tlt file not found!!!');
end


% Xf file
xf_sourcefile = [t.stack_dir,'/',imod_name,'.xf'];
xf_targetfile = [rlnTomoImportImodDir,'/',imod_name,'.xf'];
if exist(xf_sourcefile,'file')
    ln_cmd = ['cp -L -r ',xf_sourcefile,' ',xf_targetfile]; % changed "ln -sf" to "cp" in order to accomodate 8k export.
    system(ln_cmd);
else
    warning('.xf file not found!!!');
end


% Newst.com
newstcom_sourcefile = [t.stack_dir,'/newst.com'];
newstcom_targetfile = [rlnTomoImportImodDir,'/newst.com'];
if exist(newstcom_sourcefile,'file')
    ln_cmd = ['cp -L -r ',newstcom_sourcefile,' ',newstcom_targetfile]; % changed "ln -sf" to "cp" in order to accomodate 8k export.
    system(ln_cmd);
else
    warning('newst.com file not found!!!');
end

% Tilt.com
tiltcom_sourcefile = [t.stack_dir,'/tilt.com'];
tiltcom_targetfile = [rlnTomoImportImodDir,'/tilt.com'];

if exist(tiltcom_sourcefile,'file')
    ln_cmd = ['cp -L -r ',tiltcom_sourcefile,' ',tiltcom_targetfile]; % changed "ln -sf" to "cp" in order to accomodate 8k export.
    system(ln_cmd);
else
    warning('tilt.com file not found!!!');
end


disp('Updating tomolist....')
t.root_dir = strrep(t.root_dir,p.root_dir,p.empiar_dir);
t.stack_dir = strrep(t.stack_dir,p.root_dir,p.empiar_dir);

end

