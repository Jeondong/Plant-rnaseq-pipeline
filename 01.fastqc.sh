#!/usr/bin/env bash
set -euo pipefail

# Run FastQC on raw paired-end FASTQ files.
# Expects:
#   - Raw reads in RAW_DIR
#   - Paired-end naming such as sample_R1.fastq.gz / sample_R2.fastq.gz
# Produces:
#   - FastQC reports in OUT_DIR

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
OUT_DIR="${OUT_DIR:-${PROJECT_DIR}/results/01_fastqc/raw}"
READ1_SUFFIX="${READ1_SUFFIX:-_R1.fastq.gz}"
READ2_SUFFIX="${READ2_SUFFIX:-_R2.fastq.gz}"
THREADS="${THREADS:-8}"

mkdir -p "${OUT_DIR}"
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

  echo "Running FastQC for ${sample}"
  fastqc -t "${THREADS}" -o "${OUT_DIR}" "${read1}" "${read2}"
done

echo "FastQC completed: ${OUT_DIR}"
