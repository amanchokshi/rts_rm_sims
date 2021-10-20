#!/bin/bash -l

#SBATCH --job-name="cuFFS"
#SBATCH -o RTS-%A.out
#SBATCH -e RTS-%A.err
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-gpu=1
#SBATCH --time=00:10:00
#SBATCH --partition=skylake-gpu
#SBATCH --account=oz048
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

# time rmsynthesis /astro/mwaeor/achokshi/rm-synth/slurm/cuffs/cuffs_parset.in
time rmsynthesis /astro/mwaeor/achokshi/rm-synth/slurm/cuffs/"$1"

# remove temp in file
rm /astro/mwaeor/achokshi/rm-synth/slurm/cuffs/"$1"
