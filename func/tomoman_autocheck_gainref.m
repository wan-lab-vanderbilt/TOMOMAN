function p = tomoman_check_for_gain_ref_PSE(p)
%% tomoman_check_for_gain_ref
% A function to automatically look for the appropriate gain ref in the
% current frames folder.
%
% PSE 12-2019

  warning('Checking for gain ref automatically!');
        
    tmp_gain_file = dir([p.raw_frame_dir '*.dm4']);
    
    if ~isempty(tmp_gain_file)
        
        old_gain_name = [p.raw_frame_dir tmp_gain_file(1).name];
        
        new_gain_name = [p.raw_frame_dir strrep(tmp_gain_file(1).name, '.dm4', '.mrc')];
        
        system(['dm2mrc ' old_gain_name ' ' new_gain_name]);
        
        p.gainref = new_gain_name;
        
    else
        
        error('No gain reference detected! Please set it manually');
        
        
    end


end