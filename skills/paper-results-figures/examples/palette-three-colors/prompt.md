# Three-color method comparison

Sample input: [CSV](../data/grouped-scores.csv). Copy the prompt below. With this sample, change only INPUT_DATA_PATH and OUTPUT_PARENT; for your data, edit the DATA SETTINGS values.

```text
Use $paper-results-figures to create this figure from the supplied data.

DATA SETTINGS (edit for your data):
Input path: INPUT_DATA_PATH
Output parent: OUTPUT_PARENT
Column mapping: method = model; metric = metric; measurement = value; matched-unit ID = observation_id.
Selected metric: Metric A.
Metric definition: synthetic score; unitless; scientific domain [0,1]; higher is better; display label = Score.
Sampling/pairing: raw long data; each ID is one independent sampling unit matched across methods. Plot all three methods for the selected metric.
Focal method: Ours (visual highlight).
Method order: performance by the metric and its improvement direction.
Missing observations: error; do not drop or impute.
Test: none.

FIGURE SETTINGS:
Plot category: mutl-comparison.
Palette: blue-pink-purple-peach-transparent.
Output figure folder: palette-three-colors (under OUTPUT_PARENT).
Marks: vertical violin comparisons with mean icons, numeric means, sample SD and Performance Ranking. Show raw points.
Put the focal method at the left. Use automatic palette colors with no custom color map.
```
