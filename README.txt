TOMOgram MANager v0.9
WW 06-2024


Short Guide 

TOMOMAN now operates as a set of functions that take in a paramfile for each task. Tasks are individual operations,
such as sorting new stacks, running IMOD preprocessing or AreTomo alignment, and defocus determination. 

Example paramfiles are contained in the TOMOMAN folder. The tomoman_copy_paramfiles function can be used to copy 
them into a working directory. 

Each task has it's own function, but proper paramfiles have a header that can be automatically read. In that case,
tasks can be run using tomoman(paramfilename).

A pipeline of defined tasks can also be run using tomoman_pipeline. The input to this is a plain-text file consisting
of a list of .param files. 


NOTE: TOMOMAN has many dependencies on the STOPGAP toolbox, so that also needs to be sourced in MATLAB for non-compiled usage. 



Standalone

TOMOMAN is also packaged with a precompiled "standalone" executable. This provides a minimal MATLAB environment that allows 
for interactive usage and full access to the STOPGAP toolbox without a MATLAB license. 

TOMOMAN standalone can be run using the exec/bin/tomoman_standalone.sh script.



Compiling

Compile using compile_tomoman(target_dir), where target_dir is where place the compiled file. This should be the exec/lib/ subfolder.
You may need to edit this file to specify paths to the STOPGAP toolbox.


To run compiled TOMOMAN, you need to set an environmental $TOMOMANTOME that points to the exec/ subfolder. In the exec/bash/ folder are 
the run scripts. Also, remember to update the matlabRoot parameter in the exec/lib/tomoman_config.sh file.

