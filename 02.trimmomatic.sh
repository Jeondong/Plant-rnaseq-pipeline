#!/usr/bin/env bash
set -euo pipefail

# Trim adapters and low-quality bases from paired-end FASTQ files.
# Expects:
#   - Raw reads in RAW_DIR
# Produces:
#   - Paired trimmed reads in OUT_DIR/paired
#   - Unpaired reads in OUT_DIR/unpaired

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$(basename "${SCRIPT_DIR}")" == "scripts" ]]; then
  DEFAULT_PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"
else
  DEFAULT_PROJECT_DIR="${SCRIPT_DIR}"
fi
PROJECT_DIR="${PROJECT_DIR:-${DEFAULT_PROJECT_DIR}}"
CONFIG_FILE="${CONFIG_FILE:-${PROJECT_DIR}/config.sh}"

if [[ ! -f "${CONFIG_FILE}" ]]; then
  echo "Missing config file: ${CONFIG_FILE}" >&2
  echo "Copy config.example.sh to config.sh and update the required settings before running the workflow." >&2
  exit 1
fi

# Load project-specific settings shared across the workflow.
# shellcheck disable=SC1090
source "${CONFIG_FILE}"

RAW_DIR="${RAW_DIR:-${PROJECT_DIR}/data/raw}"
OUT_DIR="${OUT_DIR:-${PROJECT_DIR}/results/02_trimmed}"
PAIRED_DIR="${PAIRED_DIR:-${OUT_DIR}/paired}"
UNPAIRED_DIR="${UNPAIRED_DIR:-${OUT_DIR}/unpaired}"
READ1_SUFFIX="${READ1_SUFFIX:-_R1.fastq.gz}"
READ2_SUFFIX="${READ2_SUFFIX:-_R2.fastq.gz}"
TRIM_R1_SUFFIX="${TRIM_R1_SUFFIX:-.trim.R1.fastq.gz}"
TRIM_R2_SUFFIX="${TRIM_R2_SUFFIX:-.trim.R2.fastq.gz}"
UNPAIRED_R1_SUFFIX="${UNPAIRED_R1_SUFFIX:-.unpaired.R1.fastq.gz}"
UNPAIRED_R2_SUFFIX="${UNPAIRED_R2_SUFFIX:-.unpaired.R2.fastq.gz}"
THREADS="${THREADS:-8}"
TRIMMOMATIC_JAR="${TRIMMOMATIC_JAR:-}"
ADAPTERS="${ADAPTERS:-}"

if [[ -z "${TRIMMOMATIC_JAR}" || -z "${ADAPTERS}" ]]; then
  echo "TRIMMOMATIC_JAR and ADAPTERS must be set in ${CONFIG_FILE}" >&2
  exit 1
fi

mkdir -p "${PAIRED_DIR}" "${UNPAIRED_DIR}"
shopt -s nullglob

read1_files=("${RAW_DIR}"/*"${READ1_SUFFIX}")

if [[ ${#read1_files[@]} -eq 0 ]]; then
  echo "No read 1 FASTQ files found in ${RAW_DIR} matching *${READ1_SUFFIX}" >&2
  exit 1
fi

for read1 in "${read1_files[@]}"; do
  sample="$(basename "${read1%"${READ1_SUFFIX}"}")"
  read2="${RAW_DIR}/${sample}${READ2_SUFFIX}"

  if [[ ! -f "${read2}" ]]; then
    echo "Missing read 2 file for sample ${sample}: ${read2}" >&2
    exit 1
  fi

  trim_r1="${PAIRED_DIR}/${sample}${TRIM_R1_SUFFIX}"
  trim_r2="${PAIRED_DIR}/${sample}${TRIM_R2_SUFFIX}"
  unpaired_r1="${UNPAIRED_DIR}/${sample}${UNPAIRED_R1_SUFFIX}"
  unpaired_r2="${UNPAIRED_DIR}/${sample}${UNPAIRED_R2_SUFFIX}"

  echo "Running Trimmomatic for ${sample}"
  java -jar "${TRIMMOMATIC_JAR}" PE \
    -threads "${THREADS}" \
    -phred33 \
    "${read1}" \
    "${read2}" \
    "${trim_r1}" \
    "${unpaired_r1}" \
    "${trim_r2}" \
    "${unpaired_r2}" \
    ILLUMINACLIP:"${ADAPTERS}":2:30:10 \
    LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
done

echo "Trimmomatic completed: ${PAIRED_DIR}"
