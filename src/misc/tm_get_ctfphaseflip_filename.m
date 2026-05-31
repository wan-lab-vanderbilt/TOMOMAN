function ctfphaseflipname = tm_get_ctfphaseflip_filename(p,tomolist)
%% tm_get_ctfphaseflip_filename
% Parse a tomolist entry and return the path to the ctfphaseflip file based
% on determination algorithm. 
%
% WW 10-2025

%% Parse name

switch tomolist.ctf_determination_algorithm
    case 'ctffind4'
        ctfphaseflipname = [tomolist.stack_dir,'ctffind4/ctfphaseflip_ctffind4.txt'];
    case 'tiltctf'
        ctfphaseflipname = [tomolist.stack_dir,'tiltctf/ctfphaseflip_tiltctf.txt'];
    case 'sg_ctfrefine'
        ctfphaseflipname = [tomolist.stack_dir,'sg_ctfrefine/ctfphaseflip_sg_ctfrefine.txt'];
    case 'motioncor3'
        ctfphaseflipname = [tomolist.stack_dir,'MotionCor3/ctfphaseflip_motioncor3.txt'];
    otherwise
        if startsWith(tomolist.alignment_software,'sg_refine_')
            ctfphaseflipname = [tomolist.stack_dir,tomolist.alignment_software,'/ctfphaseflip_sg_refine.txt'];
        else
            error([p.name,'ACHTUNG !!! ',tomolist.alignment_software,' is an unsupported alignment_software type!!!']);
        end
end