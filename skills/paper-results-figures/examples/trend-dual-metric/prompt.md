# One-model dual-metric trend

Sample input: [CSV](../data/trend-dual.csv). Copy the prompt below. With this sample, change only `INPUT_DATA_PATH` and `OUTPUT_PARENT`; for your data, edit the **DATA SETTINGS** values. Keep **FIGURE SETTINGS** to reproduce this layout.

```text
Use $paper-results-figures with the following settings.

DATA SETTINGS (edit for your data):
Input file: INPUT_DATA_PATH
Output parent: OUTPUT_PARENT
Column mapping: observation ID = id; method = model; metric = metric; X covariate = covariate; response = value.
Covariate meaning / units / established domain: continuous covariate / unitless / [0,1].
Focal method: Ours.
Sampling and pairing: the same independent units supply both metrics at the same covariate values. Units are independent across IDs; separate within-metric fits do not use cross-metric dependence.
Methods: Ours only.
Metric order and definitions: Metric A = response in response units, no finite established domain, lower is favorable; Metric B = dimensionless continuous response, no finite established domain, higher is favorable. Neither is a bounded score; no cross-metric ranking.
Axis labels: X = Continuous covariate; first metric = Metric A (response units); second metric = Metric B (dimensionless).
Infer unambiguous column mappings from the file if I set a mapping to auto; ask only about unresolved scientific meaning.

FIGURE SETTINGS (keep for this layout):
Figure type: trend-comparsion
Palette: muted-green-blue-purple
Save one figure folder named trend-dual-metric under the output parent.
Use one model with two labeled original-unit numeric Y axes, separate linear OLS fits and 95% conditional-mean bands. Annotate Pearson r and its two-sided correlation p-value for each metric. This does not establish association between metrics or test a slope difference.
Show every raw point. Retain original units; fit across the full automatically selected numeric X axis and record any extrapolation.
```
