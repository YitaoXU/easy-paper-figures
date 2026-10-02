# Grouped circular benchmark profiles

Sample input: [CSV](../data/grouped_circular_scores.csv). With this fixed synthetic input, replace only `INPUT_DATA_PATH` and `OUTPUT_PARENT`. For your data, edit **DATA SETTINGS** and retain the figure settings.

```text
Use $paper-results-figures with the following settings.

DATA SETTINGS (edit for your data):
Input file: INPUT_DATA_PATH
Output parent: OUTPUT_PARENT
Column mapping: item = item; group = group; model = model; value = score.
Metric meaning / units / established domain / favorable direction: Benchmark score / unitless / [0,1] / higher is better.
Sampling and pairing: each item is one synthetic evaluation unit, matched across all four models, and belongs to exactly one group. These are item-level scores, not model averages.
Focal model: Ours.
Model and group order: use defaults; retain item identities within their groups.
Do not perform hypothesis tests.

FIGURE SETTINGS (keep for this layout):
Figure type: grouped-circular-heatmap.
Show proportional group sectors, a score track for every model, radial item labels, inner group bands, a group count legend and a central score colorbar. Use the automatic group legend placement: inside for up to six groups and on the right for larger group sets.
Include horizontal violins of exactly the same matched items in the upper-right opening, with median and quartiles. Center model titles with equal horizontal clearance to the sector start and the violin axis.
Heatmap palette: blue-pink-purple-peach. Use the same named palette for model violins and group bands.
Show a three-decimal arithmetic mean in a column to the right of each violin. Let the whole violin block extend just beyond the rightmost displayed circular item label.
Allocate a full manuscript row of 180 x 168 mm.
Title: Grouped benchmark profiles.
Caption: Synthetic data | one score per matched item and model.
Save one dedicated figure folder named grouped-circular-heatmap-pastel under the output parent.
```
