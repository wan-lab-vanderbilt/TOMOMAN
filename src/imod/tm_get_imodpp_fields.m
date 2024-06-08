function imodpp_fields = tm_get_imodpp_fields()
%% tm_get_imodpp_fields
% Return input fields for IMOD preprocessing. 
%
% WW 06-2022

%% Fields

imodpp_fields = {'force_imod','boo',false;...                       % 1 = yes, 0 = no
                 'process_stack','str','dose-filtered';...          % Stack for processing. Either 'unfiltered' or 'dose-filtered'
                 'copytomocoms','boo',false;...                     % Run copytomocoms
                 'goldsize','num','';...                            % Gold diameter (nm). Set to 0 for no gold
                 'rotation','num','';...                            % Tilt axis rotation (deg), leave empty to use from the tomolist. 
                 'ccderaser','boo',false;...                        % Run CCD Eraser. (1 = yes, 0 = no)
                 'archiveoriginal','boo',false;...                  % Archive and delete original stack. (1 = yes, 0 = no)
                 'coarsealign','boo',false;...                      % Perform coarse alignment 
                 'tiltxcorrbinning','num','';...                    % Bin factor for calculating coarse alignment in tiltxcorr
                 'tiltxcorrangleoffset','num','';...                % Offset angle (pretilt) for coarse alignment
                 'ExcludeCentralPeak','boo',false;...               % Exclude central peak
                 'ShiftLimitsXandY','num','';...                    % Maximum shift in unbinned pixels
                 'coarsealignbin','num','';...                      % Bin factor for generating coarse pre-aligned stack
                 'coarseantialias','num',6;...                      % Antialiasing filter for coarse alignment. 1 - box, 2 - blackman, 3 - triangle, 4 mitchell, 5 - lanczos 2 lobes, 6 - lanczos 3 lobes (default). See newstack documentation for more information.
                 'convbyte','str','/';...                           % Convert to bytes: '/' = no, '0' = yes
                 'tracking_method','num',0;...                      % Tracking method. -1 to disable, 0 for seed and track, 1 for patch tracking.
                 'two_surf','boo','';...                            % Track beads on two surfaces. (1 = yes, 0 = no)
                 'n_beads','num','';...                             % Target number of beads
                 'adjustsize','boo','';...                          % Adjust size of beads based on average bead size. (1 = yes, 0 = no)
                 'localareatracking','boo',false;...                % Local area bead tracking. (1 = yes, 0 = no)
                 'localareasize','num','';...                       % Size of local area
                 'sobelfilter','boo',false;...                      % Use Sobel filter. (1 = yes, 0 = no)
                 'sobelkernel','num',1.5;...                        % Sobel filter kernel. (default 1.5)
                 'n_rounds','num',2;...                             % Number of rounds of tracking in run (default = 2)
                 'n_runs','num',2;...                               % Number of times to run beadtrack (default = 2)
                 'SizeOfPatchesXandY','num','';...                  % Size in X and Y of patches to track
                 'NumberOfPatchesXandY','num','';...                % Number of patches to track in X and Y
                 'OverlapOfPatchesXandY','num',[0.33,0.33];...      % Overlap of patches in X and Y (negative allowed; default is 0.33 0.33)
                 'IterateCorrelations','num',1;...                  % Number of iterations
                 'position_tomo','boo',false;...                    % Run tomogram positioning (1 = yes, 0 = no)
                 'positioning_thickness','num','';...               % Thickness for tomogram positioning.
                 'positioning_binning','num','';...                 % Binning for tomogram positioning. 
                 'alignedstack_binning','num','';...                % Binning for aligned stack. 
                 };
             
end
                 






