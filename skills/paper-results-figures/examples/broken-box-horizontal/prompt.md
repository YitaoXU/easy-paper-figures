# Broken box axis, horizontal

Sample input: [CSV](../data/broken-scores.csv). Copy the prompt below. With this sample, change only INPUT_DATA_PATH and OUTPUT_PARENT; for your data, edit the DATA SETTINGS values. Keep FIGURE SETTINGS to reproduce this layout.

```text
Use $paper-results-figures to create this figure from the supplied data.

DATA SETTINGS (edit for your data):
Input path: INPUT_DATA_PATH
Output parent: OUTPUT_PARENT
Column mapping: method = model; measurement = value; matched-unit ID = observation_id.
Method IDs: Ours, Method A, Method B.
Metric definition: synthetic score; unitless; scientific domain [0,1]; higher is better; display label = Score (unitless).
Sampling/pairing: raw long data; each ID is one independent sampling unit matched across methods.
Focal method: Ours (visual highlight).
Method order: performance by the metric and its improvement direction.
Missing observations: error; do not drop or impute.
Axis break: omit the open interval (0.16,0.72) only if it hides no observations, complete box/whisker support or displayed mean ± SD interval.
Test: none.
Infer unambiguous column mappings from the file if I set a mapping to auto; ask only about unresolved scientific meaning.

FIGURE SETTINGS (keep for this layout):
Plot category: mutl-comparison.
Palette: blue-yellow-transparent.
Output figure folder: broken-box-horizontal (under OUTPUT_PARENT).
Marks: horizontal box comparisons with mean icons and sample SD; omit numeric mean labels and ranking. Show raw points.
Ordering: use the supplied method order; put the focal method at the bottom. Preserve method color identities.
Broken axis: apply the supplied safe interval and disclose the omitted range.
```
