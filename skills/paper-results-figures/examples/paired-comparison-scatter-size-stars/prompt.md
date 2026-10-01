# Point sizes and selected stars

Sample input: [CSV](../data/paired-size.csv). Copy the prompt below. With this sample, change only `INPUT_DATA_PATH` and `OUTPUT_PARENT`; for your data, edit the **DATA SETTINGS** values. Keep **FIGURE SETTINGS** to reproduce this layout.

```text
Use $paper-results-figures with the following settings.

DATA SETTINGS (edit for your data):
Input file: INPUT_DATA_PATH
Output parent: OUTPUT_PARENT
Column mapping: matched unit ID = pair_id; reference value = reference_score; focal value = focal_score; color covariate = covariate; size count = sample_count
Metric meaning: reference and focal are measurements of the same score.
Units / established domain / favorable direction: unitless / [0,1] / higher is better.
Sampling and pairing: one row per independent matched unit; both values are measured on that same unit. Each pair has equal statistical weight.
Axis labels: reference = Reference score; focal = Focal score.
Statistical test: one-sided paired t-test, alternative focal > reference. For the opposite predeclared hypothesis, replace focal > reference with focal < reference.
Color meaning / units / established domain: covariate / unitless / [12,22].
Size meaning: sample count, positive counts; the size encoding does not change statistical weights.
Preselected star IDs and labels: P05 = P05; P12 = P12. Set to none to omit selected stars.
Infer unambiguous column mappings from the file if I set a mapping to auto; ask only about unresolved scientific meaning.

FIGURE SETTINGS (keep for this layout):
Figure type: paired-comparison-scatter
Palette: muted-green-blue-purple
Save one figure folder named paired-comparison-scatter-size-stars under the output parent.
Plot the reference value on X and the focal value on Y with equal numeric axes.
Use continuous covariate colors and map size counts to point area. Mark and label only the preselected IDs as stars. Place color and count guides inside if safely possible.
```
