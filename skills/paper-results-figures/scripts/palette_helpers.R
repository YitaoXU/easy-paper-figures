# Palette sequence never changes scientific display order or opacity.
validate_palette_order_controls <- function(cfg) {
  mode <- cfg$palette_order
  seed <- cfg$palette_seed
  if (!is.character(mode) || length(mode) != 1L || is.na(mode) ||
      !mode %in% c("ordered", "shuffled"))
    stop("palette_order must be ordered or shuffled.")
  if (!is.numeric(seed) || length(seed) != 1L || !is.finite(seed) ||
      seed < 0 || seed > .Machine$integer.max || seed != floor(seed))
    stop("palette_seed must be a nonnegative integer within the R integer range.")
  invisible(TRUE)
}

# Select the original eligible colors first, then permute that same set. This
# preserves the selected fixed-color set, balance and any reserved focal slot.
order_palette_slots <- function(slots, palette, palette_order = "ordered", palette_seed = 42) {
  validate_palette_order_controls(list(palette_order = palette_order, palette_seed = palette_seed))
  ordered <- palette$ordered_slots
  if (is.null(ordered)) ordered <- seq_along(palette$categorical)
  ordered <- unlist(ordered, use.names = FALSE)
  if (!is.numeric(ordered) || anyNA(ordered) || any(ordered != floor(ordered)) ||
      !identical(sort(as.integer(ordered)), seq_along(palette$categorical)))
    stop("ordered_slots must be a complete permutation of the original categorical slots.")
  if (palette_order == "ordered") return(slots[order(match(slots, ordered))])
  if (length(slots) < 2L) return(slots)
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv)
  on.exit({
    if (had_seed) assign(".Random.seed", old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
      rm(".Random.seed", envir = .GlobalEnv)
  })
  set.seed(as.integer(palette_seed))
  slots[sample.int(length(slots))]
}

# Select fixed slots independently of identities and scientific values.
# For two/three colors, search fixed eligible slots instead of taking a prefix.
# Maximize the closest Lab pair; use relative balance to break equal minima.
# Including reserved slots in the score avoids a close comparator pair beside
# a distant focal color. Balanced families additionally constrain hue counts.
select_small_palette_slots <- function(slots, n, palette, reserved = integer()) {
  if (n < 0L || n > length(slots)) stop("More categories than eligible fixed palette slots.")
  if (!n) return(integer())
  if (identical(palette$categorical_assignment, "display-order")) return(slots[seq_len(n)])
  total <- n + length(reserved)
  hue_groups <- palette$categorical_hue_groups
  if (identical(palette$categorical_selection, "balanced-hues")) {
    groups <- lapply(hue_groups, function(x) as.integer(unlist(x)))
    flat <- unlist(groups, use.names = FALSE)
    if (length(groups) != 2L || anyNA(flat) || anyDuplicated(flat) ||
        !identical(sort(flat), seq_along(palette$categorical)))
      stop("Balanced palettes require two disjoint hue groups covering every fixed slot.")
    target <- c(ceiling(total / 2), floor(total / 2))
    needed <- target - vapply(groups, function(g) sum(reserved %in% g), integer(1))
    eligible <- lapply(groups, function(g) slots[slots %in% g])
    if (any(needed < 0L) || any(needed > lengths(eligible)))
      stop("Eligible palette slots cannot satisfy the balanced hue counts.")
    if (total > 3L || total < 2L) {
      return(unlist(Map(function(g, count) g[seq_len(count)], eligible, needed), use.names = FALSE))
    }
    candidates <- Filter(function(candidate) identical(
      unname(vapply(groups, function(g) sum(c(reserved, candidate) %in% g), integer(1))),
      as.integer(target)), utils::combn(slots, n, simplify = FALSE))
  } else {
    if (total < 2L || total > 3L || n == length(slots)) return(slots[seq_len(n)])
    candidates <- utils::combn(slots, n, simplify = FALSE)
  }
  rgb <- t(grDevices::col2rgb(palette$categorical)) / 255
  lab <- grDevices::convertColor(rgb, from = "sRGB", to = "Lab", scale.in = 1)
  distances <- as.matrix(stats::dist(lab))
  scores <- vapply(candidates, function(candidate) {
    chosen <- c(reserved, candidate)
    d <- distances[chosen, chosen, drop = FALSE]
    pairs <- d[lower.tri(d)]
    c(min(pairs), min(pairs) / max(pairs))
  }, numeric(2))
  best <- order(-scores[1, ], -scores[2, ], seq_along(candidates))[1]
  candidates[[best]]
}

fixed_palette_mapping <- function(categories, palette, palette_order = "ordered", palette_seed = 42) {
  keys <- unique(as.character(categories))
  if (!identical(palette$categorical_assignment, "display-order")) keys <- sort(keys, method = "radix")
  if (length(keys) > length(palette$categorical))
    stop("More categories than fixed palette slots; request an extended palette or provide an authorized named color_values map.")
  selected <- select_small_palette_slots(seq_along(palette$categorical), length(keys), palette)
  slots <- order_palette_slots(selected, palette, palette_order, palette_seed)
  setNames(palette$categorical[slots], keys)
}

