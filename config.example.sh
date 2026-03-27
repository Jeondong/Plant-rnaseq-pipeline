#!/usr/bin/env bash

# Copy this file to config.sh and update the values for your project.

export TRIMMOMATIC_JAR="/path/to/Trimmomatic-0.39/trimmomatic-0.39.jar"
export ADAPTERS="/path/to/Trimmomatic-0.39/adapters/TruSeq3-PE-2.fa"
export INDEX_PREFIX="/path/to/reference/hisat2_index/genome"
export ANNOTATION_GTF="/path/to/reference/annotation.gtf"
export THREADS=8

# Set STRANDNESS to "RF" or "FR" for stranded libraries.
# Leave empty for unstranded libraries.
export STRANDNESS=""

# featureCounts strandedness: 0=unstranded, 1=stranded, 2=reversely stranded.
export STRAND_SPECIFICITY=0
