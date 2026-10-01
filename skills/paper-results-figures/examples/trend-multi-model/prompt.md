# Four-model linear trend

Sample input: [CSV](../data/trend-multi.csv). Copy the prompt below. With this sample, change only `INPUT_DATA_PATH` and `OUTPUT_PARENT`; for your data, edit the **DATA SETTINGS** values. Keep **FIGURE SETTINGS** to reproduce this layout.

```text
Use $paper-results-figures with the following settings.

DATA SETTINGS (edit for your data):
Input file: INPUT_DATA_PATH
Output parent: OUTPUT_PARENT
Column mapping: observation ID = id; method = model; metric = metric; X covariate = covariate; response = value.
Covariate meaning / units / established domain: continuous covariate / unitless / [0,1].
Focal method: Ours.
Sampling and pairing: each row is an independent observation within its method/metric. IDs are local row identifiers; reused ID text across methods does not indicate pairing.
Response meaning / units / established domain / favorable direction: arbitrary continuous response / response units / no finite established domain / larger means more response, without a performance ranking.
Method order: Ours, Method A, Method B, Method C. Replace with your methods or set to input order.
Selected metric: Response.
Axis labels: X = Continuous covariate; Y = Response.
Infer unambiguous column mappings from the file if I set a mapping to auto; ask only about unresolved scientific meaning.

FIGURE SETTINGS (keep for this layout):
Figure type: trend-comparsion
Palette: blue-pink-purple-peach-transparent
Save one figure folder named trend-multi-model under the output parent.
Use linear regression without displayed confidence bands. Annotate slope and R² for each method.
Per-method statistics do not test differences between method trends.
Show every raw point. Retain original units; fit across the full automatically selected numeric X axis and record any extrapolation.
```
