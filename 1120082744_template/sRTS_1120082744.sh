#!/bin/bash -l
#SBATCH --job-name="RTS"
#SBATCH -o RTS-%A.out
#SBATCH --nodes=25
#SBATCH --ntasks-per-node=1
#SBATCH --time=00:40:00
#SBATCH --partition=skylake-gpu
#SBATCH --account=oz048
#SBATCH --export=NONE
#SBATCH --mem=20000
#SBATCH --gres=gpu:1
cd $SLURM_SUBMIT_DIR

srun --export=ALL --mem=20000 --ntasks=25  --nodes=25 --gres=gpu:1  --ntasks-per-node=1 \
    /fred/oz048/bpindor/mwa-RTS/bin/rts_gpu rts_rm_sim.in > srun.${SLURM_JOB_ID}_2.log

mkdir -p imgs/instr && mkdir -p imgs/stokes
mv *img*.fits imgs/instr
mv *stokes*.fits imgs/stokes
