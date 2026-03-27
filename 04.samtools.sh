#!/usr/bin/env bash
set -euo pipefail

# Convert SAM to coordinate-sorted BAM and index each BAM.
# Expects:
#   - SAM files from step 03
# Produces:
#   - .sorted.bam and .sorted.bam.bai files in OUT_DIR

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

SAM_DIR="${SAM_DIR:-${PROJECT_DIR}/results/03_hisat2}"
OUT_DIR="${OUT_DIR:-${PROJECT_DIR}/results/04_bam}"
THREADS="${THREADS:-8}"
REMOVE_SAM="${REMOVE_SAM:-false}"

mkdir -p "${OUT_DIR}"
shopt -s nullglob

sam_files=("${SAM_DIR}"/*.sam)

if [[ ${#sam_files[@]} -eq 0 ]]; then
  echo "No SAM files found in ${SAM_DIR}" >&2
  exit 1
fi

for sam_file in "${sam_files[@]}"; do
  sample="$(basename "${sam_file%.sam}")"
  bam_file="${OUT_DIR}/${sample}.sorted.bam"

  echo "Sorting and indexing ${sample}"
  samtools sort -@ "${THREADS}" -o "${bam_file}" "${sam_file}"
  samtools index -@ "${THREADS}" "${bam_file}"

  if [[ "${REMOVE_SAM}" == "true" ]]; then
    rm -f "${sam_file}"
  fi
done

echo "SAMtools processing completed: ${OUT_DIR}"
