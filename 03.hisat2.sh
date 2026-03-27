#!/usr/bin/env bash
set -euo pipefail

# Align trimmed paired-end reads with HISAT2.
# Expects:
#   - Trimmed paired reads from step 02
#   - Existing HISAT2 index basename
# Produces:
#   - One SAM file per sample in OUT_DIR

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

READ_DIR="${READ_DIR:-${PROJECT_DIR}/results/02_trimmed/paired}"
OUT_DIR="${OUT_DIR:-${PROJECT_DIR}/results/03_hisat2}"
READ1_SUFFIX="${READ1_SUFFIX:-.trim.R1.fastq.gz}"
READ2_SUFFIX="${READ2_SUFFIX:-.trim.R2.fastq.gz}"
INDEX_PREFIX="${INDEX_PREFIX:-}"
THREADS="${THREADS:-8}"
# Set STRANDNESS to "RF" or "FR" for stranded libraries.
# Leave empty for unstranded libraries.
STRANDNESS="${STRANDNESS:-}"
EXTRA_HISAT2_ARGS="${EXTRA_HISAT2_ARGS:-}"

if [[ -z "${INDEX_PREFIX}" ]]; then
  echo "INDEX_PREFIX must be set in ${CONFIG_FILE}" >&2
  exit 1
fi

mkdir -p "${OUT_DIR}"
shopt -s nullglob

read1_files=("${READ_DIR}"/*"${READ1_SUFFIX}")

if [[ ${#read1_files[@]} -eq 0 ]]; then
  echo "No trimmed read 1 FASTQ files found in ${READ_DIR} matching *${READ1_SUFFIX}" >&2
  exit 1
fi

for read1 in "${read1_files[@]}"; do
  sample="$(basename "${read1%"${READ1_SUFFIX}"}")"
  read2="${READ_DIR}/${sample}${READ2_SUFFIX}"
  sam_out="${OUT_DIR}/${sample}.sam"

  if [[ ! -f "${read2}" ]]; then
    echo "Missing trimmed read 2 file for sample ${sample}: ${read2}" >&2
    exit 1
  fi

  echo "Running HISAT2 for ${sample}"
  cmd=(
    hisat2
    -x "${INDEX_PREFIX}"
    -1 "${read1}"
    -2 "${read2}"
    -S "${sam_out}"
    -p "${THREADS}"
  )

  if [[ -n "${STRANDNESS}" ]]; then
    cmd+=(--rna-strandness "${STRANDNESS}")
  fi

  if [[ -n "${EXTRA_HISAT2_ARGS}" ]]; then
    # EXTRA_HISAT2_ARGS is appended as shell words for simple optional flags.
    # Example: EXTRA_HISAT2_ARGS="--dta"
    # shellcheck disable=SC2206
    extra_args=( ${EXTRA_HISAT2_ARGS} )
    cmd+=("${extra_args[@]}")
  fi

  "${cmd[@]}"
done

echo "HISAT2 completed: ${OUT_DIR}"
