# ============================================================
# 04_taxonomic_depth.R
# BIN-level discordance depth classification
#
# Classifies each BIN by the deepest taxonomic boundary
# crossed among its constituent specimens:
#   Concordant       — single species
#   Species-level    — multiple species, same genus
#   Genus-level      — multiple genera, same subfamily
#   Subfamily-level  — multiple subfamilies
#
# Inputs:  species_data2  (from script 02)
# Outputs: bin_discordance_depth.pdf / .tiff
# ============================================================

library(ggplot2)
library(dplyr)

depth_colors <- c(
  "Concordant"      = "#009E73",
  "Species-level"   = "#F4A582",
  "Genus-level"     = "#D73027",
  "Subfamily-level" = "#762A83"
)

# ── 1. BIN taxonomic composition ─────────────────────────────
bin_tax_depth <- species_data2 %>%
  filter(!is.na(assigned_bin)) %>%
  group_by(assigned_bin) %>%
  summarise(
    n_species   = n_distinct(Species),
    n_genus     = n_distinct(Genus),
    n_subfamily = n_distinct(Subfamily),
    n_specimens = n(),
    .groups = "drop"
  ) %>%
  mutate(
    discordance_level = case_when(
      n_species == 1                        ~ "Concordant",
      n_species > 1 & n_genus == 1         ~ "Species-level",
      n_genus > 1   & n_subfamily == 1     ~ "Genus-level",
      n_subfamily > 1                       ~ "Subfamily-level",
      TRUE                                  ~ "Unclassified"
    ),
    discordance_level = factor(
      discordance_level,
      levels = c("Concordant", "Species-level",
                 "Genus-level", "Subfamily-level")
    )
  )

cat("BIN discordance depth breakdown:\n")
bin_tax_depth %>%
  count(discordance_level) %>%
  mutate(pct = round(n / sum(n) * 100, 1)) %>%
  print()

# ── 2. Summary for plotting ───────────────────────────────────
bin_summary <- bin_tax_depth %>%
  count(discordance_level, name = "n_bins") %>%
  arrange(discordance_level) %>%
  mutate(
    pct   = round(n_bins / sum(n_bins) * 100, 1),
    label = paste0(n_bins, "\n(", pct, "%)")
  )

# ── 3. Plot ──────────────────────────────────────────────────
p <- ggplot(bin_summary,
            aes(x = discordance_level, y = n_bins,
                fill = discordance_level)) +

  geom_col(width = 0.65, color = "white", linewidth = 0.3) +

  geom_text(aes(label = label), vjust = -0.3, size = 5, lineheight = 0.9) +

  scale_fill_manual(values = depth_colors, guide = "none") +

  scale_y_continuous(expand = expansion(mult = c(0, 0.18))) +

  geom_vline(xintercept = 1.5, linetype = "dashed",
             color = "grey50", linewidth = 0.4) +

  annotate(
    "text", x = Inf, y = Inf,
    label = paste0(
      "Concordant BINs: ",
      bin_summary$n_bins[bin_summary$discordance_level == "Concordant"],
      " (", bin_summary$pct[bin_summary$discordance_level == "Concordant"], "%)\n",
      "Discordant BINs: ",
      sum(bin_summary$n_bins[bin_summary$discordance_level != "Concordant"]),
      " (",
      round(sum(bin_summary$n_bins[bin_summary$discordance_level != "Concordant"]) /
              sum(bin_summary$n_bins) * 100, 1), "%)"
    ),
    hjust = 1.05, vjust = 1.3, size = 4.8, color = "grey20", lineheight = 1.4
  ) +

  labs(x = NULL, y = "Number of BINs") +

  theme_minimal(base_size = 14) +
  theme(
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    axis.text.x        = element_text(size = 15, face = "bold"),
    axis.text.y        = element_text(size = 13),
    axis.title.y       = element_text(size = 15)
  )

print(p)

ggsave("results/bin_discordance_depth.pdf",
       plot = p, width = 12, height = 8, units = "in", dpi = 300)
ggsave("results/bin_discordance_depth.tiff",
       plot = p, width = 12, height = 8, units = "in",
       dpi = 600, compression = "lzw")
