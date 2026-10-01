# Grouped violins, horizontal

Sample input: [CSV](../data/grouped-scores.csv). Copy the prompt below. With this sample, change only INPUT_DATA_PATH and OUTPUT_PARENT; for your data, edit the DATA SETTINGS values. Keep FIGURE SETTINGS to reproduce this layout.

```text
Use $paper-results-figures to create this figure from the supplied data.

DATA SETTINGS (edit for your data):
Input path: INPUT_DATA_PATH
Output parent: OUTPUT_PARENT
Column mapping: method = model; metric ID = metric; measurement = value; matched-unit ID = observation_id.
Method IDs: Ours, Method A, Method B.
Metric order/roles: role 1 = Metric A; role 2 = Metric B; role 3 = Metric C.
Metric definition (Metric A): synthetic score; units = unitless score; scientific domain = [0,1]; higher is better.
Metric definition (Metric B): synthetic score; units = unitless score; scientific domain = [0,1]; higher is better.
Metric definition (Metric C): synthetic score; units = unitless score; scientific domain = [0,1]; higher is better.
Sampling/pairing: raw long data; each ID is one independent sampling unit matched across methods and metrics.
Focal method: Ours (visual highlight).
Ordering metric: Metric A; use its improvement direction for the common performance order.
Shared numeric-axis label: Score (unitless).
Missing observations: error; do not drop or impute.
Test: none.
Infer unambiguous column mappings from the file if I set a mapping to auto; ask only about unresolved scientific meaning.

FIGURE SETTINGS (keep for this layout):
Plot category: multi-metric-comparison.
Palette: muted-green-blue-purple-transparent.
Output figure folder: grouped-distributions-violin-horizontal (under OUTPUT_PARENT).
Layout: grouped-distributions; horizontal.
Ordering: use the supplied common method order or ordering metric; put the focal method at the bottom.
Marks: consecutive metric clusters of violins, colored by method. Show raw points.
Overlays: omit internal mean and SD overlays.
Annotations: omit numeric mean labels and ranking; retain a method legend.
```
