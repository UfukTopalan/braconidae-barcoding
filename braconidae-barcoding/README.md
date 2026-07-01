# 🐝 Finnish Braconidae — DNA Barcoding vs. Morphology

[![DOI](https://img.shields.io/badge/DOI-pending-lightgrey)](https://github.com/UfukTopalan)
[![R](https://img.shields.io/badge/R-%3E%3D4.3-steelblue?logo=R)](https://www.r-project.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![IQ-TREE2](https://img.shields.io/badge/IQ--TREE2-v2.3-orange)](http://www.iqtree.org/)
[![MAFFT](https://img.shields.io/badge/MAFFT-v7-green)](https://mafft.cbrc.jp/)

> Comparing morphological species identifications with BOLD BIN clustering across Finnish Braconidae (Hymenoptera: Braconidae) museum specimens — a reproducible analysis pipeline.

---

## 📋 Overview

This repository contains the full analysis pipeline for a study examining the concordance between morphology-based species identification and molecular BIN (Barcode Index Number) clustering in Finnish **Braconidae** parasitoid wasps. Specimens derive from the natural history museum collections of the Finnish Museum of Natural History (MZH), sequenced using both **FOA (Fiber-Optic Array)** and **SMRT** high-throughput sequencing protocols.

### Key findings at a glance

| Metric | Value |
|--------|-------|
| Dominant concordance category | **MERGE** |
| Overall discordance rate (with singletons) | **57%** |
| Overall discordance rate (without singletons) | **65%** |
| Hotspot genera (discordance > overall rate) | **6** |
| Subfamilies examined | Multiple |

### Concordance categories (after Edwards et al.)

| Category | Definition |
|----------|------------|
| **MATCH** | 1 BIN, exclusive to the morphospecies |
| **MERGE** | All BINs shared with other species (no exclusive BIN) |
| **SPLIT** | >1 BIN, all exclusive (no shared BINs) |
| **MIXTURE** | >1 BIN, at least one exclusive AND at least one shared |

---

## 🗂️ Repository Structure

```
braconidae-barcoding/
│
├── R/
│   ├── 01_sequencing_quality.R      # COI length vs. specimen age, protocol comparison
│   ├── 02_concordance_categories.R  # BIN–morphospecies concordance assignment logic
│   ├── 03_taxonomic_hotspots.R      # Subfamily & genus discordance rates
│   ├── 04_taxonomic_depth.R         # BIN-level discordance depth
│   ├── 05_sequence_glm.R            # GLM: sequence length vs. concordance outcome
│   └── 06_ml_trees.R                # ML tree visualisation (genus, BIN, Exotela case study)
│
├── scripts/
│   └── hpc/
│       ├── 01_align_mafft.sh        # SLURM: MAFFT COI alignment
│       └── 02_iqtree_ml.sh          # SLURM: IQ-TREE2 maximum likelihood tree
│
├── data/
│   └── example/
│       └── README.md                # Data description & access instructions
│
├── results/
│   └── README.md                    # Output file descriptions
│
├── docs/
│   └── concordance_logic.md         # Detailed explanation of category assignment
│
├── .gitignore
├── LICENSE
└── README.md                        ← you are here
```

---

## ⚙️ Dependencies

### R packages

```r
# Install all at once
install.packages(c(
  "ggplot2", "dplyr", "tidyr", "forcats",
  "scales", "cowplot", "ggdist"
))

# Bioconductor / GitHub
if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
BiocManager::install(c("ggtree", "ggtreeExtra"))

install.packages("ggnewscale")   # from CRAN
install.packages("ape")
```

### Bioinformatics tools (HPC)

| Tool | Version tested | Purpose |
|------|---------------|---------|
| [MAFFT](https://mafft.cbrc.jp/) | 7.x | Multiple sequence alignment |
| [IQ-TREE2](http://www.iqtree.org/) | 2.3 | Maximum likelihood phylogenetics |

---

## 🚀 Reproducing the Analysis

### Step 1 — Sequence alignment (HPC)

```bash
sbatch scripts/hpc/01_align_mafft.sh your_sequences
```

This produces `your_sequences_aligned.fasta`.

### Step 2 — Maximum likelihood tree (HPC)

```bash
sbatch scripts/hpc/02_iqtree_ml.sh your_sequences_aligned.fasta
```

IQ-TREE2 runs ModelFinder (`-m MFP`), 1000 ultrafast bootstraps (`-bb 1000`), and 1000 SH-aLRT replicates (`-alrt 1000`). Output: `.treefile`.

### Step 3 — R analysis pipeline

Run scripts in order from the `R/` directory, or source them sequentially:

```r
source("R/01_sequencing_quality.R")
source("R/02_concordance_categories.R")
source("R/03_taxonomic_hotspots.R")
source("R/04_taxonomic_depth.R")
source("R/05_sequence_glm.R")
source("R/06_ml_trees.R")
```

> **Note:** You will need to load your own `species_data2` data frame and point tree file paths to your local `.treefile`. See `data/example/README.md` for the expected data structure.

---

## 📊 Figures produced

| Script | Figure | Description |
|--------|--------|-------------|
| `01_sequencing_quality.R` | Fig. S1 | COI effective length vs. specimen age, by protocol |
| `02_concordance_categories.R` | Fig. 1 | Concordance category barplot (with/without singletons) |
| `03_taxonomic_hotspots.R` | Fig. 2 | Subfamily discordance rates; genus hotspot lollipop |
| `04_taxonomic_depth.R` | Fig. S2 | BIN-level discordance depth |
| `05_sequence_glm.R` | Fig. S3 | Raincloud plot & GLM: length vs. concordance |
| `06_ml_trees.R` | Fig. 3–5 | ML trees: BIN AAA7636, 4-category genus, *Exotela* corrections |

---

## 🔬 Case Studies

Three genera/BINs are used to illustrate distinct concordance-discordance drivers:

1. **Low COI divergence** — BIN `BOLD:AAA7636`: multiple morphospecies collapsing into a single BIN, consistent with shallow genetic divergence or recent divergence.

2. **Complex multi-driver discordance** — a genus exhibiting all four concordance categories (MATCH, MERGE, SPLIT, MIXTURE), suggesting a combination of cryptic diversity and geographic structure.

3. **Operational misidentification** — *Exotela* (Dacnusini): 10 of 14 specimens morphologically re-examined by Charles Godfray; corrections fully resolve the tree topology, attributing discordance to original misidentification rather than biological signal.

---

## 📦 Data Availability

Raw COI sequences are deposited in **BOLD** (Barcode of Life Data System). Morphological identifications and specimen metadata are associated with museum voucher specimens held at the **Finnish Museum of Natural History (MZH)**. See `data/example/README.md` for the column structure of the input data frame.

---

## 📖 Citation

> Topalan U., Mutanen M., Godfray H.C.J., Sharkey M. *et al.* (in prep.) Concordance and discordance between morphological identification and DNA barcoding in Finnish Braconidae (Hymenoptera).

---

## 👥 Authors & Contributions

| Name | Affiliation | Role |
|------|-------------|------|
| **Ufuk Topalan** | University of Oulu | Analysis, writing, code |
| **Marko Mutanen** | University of Oulu | Supervision |
| **Charles Godfray** | University of Oxford | *Exotela* / Dacnusini morphology |
| **Mike Sharkey** | — | Braconidae taxonomy |

---

## 📄 License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.
