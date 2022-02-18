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

# module purge
# module load cuda/11.1.1
# module load gcc/9.2.0
# module load openmpi/4.0.2
# module load hdf5/1.10.6
# module load cfitsio/3.480

ml purge
ml gcc/6.4.0 openmpi/3.0.0 gnuplot/5.2.4 cfitsio/3.450 hdf5/1.10.5 cuda/11.1.1

# Other build modules.
module use /fred/oz048/achokshi/software/modulefiles
module load libconfig/master
# module load cuFFS/master

time /fred/oz048/achokshi/software/cuFFS/git-repo/rmsynthesis PARSET
