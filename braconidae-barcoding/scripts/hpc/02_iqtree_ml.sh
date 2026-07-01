#!/bin/bash
#SBATCH --job-name=iqtree_ml
#SBATCH --account=project_2013890
#SBATCH --partition=small
#SBATCH --time=71:00:00
#SBATCH --ntasks=2
#SBATCH --mem-per-cpu=4000
#SBATCH --output=logs/iqtree_%j.out
#SBATCH --error=logs/iqtree_%j.err

# ============================================================
# Maximum Likelihood Phylogeny — IQ-TREE2
# Usage: sbatch 02_iqtree_ml.sh <aligned.fasta>
#
# Key options:
#   -m MFP        ModelFinder Plus (automatic best-fit model)
#   -bb 1000      Ultrafast bootstrap (1000 replicates)
#   -alrt 1000    SH-aLRT branch support (1000 replicates)
#
# Output: <aligned.fasta>.treefile  (use this in R scripts)
# ============================================================

set -euo pipefail

data=$1

if [[ -z "$data" ]]; then
  echo "ERROR: No input alignment provided."
  echo "Usage: sbatch 02_iqtree_ml.sh <aligned.fasta>"
  exit 1
fi

if [[ ! -f "$data" ]]; then
  echo "ERROR: Alignment file '$data' not found."
  exit 1
fi

echo "=== IQ-TREE2 started: $(date) ==="
echo "Input alignment : $data"

iqtree2 \
  -s "$data" \
  -m MFP \
  -bb 1000 \
  -alrt 1000

echo "=== IQ-TREE2 complete: $(date) ==="
echo "Tree file: ${data}.treefile"

# Node support interpretation reminder:
# - Values reported as: SH-aLRT/UFBoot (e.g. 95/98)
# - Threshold used in visualisation: SH-aLRT >= 70 AND UFBoot >= 80
