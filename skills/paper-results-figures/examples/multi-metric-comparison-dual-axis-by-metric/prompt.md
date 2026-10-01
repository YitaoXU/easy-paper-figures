# Dual axes, metric colors

Sample input: [CSV](../data/mixed-metrics.csv). Copy the prompt below. With this sample, change only INPUT_DATA_PATH and OUTPUT_PARENT; for your data, edit the DATA SETTINGS values. Keep FIGURE SETTINGS to reproduce this layout.

```text
Use $paper-results-figures to create this figure from the supplied data.

DATA SETTINGS (edit for your data):
Input path: INPUT_DATA_PATH
Output parent: OUTPUT_PARENT
Column mapping: method = model; metric ID = metric; measurement = value; matched-unit ID = observation_id.
Method IDs: Ours, Method A, Method B, Method C.
Metric order/roles: role 1 = Metric A; role 2 = Metric B.
Metric definition (Metric A): synthetic score; units = unitless; scientific domain = [0,1]; higher is better.
Metric definition (Metric B): synthetic response; units = response units; scientific domain = no finite established domain; higher is better.
Sampling/pairing: raw long data; each ID is one independent sampling unit matched across methods and metrics.
Focal method: Ours (visual highlight).
Ordering metric: Metric A; use its improvement direction for the common performance order.
Axis labels: metric role 1 name with its units; metric role 2 name with its units.
Descriptive statistic: Pearson correlation of the two original-scale vectors of per-method means, matched by method ID; sampling unit = displayed method; no p-value.
Missing observations: error; do not drop or impute.
Test: none.
Infer unambiguous column mappings from the file if I set a mapping to auto; ask only about unresolved scientific meaning.

FIGURE SETTINGS (keep for this layout):
Plot category: multi-metric-comparison.
Palette: blue-yellow-transparent.
Output figure folder: multi-metric-comparison-dual-axis-by-metric (under OUTPUT_PARENT).
Layout: dual-axis; vertical.
Ordering: use the supplied common method order or ordering metric; put the focal method at the left.
Marks: metric role 1 mean bars and metric role 2 mean line with icons; retain separate original scales on two labeled axes.
Overlays: show sample SD on bars; omit line SD, raw points, numeric mean labels and ranking.
Colors: one fixed color per metric.
Annotation: show the supplied descriptive mean correlation.
```
