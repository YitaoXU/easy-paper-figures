# Inspect and adapt input data

Read this reference when an inspected source does not already match the selected renderer's input contract. The agent owns format adaptation; users do not need to preformat every new file. Use renderer-native long/wide input when it already expresses the requested observations correctly.

## Decide what can be changed without another question

Inspect the delimiter, headers, representative values, numeric encodings, availability flags and grouping keys. Establish the actual sampling unit and raw-versus-summary meaning from the source and current request. Compare them with the selected specification before choosing a transformation.

Proceed with an unambiguous, reversible transformation: an explicit column mapping, long/wide reshape, selected metric or method, removal of clearly labeled aggregate rows from raw analysis, or numeric parsing of plain numeric strings. Preserve identifier strings, including leading zeros, and retain all finite numeric precision. Establish that a field is numeric from its meaning, not merely from values that resemble numbers. Keep availability flags, covariates and lineage when they affect plotting or inference.

Consult on scientific ambiguity: uncertain units or percentages, unmatched/duplicate pairing keys, repeated measurements that need aggregation, summary rows whose denominator is unknown, a failed-prediction policy, or a covariate that differs between the paired methods. Never resolve these by averaging duplicates, pairing by current row order, rounding, replacing unavailable predictions, treating means as replicates, or manufacturing SD. A user-authorized rule can be implemented in a saved per-run preprocessing script; it is not inferred by the generic adapter.

## Prefer the smallest valid transformation

| Inspected input | Renderer or adaptation |
| --- | --- |
| Paired scores in separate x/y columns | Use paired scatter directly with explicit column names and ID |
| Single-metric method rows in long form | Use the multiple-model renderer directly |
| Raw single-metric method columns in wide form | Use native `layout: wide` and `model_columns`; retain the pairing ID |
| One method/value row per pairing ID and method | Match IDs explicitly and reshape the two requested methods to x/y |
| One model row with separate metric columns | Expand selected metrics to long model/metric/value form; preserve raw IDs or supplied summary SD/count fields |
| Metric rows with model columns, containing pooled scores or means | Transpose the selected summary values into model/metric/value form |
| Other clear tabular formats | Read with their correct delimiter or parser and save a minimal per-run conversion; this helper accepts CSV, TSV, XLS and XLSX |

Do not transform an already-valid input simply to standardize its column names. The renderer validates its own statistical contract after preparation.

## Optional reusable adapter

Run the environment helper first when needed, then use:

```bash
Rscript /path/to/skill/scripts/prepare_data.R /path/to/figure-folder/preparation-request.json
```

The configuration requires `input`, a figure-specific `output_prefix`, `operation`, and the established `data_mode: raw` or `summary`. Relative paths resolve against the preparation configuration. Output prefixes follow the same dedicated-figure-folder convention as rendering. `input_format: auto` recognizes XLS/XLSX and TSV; an explicit `input_format` is retained for replay of extensionless source snapshots. Excel cells retain their native types before lexical serialization: text IDs remain unchanged and numeric cells use 17 significant digits; select `sheet` by name or index for a multi-sheet workbook, whose sheet is never guessed. Numeric mappings use the same strict conversion and retain source values. Optional `delimiter` defaults to comma (tab for a detected TSV); `na_values` defaults to empty, `NA`, and `NaN`. `filter` maps source columns to explicitly accepted values. `numeric_columns` names output columns to parse strictly, including a numeric covariate retained through `keep`. Unknown fields, duplicate headers and ambiguous numeric strings fail.

The adapter implements four focused operations. All examples below contain placeholders or fictional method/metric names.

### Paired long rows to x/y columns

```json
{
  "input": "[INPUT_DATA_PATH]",
  "output_prefix": "[OUTPUT_PARENT]/[FIGURE_NAME]/[FIGURE_NAME]",
  "operation": "paired-long-to-wide",
  "data_mode": "raw",
  "id": "observation_id",
  "model": "method",
  "value": "score",
  "x_model": "Reference",
  "y_model": "Candidate",
  "keep": {"group": "group_label", "sample_count": "sample_count"},
  "numeric_columns": ["sample_count"]
}
```

Produces `id`, numeric `x`/`y`, retained covariates and source-row lineage. IDs must be unique within each requested method with identical sets. Other methods are recorded as explicitly unselected. Each `keep` covariate must agree between both members of a pair, including missingness; differing fields need a deliberate source choice. Missing score values remain missing for the renderer's stated policy. Configure paired scatter with the prepared CSV, `id: id`, `x: x`, and `y: y`.

### Separate metric columns to long form

```json
{
  "input": "[INPUT_DATA_PATH]",
  "output_prefix": "[OUTPUT_PARENT]/[FIGURE_NAME]/[FIGURE_NAME]",
  "operation": "metrics-wide-to-long",
  "data_mode": "raw",
  "paired": true,
  "model": "method",
  "id": "observation_id",
  "metric_columns": {"metric_a": "score_a", "metric_b": "score_b"},
  "keep": {"available": "prediction_available"}
}
```

Produces `model`, `metric`, numeric `value`, optional `id`, retained fields and lineage. Paired raw mode checks model/ID uniqueness and identical ID sets before expansion. For independent raw observations set `paired: false`. Summary mode requires one source row per model; optional `sd_columns` and `n_columns` use the same metric IDs, for example `{"metric_a":"sd_a"}`. Omitted uncertainty stays absent; missing supplied fields remain missing. Raw rows cannot use summary SD/count mappings. Configure the selected multiple-model renderer with `layout: long`, canonical column names and the established data mode.

### Transposed summary table to long form

Use `operation: transposed-to-long`, `data_mode: summary`, `metric` for the row-label column, an explicit `metrics` array, and a `model_columns` mapping from method IDs to their source columns. Each selected metric must have exactly one row. This mode does not reconstruct observations or attach inferred uncertainty.

### Plain column mapping or strict parsing

Use `operation: columns` to retain the table's shape. `rename` maps new column names to existing names, such as `{"id":"sample_key","x":"reference_score"}`. `numeric_columns` lists the resulting numeric fields. All other columns remain unchanged; collisions fail. Native renderer mappings usually make this operation unnecessary.

## Per-figure records and reproduction

The source file is never edited. The adapter saves the following alongside the figure prefix, outside the skill:

- `.prepared.csv`: plot input, with source-row lineage and numeric serialization at 17 significant digits.
- `.source-data`: an unchanged byte copy of the source, using its recorded delimiter.
- `.preparation.config.json` and `.preparation.json`: explicit mappings and established data mode, source/output hashes, counts, retained/excluded row indices, missing numeric counts and a record that no aggregation, imputation or unit conversion occurred.
- `.prepare-data.R` and `.prepare.R`: helper snapshot and reproduction entry point; run `Rscript [FIGURE_NAME].prepare.R` from any directory.

Inspect the prepared schema, method/pair counts and numeric ranges before rendering. Preserve a renderer/palette snapshot and the render configuration with these records. If several figure folders use the same adapted source, keep their necessary preparation material inside each folder rather than introducing a loose shared support directory.

