#!/bin/bash
#SBATCH --job-name=snakemake_bamvcf
#SBATCH --output=logs/snakemake_%j.log
#SBATCH --error=logs/snakemake_%j.err
#SBATCH --partition=epyc
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=100
#SBATCH --mem=500G  # Now using 500GB total
#SBATCH --time=72:00:00
#SBATCH --mail-user=mkash006@ucr.edu
#SBATCH --mail-type=ALL

# Load modules
module load snakemake python bwa samtools gatk

# Create necessary log and result directories
mkdir -p logs/align logs/markdup logs/haplotypecaller
mkdir -p results/bam results/vcf results/bam_snpcall


# Run with memory-optimized settings
snakemake \
    --cores 100 \
    --jobs 4 \
    --resources mem_mb=500000 \
    --latency-wait 30 \
    --scheduler ilp \
    --rerun-incomplete
