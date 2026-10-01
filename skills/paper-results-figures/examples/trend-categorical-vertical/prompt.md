# Categories on the vertical axis

Sample input: [CSV](../data/category-two-metrics.csv). Copy the prompt below. With this sample, change only `INPUT_DATA_PATH` and `OUTPUT_PARENT`; for your data, edit the **DATA SETTINGS** values. Keep **FIGURE SETTINGS** to reproduce this layout.

```text
Use $paper-results-figures with the following settings.

DATA SETTINGS (edit for your data):
Input file: INPUT_DATA_PATH
Output parent: OUTPUT_PARENT
Column mapping: category = category; method = model; metric = metric; summary value = value.
Input meaning: one established summary per category/method/metric; no replicates or uncertainty. Categories are nominal.
Metric meaning / units / established domains: comparable scores / unitless / [0,1] for all selected metrics.
Focal method: Ours.
Category order: Category A, Category B, Category C, Category D, Category E, Category F, Category G. Replace with your categories or set to input order.
Method order: Ours, Method A, Method B. Replace with your methods or set to input order.
Metric order: Metric A, Metric B. Replace with your metrics or set to input order.
Axis labels: categories = Category; numeric values = Comparable score.
Infer unambiguous column mappings from the file if I set a mapping to auto; ask only about unresolved scientific meaning.

FIGURE SETTINGS (keep for this layout):
Figure type: trend-comparsion
Palette: blue-yellow-transparent
Save one figure folder named trend-categorical-vertical under the output parent.
Use categorical profiles with common numeric scales based on the declared domains; no regression or inference.
Put categories down the vertical axis and numeric values horizontally. Place metric panels side by side, sharing category labels only at the outer left edge.
```
