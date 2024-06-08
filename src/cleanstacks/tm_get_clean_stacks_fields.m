function c_fields = tm_get_clean_stacks_fields()
%% tm_get_clean_stacks_fields
% Return the fields for the clean stacks structs.
%
% WW 05-2022

%% Fields

c_fields = {'clean_binning','num';...        % Binning to open 3dmod with
            'clean_append','str';...         % Append to name for cleaned stack. Setting to "none" overwrites old file.
            'check_cleaning','boo';...       % Make sure stacks have been cleaned using stored bad tilts. 1 = yes, 0 = no.
            'force_cleaning','boo'};         % Force cleaning for cleaned stacks. 1 = yes, 0 = no
            
        
end
