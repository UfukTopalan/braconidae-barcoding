# Data Structure

Raw specimen and sequencing data are not included in this repository due to data sharing agreements with the Finnish Museum of Natural History (MZH) and BOLD Systems. Access to the full dataset can be requested from the corresponding author.

## Expected input: `species_data2`

The core data frame used throughout the R scripts has the following structure:

| Column | Type | Description |
|--------|------|-------------|
| `Sample ID` | character | Museum voucher ID (e.g. `MZH_GQ.243`) |
| `Species` | character | Morphological species name (binomial) |
| `Genus` | character | Genus |
| `Subfamily` | character | Subfamily |
| `assigned_bin` | character | BOLD BIN identifier (e.g. `BOLD:AAA7636`) |
| `tip_label` | character | Tip label matching the `.treefile` (e.g. `Exotela_dives_MZH_GQ.327`) |
| `coi_length` | integer | Raw COI sequence length (bp) |
| `n_count` | integer | Number of ambiguous bases (N) in the sequence |
| `Specimen Tags` | character | Sequencing protocol (`CCDB:NGSFT` = FOA; `CCDB:SMRT` = SMRT) |
| `category` | character | Concordance category — added by `02_concordance_categories.R` |

## Expected input: `age_data`

Used by `01_sequencing_quality.R`:

| Column | Type | Description |
|--------|------|-------------|
| `specimen_age_years` | numeric | Age of specimen at time of sequencing (years) |
| `coi_length` | integer | Raw COI sequence length (bp) |
| `n_count` | integer | Number of ambiguous N bases |
| `protocol` | character | Sequencing protocol (`CCDB:NGSFT` or `CCDB:SMRT`) |

## Tree file

The ML tree (`.treefile` from IQ-TREE2) should be loaded with:

```r
library(ape)
tree <- read.tree("path/to/your.treefile")
```

Tip labels must match the `tip_label` column in `species_data2`.
Node labels are in the format `SH-aLRT/UFBoot` (e.g. `95/98`).
