function rlntomostar_fields = tomoman_get_rlntomostar_fields()
%% get_motl_fields
% A function to return stopgap motivelist fields and types.
%
% WW 06-2019

rlntomostar_fields = {'rlnTomoName', 'str', 'str';
               'rlnTomoTiltSeriesName', 'str', 'str';
               'rlnTomoImportCtfFindFile', 'str', 'str';
               'rlnTomoImportImodDir', 'str', 'str';               
               'rlnTomoImportFractionalDose', 'num', 'float';
               'rlnTomoImportOrderList', 'str', 'str'};
           
end
