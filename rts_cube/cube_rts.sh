#!/bin/bash --login

#SBATCH --nodes=1
#SBATCH --time=00:30:00
#SBATCH --partition=skylake
#SBATCH --account=oz048
#SBATCH --nodes=1
#SBATCH --mem=30gb
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH -o cube-%A.out
#SBATCH -e cube-%A.err

WORKDIR=$1
data_dir="/fred/oz048/achokshi/rts_rm_sims/${WORKDIR}"

module purge
module load gcc/6.4.0
module load openmpi/3.0.0
module load python/3.6.4
module load numpy/1.16.3-python-3.6.4
module load astropy/3.1.2-python-3.6.4

time python "${data_dir}"/cube_rts/cube_rts.py \
    --fits_dir="$data_dir"/imgs/stokes --out_dir="$data_dir"/imgs/cubes
