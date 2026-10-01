# Comparable mean lines on one axis

Sample input: [CSV](../data/comparable-metrics.csv). Copy the prompt below. With this sample, change only INPUT_DATA_PATH and OUTPUT_PARENT; for your data, edit the DATA SETTINGS values. Keep FIGURE SETTINGS to reproduce this layout.

```text
Use $paper-results-figures to create this figure from the supplied data.

DATA SETTINGS (edit for your data):
Input path: INPUT_DATA_PATH
Output parent: OUTPUT_PARENT
Column mapping: method = model; metric ID = metric; measurement = value; matched-unit ID = observation_id.
Method IDs: Ours, Method A, Method B, Method C.
Metric order/roles: role 1 = Score Alpha; role 2 = Score Beta; role 3 = Score Gamma.
Metric definition (Score Alpha): synthetic score; units = unitless; scientific domain = [0,1]; higher is better.
Metric definition (Score Beta): synthetic score; units = unitless; scientific domain = [0,1]; higher is better.
Metric definition (Score Gamma): synthetic score; units = unitless; scientific domain = [0,1]; higher is better.
Sampling/pairing: raw long data; each ID is one independent sampling unit matched across methods and metrics.
Focal method: Ours (visual highlight).
Ordering metric: Score Alpha; use its improvement direction for the common performance order.
Shared numeric-axis label: Score (unitless).
Missing observations: error; do not drop or impute.
Test: none.
Infer unambiguous column mappings from the file if I set a mapping to auto; ask only about unresolved scientific meaning.

FIGURE SETTINGS (keep for this layout):
Plot category: multi-metric-comparison.
Palette: muted-green-blue-purple-transparent.
Output figure folder: multi-metric-shared-axis (under OUTPUT_PARENT).
Layout: shared-axis; vertical.
Ordering: use the supplied common method order or ordering metric; put the focal method at the left.
Marks: comparable metric mean lines with icons and sample SD on one shared numeric axis; fixed metric colors and line types.
Annotations: omit numeric mean labels, raw points and ranking.
```
