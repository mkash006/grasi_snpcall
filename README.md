# GRAS-Di SNP Calling Pipeline

This repository contains a pipeline for SNP discovery from GRAS-Di (Genotyping by Random Amplicon Sequencing–Direct) sequencing data using a combination of **Snakemake** and **shell scripts**. It is tailored for use on an HPC cluster with SLURM and follows **GATK Best Practices** for variant calling.

⚠️ **Note:** All steps assume input files have already been **trimmed to remove adapter contamination**. Raw FASTQ files must be pre-processed using tools such as **Trimmomatic** or **fastp** prior to running this pipeline.

---

## 🔧 Pipeline Overview

### 📂 Snakefile: Per-sample GVCF Calling
The `Snakefile` performs **per-sample variant calling** and generates **GVCF files** via GATK HaplotypeCaller. Key steps include:

1. **Reference Indexing**
2. **Alignment to Reference** (BWA-MEM)
3. **BAM Sorting & Marking Duplicates**
4. **Read Group Assignment**
5. **GATK HaplotypeCaller** in GVCF mode

All outputs are organized in `results/`, and logs are saved in the `logs/` directory.

---

### 🧪 Separate `.sh` Scripts: Joint Genotyping & SNP Filtering
The shell scripts (`.sh` files) are used for **joint SNP calling and post-processing**, including:

- **GATK GenotypeGVCFs**
- **VCF filtering**
- **Chromosome-based selection**
- **Custom filters and VCF manipulation***

These steps are separated intentionally because they often require **manual decisions**, such as:
- Selecting scaffolds or chromosomes of interest
- Adjusting filtering thresholds interactively

---

## 📁 Directory Structure
