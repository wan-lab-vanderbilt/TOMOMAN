function tomopitch  = tm_imod_parse_tomopitchlog(tomopitchlog_name)
%% tm_imod_parse_tomopitchlog
% A function to take the path to an IMOD tomopitch log file, and parse out 
% the results. Parameterts are returned in a struct array.
%
% Sagar 08-2020

%% Debug
%tomopitchlog_name = '/fs/pool/pool-plitzko/Sagar/Projects/insitu_rubisco/chlamy_t4_1.2A/tomo/20200626_ChR_Rubisco_tomo__Position_16/tomopitch.log';

%% Read in tilt.com
fid = fopen(tomopitchlog_name);
tiltcom_text = textscan(fid, '%s', 'Delimiter', '\n');
fclose(fid);

% Initilize tiltcom struct
tomopitch = struct;

%% Parse parameters
parameters = {'XAXISTILT','num';...
              'ANGLEOFFSET','num';...
              'ZSHIFT','num';...
              };
          
n_param = size(parameters,1);      


for i = 1:n_param
%      idx = find(~cellfun('isempty',regexpi(tiltcom_text{1},['^',parameters{i,1}])),1,'first');
%     if isempty(idx)
%         tiltcom.(parameters{i}) = [];
%     else
    switch parameters{i,1}
        case 'XAXISTILT'
            idx = find(~cellfun('isempty',regexpi(tiltcom_text{1},'X axis tilt')),1,'last');
            tempstr = strsplit(tiltcom_text{1}{idx});
            tomopitch.(parameters{i,1}) = str2num(tempstr{end});
        case 'ANGLEOFFSET'
            idx = find(~cellfun('isempty',regexpi(tiltcom_text{1},'Angle offset')),1,'last');
            tempstr = strsplit(tiltcom_text{1}{idx});
            tomopitch.(parameters{i,1}) = str2num(tempstr{end}); %#ok<ST2NM>
        case 'ZSHIFT'
            idx = find(~cellfun('isempty',regexpi(tiltcom_text{1},'Z shift')),1,'last');
            tempstr = strsplit(tiltcom_text{1}{idx});
            tomopitch.(parameters{i,1}) = str2num(tempstr{end});
    end
    
end

          