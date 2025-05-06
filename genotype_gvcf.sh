#!/bin/bash
#SBATCH --job-name=genotype_gvcfs
#SBATCH --output=logs/genotype_gvcfs_%A_%a.out
#SBATCH --error=logs/genotype_gvcfs_%A_%a.err
#SBATCH --array=1-23
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8      # 8 CPUs/job (18 jobs = 144 CPUs)
#SBATCH --mem=16G              # 16GB/job (under your 300GB total)
#SBATCH --time=40:00:00
#SBATCH --partition=epyc

module load gatk/4.3.0.0
mkdir -p results/genotyped_vcfs

CHROMOSOMES=(
  "LG1_scaffold_3"
  "LG2_1_scaffold_12"
  "LG2_2_scaffold_24"
  "LG3_scaffold_2"
  "LG4_scaffold_10"
  "LG5_scaffold_8"
  "LG6_scaffold_11"
  "LG7_scaffold_7"
  "LG8_scaffold_19"
  "LG9_scaffold_4"
  "LG10_scaffold_9"
  "LG11_scaffold_16"
  "LG12_scaffold_17"
  "LG13_scaffold_5"
  "LG14_scaffold_15"
  "LG15_scaffold_14"
  "LG16_scaffold_5"
  "LG17_scaffold_13"
  "LG18_scaffold_20"
  "LG19_scaffold_18"
  "LG20_scaffold_21"
  "LG21_scaffold_22"
  "LG22_scaffold_1"
  "LG23_scaffold_23"
)

CHR=${CHROMOSOMES[$SLURM_ARRAY_TASK_ID - 1]}

# Run WITHOUT explicit heap settings (let Java manage memory)
gatk GenotypeGVCFs \
  -R reference/h_formosa.ref.fasta \
  -V "gendb://results/genomicsdb_per_chr/${CHR}" \
  -O "results/genotyped_vcfs/${CHR}.vcf.gz" \
  
