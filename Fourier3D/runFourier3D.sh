#!/usr/bin/env bash
## Fourier3D
# A script to run Beata Turonova's Fourier3D script for Fourier cropping of large volumes.
#
# WW 08-2017

##### INPUT OPTIONS ######
input='./bin1/04.rec'
output='./bin4_fcrop/04.rec'
binning=4
memlimit=60000

######################################################
fourier3d='/fs/pool/pool-plitzko/will_wan/software/novasoft/Fourier3D/Fourier3D'

eval "$fourier3d -InputFile $input -OutputFile $output -BinFactor $binning -MemoryLimit $memlimit"

