function job_array = tm_job_array(n_jobs,n_cores)
%% tm_job_array
% A script for generating a job array to optimally distributing a set a
% jobs to a number of cores. 
%
% WW 01-2018

%% Calcualte job array 

if n_cores >= n_jobs
    
    % If more cores than jobs, the first n_jobs cores get 1 job
    job_array  = zeros(n_jobs,3);
    job_array(:,1) = 1;
    job_array(:,2) = (1:n_jobs)';
    job_array(:,3) = (1:n_jobs)';

else
    
    % Average job size per node
    avg_size = floor(n_jobs/n_cores);

    % Array to hold job sizes, starts, and ends
    job_array = zeros(n_cores,3);
    job_array(:,1) = ones(n_cores,1)*avg_size;

    % Disperse remainder to earliest nodes
    remainder = mod(n_jobs,n_cores);
    job_array(1:remainder,1) = job_array(1:remainder,1) + 1;

    % Fill ends
    job_array(:,3) = cumsum(job_array(:,1));

    % Fill starts
    job_array(1,2) = 1;
    job_array(2:end,2) = job_array(2:end,3) - job_array(2:end,1) + 1;

end

