# Horizontal significance brackets

Sample input: [CSV](../data/method-scores.csv). Copy the prompt below. With this sample, change only INPUT_DATA_PATH and OUTPUT_PARENT; for your data, edit the DATA SETTINGS values. Keep FIGURE SETTINGS to reproduce this layout.

```text
Use $paper-results-figures to create this figure from the supplied data.

DATA SETTINGS (edit for your data):
Input path: INPUT_DATA_PATH
Output parent: OUTPUT_PARENT
Column mapping: method = model; measurement = score; matched-unit ID = observation_id.
Method IDs: Ours, Method A, Method B, Method C.
Metric definition: synthetic score; unitless; scientific domain [0,1]; higher is better; display label = Score.
Sampling/pairing: raw long data; each ID is one independent sampling unit matched across methods.
Focal method: Ours (visual highlight).
Method order: performance by the metric and its improvement direction.
Missing observations: error; do not drop or impute.
Test: one-sided paired t-tests of the focal method against every other displayed method; hypothesis focal > comparator; p adjustment = none; threshold = 0.05.
Infer unambiguous column mappings from the file if I set a mapping to auto; ask only about unresolved scientific meaning.

FIGURE SETTINGS (keep for this layout):
Plot category: mutl-comparison.
Palette: blue-pink-purple-peach-transparent.
Output figure folder: multi-comparison-significance-horizontal (under OUTPUT_PARENT).
Marks: horizontal violin comparisons with mean icons, numeric means, sample SD and Performance Ranking. Omit raw points.
Ordering: use the supplied method order; put the focal method at the bottom. Preserve method color identities.
Significance display: draw all comparator brackets only when every supplied test passes the threshold; otherwise draw none and retain all test results.
```
