#!/bin/bash

echo '---------------------------'
echo "Configure RTS RM SIMULATION"
echo -e '---------------------------\n'

#####################################
#                                   #
#   Make RTS cal and sim srclists   #
#                                   # 
#####################################

yml_cfg_dir=${PWD}/rts_rm_pipeline/rts/srclists/srclist_cfgs

cd $yml_cfg_dir || exit
srclist_files=(*.yaml)
cd - >/dev/null

PS3="Enter File Index, or [0] to exit: "
echo "Select a RTS sourcelist config file from /rts_rm_pipeline/rts/srclists/srclist_cfgs/*.yaml"
select file in "${srclist_files[@]}"; do
    if [[ $REPLY == "0" ]]; then
        exit
    elif [[ -z $file ]]; then
        echo 'Invalid choice, try again' >&2
    else
        yml_cfg=${yml_cfg_dir}/${file}
        cfg_file_name=$(echo ${file} | cut -d "." -f 1)
        echo -e "RTS srclist config file is: ${file}\n"
        break
    fi
done

#####################################
#                                   #
#     Beam model for simulation     #
#                                   # 
#####################################

while true
do
 read -r -p "Use deformed FEE model for simulation? [Y/n] " input

 case $input in
     [yY][eE][sS]|[yY])
 META='1120082744_DipAmps'
 SIM=DEF
 break
 ;;
     [nN][oO]|[nN])
 META='1120082744'
 SIM=FEE
 break
        ;;
     *)
 echo "Invalid input..."
 ;;
 esac
done


#####################################
#                                   #
#     Beam model for calibration    #
#                                   # 
#####################################

while true
do
 read -r -p "Use deformed FEE model for calibration? [Y/n] " input

 case $input in
     [yY][eE][sS]|[yY])
 CALBEAM='1'
 CAL=DEF
 break
 ;;
     [nN][oO]|[nN])
 CALBEAM='0'
 CAL=FEE
 break
        ;;
     *)
 echo "Invalid input..."
 ;;
 esac
done


#####################################
#                                   #
#      Output dir structure etc     #
#                                   # 
#####################################

echo -en "Optional - enter suffix for output directory " && read -r SUF

# Make output directory
WORKDIR="${PWD}/${cfg_file_name}/1120082744_${SIM}_${CAL}_${SUF}"
mkdir -p "$WORKDIR"

cp -r ./rts_rm_pipeline/cube/* $WORKDIR
cp -r ./rts_rm_pipeline/cuffs/* $WORKDIR
cp ./rts_rm_pipeline/rts/rts_rm_sim.in $WORKDIR
cp ./rts_rm_pipeline/rts/sbatch_rts.sh $WORKDIR
cp ./rts_rm_pipeline/rts/metafits/${META}.metafits $WORKDIR


#####################################
#                                   #
#    Make RTS Sim & Cal srclists    #
#                                   # 
#####################################

# Nuke python 2.7 stuff from .profile
# export PYTHONPATH=
# 
# module purge
# module load gcc/6.4.0
# module load openmpi/3.0.0
# module load python/3.6.4
# module load numpy/1.16.3-python-3.6.4
# module load astropy/3.1.2-python-3.6.4
# module load scipy/1.3.0-python-3.6.4
# module load matplotlib/2.2.2-python-3.6.4

python ${PWD}/rts_rm_pipeline/rts/srclists/rts_srclist.py --yaml_cfg=${yml_cfg} --out_dir=${WORKDIR}
cal_srclist=$(ls ${WORKDIR}/*cal.txt)
sim_srclist=$(ls ${WORKDIR}/*sim.txt)


#####################################
#                                   #
#     Customise scripts for run     #
#                                   # 
#####################################

cd "$WORKDIR"

# Path to image cubes after rts & cubing the stokes images
CUBEDIR=${PWD}/imgs/cubes
PARSET=${PWD}/cuffs_parset.in
TAG="1120082744_${SIM}_${CAL}_${SUF}_"

echo "Running the RTS from ${WORKDIR}"
 
sed -i "" "s|META|${META}|g" rts_rm_sim.in
sed -i "" "s|WORKDIR|${WORKDIR}|g" rts_rm_sim.in
sed -i "" "s|CALBEAM|${CALBEAM}|g" rts_rm_sim.in
sed -i "" "s|sim_srclist|${sim_srclist}|g" rts_rm_sim.in
sed -i "" "s|cal_srclist|${cal_srclist}|g" rts_rm_sim.in

sed -i "" "s|PARSET|${PARSET}|g" cuffs.sh
sed -i "" "s|CUBEDIR|${CUBEDIR}|g" cuffs_parset.in
sed -i "" "s|TAG|${TAG}|g" cuffs_parset.in


#####################################
#                                   #
#          Run SLURM Jobs           #
#                                   #
#####################################

RTS_JOB=$(sbatch  ./sRTS_1120082744.sh | cut -d " " -f 4)
CUBE_JOB=$(sbatch  --dependency=afterok:$RTS_JOB cube_rts.sh $WORKDIR | cut -d " " -f 4)
CUFFS_JOB=$(sbatch  --dependency=afterok:$CUBE_JOB cuffs.sh | cut -d " " -f 4)
