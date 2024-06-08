function filename_cell = tm_get_archive_filenames(task,tomolist,archive)
%% tm_get_archive_filenames
% Get the list of filenames for a minimal archive for a given task.
%
% The filename_cell contains each file or folder to copy along the rows,
% with column 1 as the source and column 2 as the destination.
%
% WW 09-2023

%% Check check

% List of tasks
task_list = {'import','stacks','ctf','ali'};

% Check input task
if ~any(strcmp(task,task_list))
    error(['ACHTUNG!!! ',task,' is not supported!!!']);
end



%% Get filenames for each task

% Parse new stack directory
new_stack_dir = strrep(tomolist.stack_dir,tomolist.root_dir,archive.archive_dir);

switch task
    
    case 'import'              
        
        % Parse frames and .mdoc names
        frames_mdoc = {[tomolist.frame_dir], [new_stack_dir,'frames/'];...                            % Frame directory
                       [tomolist.stack_dir,tomolist.mdoc_name], [new_stack_dir,tomolist.mdoc_name];   % .mdoc file
                       };
                     
        % Parse gainref and defects file
        if ~isempty(tomolist.gainref)
            
            %
            new_gainref = strrep(tomolist.gainref,tomolist.root_dir,archive.archive_dir);
            gainref_cell = {tomolist.gainref, new_gainref};
        else
            gainref_cell = [];
        end
        if ~isempty(tomolist.defects_file)
            new_defects_file = strrep(tomolist.defects_file,tomolist.root_dir,archive.root_dir);
            defects_cell = {tomolist.gainref, new_defects_file};
        else
            defects_cell = [];
        end
        
        % Output cell
        filename_cell = cat(1,frames_mdoc,gainref_cell,defects_cell);
        
    case 'stacks'
        
        % Parse stack name
        [~,st_name,ext] = fileparts(tomolist.stack_name);
        
        % Main stack
        stack_cell = {[tomolist.stack_dir,tomolist.stack_name], [new_stack_dir,tomolist.stack_name];...     % Frame aligned stack
                      [tomolist.stack_dir,st_name,'.rawtlt'], [new_stack_dir,st_name,'.rawtlt'];...               % Rawtlt name
                      };
                  
        % Dose filtered stack
        if ~isempty(tomolist.dose_filtered_stack_name)
            [~,df_name,df_ext] = fileparts(tomolist.dose_filtered_stack_name);
            df_cell = {[tomolist.stack_dir,tomolist.dose_filtered_stack_name], [new_stack_dir,tomolist.dose_filtered_stack_name];...     % Dose filtered stack
                      [tomolist.stack_dir,df_name,'.rawtlt'], [new_stack_dir,df_name,'.rawtlt'];...                                      % Rawtlt name
                      };
        else
            df_cell = [];
        end
        
        
        % Odd/Even stacks
        oe_cell = cell(4,2);                    % odd/even fileanmes
        c = 0;                                  % Cell counter
        stacks = {'norm','df';'_ODD','_EVN'};   % Stack types
        for i = 1:2            
            for j = 1:2
                % Parse stack name
                switch stacks{1,j}
                    case 'norm'
                        temp_name = [st_name,stacks{2,i},ext];
                    case 'df'
                        temp_name = [df_name,stacks{2,i},df_ext];
                end
                
                % Check existance
                if exist([tomolist.stack_dir,temp_name],'file')
                    % Store names
                    oe_cell{c+1,1}  = [tomolist.stack_dir,temp_name];
                    oe_cell{c+1,2}  = [new_stack_dir,temp_name];
                    c = c+1;
                end
            end
        end
        
        % Concatenate output cell
        filename_cell = cat(1,stack_cell,df_cell,oe_cell(1:c,:));
        
        
    case 'ctf'                
        
        switch tomolist.ctf_determination_algorithm
            case 'ctffind4'
                ctfphaseflipname = 'ctffind4/ctfphaseflip_ctffind4.txt'; 
            case 'tiltctf'
                ctfphaseflipname = 'tiltctf/ctfphaseflip_tiltctf.txt';
            otherwise
                warning([p.name,'ACHTUNG!!! Unsupported ctf_determination_algorithm']);
        end
        
        filename_cell = {[tomolist.stack_dir,ctfphaseflipname],[new_stack_dir,ctfphaseflipname]};
        
        
    case 'ali'
        
        switch archive.process_stack
            case 'unfiltered'
                [~,ali_name,~] = fileparts(tomolist.stack_name);
            case 'dose-filtered'
                [~,ali_name,~] = fileparts(tomolist.dose_filtered_stack_name);
            otherwise
                error(['TOMOMAN: ACHTUNG!!! ',archive.process_stack,' is an unsupported stack type!!! Allowed types are either "unfiltered" or "dose-filtered"']);
        end
        
        % Parse IMOD-formatted Alignment Filenames
        switch tomolist.alignment_software
            case 'AreTomo'
                subfolder = 'AreTomo/';
            case 'imod'
                subfolder = 'imod/';
            otherwise  % Assume IMOD
                subfolder = 'imod/';
        end

        % Parse filenames
        ali_files = cell(4,1);
        ali_files{1} = [subfolder,'tilt.com'];      % tilt.com
        ali_files{2} = [subfolder,'newst.com'];    % newstack
        ali_files{3} = [subfolder,ali_name,'.tlt'];    % tilt file
        ali_files{4} = [subfolder,ali_name,'.xf'];      % transform file
        
        % Fill filename cell
        filename_cell = cell(4,2);
        for i = 1:4
            filename_cell{i,1} = [tomolist.stack_dir,ali_files{i}];
            filename_cell{i,2} = [new_stack_dir,ali_files{i}];
        end
            
end
                        
        
        
        





