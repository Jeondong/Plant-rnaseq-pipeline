#!/usr/bin/env bash
set -euo pipefail

# Run the full 6-step bulk RNA-seq workflow in order.
# This wrapper only orchestrates execution; step-specific logic stays in each script.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$(basename "${SCRIPT_DIR}")" == "scripts" ]]; then
  PROJECT_DIR="${PROJECT_DIR:-$(dirname "${SCRIPT_DIR}")}"
  WORKFLOW_DIR="${SCRIPT_DIR}"
else
  PROJECT_DIR="${PROJECT_DIR:-${SCRIPT_DIR}}"
  WORKFLOW_DIR="${SCRIPT_DIR}"
fi
export PROJECT_DIR

run_step() {
  local label="$1"
  shift
  echo "=================================================="
  echo "Starting ${label}"
  echo "=================================================="
  "$@"
  echo "Completed ${label}"
  echo
}

echo "Workflow directory: ${WORKFLOW_DIR}"
echo "Project directory: ${PROJECT_DIR}"
echo

run_step "01 FastQC" bash "${WORKFLOW_DIR}/01.fastqc.sh"
run_step "02 Trimmomatic" bash "${WORKFLOW_DIR}/02.trimmomatic.sh"
run_step "03 HISAT2" bash "${WORKFLOW_DIR}/03.hisat2.sh"
run_step "04 SAMtools" bash "${WORKFLOW_DIR}/04.samtools.sh"
run_step "05 featureCounts" bash "${WORKFLOW_DIR}/05.featurecounts.sh"
run_step "06 DESeq2" Rscript "${WORKFLOW_DIR}/06.deseq2.rscript"

echo "RNA-seq workflow completed successfully."
