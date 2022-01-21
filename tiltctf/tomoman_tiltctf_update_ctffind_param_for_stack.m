function ctffind = tomoman_tiltctf_update_ctffind_param_for_stack(tomolist,tctf,ctffind)
%% tomoman_tiltctf_update_ctffind_param_for_stack
% Update the CTFFIND parameters with a particular stack's settings.
%
% WW 07-2018

%% Update!!!

% Update pixelsize
ctffind.pixelsize = tomolist.pixelsize*tctf.fscaling;

% Update defocus range
ctffind.min_def = (abs(tomolist.target_defocus)-ctffind.def_range)*10000;
ctffind.max_def = (abs(tomolist.target_defocus)+ctffind.def_range)*10000;

