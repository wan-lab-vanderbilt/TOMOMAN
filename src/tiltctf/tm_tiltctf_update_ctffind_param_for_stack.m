function ctffind4 = tm_tiltctf_update_ctffind_param_for_stack(tomolist,tctf,ctffind4)
%% tm_tiltctf_update_ctffind_param_for_stack
% Update the CTFFIND parameters with a particular stack's settings.
%
% WW 07-2018

%% Update!!!

% Update pixelsize
ctffind4.pixelsize = tomolist.pixelsize*tctf.fscaling;

% Update defocus range
ctffind4.min_def = (abs(tomolist.target_defocus)-ctffind4.def_range)*10000;
ctffind4.max_def = (abs(tomolist.target_defocus)+ctffind4.def_range)*10000;

