# Three-group benchmark profiles

Sample input: [CSV](../data/grouped_circular_three_groups.csv). With this fixed synthetic input, replace only `INPUT_DATA_PATH` and `OUTPUT_PARENT`. For your data, edit **DATA SETTINGS** and retain the figure settings.

```text
Use $paper-results-figures with the following settings.

DATA SETTINGS (edit for your data):
Input file: INPUT_DATA_PATH
Output parent: OUTPUT_PARENT
Column mapping: item = item; group = group; model = model; value = score.
Metric meaning / units / established domain / favorable direction: Benchmark score / unitless / [0,1] / higher is better.
Sampling and pairing: each item is one independent synthetic evaluation unit, matched across all four models, and belongs to exactly one group. These are item-level scores, not model averages.
Focal model: Ours.
Model and group order: use defaults; retain item identities within their groups.
Scientific comparison: Ours versus every other displayed model, with a one-sided paired t-test (Ours > comparator), matching by item identity. The item-level paired differences are independent across items. Apply Holm correction across these comparisons; do not aggregate by group or choose the hypothesis from the observed scores.

FIGURE SETTINGS (keep for this layout):
Figure type: grouped-circular-heatmap.
Show proportional group sectors, a score track for every model, radial item labels, inner group bands, a group count legend and a central score colorbar. Use the automatic group legend placement: inside for up to six groups and on the right for larger group sets.
Include horizontal violins of exactly the same matched items in the upper-right opening, with median and quartiles. Use equal item weights when pooling across groups.
Keep equal horizontal clearance on both sides of each model title, between the circular track endpoint and the violin start.
Use coordinated named palettes: heatmap_palette = blue-yellow; let the model violins and group bands inherit its fixed colors.
Show significance instead of the mean column, using gray nested brackets on the right only when every Holm-adjusted comparison meets p < 0.05. Preserve every test result even when brackets are omitted. Let the whole violin block extend just beyond the rightmost displayed circular item label.
Allocate a full manuscript row of 180 x 168 mm, preserving the default print typography.
Title: Three-group benchmark profiles.
Caption: Synthetic data | one score per matched item and model.
Save one dedicated figure folder named grouped-circular-heatmap-three-groups under the output parent.
```
