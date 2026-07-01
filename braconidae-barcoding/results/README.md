# Results

This directory is populated by running the R scripts in order. All output files are excluded from version control (see `.gitignore`) and must be regenerated locally.

## Expected outputs

| File | Script | Figure in paper |
|------|--------|----------------|
| `Age_VS_length.pdf` | `01_sequencing_quality.R` | Fig. S1 |
| `concordance_barplot.pdf` | `02_concordance_categories.R` | Fig. 1 |
| `top_Subfamily_discordance.pdf` | `03_taxonomic_hotspots.R` | Fig. 2A |
| `top_genus_discordance.pdf` | `03_taxonomic_hotspots.R` | Fig. 2B |
| `top_discordanceAB.pdf` | `03_taxonomic_hotspots.R` | Fig. 2 (combined) |
| `bin_discordance_depth.pdf` | `04_taxonomic_depth.R` | Fig. S2 |
| `sequence_length_concordance.pdf` | `05_sequence_glm.R` | Fig. S3A |
| `GLM_length_concordance.pdf` | `05_sequence_glm.R` | Fig. S3B |
| `BIN_AAA7636_tree.pdf` | `06_ml_trees.R` | Fig. 3 |
| `<genus>_MLTree.pdf` | `06_ml_trees.R` | Fig. 4 |
| `Exotela_corrections_tree.pdf` | `06_ml_trees.R` | Fig. 5 |

All PDFs also have `.tiff` equivalents (600 dpi, LZW compression) for journal submission.
