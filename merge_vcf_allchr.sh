#!/bin/bash
#SBATCH --job-name=merge_vcfs
#SBATCH --output=logs/merge_vcfs_%j.out
#SBATCH --error=logs/merge_vcfs_%j.err
#SBATCH --partition=epyc             # Adjust partition as needed
#SBATCH --time=04:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=mkash006@ucr.edu

set -euo pipefail

# Load GATK module
module load gatk/4.3.0.0

# Define directories and variables
VCF_DIR="results/genotyped_vcfs"
OUTPUT_VCF="${VCF_DIR}/merged_all_chromosomes.vcf.gz"
REF="reference/h_formosa.ref.fasta"   # Update this if needed

# Define chromosome names
CHROM_NAMES=(
  LG1_scaffold_3 LG2_1_scaffold_12 LG2_2_scaffold_24
  LG3_scaffold_2 LG4_scaffold_10 LG5_scaffold_8
  LG6_scaffold_11 LG7_scaffold_7 LG8_scaffold_19
  LG9_scaffold_4 LG10_scaffold_9 LG11_scaffold_16
  LG12_scaffold_17 LG13_scaffold_5 LG14_scaffold_15
  LG15_scaffold_14 LG16_scaffold_5 LG17_scaffold_13
  LG18_scaffold_20 LG19_scaffold_18 LG20_scaffold_21
  LG21_scaffold_22 LG22_scaffold_1 LG23_scaffold_23
)

# Build list of input VCFs
VCF_INPUTS=""
for chr in "${CHROM_NAMES[@]}"; do
  VCF_PATH="${VCF_DIR}/${chr}.vcf.gz"
  if [[ -f "$VCF_PATH" ]]; then
    VCF_INPUTS+=" -I $VCF_PATH"
  else
    echo "Warning: VCF not found for $chr: $VCF_PATH" >&2
  fi
done

# Run GATK MergeVcfs
gatk MergeVcfs \
  -R "$REF" \
  $VCF_INPUTS \
  -O "$OUTPUT_VCF"

echo "Merged VCF written to: $OUTPUT_VCF"

