# Bulk RNA-seq Workflow

This repository keeps a simple 6-step paired-end bulk RNA-seq workflow in shell scripts plus one DESeq2 R script.

## Expected layout

```text
.
├── 01.fastqc.sh
├── 02.trimmomatic.sh
├── 03.hisat2.sh
├── 04.samtools.sh
├── 05.featurecounts.sh
├── 06.deseq2.rscript
├── data/
│   └── raw/
├── metadata/
│   └── sample_metadata.tsv
├── reference/
│   ├── annotation.gtf
│   └── hisat2_index/
└── results/
```

## Input naming

Raw FASTQ files should use paired-end names like:

```text
data/raw/sampleA_R1.fastq.gz
data/raw/sampleA_R2.fastq.gz
data/raw/sampleB_R1.fastq.gz
data/raw/sampleB_R2.fastq.gz
```

The sample ID is the shared prefix before `_R1.fastq.gz` and `_R2.fastq.gz`.

## Example metadata

The first column in `metadata/sample_metadata.tsv` is the sample ID and must match the final sample IDs used in the count matrix:

```tsv
sample_id	condition	replicate
sampleA	control	1
sampleB	control	2
sampleC	treated	1
sampleD	treated	2
```

## Example commands

Set project-specific tool/reference paths first:

```bash
export PROJECT_DIR="$(pwd)"
export THREADS=8
export TRIMMOMATIC_JAR="/tools/Trimmomatic-0.39/trimmomatic-0.39.jar"
export ADAPTERS="/tools/Trimmomatic-0.39/adapters/TruSeq3-PE-2.fa"
export INDEX_PREFIX="$PROJECT_DIR/reference/hisat2_index/genome"
export ANNOTATION_GTF="$PROJECT_DIR/reference/annotation.gtf"
```

Run the six steps:

```bash
bash 01.fastqc.sh
bash 02.trimmomatic.sh
bash 03.hisat2.sh
bash 04.samtools.sh
bash 05.featurecounts.sh
Rscript 06.deseq2.rscript
```

Or run the full workflow with the wrapper:

```bash
bash run_all.sh
```

The wrapper resolves its own location, so the same workflow can also be launched from the repository root when the scripts live in `scripts/`:

```bash
bash scripts/run_all.sh
```

## Optional settings

- Change FASTQ suffixes if needed:

```bash
export READ1_SUFFIX="_1.fastq.gz"
export READ2_SUFFIX="_2.fastq.gz"
```

- Set library strandedness for HISAT2 if known:

```bash
export STRANDNESS="RF"
```

Use `RF` or `FR` for stranded libraries. Leave it empty for unstranded data.

- Set featureCounts strandedness:

```bash
export STRAND_SPECIFICITY=2
```

Use `0` for unstranded, `1` for stranded, and `2` for reversely stranded libraries.

- Set DESeq2 comparison explicitly:

```bash
export DESIGN_FORMULA="~ condition"
export CONTRAST_COLUMN="condition"
export REFERENCE_LEVEL="control"
export CONTRAST_TEST="treated"
export CONTRAST_REF="control"
Rscript 06.deseq2.rscript
```

## Output handoff

- `02.trimmomatic.sh` writes trimmed paired reads to `results/02_trimmed/paired/`
- `03.hisat2.sh` writes `sample.sam`
- `04.samtools.sh` writes `sample.sorted.bam`
- `05.featurecounts.sh` writes one combined count matrix
- `06.deseq2.rscript` normalizes featureCounts column names to bare sample IDs by removing directory paths and the `.sorted.bam` suffix
