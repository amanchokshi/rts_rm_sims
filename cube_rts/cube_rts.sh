#!/bin/bash --login

#SBATCH --nodes=1
#SBATCH --time=00:30:00
#SBATCH --partition=skylake-gpu
#SBATCH --account=oz048
#SBATCH --nodes=1
#SBATCH --mem=30gb
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH -o cube-%A.out
#SBATCH -e cube-%A.err

WORKDIR=$1
data_dir="/fred/oz048/achokshi/rts_rm_sims/${WORKDIR}"

module load python/3.8.5
module load numpy
module load astropy

time python "${WORKDIR}"/cube_rts/cube_rts.py \
    --fits_dir="$data_dir"/imgs/stokes --out_dir="$data_dir"/imgs/cubes
