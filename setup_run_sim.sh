#!/bin/bash

echo '---------------------------'
echo "Configure RTS RM SIMULATION"
echo -e '---------------------------\n'

# Beam model for sim
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


# Beam model for calibration
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

echo -en "Optional - enter suffix for output directory " && read -r SUF

WORKDIR="1120082744_${SIM}_${CAL}_${SUF}"
mkdir "$WORKDIR"
cp ./rts_rm_pipeline/* "$WORKDIR"
cd "$WORKDIR"

echo "Running the RTS from ./${WORKDIR}"

sed -i "s/META/${META}/g" rts_rm_sim.in
sed -i "s/WORKDIR/${WORKDIR}/g" rts_rm_sim.in
sed -i "s/CALBEAM/${CALBEAM}/g" rts_rm_sim.in

SETUP_JOB_0=$(sbatch  ./sRTS_1120082744.sh | cut -d " " -f 4)
REFLAG_JOB_0=$(sbatch  --dependency=afterok:$SETUP_JOB_0 ./rts_cube/cube_rts.sh $WORKDIR | cut -d " " -f 4)
