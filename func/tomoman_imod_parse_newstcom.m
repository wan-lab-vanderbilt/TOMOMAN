function newstcom  = tomoman_imod_parse_newstcom(newstcom_name)

%% sg_read_IMOD_tiltcom
% A function to take the path to an IMOD newst.com file, and parse out the
% inputs in the tilt.com. Parameterts are returned in a struct array.
%
% WW 01-2018

%% Read in tilt.com
fid = fopen(newstcom_name);
newstcom_text = textscan(fid, '%s', 'Delimiter', '\n');
fclose(fid);

% Initilize tiltcom struct
newstcom = struct;

%% Parse parameters
parameters = {'InputFile', 'str';...
              'OutputFile', 'str';...
              'TransformFile','str';...
              'TaperAtFill','num';...
              'OffsetsInXandY','num';...
              'ImagesAreBinned','num';...
              'BinByFactor','num';...
              'AntialiasFilter','num';...
              };
          
n_param = size(parameters,1);      


for i = 1:n_param
    idx = find(~cellfun('isempty',regexpi(newstcom_text{1},['^',parameters{i,1}])),1,'first');
    if isempty(idx)
        newstcom.(parameters{i}) = [];
    else
        switch parameters{i,2}
            case 'str'
                newstcom.(parameters{i,1}) = newstcom_text{1}{idx}(numel(parameters{i,1})+1:end);
            case 'num'
                newstcom.(parameters{i,1}) = str2num(newstcom_text{1}{idx}(numel(parameters{i,1})+1:end)); %#ok<ST2NM>
        end
            
    end
end

          
