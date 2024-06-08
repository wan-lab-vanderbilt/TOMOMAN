function archive_fields = tm_get_archive_fields()
%% tm_get_archive_fields
% Return input fields for TOMOMAN archiving. 
%
% SK 09-2023

%% Fields

archive_fields = {'archive_list','str', '';...                   % list of tilt-series to archive.
                 'process_stack', 'str', '';...                  % Stack for processing. Either 'unfiltered' or 'dose-filtered'
                 'archive_dir','str', '';...                     % Output directory
                 'raw_data_dir','str', '';...                    % Directory where the raw data imported into the TOMOMAN projet resides.
                 %'command','str', 'rsync -a';...                    % archival command. eg. 'rsync -a' ;
                  };
end
                 






