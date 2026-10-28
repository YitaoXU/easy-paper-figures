# Work from a short plotting request

Use this reference when a scientific decision or deliverable is unresolved, or when generating multiple candidates. The [skill entry point](../SKILL.md) supplies the shared input, rendering and delivery workflow; the [catalog](figure-catalog.md) routes to category contracts.

## Consult before rendering

Inspect the input read-only before deciding what to ask. Reuse explicit session choices; a reference image or previous dataset does not establish a new input's scientific meaning.

- Resolve only missing decisions that change the result: metric/units and row meaning, score columns, pairing/repeated-measurement unit, direction and one-sided hypothesis, categorical versus continuous covariates, or missing/failed-prediction handling. Never choose a hypothesis from the observed winner.
- Clarify materially different deliverables only when unspecified: one recommended figure versus candidates, paired scatter versus distributions, or separate metrics versus a combined layout. Offer concise options informed by the input. Permission to choose automatically, produce alternatives or use defaults already answers the applicable visual choice.
- Use an established output destination from the request, session or project convention; otherwise establish it. An unnamed palette uses documented defaults. An ambiguous reference color or requested new color needs its intended palette/family established rather than a guessed exact identity.
- Bundle related questions, normally one to three. A short brief can state the metric, unit, methods, layout, color meaning and destination. Do not require another confirmation after the user answers, or turn adaptable cosmetic parameters into a questionnaire.

Wait for required answers before dependent analysis/rendering; inspect ranges, grouping and availability, load selected references or prepare the environment meanwhile. Existing figure revisions keep their established data contract unless the revision makes it ambiguous. Record resolved scientific choices with the figure.

## Select useful candidates

Honor a requested style and delivery mode; a maximum number of candidates is not a quota. Use the [catalog's selection boundaries](figure-catalog.md#selection-boundaries) and selected category contract rather than reconstructing observations from summaries or silently normalizing unlike metrics.

For a general multiple-method request with no style selected, raw data normally support box, violin and bar candidates with observations and mean ± sample SD. Add a paired reference-difference line only when a reference and valid pairing are established. If one recommended figure is requested, choose a box plot for broad/skewed raw distributions or a bar plot for summary-only data; do not generate extras automatically. Summary input permits bars or requested mean lines, with SD only when supplied. Small/constant raw groups may not support a meaningful violin.

Multiple metrics use separate panels by default with stable method colors; combine them when useful for the requested comparison. Shared model labels need one common ordering metric or explicit model order. Shared-axis lines require identical established units/domains. Follow the [multiple-metric contract](multi-metric-comparison.md) for shared rows, stacked bars, grouped distributions, dual axes and conditional SD. Paired scatter is one matched-score comparison, not a multi-style batch.

## Render a single-metric candidate batch

`scripts/render_candidates.R` accepts one validated single-metric multi-comparison configuration and optional comma-separated styles. It reuses the normal renderer; it does not infer scientific meaning.

```bash
Rscript /path/to/skill/scripts/render_candidates.R /path/to/base-config.json
Rscript /path/to/skill/scripts/render_candidates.R /path/to/base-config.json box,violin
```

Set `output_prefix` to `<output-parent>/<base-name>/<base-name>`. Candidates get independent folders with suffixes `_box_points_sd`, `_violin_points_sd`, `_bar_points_sd` or `_delta_reference_line`. A supplied `reference` and `paired: true` enable the default difference-line candidate; explicit `line` without a reference produces a mean line. Default raw candidates use points/SD; summary candidates use SD only when a column is supplied. Explicit `show_points`, `show_sd`, `line_markers` and styles take precedence. Clear inherited `limits`/`breaks` when switching raw to delta; the helper does this for its delta candidate and fixes one model-color map across candidates.

Keep requests semantic and minimal. The selected renderer resolves typography, marks, spacing and guides; do not copy the gallery's selected IDs, hypotheses or ranges. Inspect every candidate and retain the normal exports/reproduction records. Keep the batch index/overview in the first figure folder, without loose files or a shared support folder in the output parent. Do not rerender unrelated figures merely because defaults changed.
