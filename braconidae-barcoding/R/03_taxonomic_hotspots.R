# ============================================================
# 03_taxonomic_hotspots.R
# Subfamily & genus discordance rates
#
# Panel A — Stacked horizontal bar: subfamily concordance
# Panel B — Lollipop chart: genus hotspots (n >= 20 species,
#           discordance rate >= overall rate)
#
# Inputs:  species_data2, species_summary  (from script 02)
# Outputs: top_Subfamily_discordance.pdf / .tiff
#          top_genus_discordance.pdf / .tiff
#          top_discordanceAB.pdf
# ============================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(forcats)
library(cowplot)

concordant_color <- "#009E73"
discordant_color <- "#882255"

# ── 1. Overall discordance rate ───────────────────────────────
overall_disc_rate  <- sum(species_summary$category != "MATCH", na.rm = TRUE) /
                      nrow(species_summary)
overall_disc_pct   <- paste0(round(overall_disc_rate * 100, 1), "%")

# ── 2. Subfamily summary (n >= 10 species) ───────────────────
subfamily_data <- species_data2 %>%
  group_by(Subfamily) %>%
  summarise(
    n_species        = n_distinct(Species),
    n_concordant     = n_distinct(Species[category == "MATCH"]),
    n_discordant     = n_distinct(Species[category != "MATCH"]),
    discordance_rate = n_discordant / n_species,
    .groups = "drop"
  ) %>%
  filter(n_species >= 2) %>%
  arrange(desc(discordance_rate))

subfam_filtered <- subfamily_data %>%
  filter(n_species >= 10) %>%
  mutate(
    Subfamily = fct_reorder(Subfamily, n_species)
  )

subfam_plot <- subfam_filtered %>%
  pivot_longer(cols = c(n_concordant, n_discordant),
               names_to = "status", values_to = "n") %>%
  mutate(
    status = ifelse(status == "n_concordant", "Concordant", "Discordant"),
    status = factor(status, levels = c("Concordant", "Discordant"))
  )

subfam_labels <- subfam_filtered %>%
  mutate(
    Subfamily  = fct_reorder(Subfamily, n_species),
    disc_label = paste0(round(discordance_rate * 100), "%"),
    label_x    = n_discordant / 2
  )

# ── 3. Panel A ───────────────────────────────────────────────
pA <- ggplot(subfam_plot,
             aes(y = Subfamily, x = n, fill = status)) +

  geom_col(width = 0.7, color = "white", linewidth = 0.3) +

  geom_text(data = subfam_labels,
            aes(y = Subfamily, x = n_species,
                label = paste0("n=", n_species)),
            inherit.aes = FALSE, hjust = -0.15, size = 5, color = "grey40") +

  geom_text(data = subfam_labels %>% filter(n_discordant >= 8),
            aes(y = Subfamily, x = label_x, label = disc_label),
            inherit.aes = FALSE, size = 4.5, color = "white", fontface = "bold") +

  scale_fill_manual(values = c("Concordant" = concordant_color,
                               "Discordant" = discordant_color)) +

  scale_x_continuous(expand = expansion(mult = c(0, 0.22))) +

  labs(x = "Number of morphospecies", y = NULL, fill = NULL) +

  theme_minimal(base_size = 16) +
  theme(
    legend.position    = "top",
    legend.text        = element_text(size = 15),
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    axis.text.y        = element_text(size = 15, face = "italic"),
    axis.text.x        = element_text(size = 13),
    axis.title.x       = element_text(size = 15)
  )

print(pA)
ggsave("results/top_Subfamily_discordance.pdf",
       plot = pA, width = 14, height = 8, units = "in", dpi = 300)

# ── 4. Genus summary (n >= 20, above overall rate) ───────────
genus_data <- species_data2 %>%
  group_by(Genus, Subfamily) %>%
  summarise(
    n_species        = n_distinct(Species),
    n_concordant     = n_distinct(Species[category == "MATCH"]),
    n_discordant     = n_distinct(Species[category != "MATCH"]),
    discordance_rate = n_discordant / n_species,
    .groups = "drop"
  ) %>%
  filter(n_species >= 20, discordance_rate >= overall_disc_rate) %>%
  arrange(desc(discordance_rate))

# ── 5. Panel B — lollipop ────────────────────────────────────
genus_plot <- genus_data %>%
  mutate(
    label    = paste0(Genus, "\n(", Subfamily, ")"),
    label    = factor(label, levels = genus_data %>%
                        arrange(discordance_rate) %>%
                        mutate(label = paste0(Genus, "\n(", Subfamily, ")")) %>%
                        pull(label)),
    disc_pct = paste0(round(discordance_rate * 100), "%")
  )

pB <- ggplot(genus_plot,
             aes(y = label, x = discordance_rate)) +

  geom_segment(aes(y = label, yend = label, x = 0, xend = discordance_rate),
               color = "grey70", linewidth = 0.6) +

  geom_point(aes(size = n_species), color = discordant_color, alpha = 0.85) +
  scale_size_area(max_size = 23) +

  geom_text(aes(label = paste0("n=", n_species)),
            size = 4, color = "white", fontface = "bold") +

  geom_text(aes(label = disc_pct, x = discordance_rate + 0.03),
            hjust = 0, size = 6, fontface = "bold", color = "grey20") +

  geom_vline(xintercept = overall_disc_rate,
             linetype = "dashed", color = "grey50", linewidth = 0.4) +

  annotate("text", x = overall_disc_rate - 0.01, y = nrow(genus_data) + 0.5,
           label = paste0("Overall discordance: ", overall_disc_pct),
           hjust = 1, size = 3.8, color = "grey50") +

  scale_x_continuous(limits = c(0, 1.08),
                     labels = scales::percent_format(accuracy = 1),
                     expand = expansion(mult = c(0.02, 0.05))) +

  labs(x = "Discordance rate", y = NULL) +
  guides(size = "none") +

  theme_minimal(base_size = 15) +
  theme(
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    axis.text.y        = element_text(size = 15, face = "italic"),
    axis.text.x        = element_text(size = 15),
    axis.title.x       = element_text(size = 17)
  )

print(pB)
ggsave("results/top_genus_discordance.pdf",
       plot = pB, width = 15, height = 10, units = "in", dpi = 300)

# ── 6. Combined panel ────────────────────────────────────────
combined <- plot_grid(pA, pB, ncol = 2, rel_widths = c(1.3, 1), align = "h")
ggsave("results/top_discordanceAB.pdf",
       plot = combined, width = 18, height = 8, units = "in", dpi = 300)

# TIFF exports
ggsave("results/top_Subfamily_discordance.tiff",
       plot = pA, width = 14, height = 8, units = "in",
       dpi = 600, compression = "lzw")
ggsave("results/top_genus_discordance.tiff",
       plot = pB, width = 15, height = 10, units = "in",
       dpi = 600, compression = "lzw")
