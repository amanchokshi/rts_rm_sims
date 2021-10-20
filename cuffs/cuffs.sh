#!/bin/bash -l

#SBATCH --job-name="cuFFS"
#SBATCH -o cuffs-%A.out
#SBATCH -e cuffs-%A.err
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=00:10:00
#SBATCH --partition=skylake-gpu
#SBATCH --account=oz048
#SBATCH --mem=20000
#SBATCH --gres=gpu:1

module purge
module load cuda/11.1.1
module load gcc/9.2.0
module load openmpi/4.0.2
module load hdf5/1.10.6
module load cfitsio/3.480

# Other build modules.
module use /fred/oz048/achokshi/software/modulefiles
module load libconfig/master
module load cuFFS/master

# time rmsynthesis /astro/mwaeor/achokshi/rm-synth/slurm/cuffs/cuffs_parset.in
time rmsynthesis /fred/oz048/achokshi/rts_rm_sims/cuffs/"$1"

# remove temp in file
# rm /astro/mwaeor/achokshi/rm-synth/slurm/cuffs/"$1"
