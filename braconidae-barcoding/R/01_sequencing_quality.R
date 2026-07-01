# ============================================================
# 01_sequencing_quality.R
# COI effective length vs. specimen age — protocol comparison
#
# Inputs:  age_data  (data frame; columns: specimen_age_years,
#                     coi_length, n_count, protocol)
# Outputs: Age_VS_length.pdf / .tiff
# ============================================================

library(ggplot2)
library(dplyr)

# ── 1. Compute effective length & outcome category ──────────
age_data <- age_data %>%
  mutate(
    effective_length = coi_length - n_count,
    outcome = case_when(
      is.na(effective_length) | effective_length == 0 ~ "Fail (0 bp)",
      effective_length >= 600                          ~ "Full-length (\u2265600 bp)",
      effective_length > 0                             ~ "Partial (1-599 bp)"
    ),
    outcome = factor(outcome,
                     levels = c("Full-length (\u2265600 bp)",
                                "Partial (1-599 bp)",
                                "Fail (0 bp)"))
  )

# ── 2. Protocol display labels ───────────────────────────────
protocol_labels <- c(
  "CCDB:NGSFT" = "FOA (n=803)",
  "CCDB:SMRT"  = "SMRT (n=924)"
)

outcome_colors <- c(
  "Full-length (\u2265600 bp)" = "#2166AC",
  "Partial (1-599 bp)"         = "#F4A582",
  "Fail (0 bp)"                = "#B2182B"
)

# ── 3. Plotting data frame (fails plotted at 0 for LOESS) ───
age_data_plot <- age_data %>%
  mutate(
    plot_length = ifelse(outcome == "Fail (0 bp)", 0, effective_length),
    outcome = case_when(
      plot_length == 0   ~ "Fail (0 bp)",
      plot_length >= 600 ~ "Full-length (\u2265600 bp)",
      plot_length > 0    ~ "Partial (1-599 bp)"
    ),
    outcome = factor(outcome,
                     levels = c("Full-length (\u2265600 bp)",
                                "Partial (1-599 bp)",
                                "Fail (0 bp)"))
  )

# ── 4. Percentage labels ─────────────────────────────────────
pct_labels <- age_data_plot %>%
  group_by(protocol, outcome) %>%
  summarise(n = n(), .groups = "drop") %>%
  group_by(protocol) %>%
  mutate(
    pct   = round(n / sum(n) * 100, 1),
    label = paste0(pct, "%")
  )

# ── 5. Plot ──────────────────────────────────────────────────
p <- ggplot(age_data_plot,
            aes(x = specimen_age_years, y = plot_length)) +

  geom_count(aes(color = outcome, alpha = outcome), shape = 16) +

  scale_size_area(name = "Count", breaks = c(1, 5, 10, 20, 30), max_size = 10) +

  geom_smooth(method = "loess", se = TRUE,
              color = "black", fill = "grey30",
              alpha = 0.15, linewidth = 1, span = 1.2) +

  geom_hline(yintercept = 600, linetype = "dashed",
             color = "grey40", linewidth = 0.4) +

  geom_text(data = pct_labels,
            aes(label = label, color = outcome,
                y = case_when(
                  outcome == "Full-length (\u2265600 bp)" ~ 660,
                  outcome == "Partial (1-599 bp)"         ~ 350,
                  outcome == "Fail (0 bp)"                ~ 40
                )),
            x = Inf, hjust = 1.1, size = 3.8,
            fontface = "bold", inherit.aes = FALSE) +

  annotate("text", x = 118, y = 615, label = "600 bp threshold",
           hjust = 1, size = 3, color = "grey40") +

  scale_color_manual(values = outcome_colors, name = "Outcome",
                     guide = guide_legend(
                       override.aes = list(shape = 19, size = 6, alpha = 1)
                     )) +

  scale_alpha_manual(
    values = c("Full-length (\u2265600 bp)" = 0.7,
               "Partial (1-599 bp)"          = 0.35,
               "Fail (0 bp)"                 = 0.7),
    guide = "none") +

  scale_y_continuous(breaks = seq(0, 650, 100), limits = c(-20, 720)) +
  scale_x_continuous(breaks = seq(0, 120, 20), limits = c(0, 125)) +

  facet_wrap(~protocol, ncol = 1, scales = "fixed",
             labeller = labeller(protocol = protocol_labels)) +

  labs(x = "Specimen age at sequencing (years)",
       y = "Effective COI length (bp)") +

  theme_minimal(base_size = 13) +
  theme(
    legend.position  = "top",
    legend.text      = element_text(size = 13),
    legend.title     = element_text(size = 15, face = "bold"),
    strip.text       = element_text(size = 15, face = "bold"),
    panel.grid.minor = element_blank(),
    axis.text        = element_text(size = 13),
    axis.title       = element_text(size = 15),
    panel.spacing    = unit(1.5, "lines")
  )

print(p)

# ── 6. Save ──────────────────────────────────────────────────
ggsave("results/Age_VS_length.pdf",
       plot = p, width = 11.5, height = 8.5, units = "in",
       dpi = 300, device = cairo_pdf)

ggsave("results/Age_VS_length.tiff",
       plot = p, width = 11.5, height = 8.5, units = "in",
       dpi = 600, compression = "lzw")
