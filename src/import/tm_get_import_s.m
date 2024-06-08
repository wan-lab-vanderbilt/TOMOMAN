function s_fields = tm_get_import_s()
%% tm_get_sortnew_ov
% Return the fields for the sortnew override struct.
%
% WW 05-2022

s_fields = {'ignore_raw_stacks', 'boo';...          % Move files even if raw stack is missing
            'ignore_missing_frames', 'boo'};        % Move files even if frames are missing
        
end
