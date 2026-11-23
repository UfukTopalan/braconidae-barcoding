# Concordance Category Assignment Logic

This document explains how each morphospecies is assigned to one of four concordance categories based on its relationship with BOLD BINs.

## Definitions

A **BIN** (Barcode Index Number) is an algorithmically generated cluster on BOLD Systems, analogous to an OTU in metabarcoding. Each specimen receives one BIN.

A BIN is **exclusive** to a species if it contains specimens of that species only.  
A BIN is **shared** if it contains specimens of two or more morphospecies.

## The four categories

| Category | Conditions | Biological interpretation |
|----------|-----------|--------------------------|
| **MATCH** | 1 BIN, exclusive | BIN and morphospecies boundaries agree |
| **MERGE** | ≥1 BIN, none exclusive | Multiple morphospecies collapsed into shared BINs; genetic divergence below BIN threshold or oversplitting of the species |
| **SPLIT** | >1 BIN, all exclusive | Single morphospecies spans multiple BINs; potential cryptic diversity |
| **MIXTURE** | >1 BIN; ≥1 exclusive AND ≥1 shared | Complex pattern; possible cryptic diversity combined with misidentification or gene flow |


## Implementation

```r
# Step 1: flag whether each BIN is exclusive to the focal species
species_bin_detail <- species_data2 %>%
  distinct(Species, assigned_bin) %>%
  left_join(
    species_data2 %>%
      group_by(assigned_bin) %>%
      summarise(n_species_in_bin = n_distinct(Species)),
    by = "assigned_bin"
  ) %>%
  mutate(bin_is_exclusive = (n_species_in_bin == 1))

# Step 2: summarise per species
species_category <- species_bin_detail %>%
  group_by(Species) %>%
  summarise(
    n_bins           = n_distinct(assigned_bin),
    n_exclusive_bins = sum(bin_is_exclusive),
    n_shared_bins    = sum(!bin_is_exclusive)
  ) %>%
  mutate(
    category = case_when(
      n_bins == 1 & n_exclusive_bins == 1                     ~ "MATCH",
      n_bins  > 1 & n_shared_bins == 0                        ~ "SPLIT",
      n_exclusive_bins == 0                                    ~ "MERGE",
      n_bins  > 1 & n_exclusive_bins > 0 & n_shared_bins > 0  ~ "MIXTURE"
    )
  )
```

## Discordance rate

All categories other than MATCH are considered **discordant**. Discordance rate is reported both with and without singleton species (n = 1 specimen), since singletons cannot be reliably assigned to SPLIT and inflate MERGE.
