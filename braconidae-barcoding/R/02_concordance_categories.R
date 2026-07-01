# ============================================================
# 02_concordance_categories.R
# BIN–morphospecies concordance category assignment
#
# Categories (after Edwards et al.):
#   MATCH   — 1 BIN, exclusive to the morphospecies
#   MERGE   — all BINs shared; no exclusive BIN for this species
#   SPLIT   — >1 BIN, all exclusive; none shared
#   MIXTURE — >1 BIN; at least one exclusive AND one shared
#
# Inputs:  species_data2  (data frame with columns:
#            Species, Genus, Subfamily, assigned_bin,
#            tip_label, Specimen Tags, ...)
# Outputs: species_summary  (species-level category table)
#          concordance_barplot.pdf / .tiff
# ============================================================

library(ggplot2)
library(dplyr)
library(scales)

# ── 1. Per-BIN exclusivity flag ──────────────────────────────
species_bin_detail <- species_data2 %>%
  filter(!is.na(assigned_bin), !is.na(Species)) %>%
  distinct(Species, assigned_bin) %>%
  left_join(
    species_data2 %>%
      filter(!is.na(assigned_bin), !is.na(Species)) %>%
      group_by(assigned_bin) %>%
      summarise(n_species_in_bin = n_distinct(Species), .groups = "drop"),
    by = "assigned_bin"
  ) %>%
  mutate(bin_is_exclusive = (n_species_in_bin == 1))

# ── 2. Species-level category assignment ─────────────────────
species_category <- species_bin_detail %>%
  group_by(Species) %>%
  summarise(
    n_bins           = n_distinct(assigned_bin),
    n_exclusive_bins = sum(bin_is_exclusive),
    n_shared_bins    = sum(!bin_is_exclusive),
    .groups = "drop"
  ) %>%
  mutate(
    category = case_when(
      n_bins == 1 & n_exclusive_bins == 1                          ~ "MATCH",
      n_bins  > 1 & n_shared_bins == 0                            ~ "SPLIT",
      n_exclusive_bins == 0                                        ~ "MERGE",
      n_bins  > 1 & n_exclusive_bins > 0 & n_shared_bins > 0      ~ "MIXTURE",
      TRUE ~ NA_character_
    )
  ) %>%
  select(Species, category)

# ── 3. Join back to main data ────────────────────────────────
species_data2 <- species_data2 %>%
  select(-any_of("category")) %>%
  left_join(species_category, by = "Species")

# ── 4. Species summary table ─────────────────────────────────
species_summary <- species_data2 %>%
  group_by(Species) %>%
  summarise(
    n_specimens = n(),
    n_bins      = n_distinct(assigned_bin, na.rm = TRUE),
    category    = first(category),
    .groups = "drop"
  ) %>%
  mutate(singleton_species = n_specimens == 1)

cat("=== Category breakdown ===\n")
species_summary %>%
  count(category) %>%
  mutate(pct = round(n / sum(n) * 100, 1)) %>%
  print()

# ── 5. Plot colours ──────────────────────────────────────────
cat_colors <- c(
  "MATCH"   = "#009E73",
  "MERGE"   = "#D73027",
  "MIXTURE" = "#756BB1",
  "SPLIT"   = "#F46D43"
)

cat_colors_light <- c(
  "MATCH"   = "#66D1AB",
  "MERGE"   = "#F4A582",
  "MIXTURE" = "#C2B0D8",
  "SPLIT"   = "#FDCDB0"
)

cat_levels <- c("MATCH", "MERGE", "MIXTURE", "SPLIT")