# Model emphasis normally reserves hue slots. Display-sequence families instead
# follow the established caller order; neither policy infers a scientific focal.
resolve_model_palette_mapping <- function(categories, palette, focal = NULL,
                                          colors = NULL, saved_record = NULL,
                                          palette_order = "ordered", palette_seed = 42) {
  validate_palette_order_controls(list(palette_order = palette_order, palette_seed = palette_seed))
  keys <- unique(as.character(categories))
  if (!identical(palette$categorical_assignment, "display-order")) keys <- sort(keys, method = "radix")
  if (anyNA(keys) || any(!nzchar(keys))) stop("Model identities must be nonmissing and nonempty.")
  if (is.null(focal)) focal <- intersect("Ours", keys)
  if (!is.character(focal) || anyNA(focal) || anyDuplicated(focal) || any(!focal %in% keys))
    stop("Focal models must explicitly name distinct observed model identities.")
  focal <- sort(focal, method = "radix")
  if (!is.null(colors)) {
    result <- unlist(colors)
    if (!is.character(result) || is.null(names(result)) || anyDuplicated(names(result)) ||
        !all(keys %in% names(result)) || anyNA(result[keys]))
      stop("color_values must be a named color map covering every model.")
    invisible(grDevices::col2rgb(result))
    result <- result[keys]
    # A resolved configuration is an explicit map on replay; retain its original
    # mapping provenance when the recorded base colors still match exactly.
    old <- if (is.null(saved_record)) NULL else unlist(saved_record$base_colors)
    same <- !is.null(old) && setequal(names(old), keys) && identical(unname(old[keys]), unname(result))
    record <- if (same) saved_record else list(policy = "explicit-named-model-map",
      focal_models = focal, base_colors = as.list(result), palette_slots = NULL)
    return(list(colors = result, record = record))
  }
  if (identical(palette$categorical_assignment, "display-order")) {
    selected <- select_small_palette_slots(seq_along(palette$categorical), length(keys), palette)
    slots <- order_palette_slots(selected, palette, palette_order, palette_seed)
    result <- setNames(palette$categorical[slots], keys)
    return(list(colors = result, record = list(policy = "fixed-palette-display-sequence",
      focal_models = focal, display_order = keys, base_colors = as.list(result),
      palette_order = palette_order, palette_seed = palette_seed,
      palette_slots = as.list(setNames(slots, keys)))))
  }
  if (!length(focal)) {
    selected <- select_small_palette_slots(seq_along(palette$categorical), length(keys), palette)
    slots <- order_palette_slots(selected, palette, palette_order, palette_seed)
    result <- setNames(palette$categorical[slots], keys)
    return(list(colors = result, record = list(policy = "fixed-palette-model-identity",
      focal_models = character(), base_colors = as.list(result),
      palette_order = palette_order, palette_seed = palette_seed,
      palette_slots = as.list(setNames(slots, keys)))))
  }
  roles <- palette$focal_model_mapping
  if (is.null(roles)) stop("Palette has no fixed focal-model hue policy; provide an authorized named color_values map.")
  focal_slots <- as.integer(unlist(roles$focal_slots))
  comparator_slots <- as.integer(unlist(roles$comparator_slots))
  slots <- c(focal_slots, comparator_slots)
  if (!length(focal_slots) || !length(comparator_slots) || anyNA(slots) ||
      anyDuplicated(slots) || any(slots < 1L | slots > length(palette$categorical)))
    stop("Invalid fixed focal/comparator palette slots.")
  opponents <- setdiff(keys, focal)
  if (length(focal) > length(focal_slots))
    stop("More focal models than distinct reserved focal hue slots; provide an authorized named color_values map or select a palette with sufficient distinct focal slots.")
  if (length(opponents) > length(comparator_slots))
    stop("More comparator models than reserved contrasting palette slots; select a suitable palette or provide an authorized named color_values map. Automatic colors are never invented or recycled.")
  focal_used <- order_palette_slots(focal_slots[seq_along(focal)], palette, palette_order, palette_seed)
  eligible <- comparator_slots
  if (length(keys) <= 3L && !is.null(roles$small_set_comparator_slots)) {
    eligible <- as.integer(unlist(roles$small_set_comparator_slots))
    if (anyNA(eligible) || anyDuplicated(eligible) || any(eligible %in% focal_slots) ||
        any(eligible < 1L | eligible > length(palette$categorical)))
      stop("Invalid small-set comparator palette slots.")
  }
  selected <- select_small_palette_slots(eligible, length(opponents), palette, reserved = focal_used)
  opponent_used <- order_palette_slots(selected, palette, palette_order, palette_seed)
  assigned <- c(setNames(focal_used, focal), setNames(opponent_used, opponents))[keys]
  result <- setNames(palette$categorical[assigned], keys)
  list(colors = result, record = list(policy = if (identical(palette$categorical_selection, "balanced-hues")) "fixed-balanced-focal-model-slots" else "fixed-focal-model-hue-slots",
    focal_models = focal, base_colors = as.list(result), palette_slots = as.list(assigned),
    palette_order = palette_order, palette_seed = palette_seed,
    focal_hue_family = roles$focal_hue_family,
    comparator_hue_families = if (length(keys) <= 3L && !is.null(roles$small_set_comparator_hue_families))
      roles$small_set_comparator_hue_families else roles$comparator_hue_families))
}

# A fixed, mark-family-specific transform; keep base palette slots unchanged.
darken_palette_colors <- function(colors, amount) {
  if (!is.numeric(amount) || length(amount) != 1 || !is.finite(amount) || amount < 0 || amount > 1)
    stop("point_darken must be a number between 0 and 1.")
  channels <- grDevices::col2rgb(colors) * (1 - amount)
  result <- grDevices::rgb(channels[1, ], channels[2, ], channels[3, ], maxColorValue = 255)
  if (!is.null(names(colors))) names(result) <- names(colors)
  result
}
