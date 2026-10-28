# Shared Figure Style

These defaults apply at final manuscript size. Explicit user choices override established figure-family settings, which override renderer defaults. Omitted fields resolve the selected category/layout profile; synthetic selections and scientific bounds are never defaults for unrelated input. Keep category-specific statistics, encodings and geometry in the [selected specification](figure-catalog.md), and fixed mark colors/transforms in the [palette contract](palette-contract.md).

## Numbers and inference

- Display measured values, measured-quantity size-guide labels, means and test statistics with **three decimal places**, including trailing zeros. Counts remain integers; preserve category names and IDs verbatim.
- Numeric axes, including continuous color, use compact adaptive decimals: `0.5`, `1.0`, `0.25`. Remove unnecessary trailing zeros while retaining at least one decimal. Use `scripts/formatting.R`.
- Compute and decide significance at full precision. Display `p-value < 0.05` when p < 0.05; otherwise `p-value = 0.xxx`. The threshold is `0.05`, not `0.050`; retain unrounded calculations in machine-readable records.

## Physical size and typography

Design for a 180 mm manuscript row: `layout_columns: 3` uses a complete 56 × 40 mm canvas; four columns use 42 × 40 mm, leaving 12 mm total row gutters. A two-slot horizontal compound uses 88 × 40 mm, including its 4 mm gutter. Selected compounds have [layout-specific sizes](multi-metric-comparison.md#choose-the-layout). `width_mm`/`height_mm` override legacy inch-valued `width`/`height`; change the millimeter values directly when adapting a resolved configuration.

Dimensions include titles, tags, axes, guides and annotations. Facet count does not multiply the canvas budget. Overview labels such as “Violin + points + SD” belong only to a contact sheet. Fit compound content using shared outer labels and measured gaps/ticks; establish a larger allocation only when readable scientific content cannot fit. Preserve paired scatter's square data panel. Prefer width greater than height, and record any authorized height increase.

Use **actual Arial everywhere**, verified/embedded through `scripts/font_export.R`, with ragg PNG output. Start with 7–8 pt titles/axis titles, 6–6.5 pt ticks/category names and comparable numeric annotations; ticks are about one point smaller than axis titles. Long category lists may use the documented approximately 5.6 pt profile, wrapping or an established taller allocation. Do not shrink fonts merely to force inherited geometry. The selected specification supplies profile overrides, including the compact four-column comparison profile.

For method/value text, `label_angle`, `value_angle` and `label_wrap` default to `auto`. Measure actual Arial on the final-size device for readable 0/45/90° rotation or wrapping; supported horizontal-label fits also allow modest 15°/30° rotation. Initial `text_fit_gap_mm` is 0.7 mm and minimum useful panel width is 12 mm. Check actual category positions, including grouped metric clusters. Preserve explicit angles/wrapping and record the fit in configuration/statistics. If content cannot fit, establish a wider canvas or authorized shorter display labels. Requested internal values must remain inside through supported measured refinement.

Center titles over the complete canvas, including ranking gutters. An optional bold Arial panel letter sits at the complete figure's left edge (at most slightly beyond), slightly above the title, without a detached tag margin. Build/measure layouts on an Arial-capable device.

## Marks, opacity and distributions

Use white backgrounds and shared dark-gray `#333333` axes: 0.25 mm baselines, 0.22 mm ticks with 1.3 pt length. Fixed palette RGB, opacity and darkening are governed by the [palette contract](palette-contract.md), including renderer-specific transforms. Keep line and fill opacity separate. Explicit per-figure overrides remain valid; clear resolved optional overrides when requesting new palette defaults. Automatic layout refinement may change geometry, size or jitter, not fixed color transforms.

Distribution defaults are 0.28 mm outer outlines, 0.22 mm internal/whisker lines and a median at 75% of outline thickness, with dark-gray border opacity 0.80. Box quartiles are solid; violin Q1/Q3 are dashed and stop at the density contour; medians are solid. SD overlays are 0.30 mm with a small white mean diamond. Quartiles and SD have different meanings. Raw-point size defaults to 0.36 mm when the densest retained method/metric group has at least 200 observations, otherwise 0.48 mm; this is a visual heuristic, not a scientific cutoff. Retain every observation. Crowded grouped boxes/violins omit internal mean/SD overlays by default while keeping summaries in records; explicit overlay requests remain authoritative.

Mean lines start at 0.38 mm with filled diamonds (shape 18): 2.3 mm for paired reference differences, 2.0 mm for dual/shared-axis means, 1.3 mm for ordinary/faceted means. Explicit marker settings take precedence; no raw scatter is added to line layers.

Ordinary bar/box widths start at 0.72/0.65 category units. Stacked two-metric bars use 0.84 width and 0.70 outer padding. Width and outer clearance are independent. Vertical padding starts at 0.50 for boxes (or enough for their width), 0.58 for violins, bar half-width + 0.18, and 0.46 for lines. Horizontal boxes reserve half box width + 0.24 beyond their centers; violins start at 0.64; bars retain about 0.24 beyond their outer edges. Apply expansion once, preserve explicit padding and inspect outer marks/strokes for axis clearance. Significance and grouped layouts have their documented overrides.

Bars meet their baseline without expansion gaps. Automatic bar views may zoom to the complete displayed values/points/SD; distributions and lines retain their complete extent. Honor explicit zero/full/zoom policies and limits. Disclose every nonzero bar baseline and never interpret truncated lengths as ratios. SD crossing zero must remain visible with the categorical baseline at zero. See [single-metric axes](multi-comparison.md#axes-and-transparency) and [multi-metric SD/inside values](multi-metric-comparison.md) for the precise policies; never substitute SEM/CI or change computed SD to avoid overlap.

## Compact ranking, legends and layout

For categorical method comparisons, place the requested focal method left in vertical figures and bottom in horizontal figures, ordering other methods by the established improvement direction. An explicit scientific order takes precedence. Use `model_order` when the renderer's performance sort would not produce that order, and disable a ranking arrow when the explicit order is nonmonotonic. Do not performance-sort scientific categories, continuous covariates or radar axes. Exact raw ID `Ours` is a default visual color identity, not evidence of performance, pairing or a hypothesis. Preserve method-color identities when reordering.

Keep ranking arrows/text with their numeric-value block, pointing toward better performance. Numeric labels stay aligned with categories and clear of marks/titles. Vertical values normally start at `value_offset: 0.135`, horizontal distributions at 0.075; horizontal bars and paired differences have [category-specific offsets](multi-comparison.md#values-ranking-and-colors). Anchor ranking text near its non-arrow tail with an inward inset and descender clearance. Moving values to an interior significance strip also moves their ranking block.

Choose ticks using the final physical axis length and Arial glyph bounds, coarsening crowded intervals rather than imposing a fixed step. Every major tick has a label. Explicit breaks remain authoritative and require inspection. Preserve all observations and shown uncertainty when adjusting limits, padding or annotation space.

Measure complete ordinary guides—keys, labels, padding and frame—and use actual empty regions with positive physical clearance from marks, uncertainty, annotations and panel boundaries. Use the selected category's supported placement controls; an external ordinary top guide is unframed. Paired guides have their own frame/occupancy contract, and required continuous-trend statistics stay in their top two-row layout. Do not invent universal legend parameters.

Detailed layouts are intentionally routed:

- [Paired guides](paired-comparison-scatter.md#visual-contract): proportional Arial frames, categorical stack/occupancy, continuous numeric axis, separate size guide and optional marginals.
- [Single-metric significance](multi-comparison.md#optional-one-sided-significance): opt-in tests, all-comparator gate and measured annotation strips; [broken axes](multi-comparison.md#optional-broken-numeric-axis-for-boxes) require an explicitly empty interval and disclosure.
- [Multiple metrics](multi-metric-comparison.md): SD halves and inside values, metric-key icons, grouped guides and descriptive correlation of method means.
- [Trends](trend-comparsion.md): top icon-line/statistic rows, light mean-fit confidence fills with thin colored boundaries, extrapolation records and shared categorical labels.
- [Radar](radar-comparison.md): declared domains, circular guides/decorative bands, effective curve colors, corner legends and measured raw-value labels.
- [Circular heatmaps](grouped-circular-heatmap.md): matched-item sectors, coordinated colors, companion violins and optional focal tests.

## Complete nearby endpoint ticks

For an automatic numeric range and tick interval, extend outward to the next major tick when the remaining gap is at most 20% of that interval, and label it. Never move a limit inward or crop data/uncertainty. With 0.1 ticks, 0.79 can extend to 0.8 and 0.51 to 0.5; 0.48 must not move inward to 0.5. Explicit limits/ticks take precedence. Small outward completion can override initial zoom occupancy. Paired scatter retains identical rounded x/y scales.

The single-metric/shared-row renderers apply this when both limits and ticks are automatic; trend continuous axes use the same rule. Requested identical ticks across comparable shared-row metrics require common limits containing every value. Values below the first labeled tick still need axis space. Recheck endpoint glyphs and label spacing at final size.

## Adapt after rendering

Inspect actual ranges, category counts/name lengths, density and empty regions. Refine only supported geometry when the default does not fit; preserve scientific values, palette transforms and explicit settings. Distinguish user-specified paired rectangles from resolved automatic frames, and remeasure after marginals or labels change. Use recorded complete-frame searches before manual coordinates. A guide fitting only its gradient or keys while clipping text is not safe.

Inspect the complete actual PNG and representative vector export at print size, including fonts, ticks, labels, transparency, annotation fit and uncertainty. Retain final settings and material refinements. Follow the [entry point's delivery workflow](../SKILL.md#render-inspect-and-deliver) for numerical checks, exports, source/preparation/renderer snapshots and reproduction.
