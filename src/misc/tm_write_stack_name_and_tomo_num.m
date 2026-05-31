function tm_write_stack_name_and_tomo_num(tomolist_name,output_name)
%% tm_write_stack_name_and_tomo_num
% Write out a space delimited text file with the root of the stack/mdoc and
% the tomo_num.
%
% This will overwrite any other files called output_name.
%
% WW 11-2024

%% Initalize

% Load tomolist
load(tomolist_name,'tomolist');
n_stacks = numel(tomolist);

% Parse maximum length of .mdoc names
ml = max(cellfun('length',{tomolist.mdoc_name})) - 5;   % Subtract 5 for filename
name_format = [' %-',num2str(ml),'s'];

% Parse maximum digits for tomo_num
md = max(cellfun(@(x) floor(log10(abs(floor(x))+1))+1,{tomolist.tomo_num}));
num_format = ['% ',num2str(md+1),'i'];

%% Write ouptut

% Open output file
fid = fopen(output_name,'w');

% Write outputs for each stack
for i = 1:n_stacks
    
    % Parse name
    [~,name,~] = fileparts(tomolist(i).mdoc_name);
    
    % Print line
    fprintf(fid,name_format,name);
    fprintf(fid,'%s','    ');
    fprintf(fid,num_format,tomolist(i).tomo_num);
    fprintf(fid,'\n');
    
end

% Close output file
fclose(fid);


