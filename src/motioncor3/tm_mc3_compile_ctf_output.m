function tomolist = tm_mc3_compile_ctf_output(p,tomolist,mc3,mc3_dir,tomo_str,n_tilts)
%% tm_mc3_compile_ctf_output
% Compile the CTF estimation output of MotionCor3.
%
% This was built on MotionCor3 version 1.1.1 on SBGrid.
%
% WW 08-2025



%% Assemble CTF diagnostic plot
disp([p.name,'Assembling MotionCor3 CTF diagnostic images...']);

% Initialize diagnostic stack
diagnostic = zeros(512,512,n_tilts,'single');

% Assemble stack
for i = 1:n_tilts
    
    % Parse image name
    img_name = [mc3_dir,tomo_str,'_',num2str(i),'_Ctf.mrc'];
    
    % Read image
    diagnostic(:,:,i) = sg_mrcread(img_name);
end

% Write stack
diagnostic_name = [mc3_dir,'diagnostic_',tomo_str,'.mrc'];
sg_mrcwrite(diagnostic_name,diagnostic);

% Clear split files
system(['rm ',mc3_dir,tomo_str,'_*_Ctf.mrc']);

%% Assemble estimate data
disp([p.name,'Assembling MotionCor3 CTF estimation data...']);

% Initialize array to hold data
if mc3.ExtPhase
    ctf = zeros(n_tilts,4);
else
    ctf = zeros(n_tilts,3);
end

% Read and store data
for i = 1:n_tilts
    
    % Read numeric array
    filename = [mc3_dir,tomo_str,'_',num2str(i),'_Ctf.txt'];
    fid = fopen(filename,'r');
    ctf_est = textscan(fid,'%s','CommentStyle','#');
    fclose(fid);
    
    % Fill arrays
   ctf(i,1) = str2double(ctf_est{1}{1});
   ctf(i,2) = str2double(ctf_est{1}{2});
   ctf(i,3) = str2double(ctf_est{1}{3});
   if mc3.ExtPhase
       ctf(i,4) = num2str(ctf_est{1}{4});
   end
   

end

% Fix defocus units
ctf(:,1:2) = ctf(:,1:2)./10000;


% Update tomolist
tomolist.ctf_determined = true;
tomolist.ctf_determination_algorithm = 'MotionCor3';
tomolist.ctf_parameters = struct('cs',mc3.Cs,'famp',mc3.AmpCont);
tomolist.determined_defocii = ctf;

tm_write_ctfphaseflip(tomolist,'motioncor3');