# ── 6. Build plotting table ───────────────────────────────────
plot_df <- species_summary %>%
  mutate(
    category = factor(category, levels = cat_levels),
    singleton = ifelse(n_specimens == 1,
                       "Singleton (n=1)",
                       "Non-singleton (n>1)"),
    singleton = factor(singleton,
                       levels = c("Non-singleton (n>1)", "Singleton (n=1)"))
  ) %>%
  count(category, singleton, name = "n") %>%
  group_by(category) %>%
  mutate(total_cat = sum(n)) %>%
  ungroup() %>%
  mutate(fill_color = ifelse(
    singleton == "Non-singleton (n>1)",
    cat_colors[as.character(category)],
    cat_colors_light[as.character(category)]
  ))

totals <- plot_df %>%
  distinct(category, total_cat) %>%
  mutate(
    prop_of_all = total_cat / sum(total_cat),
    lab = paste0(total_cat, "\n(", percent(prop_of_all, accuracy = 0.1), ")")
  )

concordant_n <- sum(species_summary$category == "MATCH", na.rm = TRUE)
discordant_n <- sum(species_summary$category != "MATCH", na.rm = TRUE)
all_n        <- nrow(species_summary)

corner_label <- paste0(
  "Concordant: ", concordant_n, " / ", all_n,
  " (", percent(concordant_n / all_n, 0.1), ")\n",
  "Discordant: ", discordant_n, " / ", all_n,
  " (", percent(discordant_n / all_n, 0.1), ")"
)

singleton_only_labels <- plot_df %>%
  filter(singleton == "Singleton (n=1)", n > 0) %>%
  mutate(label_text = paste0("Singleton\nn=", n))

# ── 7. Plot ──────────────────────────────────────────────────
p <- ggplot(plot_df,
            aes(x = category, y = n,
                fill = interaction(singleton, category))) +

  geom_col(color = "white", linewidth = 0.4, width = 0.65) +

  geom_text(data = singleton_only_labels,
            aes(label = label_text),
            position = position_stack(vjust = 0.5),
            size = 3.8, color = "white", fontface = "bold",
            lineheight = 0.9, inherit.aes = TRUE) +

  geom_text(data = totals,
            aes(x = category, y = total_cat, label = lab),
            inherit.aes = FALSE, vjust = -0.2, size = 4.5, lineheight = 0.9) +

  scale_fill_manual(
    values = setNames(
      c(cat_colors["MATCH"],   cat_colors_light["MATCH"],
        cat_colors["MERGE"],   cat_colors_light["MERGE"],
        cat_colors["MIXTURE"], cat_colors_light["MIXTURE"],
        cat_colors["SPLIT"],   cat_colors_light["SPLIT"]),
      c("Non-singleton (n>1).MATCH",   "Singleton (n=1).MATCH",
        "Non-singleton (n>1).MERGE",   "Singleton (n=1).MERGE",
        "Non-singleton (n>1).MIXTURE", "Singleton (n=1).MIXTURE",
        "Non-singleton (n>1).SPLIT",   "Singleton (n=1).SPLIT")
    ),
    guide = "none"
  ) +

  geom_vline(xintercept = 1.5, linetype = "dashed",
             color = "grey50", linewidth = 0.4) +

  annotate("text", x = Inf, y = Inf, label = corner_label,
           hjust = 1.05, vjust = 1.3, size = 5,
           lineheight = 1.4, color = "grey20") +

  scale_y_continuous(expand = expansion(mult = c(0, 0.18))) +

  labs(x = NULL, y = "Number of morphospecies") +

  theme_minimal(base_size = 14) +
  theme(
    legend.position    = "none",
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    axis.text.y        = element_text(size = 12),
    axis.title.y       = element_text(size = 13, margin = margin(r = 10)),
    axis.text.x        = element_text(size = 13, face = "bold",
                                      color = cat_colors[cat_levels])
  )

print(p)

# ── 8. Save ──────────────────────────────────────────────────
ggsave("results/concordance_barplot.pdf",
       plot = p, width = 11, height = 8.5, units = "in", dpi = 300)

ggsave("results/concordance_barplot.tiff",
       plot = p, width = 11, height = 8.5, units = "in",
       dpi = 600, compression = "lzw")
