args <- commandArgs(trailingOnly = TRUE)
skill_dir <- normalizePath(args[[1]], mustWork = TRUE)
cache_dir <- normalizePath(args[[2]], mustWork = TRUE)
local_library <- file.path(cache_dir, "library")
dir.create(local_library, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(local_library, .libPaths()))
required <- readLines(file.path(skill_dir, "scripts", "dependencies.txt"))
required <- required[nzchar(required)]
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  install.packages(missing, lib = local_library, repos = "https://cloud.r-project.org")
}
if (!all(vapply(required, requireNamespace, logical(1), quietly = TRUE))) {
  stop("Required packages could not be loaded; no successful record was written.")
}
if (utils::packageVersion("ggplot2") < "3.5.0") stop("ggplot2 >= 3.5.0 is required. Update it in the local library, then refresh.")
source(file.path(skill_dir, "scripts", "font_export.R"))
arial_faces <- resolve_arial_fonts()
probe <- ggplot2::ggplot(data.frame(x = 1:3, y = c(1, 3, 2)), ggplot2::aes(x, y)) + ggplot2::geom_point() + ggplot2::theme_classic(base_family = "Arial") +
  ggplot2::labs(title = "Arial export check")
for (format in c("pdf", "svg", "png")) {
  path <- file.path(cache_dir, paste0(".device-check.", format))
  device <- switch(format, pdf = arial_pdf_device, svg = svglite::svglite, png = ragg::agg_png)
  ggplot2::ggsave(path, probe, device = device, width = 2, height = 2, dpi = 72)
  if (!file.exists(path) || file.info(path)$size == 0) stop("Export device check failed.")
  if (format == "pdf") verify_pdf_arial(path)
  if (format == "svg") embed_arial_in_svg(path, arial_faces)
  unlink(path)
}
record <- list(
  status = "ready", checked_at_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  host = unname(Sys.info()["nodename"]), R_version = R.version.string,
  platform = R.version$platform, R_home = R.home(), Rscript = Sys.which("Rscript"),
  libraries = .libPaths(), packages = setNames(lapply(required, function(p) as.character(utils::packageVersion(p))), required),
  fonts = list(family = "Arial", faces = arial_faces, pdf_fonts_verified = TRUE, svg_fonts_embedded = TRUE),
  installed_on_this_check = missing, verified_formats = c("pdf", "svg", "png")
)
jsonlite::write_json(record, file.path(cache_dir, "environment.json"), pretty = TRUE, auto_unbox = TRUE)
writeLines(capture.output(sessionInfo()), file.path(cache_dir, "environment-session.txt"))
message("R environment checked and recorded: ", file.path(cache_dir, "environment.json"))
