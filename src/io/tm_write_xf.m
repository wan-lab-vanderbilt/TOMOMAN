function tm_write_xf(xf_name,xf)
%% tm_write_xf
% Write IMOD .xf file with column formatting.
%
% WW 06-2022

%% Write output

% Open file
fid = fopen(xf_name,'w');

% Write output
for i = 1:size(xf,1)
    fprintf(fid,'%8.7f   %8.7f   %8.7f   %8.7f   %7.3f   %7.3f\n',xf(i,:));
end

% Close file
fclose(fid);

end
