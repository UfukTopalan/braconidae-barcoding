# ============================================================
# 06_ml_trees.R
# Maximum likelihood tree visualisations
#
# Three case studies illustrating distinct discordance drivers:
#   A. BIN BOLD:AAA7636         — low COI divergence (MERGE)
#   B. Genus with all 4 categories — cryptic diversity / geography
#   C. Exotela (Dacnusini)      — operational misidentification
#
# Inputs:
#   tree          — ape phylo object (read from .treefile)
#   species_data2 — main data frame (from script 02)
#
# Outputs: ML tree PDFs and TIFFs in results/
# ============================================================

library(ape)
library(ggtree)
library(ggtreeExtra)
library(ggplot2)
library(dplyr)
library(ggnewscale)

cat_colors <- c(
  "MATCH"   = "#009E73",
  "MERGE"   = "#D73027",
  "MIXTURE" = "#756BB1",
  "SPLIT"   = "#F46D43"
)

# ── Helper: make BIN colour palette ──────────────────────────
make_bin_colors <- function(bin_levels) {
  setNames(
    colorRampPalette(c("#E41A1C", "#377EB8", "#4DAF4A",
                       "#984EA3", "#FF7F00", "#A65628",
                       "#F781BF", "#999999"))(length(bin_levels)),
    bin_levels
  )
}

# ── Helper: prune tree to target tips ────────────────────────
prune_to_tips <- function(tree, target_tips) {
  drop.tip(tree, tree$tip.label[!tree$tip.label %in% target_tips])
}

# ── Helper: add BIN square layer ─────────────────────────────
add_bin_squares <- function(p, tree_meta, x_offset = 1.35) {
  tip_positions <- p$data %>%
    filter(isTip) %>%
    select(label, y)

  bin_data <- tree_meta %>%
    left_join(tip_positions, by = "label") %>%
    filter(!is.na(y))

  x_max  <- max(p$data$x, na.rm = TRUE)
  x_tile <- x_max * x_offset

  p +
    new_scale_fill() +
    geom_point(data = bin_data,
               aes(x = x_tile, y = y, fill = assigned_bin),
               shape = 22, size = 7, color = "white",
               inherit.aes = FALSE) +
    geom_segment(data = bin_data,
                 aes(x = x_max * 1.18, xend = x_tile * 0.98,
                     y = y, yend = y),
                 linetype = "dotted", linewidth = 0.3,
                 color = "grey60", inherit.aes = FALSE) +
    scale_fill_manual(name = "BIN",
                      values = make_bin_colors(levels(bin_data$assigned_bin)))
}

# ── Node label filter: SH-aLRT >= 70, UFBoot >= 80 ──────────
node_label_expr <- function(label) {
  ifelse(
    suppressWarnings(as.numeric(sub("/.*", "", label))) >= 70 &
      suppressWarnings(as.numeric(sub(".*/", "", label))) >= 80,
    label, ""
  )
}

# ════════════════════════════════════════════════════════════
# CASE STUDY A — BIN BOLD:AAA7636 (low COI divergence)
# ════════════════════════════════════════════════════════════

target_bin  <- "BOLD:AAA7636"
target_tips <- species_data2 %>%
  filter(assigned_bin == target_bin) %>%
  pull(tip_label)

pruned_tree <- prune_to_tips(tree, target_tips)

tree_meta_bin <- species_data2 %>%
  filter(tip_label %in% target_tips) %>%
  select(tip_label, Species, Genus, Subfamily,
         assigned_bin, category, `Specimen Tags`) %>%
  rename(label = tip_label, protocol = `Specimen Tags`) %>%
  mutate(assigned_bin = factor(assigned_bin))

p_bin <- ggtree(pruned_tree, layout = "rectangular", linewidth = 0.6) %<+%
  tree_meta_bin +
  geom_tippoint(aes(color = category), size = 5) +
  geom_tiplab(aes(label = gsub("_", " ", Species)),
              size = 5, offset = 0.001, fontface = "italic") +
  geom_nodelab(aes(label = node_label_expr(label)),
               size = 4, nudge_y = 0.15, hjust = 0) +
  scale_color_manual(name = "Concordance", values = cat_colors, na.value = "grey60") +
  geom_treescale(fontsize = 5, linesize = 0.5, offset = 0.2) +
  theme_tree() +
  theme(legend.position = "right",
        legend.text  = element_text(size = 16),
        legend.title = element_text(size = 16, face = "bold"),
        plot.margin  = margin(10, 120, 10, 10))

p_bin_final <- add_bin_squares(p_bin, tree_meta_bin)

print(p_bin_final)
ggsave(paste0("results/BIN_AAA7636_tree.pdf"),
       plot = p_bin_final,
       width = 20, height = max(10, length(target_tips) * 0.5),
       units = "in")

# ════════════════════════════════════════════════════════════
# CASE STUDY B — genus with all four concordance categories
# Change target_genus to whichever genus you select
# ════════════════════════════════════════════════════════════

target_genus <- "Phaenocarpa"   # <-- update as needed

target_tips <- tree$tip.label[grepl(paste0("^", target_genus, "_"),
                                    tree$tip.label)]
pruned_tree  <- prune_to_tips(tree, target_tips)

