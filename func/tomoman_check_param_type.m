function param = tomoman_check_param_type(param,param_name,type)
%% tomoman_check_param_type
% Checks to make sure input parameters have correct type.
%
% WW 07-2018

%% Check check!!!

switch type
    
    % Logical input
    case 'boo'
        switch param
            case 1
                param = true;
            case 0
                param = false;
            case {'t','true','y','yes','1'}
                param = true;
            case {'f','false','n','no','0'}
                param = false;
            otherwise
                error(['ACHTUNG!!! Invalid parameter for ',param_name,'. Expected logical input (0 = no, 1 = yes)!!!']);                
        end
        
    % Numeric input
    case 'num'
        
        if islogical(param)
            
            param = double(param);
            
        elseif ~isnumeric(param)
            
            param = str2num(param); %#ok<ST2NM>
            
        end
        
    % String input
    case 'str'
        
        if isnumeric(param) || islogical(param)
            
            param = num2str(param);
            
        end
        
end
        
        
        
    