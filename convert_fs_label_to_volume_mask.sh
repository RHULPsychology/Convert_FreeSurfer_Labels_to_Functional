#!/bin/bash

#######
#This is a Template script. DOn't use the commands blindly without changing the parameters 
#because they might affect Giusi's Analysis
#######

### change to the corresponding subject folder
source /usr/local/apps/psycapps/config/freesurfer_bash_update <your freesurfer subjects dir>

### use fsl
source /usr/local/apps/psycapps/config/fsl_bash

### Convert Freeesurfer Brain to volumetric brain (.mgz to .nii.gz)
### The nifti output of the previous step results in a volume image of 256x256x256. If you want to change the size use -- cropsize flag
mri_convert --out_orientation RAS <your freesurfer subjects dir>/<subject>/mri/brain.mgz <output_folder>/freesurfer_brain.nii.gz


### if you want to merge multiple labels use the following command
# mri_mergelabels -i label1.label -i label2.label -o generated_label.label

### Convert Label to volume 

mri_label2vol --label <your freesurfer subjects dir>/<subject>/label/lh.V1_exvivo.thresh.label \
              --identity \
              --temp <your freesurfer subjects dir>/<subject>/mri/brain.mgz \
	      --fillthresh 0.0  \
	      --proj frac 0 1 .1 \
	      --subject <subject> --hemi lh \
	      --o <output_folder>/<subject>/masks/lh_V1.nii.gz
	      
	      
### Fix the orientation of the mask
mri_convert --out_orientation RAS <output_folder>/<subject>/masks/lh_V1.nii.gz <output_folder>/<subject>/masks/lh_V1.nii.gz

### Create mean of your functional scans using fslmaths
fslmaths <BIDS_Folder>/<subject>/ses-mri/func/<functional_run>.nii.gz -Tmean <output_folder>/<subject>/<functional_run>_meants.nii.gz

### Coregister Mean TS with freesurfer brain
/usr/local/apps/psycapps/fsl/fsl-latest/bin/flirt \
	-in <output_folder>/<subject>/<functional_run>_meants.nii.gz \
	-ref <output_folder>/<subject>/freesurfer_brain.nii.gz \
	-out <output_folder>/<subject>/<functional_run>_bold2fs.nii.gz \
	-omat <output_folder>/<subject>/<functional_run>_bold2fs.mat \
	-bins 256 -cost corratio -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 12  -interp trilinear
	
### Invert the transformation matrix
/usr/local/apps/psycapps/fsl/fsl-latest/bin/convert_xfm \
	-omat <output_folder>/<subject>/<functional_run>_fs2bold.mat \
	-inverse <output_folder>/<subject>/<functional_run>_bold2fs.mat

### Apply the tranformation matrix

/usr/local/apps/psycapps/fsl/fsl-latest/bin/flirt \
	-in <output_folder>/<subject>/masks/lh_V1.nii.gz \
	-applyxfm -init <output_folder>/<subject>/<functional_run>_bold2fs.mat \
	-out <output_folder>/<subject>/masks/lh_V1_bold.nii.gz \
	-paddingsize 0.0 -interp trilinear \
	-ref <output_folder>/<subject>/<functional_run>_meants.nii.gz



