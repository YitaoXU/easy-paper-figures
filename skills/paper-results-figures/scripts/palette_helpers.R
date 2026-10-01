# Fixed categorical slots, independent of performance, row order and plot family.
fixed_palette_mapping <- function(categories, palette) {
  keys <- sort(unique(as.character(categories)), method = "radix")
  if (length(keys) > length(palette$categorical))
    stop("More categories than fixed palette slots; request an extended palette or provide an authorized named color_values map.")
  setNames(palette$categorical[seq_along(keys)], keys)
}

# Model emphasis uses reserved hue families rather than the ordered-prefix map.
# Never select a focal identity from observed scores, rankings or display order.
resolve_model_palette_mapping <- function(categories, palette, focal = NULL,
                                          colors = NULL, saved_record = NULL) {
  keys <- sort(unique(as.character(categories)), method = "radix")
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
  if (!length(focal)) {
    result <- fixed_palette_mapping(keys, palette)
    return(list(colors = result, record = list(policy = "fixed-palette-model-identity",
      focal_models = character(), base_colors = as.list(result),
      palette_slots = as.list(setNames(seq_along(keys), keys)))))
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
  assigned <- c(setNames(focal_slots[seq_along(focal)], focal),
                setNames(comparator_slots[seq_along(opponents)], opponents))[keys]
  result <- setNames(palette$categorical[assigned], keys)
  list(colors = result, record = list(policy = "fixed-focal-model-hue-slots",
    focal_models = focal, base_colors = as.list(result), palette_slots = as.list(assigned),
    focal_hue_family = roles$focal_hue_family, comparator_hue_families = roles$comparator_hue_families))
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
