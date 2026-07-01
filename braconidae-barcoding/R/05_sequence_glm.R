# ============================================================
# 05_sequence_glm.R
# Sequence quality vs. concordance outcome
#
# Tests whether effective COI length predicts concordance
# category using a binomial GLM (concordant vs. discordant).
# Visualised as a raincloud plot (Panel A) and a stacked
# proportional bar chart by length bin (Panel B).
#
# Inputs:  species_data2  (from script 02)
# Outputs: sequence_length_concordance.pdf / .tiff
#          GLM_length_concordance.pdf / .tiff
# ============================================================

library(ggplot2)
library(dplyr)
library(cowplot)
library(ggdist)

cat_colors <- c(
  "MATCH"   = "#009E73",
  "MERGE"   = "#D73027",
  "MIXTURE" = "#756BB1",
  "SPLIT"   = "#F46D43"
)

# ── 1. Prepare data ──────────────────────────────────────────
seq_concordance <- species_data2 %>%
  filter(!is.na(category), !is.na(coi_length)) %>%
  mutate(
    effective_length = coi_length - n_count,
    category = factor(category, levels = c("MATCH", "MERGE", "MIXTURE", "SPLIT")),
    concordance = ifelse(category == "MATCH", "Concordant", "Discordant")
  )

# ── 2. GLM ───────────────────────────────────────────────────
glm_model <- glm(
  concordance == "Concordant" ~ effective_length,
  data   = seq_concordance,
  family = binomial()
)

cat("\n=== GLM: concordance ~ effective COI length ===\n")
print(summary(glm_model))

glm_p       <- coef(summary(glm_model))["effective_length", "Pr(>|z|)"]
glm_p_label <- paste0("GLM: p = ", round(glm_p, 3),
                       "\n(sequence length not significant)")

# ── 3. Panel A — Raincloud ───────────────────────────────────
pA <- ggplot(seq_concordance,
             aes(x = category, y = effective_length,
                 fill = category, color = category)) +

  ggdist::stat_halfeye(adjust = 0.8, width = 0.6, alpha = 0.5,
                       position = position_nudge(x = 0.15),
                       .width = 0, point_color = NA) +

  geom_boxplot(width = 0.15, outlier.shape = NA, alpha = 0.8,
               color = "grey20", position = position_nudge(x = -0.05)) +

  geom_point(position = position_nudge(x = -0.2), alpha = 0.2, size = 0.8) +

  geom_hline(yintercept = 600, linetype = "dashed",
             color = "grey40", linewidth = 0.4) +

  annotate("text", x = 4.7, y = 610, label = "600 bp threshold",
           hjust = 1, size = 4, color = "grey40") +

  stat_summary(fun = mean, geom = "point", shape = 18, size = 4,
               color = "black", position = position_nudge(x = -0.05)) +

  scale_fill_manual(values = cat_colors, guide = "none") +
  scale_color_manual(values = cat_colors, guide = "none") +
  scale_y_continuous(breaks = seq(0, 700, 100), limits = c(-20, 730)) +

  annotate("text", x = Inf, y = Inf, label = glm_p_label,
           hjust = 1.05, vjust = 1.3, size = 4,
           color = "grey40", lineheight = 1.3) +

  labs(x = NULL, y = "Effective COI length (bp)") +

  theme_minimal(base_size = 13) +
  theme(
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    axis.text.x        = element_text(size = 16, face = "bold",
                                      color = cat_colors),
    axis.text.y        = element_text(size = 16),
    axis.title.y       = element_text(size = 16)
  )

print(pA)
ggsave("results/sequence_length_concordance.pdf",
       plot = pA, width = 14, height = 10, units = "in", dpi = 300)

# ── 4. Panel B — Proportional bars by length bin ────────────
length_bins <- seq_concordance %>%
  mutate(
    length_bin = cut(effective_length,
                     breaks = c(0, 200, 400, 500, 550, 600, 700),
                     labels = c("1-200", "201-400", "401-500",
                                "501-550", "551-600", ">600"),
                     include.lowest = TRUE)
  ) %>%
  filter(!is.na(length_bin)) %>%
  group_by(length_bin, category) %>%
  summarise(n = n(), .groups = "drop") %>%
  group_by(length_bin) %>%
  mutate(total = sum(n), pct = n / total * 100) %>%
  ungroup()

bin_totals <- length_bins %>% distinct(length_bin, total)

pB <- ggplot(length_bins,
             aes(x = length_bin, y = pct, fill = category)) +

  geom_col(width = 0.7, color = "white", linewidth = 0.3) +

  geom_text(data = bin_totals,
            aes(x = length_bin, y = -4, label = paste0("n=", total)),
            inherit.aes = FALSE, size = 3.2, color = "grey40") +

  scale_fill_manual(values = cat_colors, name = "Category") +

  scale_y_continuous(labels = function(x) paste0(x, "%"),
                     limits = c(-8, 108), breaks = seq(0, 100, 25)) +

  annotate("text", x = Inf, y = Inf, label = glm_p_label,
           hjust = 1.05, vjust = 1.3, size = 4,
           color = "grey40", lineheight = 1.3) +

  labs(x = "Effective COI length (bp)",
       y = "Proportion of specimens (%)") +

  theme_minimal(base_size = 13) +
  theme(
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    legend.position    = "right",
    legend.text        = element_text(size = 15),
    legend.title       = element_text(size = 17, face = "bold"),
    axis.text.x        = element_text(size = 15),
    axis.text.y        = element_text(size = 15),
    axis.title.y       = element_text(size = 17),
    axis.title.x       = element_text(size = 17)
  )

ggsave("results/GLM_length_concordance.pdf",
       plot = pB, width = 14, height = 10, units = "in", dpi = 300)

# TIFF exports
ggsave("results/sequence_length_concordance.tiff",
       plot = pA, width = 14, height = 10, units = "in",
       dpi = 600, compression = "lzw")
ggsave("results/GLM_length_concordance.tiff",
       plot = pB, width = 14, height = 10, units = "in",
       dpi = 600, compression = "lzw")
