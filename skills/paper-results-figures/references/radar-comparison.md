# Radar Comparison

Use `plot_type: radar-comparison` to display complete model profiles across three or more explicitly ordered metric or category axes. Radial profiles answer a different question from continuous trend regressions and categorical distributions. Color encodes model identity, with the same fixed palette slots as related figures. A compact ordinary model legend combines each model's line and icon, preferably in measured lower circle-corner whitespace. The defaults use a white background with circular guides, a solid perimeter, dashed inner rings, thin light-grey spokes, model-colored closed lines and small icons. Model polygon fills are off. Outer labels use readable Arial with measured canvas clearance.

## Input contract and scientific decisions

Supply a CSV with exactly one established numeric summary for each model-axis pair. Map the actual columns with `model`, `axis` and `value`; these defaults are names to override, not mandatory source headers. Model and axis identities are read as strings. Values must be numeric, finite and inside their declared domains. Every model must have every axis. Duplicate summaries, incomplete profiles and missing values are errors. The renderer performs no averaging, imputation, clipping, tests or inference from pooled scores.

`axis_order` is required, lists every observed axis exactly once and establishes clockwise spoke order from the top. At least three axes are necessary. `model_order` optionally establishes polygon/legend order; otherwise source first-occurrence order is preserved. Method colors follow the fixed focal/comparator palette contract, independently of display order: explicit visual focal selections take precedence, otherwise the exact raw ID `Ours` receives the reserved distinct focal hue. Comparator IDs use their fixed slots in sorted raw-identity order; saved or authorized named maps remain exact. Optional `focus_models` explicitly selects foreground profiles, rendered last with solid outlines while the remaining model profiles use dashed outlines. Foreground selection never changes numerical radii. Select foreground profiles from the scientific brief; do not infer them from observed performance. The `Ours` color fallback is a visual convention and does not select foreground profiles, numeric annotations or a statistical hypothesis. Optional `model_labels` and `axis_labels` are complete named display-label maps. `sampling_unit` records the established summary's scientific unit of observation; consult when unclear. Establish any aggregation outside this renderer with its provenance before plotting raw repeated measurements.

Choose the domain policy before rendering:

- `scale_mode: common-domain` is the default. It requires `unit` and a scientifically established `metric_domain: [lower, upper]` shared by every axis. Equal numerical ranges alone do not establish comparability. This mode is suitable for one metric measured across categories or multiple metrics with identical established units and domains. `direction` is `higher` by default; explicitly choose `lower` when lower scores are better. Radial tick labels display original domain units and the caption names the unit.
- `scale_mode: per-axis-domain` is opt-in for different domains, units or improvement directions. Provide a complete `axis_specs` map with an increasing two-number `domain`, explicit `unit` and `direction: higher|lower` for each axis. Require `normalization_reason` to explain why relative positions in these established domains are scientifically comparable. The numeric guide displays domain-scaled positions from 0 to 1 and the figure states that outward is better. Save original units/domains in the records and explain them in the manuscript caption. Never use observed model minima/maxima to choose the domains.

The exact transformation is `(value - domain_min) / (domain_max - domain_min)` for `higher` and its complement for `lower`. It maps the declared domain endpoints to 0 and 1, preserving full-precision raw and transformed values in `.plotted-data.csv` and `.statistics.json`. Values outside a domain are rejected. Zero radius means the declared endpoint, not a missing value. A reversed common scale is disclosed on the figure.

Do not rank models by polygon area: area depends on axis order, number, angles and domain definitions. Connecting adjacent spokes does not establish interpolation, correlation or a continuous covariate. This layout shows supplied profiles, not sampling uncertainty. Many models, long labels and optional value labels can become difficult to read; use a larger canvas, authorized shorter labels or a categorical profile/heatmap when necessary. Do not drop inconvenient axes or invent uncertainty to improve appearance. Identical units and domains remain a scientific assumption to establish with the user, not something the renderer can prove from a CSV.

## Configuration and invocation

