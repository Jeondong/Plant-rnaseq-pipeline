#!/usr/bin/env bash
set -euo pipefail

# Count reads per gene across all sorted BAM files.
# Expects:
#   - Sorted BAM files from step 04
#   - Annotation GTF/GFF file
# Produces:
#   - One combined featureCounts matrix for all samples

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

BAM_DIR="${BAM_DIR:-${PROJECT_DIR}/results/04_bam}"
OUT_DIR="${OUT_DIR:-${PROJECT_DIR}/results/05_featurecounts}"
ANNOTATION_GTF="${ANNOTATION_GTF:-}"
THREADS="${THREADS:-8}"
FEATURE_TYPE="${FEATURE_TYPE:-exon}"
ATTRIBUTE_TYPE="${ATTRIBUTE_TYPE:-gene_id}"
IS_PAIRED_END="${IS_PAIRED_END:-true}"
REQUIRE_BOTH_ENDS_MAPPED="${REQUIRE_BOTH_ENDS_MAPPED:-true}"
# featureCounts strandedness: 0=unstranded, 1=stranded, 2=reversely stranded.
STRAND_SPECIFICITY="${STRAND_SPECIFICITY:-0}"
COUNT_FILE="${COUNT_FILE:-${OUT_DIR}/gene_counts.txt}"

if [[ -z "${ANNOTATION_GTF}" ]]; then
  echo "ANNOTATION_GTF must be set in ${CONFIG_FILE}" >&2
  exit 1
fi

mkdir -p "${OUT_DIR}"
shopt -s nullglob

bam_files=("${BAM_DIR}"/*.sorted.bam)

if [[ ${#bam_files[@]} -eq 0 ]]; then
  echo "No sorted BAM files found in ${BAM_DIR}" >&2
  exit 1
fi

cmd=(
  featureCounts
  -T "${THREADS}"
  -a "${ANNOTATION_GTF}"
  -t "${FEATURE_TYPE}"
  -g "${ATTRIBUTE_TYPE}"
  -s "${STRAND_SPECIFICITY}"
  -o "${COUNT_FILE}"
)

if [[ "${IS_PAIRED_END}" == "true" ]]; then
  cmd+=(-p)
fi

if [[ "${REQUIRE_BOTH_ENDS_MAPPED}" == "true" ]]; then
  cmd+=(-B)
fi

cmd+=("${bam_files[@]}")

echo "Running featureCounts"
"${cmd[@]}"

echo "featureCounts completed: ${COUNT_FILE}"
