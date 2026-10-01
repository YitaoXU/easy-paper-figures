# Paired reference differences

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
Reference: Method A; compute each ID-matched difference as method score minus reference score; difference domain [-1,1]; display label = Score difference vs Method A.
Test: none.
Infer unambiguous column mappings from the file if I set a mapping to auto; ask only about unresolved scientific meaning.

FIGURE SETTINGS (keep for this layout):
Plot category: mutl-comparison.
Palette: muted-green-blue-purple-transparent.
Output figure folder: mutl-comparison-reference-line (under OUTPUT_PARENT).
Marks: vertical line comparisons with mean icons, numeric means, sample SD and Performance Ranking. Omit raw points.
Ordering: use the supplied method order; put the focal method at the left. Preserve method color identities.
Reference display: summarize the supplied paired differences and retain the zero reference line.
```
