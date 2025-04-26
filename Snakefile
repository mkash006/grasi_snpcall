import os
from glob import glob
#sample configuration
SAMPLES = sorted(set(
    os.path.basename(f).replace('_R1_paired.fq.gz', '')
    for f in glob("data/*_R1_paired.fq.gz")
))

REF = "reference/h_formosa.ref.fasta"
#CPU and parralel configuration
TOTAL_CPUS = 100
TOTAL_MEM = 500000  # 500GB in MB

# Parallel jobs configuration
SAMPLES_IN_PARALLEL = 4  # For align/sort and mark_duplicates
HC_SAMPLES_IN_PARALLEL = 2  # For haplotype_caller

# Memory-optimized thread allocation
ALIGN_THREADS = 20  # 4x20=80 CPUs (160GB)
MARKDUP_THREADS = 10  # 4x10=40 CPUs (120GB)
HC_THREADS = 20  # 2x20=40 CPUs (220GB)

rule all:
    input:
        expand("results/vcf/{sample}_snp_calls.g.vcf.gz", sample=SAMPLES),
        expand("results/bam/{sample}_marked_duplicates.bam", sample=SAMPLES),
        expand("results/bam/{sample}_marked_duplicates.bai", sample=SAMPLES),
        "logs/notify_pipeline_complete.txt"
        
rule index_reference:
    input:
        REF
    output:
        REF + ".bwt",
        REF + ".fai",  # samtools index
        REF.replace(".fasta", ".dict")  # picard dictionary
    threads: 4
    resources: mem_mb=32000  # 32GB
    log:
        "logs/index_reference.log"
    shell:
        """
        set -euo pipefail
        module load bwa/0.7.17
        module load samtools/1.18
        module load gatk/4.3.0.0
        echo "[`date`] Indexing reference genome" > {log}
        bwa index {input} >> {log} 2>&1
        samtools faidx {input} >> {log} 2>&1
        gatk CreateSequenceDictionary -R {input} >> {log} 2>&1
        echo "[`date`] Done indexing" >> {log}
        """

rule align_and_sort:
    input:
        index=rules.index_reference.output,
        r1="data/{sample}_R1_paired.fq.gz",
        r2="data/{sample}_R2_paired.fq.gz",
        ref=REF
    output:
        bam="results/bam/{sample}_aligned.bam"
    threads: ALIGN_THREADS
    resources: mem_mb=160000 #160GB
    log:
        "logs/align/{sample}.log"
    shell:
        """
        set -euo pipefail
        module load bwa/0.7.17
        module load samtools/1.18
        echo "[`date`] Aligning {wildcards.sample}" > {log}
        bwa mem -t {threads} {input.ref} {input.r1} {input.r2} 2>> {log} | \
        samtools view -Sb - 2>> {log} | \
        samtools sort -@ {threads} -o {output.bam} 2>> {log}
        echo "[`date`] Finished alignment {wildcards.sample}" >> {log}
        """
        
rule mark_duplicates:
    input:
        bam="results/bam/{sample}_aligned.bam"
    output:
        bam="results/bam/{sample}_marked_duplicates.bam",
        index="results/bam/{sample}_marked_duplicates.bai",
        metrics="results/bam/{sample}_marked_dup_metrics.txt",
        sorted_bam="results/bam/{sample}_sorted_marked_duplicates.bam"  # Add a separate output for sorted BAM
    threads: MARKDUP_THREADS
    resources: mem_mb=120000  # 120GB/sample
    log:
        "logs/markdup/{sample}.log"
    shell:
        """
        set -euo pipefail
        module load gatk/4.3.0.0
        module load samtools/1.18
        gatk --java-options "-Xmx120G -XX:ParallelGCThreads={threads}" MarkDuplicates \
            -I {input.bam} \
            -O {output.bam} \
            -M {output.metrics} \
            --CREATE_INDEX true \
            --VALIDATION_STRINGENCY LENIENT \
            --ASSUME_SORTED true \
            >> {log} 2>&1 && \
        samtools sort {output.bam} -o {output.sorted_bam} >> {log} 2>&1
        """

rule haplotype_caller:
    input:
        bam="results/bam/{sample}_sorted_marked_duplicates.bam",
        ref=REF
    output:
        gvcf="results/vcf/{sample}_snp_calls.g.vcf.gz",
        bam="results/bam_snpcall/{sample}_hpcall.bam"
    threads: HC_THREADS
    resources: mem_mb=220000 #220GB
    log:
        "logs/haplotypecaller/{sample}.log"
    shell:
        """
        set -euo pipefail
        module load gatk/4.3.0.0
        gatk --java-options "-Xmx120G -XX:ParallelGCThreads={threads}" HaplotypeCaller \
            -R {input.ref} \
            -I {input.bam} \
            --sample-name {wildcards.sample} \
            --emit-ref-confidence GVCF \
            --bam-output {output.bam} \
            -O {output.gvcf} >> {log} 2>&1
        """

rule notify_completion:
    input:
        expand("results/vcf/{sample}_snp_calls.g.vcf.gz", sample=SAMPLES)
    output:
        "logs/notify_pipeline_complete.txt"
    shell:
        """
        echo "Pipeline completed on `date`" > {output}
        echo "Your Snakemake pipeline has finished successfully." | mail -s "HPCC: Snakemake pipeline complete" mkash006@ucr.edu
        """
