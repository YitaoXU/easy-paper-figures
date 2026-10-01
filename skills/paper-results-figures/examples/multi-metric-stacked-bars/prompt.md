# Stacked vertical bar panels

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
Missing observations: error; do not drop or impute.
Test: none.
Infer unambiguous column mappings from the file if I set a mapping to auto; ask only about unresolved scientific meaning.

FIGURE SETTINGS (keep for this layout):
Plot category: multi-metric-comparison.
Palette: muted-green-blue-purple-transparent.
Output figure folder: multi-metric-stacked-bars (under OUTPUT_PARENT).
Layout: stacked-bars; vertical.
Ordering: use the supplied common method order or ordering metric; put the focal method at the left.
Marks: vertically stacked bar panels sharing method labels; retain separate original metric scales and consistent method colors.
Overlays: show sample SD.
Values: place numeric means inside the bars; omit raw points and ranking.
```
