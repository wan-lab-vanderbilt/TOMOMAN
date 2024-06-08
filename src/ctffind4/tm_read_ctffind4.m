function ctffind_struct = tm_read_ctffind4(filename)
%% tm_read_ctffind4
% Read a CTFFIND4 diagnostic output file into a struct array.
%
% WW 07-2018

%% Read and convert

% Read numeric array
num_array = dlmread(filename,' ',5,0);
n_img = size(num_array,1);

% Row headers
row_headers = {'micrograph_num';...
               'defocus_1';...
               'defocus_2';...
               'astig_angle';...
               'pshift';...
               'cc';...
               'fit_res'};

           
% Fill struct array
ctffind_struct = struct();

for i = 1:numel(row_headers)
    temp_cell = num2cell(num_array(:,i));
    [ctffind_struct(1:n_img).(row_headers{i})] = temp_cell{:};
end



