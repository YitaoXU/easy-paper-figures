# Radar model profiles with tinted bands

Sample input: [CSV](../data/radar-scores.csv). Copy the prompt below. With this sample, change only `INPUT_DATA_PATH` and `OUTPUT_PARENT`; for your data, edit the **DATA SETTINGS** values. Keep **FIGURE SETTINGS** to reproduce this layout.

```text
Use $paper-results-figures with the following settings.

DATA SETTINGS (edit for your data):
Input file: INPUT_DATA_PATH
Output parent: OUTPUT_PARENT
Column mapping: method = method_id; radar category = category_id; score = score.
Input meaning: one established summary per method/category, without replicate uncertainty.
Metric meaning / units / established domain / favorable direction: score / unitless / [0,1] for every category / higher is better.
Focal method: Ours.
Clockwise category order: Category A, Category B, Category C, Category D, Category E, Category F, Category G, Category H. Replace with your categories or set to input order.
Infer unambiguous column mappings from the file if I set a mapping to auto; ask only about unresolved scientific meaning.

FIGURE SETTINGS (keep for this layout):
Figure type: radar-comparison
Palette: muted-green-blue-purple
Save one figure folder named radar-comparison-bands under the output parent.
Retain original values and scale radii using the declared scientific domains; label the focal method with its original values. No inference or polygon-area ranking.
Use a circular radar with solid model lines and symbols, and concentric decorative tinted bands from a subtle warm center to pale green outer bands. These bands are not observed thresholds or quantiles.
```
