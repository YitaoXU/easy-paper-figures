# Resolve actual Arial faces rather than accepting a system fallback.
resolve_arial_fonts <- function() {
  faces <- list(regular = c(FALSE, FALSE), bold = c(TRUE, FALSE),
                italic = c(FALSE, TRUE), bold_italic = c(TRUE, TRUE))
  lapply(faces, function(face) {
    match <- systemfonts::match_fonts("Arial", italic = face[2], weight = if (face[1]) "bold" else "normal")
    info <- systemfonts::font_info(path = match$path[1], index = match$index[1])
    if (!identical(info$family[1], "Arial")) stop("Arial is unavailable. Install the actual Arial family; font substitution is not allowed.")
    list(path = match$path[1], index = match$index[1], name = info$name[1])
  })
}

arial_pdf_device <- function(filename, width, height, bg = "white", ...) {
  if (identical(Sys.info()[["sysname"]], "Darwin") && capabilities("aqua")) {
    grDevices::quartz(type = "pdf", file = filename, width = width, height = height,
                     family = "Arial", bg = bg)
  } else if (capabilities("cairo")) {
    grDevices::cairo_pdf(filename = filename, width = width, height = height,
                        family = "Arial", bg = bg)
  } else stop("An Arial-capable PDF backend is required: Quartz on macOS or a working Cairo backend.")
}

verify_pdf_arial <- function(path) {
  executable <- Sys.which("pdffonts")
  if (!nzchar(executable)) stop("PDF font verification requires pdffonts from Poppler.")
  report <- system2(executable, shQuote(path), stdout = TRUE, stderr = TRUE)
  status <- attr(report, "status")
  if (!is.null(status) && status != 0) stop("PDF font inspection failed: ", paste(report, collapse = " "))
  rows <- report[-seq_len(min(2, length(report)))]
  rows <- rows[nzchar(trimws(rows))]
  if (!length(rows)) stop("PDF has no inspectable text fonts.")
  entries <- strsplit(trimws(rows), "\\s+", perl = TRUE)
  names <- vapply(entries, function(x) sub("^[A-Z]{6}\\+", "", x[1]), character(1))
  embedded <- vapply(entries, function(x) length(x) >= 8 && x[length(x) - 4] == "yes", logical(1))
  allowed <- c("Arial", "ArialMT", "Arial-BoldMT", "Arial-ItalicMT", "Arial-BoldItalicMT")
  if (!all(names %in% allowed) || !all(embedded)) stop("PDF font check failed: every font must be embedded Arial.")
  list(family = "Arial", fonts = unique(names), all_embedded = TRUE)
}

embed_arial_in_svg <- function(path, faces) {
  svg <- paste(readLines(path, warn = FALSE), collapse = "\n")
  families <- regmatches(svg, gregexpr("font-family:[^;]+;", svg, perl = TRUE))[[1]]
  if (!length(families) || any(!grepl("^font-family: *['\"]?Arial['\"]?;", families))) {
    stop("SVG text must explicitly use Arial throughout.")
  }
  rules <- vapply(names(faces), function(style) {
    face <- faces[[style]]
    if (face$index != 0 || !grepl("\\.ttf$", face$path, ignore.case = TRUE)) {
      stop("SVG embedding currently requires individual Arial TrueType font files.")
    }
    raw <- readBin(face$path, "raw", n = file.info(face$path)$size)
    # base64_enc wraps lines; unescaped newlines invalidate quoted CSS URLs.
    encoded <- gsub("[\r\n]", "", jsonlite::base64_enc(raw))
    sprintf("@font-face {font-family:'Arial';font-style:%s;font-weight:%s;src:url('data:font/ttf;base64,%s') format('truetype');}",
            if (grepl("italic", style)) "italic" else "normal",
            if (grepl("bold", style)) "700" else "400", encoded)
  }, character(1))
  style <- paste0("<style type='text/css'><![CDATA[\n", paste(rules, collapse = "\n"), "\n]]></style>")
  if (!grepl("<defs>", svg, fixed = TRUE)) stop("SVG definitions element is missing.")
  svg <- sub("<defs>", paste0("<defs>\n", style), svg, fixed = TRUE)
  writeLines(svg, path, useBytes = TRUE)
  list(family = "Arial", embedded_faces = names(faces))
}