Start from [the example](../examples/radar-comparison/request.json), replace placeholder paths and map the inspected source columns. Resolve a figure-specific output prefix `<output-parent>/<figure-name>/<figure-name>`. Relative paths resolve against the JSON's directory. A saved resolved configuration reuses its folder without additional nesting.

```sh
bash scripts/render.sh /path/to/config.json
```

Minimal common-domain configuration:

```json
{
  "plot_type": "radar-comparison",
  "input": "/path/to/summary.csv",
  "output_prefix": "/path/to/output/figure-name/figure-name",
  "model": "method_id",
  "axis": "category_id",
  "value": "score",
  "axis_order": ["Synthetic A", "Synthetic B", "Synthetic C"],
  "metric_domain": [0, 1],
  "unit": "unitless score"
}
```

These axis names and the domain are synthetic illustrations, not universal requirements. For a heterogeneous-axis example, replace the policy with:

```json
{
  "scale_mode": "per-axis-domain",
  "axis_specs": {
    "Synthetic A": {"domain": [0, 1], "unit": "unitless", "direction": "higher"},
    "Synthetic B": {"domain": [0, 20], "unit": "synthetic duration", "direction": "lower"},
    "Synthetic C": {"domain": [-2, 2], "unit": "synthetic signal", "direction": "higher"}
  },
  "normalization_reason": "Explain why relative established-domain position is comparable for these scientific endpoints."
}
```

The renderer also accepts `radial_breaks` (raw units for common-domain, scaled positions for per-axis-domain), `start_angle` (degrees, default 90), `clockwise` (default true), `palette`, complete named `color_values`, `line_color_values` and `shape_values`, `line_darken`, `fill_alpha`, `line_alpha`, `line_width`, `point_size`, `title`, `caption`, `panel_tag`, standard `width_mm`, `height_mm`, `layout_columns`, font-size controls, `formats` and `dpi`.

`muted-green-blue-purple` is the radar default. Its model curves, symbols, guide keys and optional raw-value labels use unchanged green/blue/purple base RGB with opaque `line_alpha: 1`; polygon fills remain off. Null/omitted `line_darken` resolves to zero for this palette and other non-rainbow palettes. Rainbow requests without color overrides retain a radar-specific `line_darken: 0.40` contrast transform, multiplying each base sRGB channel by 0.60 and converting to 8-bit RGB with `grDevices::rgb(maxColorValue = 255)`. An explicit amount in [0,1] applies that transform to base colors; zero preserves base RGB. This renderer-specific transform never alters palette definitions, categorical assignments, polygon fill RGB/opacity or other figure families.

Explicit `color_values`, including legacy saved base maps, resolves an omitted transform to zero, preserving the map exactly. A complete named `line_color_values` map directly overrides effective curve/icon colors, including saved effective maps. To change a saved transform or palette while requesting newly computed line colors, clear `line_color_values` to null; retain `color_values` for an existing category mapping, or clear it only when a new palette mapping is requested. Resolved configurations save base colors, effective colors and the amount separately; replay never darkens the effective map twice. Statistics save the color policy and opacity. None of these visual settings affects raw values, declared domains or radii.

### Ordinary model legend

`legend_position: auto` first measures the complete native icon-line-name guide using actual Arial at the fixed 6 pt default. It tests horizontal, wrapped and vertical layouts in the lower-left and lower-right whitespace outside the complete circular background. The interior guide has a white rectangular frame. Circle boundaries, model symbols, radial/outer-axis labels, optional raw-value labels, title, caption and panel tag are occupied geometry; the frame, including its stroke, must clear all of them and the canvas edge by `legend_clearance_mm: 0.7`. The search uses the actual final export geometry, never example-specific data coordinates or a smaller font.

When neither corner fits, automatic placement restores an unframed top external guide, measures its complete key/text width and reruns the radial panel geometry with its occupied rows. Long names or the smaller four-column canvas can legitimately trigger this fallback. The record retains the attempted layouts, measured circle and occupied bounds, chosen corner/frame bounds or fallback reason. A successful interior guide does not reserve an empty external legend row.

