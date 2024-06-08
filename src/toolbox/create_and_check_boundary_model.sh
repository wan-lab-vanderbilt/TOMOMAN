#!/usr/bin/env bash
set -e              # Crash on error
set -o nounset      # Crash on unset variables

## tomoman_initialize_folder.sh
# Bash script for initializing default TOMOMAN folder and copy paramfiles for all tasks.
#
# To use, run this script with the appropriate task as input.
# Tasks are: 'all'
# argument1 = Root directory (path/to/root_dir/)
# argument2 = tomolist name (tomolist.mat)
# argument3 = tomoman log (tomoman.log)
# argument4 = task ('all'. only supports copying all files.  )
# WW 07-2017



# Parse input arguments
args=("$@")

if [[ ${args[0]} == '--help' ]]; then
    echo "***************TOMOMAN v 0.9***************"
    echo "***************Usage:"
    echo "                      create_and_check_boundary_model.sh /path/to/tomo_dir/ "
    echo "                      argument1 = Tomogram directory (bin8 with sirt like filter) (path/to/root_dir/)"
    echo "                      argument2 = tomogram extension (.mrc or .rec)"
    echo "                      argument3 = calculate boundary model. 0=false. 1=true"
    echo "                      argument3 = check with 3dmod. 0=false. 1=true"
#    echo "                      argument4 = task ('all'. only supports copying all files.  )"
else
tomo_dir=${args[0]}
tomo_ext=${args[1]}
cal_boundary=${args[2]}
check=${args[3]}

process=0


# tomolist_name=${args[1]}
# log_name=${args[2]}
# task=${args[3]}

# cd to the root directory
cd $tomo_dir

# template param files 
# temp_param=$TOMOMANHOME/param_files/

# Initialize folder by task
for f in $(ls *$tomo_ext); do
    name=${f%%.*}
    echo $name
    boundary_name="$name"_boundary.mod
    points_name="$name"_boundary.txt
    
    if test -f "$points_name"; then
        if [ $(stat -c %s "$points_name") -eq 0 ]; then
            process=1
        else
            if [ "$cal_boundary" -eq "1" ]; then
                process=1
            else
                process=0
            fi
        fi
    else
        process=1
    fi
    
    
    if [ $process -eq 1 ]; then
        findsection -scal 2 -size 24,24,24 -block 48 -samp 5 -pitch $boundary_name $f || :
    
        
        if [ "$check" -eq "1" ]; then
            3dmod -Y $f "$name"_boundary.mod || :
            echo "Press 'y' to continue...."
            # Wait for the user to press a key
            read -s -n 1 key
            # Check which key was pressed
            case $key in
                y|Y)
                    echo "You pressed 'y'. Continuing..."
                    continue
                    ;;
                *)
                    echo "Invalid input. Please press 'y' or 'n'."
                    ;;
            esac
        fi
        model2point $boundary_name $points_name || :
    fi
done
    
    

# if [[ ${task} == 'all' ]]; then
#     echo "Initializing TOMOMAN folder..."
#     mkdir -p params
#     cp $temp_param/*.param params/
#     files="params/*"
#     for f in $files
#     do
#         sed -i "s+%root_directory+$root_dir+g" $f
#         sed -i "s+%tomolist_filename+$tomolist_name+g" $f
#         sed -i "s+%tomoman_log_filename+$log_name+g" $f
#     done
#     
# else
#     echo "ACHTUNG!!! Unsupported task!!!"
#     exit 1
# fi
fi
