#!/bin/bash
#SBATCH --job-name=mafft_align
#SBATCH --account=project_2013890
#SBATCH --partition=small
#SBATCH --time=02:00:00
#SBATCH --ntasks=2
#SBATCH --mem-per-cpu=4000
#SBATCH --output=logs/mafft_%j.out
#SBATCH --error=logs/mafft_%j.err

# ============================================================
# COI Multiple Sequence Alignment — MAFFT
# Usage: sbatch 01_align_mafft.sh <basename>
#   <basename>  FASTA file prefix (without .fasta extension)
# Output: <basename>_aligned.fasta
# ============================================================

set -euo pipefail

data=$1

if [[ -z "$data" ]]; then
  echo "ERROR: No input basename provided."
  echo "Usage: sbatch 01_align_mafft.sh <basename>"
  exit 1
fi

if [[ ! -f "${data}.fasta" ]]; then
  echo "ERROR: Input file '${data}.fasta' not found."
  exit 1
fi

echo "=== MAFFT alignment started: $(date) ==="
echo "Input : ${data}.fasta"
echo "Output: ${data}_aligned.fasta"

mafft --auto "${data}.fasta" > "${data}_aligned.fasta"

echo "=== Alignment complete: $(date) ==="
echo "Output sequences: $(grep -c '^>' "${data}_aligned.fasta")"