Explicit `legend_position: top|right` remains external and unframed. Explicit `lower-left|lower-right` requires safe fit in that requested corner and fails with a refinement explanation if impossible. Saved explicit positions, readable font sizes, colors and opacity remain authoritative. Wide names can require a wider canvas or authorized shorter `model_labels`; the renderer never clips the complete guide or silently reduces its font.

### Circular guides and optional raw labels

`grid_style: circular` is the default: white background, dashed inner circular guides and a solid outer perimeter at the declared domain endpoint. Custom `radial_breaks` never remove this perimeter. `grid_style: circular-bands` explicitly retains colored circular bands with solid guide rings. `band_colors` is a fixed inner-to-outer decorative color list, independent of model colors and observed results; `band_alpha` defaults to 0.28, lightening the background while retaining its warm-to-green sequence. Explicit saved band colors and opacity remain unchanged. Band boundaries use the declared radial guide positions and are recorded. These bands are visual guides, not empirical quantiles, probability intervals or calibrated performance thresholds. Light-grey `grid_color` and `grid_width: 0.18` retain the shared manuscript foundation. Model outlines default to 0.25 mm with 0.70 mm icons. `grid_style: polygon` retains the earlier plain polygon guide; `show_polygons: true` optionally adds model fills using the selected palette's unchanged fill opacity.

A request for the earlier pale green background, a green tinted concentric background or the warm-center-to-green-outer-ring style selects `grid_style: circular-bands`; see the [retained band-background example](../examples/radar-comparison-bands/request.json). Use its fixed band colors and opacity without copying decorative RGB values into the request. This retained variant changes only the background guides; it uses the same scientific domains, profile values, model colors and readable annotation defaults as the white version. When the brief asks for all profile lines to be solid, omit `focus_models`; selected raw-value annotations can still use `value_models` independently. A foreground-profile request retains the normal solid focal and dashed comparator convention. Do not substitute observed quantiles for the fixed decorative band intervals.

`radial_label_policy: endpoints` labels the established center and outer endpoint by default, leaving room for the data. `all` labels the requested radial breaks; `none` omits numeric guide labels and requires a caption/manuscript disclosure of the domains. The legacy `show_radial_labels: true|false` explicitly selects `all|none`; null uses the new policy. None of these settings changes domains, radii or observed values. The automatic ordinary guide uses a safe framed lower corner when available and an unframed top fallback; explicit right-side guides may need a wider canvas.

`show_values: true` requires an explicit `value_models` selection; the renderer never chooses models by performance. Values use the original units and three decimal places. Their default 1.5 mm font is fixed, not silently reduced when space is tight. `value_position: auto` searches coherent inward/outward radial offsets with modest tangential alternatives. Measured Arial text bounds must clear every model's vertices and line segments, outer/radial labels and already placed value labels. These geometry changes affect annotation positions only. `inside` or `outside` constrains that search; `value_offset` sets its initial radial distance, `value_clearance_mm` its physical breathing room, and a named `value_offsets` map sets per-model signed radial distances. No configuration uses example-specific point coordinates. Actual positions and bounds are saved. When readable placement is impossible, increase dimensions, select fewer explicitly authorized annotation models or refine offsets; the renderer fails rather than clipping labels or hiding observations.

## Deliverables and validation

Default exports are vector PDF, editable SVG with embedded Arial and 600 dpi PNG. The grouped folder also retains the resolved configuration, plotted raw/transformed observations, scientific domains/directions/limitations, source and renderer hashes, font verification and R session record. Captions wrap at word boundaries using actual Arial text grobs on the export device, retain explicit paragraph boundaries and scientific words, and reserve at least 0.7 mm from either canvas side. An unbreakable word that cannot fit is an error requiring a wider canvas or an authorized shorter caption; it is never silently clipped or abbreviated. Caption line widths and absolute bounds are recorded alongside the outer-axis bounds. Keep source/preparation snapshots, reproduction commands and visual inspection notes in that same external figure folder. Runtime paths and real data never belong in the skill.


Caption paragraphs wrap using measured Arial at the final canvas width before panel bounds are resolved. Long explanations reserve real device space; if that leaves an unreadable radial panel, increase the dimensions rather than clipping labels or silently shrinking type.