tree_meta_genus <- species_data2 %>%
  filter(tip_label %in% target_tips) %>%
  select(tip_label, Species, Genus, Subfamily,
         assigned_bin, category, `Specimen Tags`) %>%
  rename(label = tip_label, protocol = `Specimen Tags`) %>%
  mutate(assigned_bin = factor(assigned_bin))

p_genus <- ggtree(pruned_tree, layout = "rectangular", linewidth = 0.6) %<+%
  tree_meta_genus +
  geom_tippoint(aes(color = category), size = 5) +
  geom_tiplab(aes(label = gsub("_", " ", Species)),
              size = 5, offset = 0.001, fontface = "italic") +
  geom_nodelab(aes(label = node_label_expr(label)),
               size = 4, nudge_y = -0.2, hjust = 0) +
  scale_color_manual(name = "Concordance", values = cat_colors, na.value = "grey60") +
  geom_treescale(fontsize = 5, linesize = 0.5, offset = 0.2) +
  theme_tree() +
  theme(legend.position = "right",
        legend.text  = element_text(size = 13),
        legend.title = element_text(size = 14, face = "bold"),
        plot.margin  = margin(10, 120, 10, 10))

p_genus_final <- add_bin_squares(p_genus, tree_meta_genus) +
  guides(color = guide_legend(order = 1), fill = guide_legend(order = 2))

print(p_genus_final)
ggsave(paste0("results/", target_genus, "_MLTree.pdf"),
       plot   = p_genus_final,
       width  = 20,
       height = max(10, length(target_tips) * 0.5),
       units  = "in")

# ════════════════════════════════════════════════════════════
# CASE STUDY C — Exotela (operational misidentification)
# Charles Godfray's morphological corrections (10 specimens)
# ════════════════════════════════════════════════════════════

charles_corrections <- data.frame(
  sample_id = c(
    "MZH_GQ.1001", "MZH_GQ.243",  "MZH_GQ.244",
    "MZH_GQ.1145", "MZH_GQ.1146", "MZH_GQ.246",
    "MZH_GQ.327",  "MZH_GQ.331",  "MZH_GQ.332",
    "MZH_GQ.333"
  ),
  corrected_name = c(
    "Antrusa flavicoxa",  "Antrusa flavicoxa",  "Antrusa vaenia",
    "Antrusa vaenia",     "Antrusa vaenia",      "Antrusa melanocera",
    "Exotela dives",      "Exotela cyclogaster", "Exotela cyclogaster",
    "Antrusa melanocera"
  ),
  stringsAsFactors = FALSE
)

target_tips <- tree$tip.label[grepl("^Exotela_", tree$tip.label)]
pruned_tree  <- prune_to_tips(tree, target_tips)

tree_meta_ex <- species_data2 %>%
  filter(tip_label %in% target_tips) %>%
  select(tip_label, Species, `Sample ID`, assigned_bin, category, `Specimen Tags`) %>%
  rename(label = tip_label, sample_id = `Sample ID`, protocol = `Specimen Tags`) %>%
  left_join(charles_corrections, by = "sample_id") %>%
  mutate(
    correction_status = ifelse(!is.na(corrected_name),
                               "Morphologically corrected",
                               "Original identification"),
    display_label = case_when(
      !is.na(corrected_name) ~ paste0(gsub("_", " ", Species), " \u2192 ", corrected_name),
      TRUE                   ~ gsub("_", " ", Species)
    ),
    assigned_bin = factor(assigned_bin)
  )

label_colors <- c(
  "Original identification"   = "grey20",
  "Morphologically corrected" = "#1A78C2"
)

p_ex <- ggtree(pruned_tree, layout = "rectangular", linewidth = 0.6) %<+%
  tree_meta_ex +
  geom_tippoint(aes(color = category), size = 5) +
  geom_tiplab(aes(label = display_label, color = correction_status),
              size = 5, offset = 0.001, fontface = "italic") +
  geom_nodelab(aes(label = node_label_expr(label)),
               size = 3.8, nudge_y = 0, hjust = 0) +
  scale_color_manual(
    name   = "Concordance",
    values = c(cat_colors, label_colors),
    breaks = names(cat_colors),
    guide  = guide_legend(override.aes = list(size = 5, shape = 16))
  ) +
  geom_treescale(fontsize = 5, linesize = 0.5, offset = 0.2) +
  theme_tree() +
  theme(legend.position = "right",
        legend.text  = element_text(size = 13),
        legend.title = element_text(size = 14, face = "bold"),
        plot.margin  = margin(10, 120, 10, 10))

p_ex_final <- add_bin_squares(p_ex, tree_meta_ex, x_offset = 1.45) +
  theme(plot.margin = margin(10, 160, 30, 10))

print(p_ex_final)
ggsave("results/Exotela_corrections_tree.pdf",
       plot   = p_ex_final,
       width  = 22,
       height = max(10, length(target_tips) * 0.65),
       units  = "in")

# TIFF exports
ggsave("results/Exotela_corrections_tree.tiff",
       plot = p_ex_final,
       width = 22, height = max(10, length(target_tips) * 0.65),
       units = "in", dpi = 600, compression = "lzw")
