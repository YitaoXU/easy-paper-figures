# Synthetic figure examples

Choose a preview and copy the fenced prompt. For its supplied fixed CSV, edit only `INPUT_DATA_PATH` and `OUTPUT_PARENT`; for your own results, edit the labeled **DATA SETTINGS**, including column names and scientific meaning. Keep **FIGURE SETTINGS** to reproduce the layout. Set an unambiguous column mapping to `auto` if you want the agent to identify it. [Data meanings](data/README.md) · [English guide](../README.md) · [中文指南](../README.zh.md).

### Paired observations

<table><tr>
<td align="center" width="300"><a href="paired-comparison-scatter/prompt.md"><img src="paired-comparison-scatter/preview-card.svg" width="300" height="285" alt="Categorical paired scatter"></a><br><strong>Categorical paired scatter</strong><br><code>muted-green-blue-purple</code><br><a href="paired-comparison-scatter/prompt.md">Prompt and CSV</a> · <a href="paired-comparison-scatter/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="paired-comparison-scatter-continuous/prompt.md"><img src="paired-comparison-scatter-continuous/preview-card.svg" width="300" height="285" alt="Continuous-color paired scatter"></a><br><strong>Continuous-color paired scatter</strong><br><code>muted-green-blue-purple</code><br><a href="paired-comparison-scatter-continuous/prompt.md">Prompt and CSV</a> · <a href="paired-comparison-scatter-continuous/preview.png">Actual export</a></td>
</tr></table>

<table><tr>
<td align="center" width="300"><a href="paired-comparison-scatter-size-stars/prompt.md"><img src="paired-comparison-scatter-size-stars/preview-card.svg" width="300" height="285" alt="Point sizes and selected stars"></a><br><strong>Point sizes and selected stars</strong><br><code>muted-green-blue-purple</code><br><a href="paired-comparison-scatter-size-stars/prompt.md">Prompt and CSV</a> · <a href="paired-comparison-scatter-size-stars/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="paired-comparison-scatter-marginals/prompt.md"><img src="paired-comparison-scatter-marginals/preview-card.svg" width="300" height="285" alt="Marginal histograms and KDE"></a><br><strong>Marginal histograms and KDE</strong><br><code>rainbow-transparent</code><br><a href="paired-comparison-scatter-marginals/prompt.md">Prompt and CSV</a> · <a href="paired-comparison-scatter-marginals/preview.png">Actual export</a></td>
</tr></table>

### One metric across methods

<table><tr>
<td align="center" width="300"><a href="mutl-comparison/prompt.md"><img src="mutl-comparison/preview-card.svg" width="300" height="285" alt="Boxes, points and SD"></a><br><strong>Boxes, points and SD</strong><br><code>rainbow-transparent</code><br><a href="mutl-comparison/prompt.md">Prompt and CSV</a> · <a href="mutl-comparison/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="mutl-comparison-violin/prompt.md"><img src="mutl-comparison-violin/preview-card.svg" width="300" height="285" alt="Violins, points and SD"></a><br><strong>Violins, points and SD</strong><br><code>blue-pink-purple-peach-transparent</code><br><a href="mutl-comparison-violin/prompt.md">Prompt and CSV</a> · <a href="mutl-comparison-violin/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="mutl-comparison-bar-horizontal/prompt.md"><img src="mutl-comparison-bar-horizontal/preview-card.svg" width="300" height="285" alt="Horizontal mean bars"></a><br><strong>Horizontal mean bars</strong><br><code>blue-yellow</code><br><a href="mutl-comparison-bar-horizontal/prompt.md">Prompt and CSV</a> · <a href="mutl-comparison-bar-horizontal/preview.png">Actual export</a></td>
</tr></table>

<table><tr>
<td align="center" width="300"><a href="mutl-comparison-reference-line/prompt.md"><img src="mutl-comparison-reference-line/preview-card.svg" width="300" height="285" alt="Paired reference differences"></a><br><strong>Paired reference differences</strong><br><code>muted-green-blue-purple-transparent</code><br><a href="mutl-comparison-reference-line/prompt.md">Prompt and CSV</a> · <a href="mutl-comparison-reference-line/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="mutl-comparison-four-column/prompt.md"><img src="mutl-comparison-four-column/preview-card.svg" width="300" height="285" alt="Four-column manuscript profile"></a><br><strong>Four-column manuscript profile</strong><br><code>blue-yellow-transparent</code><br><a href="mutl-comparison-four-column/prompt.md">Prompt and CSV</a> · <a href="mutl-comparison-four-column/preview.png">Actual export</a></td>
</tr></table>

<table><tr>
<td align="center" width="300"><a href="mutl-comparison-significance/prompt.md"><img src="mutl-comparison-significance/preview-card.svg" width="300" height="285" alt="Vertical significance brackets"></a><br><strong>Vertical significance brackets</strong><br><code>rainbow-transparent</code><br><a href="mutl-comparison-significance/prompt.md">Prompt and CSV</a> · <a href="mutl-comparison-significance/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="mutl-comparison-significance-horizontal/prompt.md"><img src="mutl-comparison-significance-horizontal/preview-card.svg" width="300" height="285" alt="Horizontal significance brackets"></a><br><strong>Horizontal significance brackets</strong><br><code>blue-pink-purple-peach-transparent</code><br><a href="mutl-comparison-significance-horizontal/prompt.md">Prompt and CSV</a> · <a href="mutl-comparison-significance-horizontal/preview.png">Actual export</a></td>
</tr></table>

### Several metrics across methods

<table><tr>
<td align="center" width="300"><a href="multi-metric-shared-rows/prompt.md"><img src="multi-metric-shared-rows/preview-card.svg" width="300" height="285" alt="Parallel bars, outside values"></a><br><strong>Parallel bars, outside values</strong><br><code>rainbow-transparent</code><br><a href="multi-metric-shared-rows/prompt.md">Prompt and CSV</a> · <a href="multi-metric-shared-rows/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="multi-metric-shared-rows-inside/prompt.md"><img src="multi-metric-shared-rows-inside/preview-card.svg" width="300" height="285" alt="Parallel bars, inside values and SD"></a><br><strong>Parallel bars, inside values and SD</strong><br><code>blue-pink-purple-peach-transparent</code><br><a href="multi-metric-shared-rows-inside/prompt.md">Prompt and CSV</a> · <a href="multi-metric-shared-rows-inside/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="multi-metric-shared-rows-no-sd/prompt.md"><img src="multi-metric-shared-rows-no-sd/preview-card.svg" width="300" height="285" alt="Parallel bars, inside values without SD"></a><br><strong>Parallel bars, inside values without SD</strong><br><code>blue-yellow-transparent</code><br><a href="multi-metric-shared-rows-no-sd/prompt.md">Prompt and CSV</a> · <a href="multi-metric-shared-rows-no-sd/preview.png">Actual export</a></td>
</tr></table>

<table><tr>
<td align="center" width="300"><a href="multi-metric-stacked-bars/prompt.md"><img src="multi-metric-stacked-bars/preview-card.svg" width="300" height="285" alt="Stacked vertical bar panels"></a><br><strong>Stacked vertical bar panels</strong><br><code>muted-green-blue-purple-transparent</code><br><a href="multi-metric-stacked-bars/prompt.md">Prompt and CSV</a> · <a href="multi-metric-stacked-bars/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="multi-metric-shared-axis/prompt.md"><img src="multi-metric-shared-axis/preview-card.svg" width="300" height="285" alt="Comparable mean lines on one axis"></a><br><strong>Comparable mean lines on one axis</strong><br><code>muted-green-blue-purple-transparent</code><br><a href="multi-metric-shared-axis/prompt.md">Prompt and CSV</a> · <a href="multi-metric-shared-axis/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="multi-metric-shared-axis-bars/prompt.md"><img src="multi-metric-shared-axis-bars/preview-card.svg" width="300" height="285" alt="Comparable mean lines with bars"></a><br><strong>Comparable mean lines with bars</strong><br><code>blue-pink-purple-peach-transparent</code><br><a href="multi-metric-shared-axis-bars/prompt.md">Prompt and CSV</a> · <a href="multi-metric-shared-axis-bars/preview.png">Actual export</a></td>
</tr></table>

<table><tr>
<td align="center" width="300"><a href="multi-metric-comparison-dual-axis/prompt.md"><img src="multi-metric-comparison-dual-axis/preview-card.svg" width="300" height="285" alt="Dual axes, model colors"></a><br><strong>Dual axes, model colors</strong><br><code>blue-yellow-transparent</code><br><a href="multi-metric-comparison-dual-axis/prompt.md">Prompt and CSV</a> · <a href="multi-metric-comparison-dual-axis/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="multi-metric-comparison-dual-axis-by-metric/prompt.md"><img src="multi-metric-comparison-dual-axis-by-metric/preview-card.svg" width="300" height="285" alt="Dual axes, metric colors"></a><br><strong>Dual axes, metric colors</strong><br><code>blue-yellow-transparent</code><br><a href="multi-metric-comparison-dual-axis-by-metric/prompt.md">Prompt and CSV</a> · <a href="multi-metric-comparison-dual-axis-by-metric/preview.png">Actual export</a></td>
</tr></table>

### Grouped distributions

<table><tr>
<td align="center" width="300"><a href="grouped-distributions-bar-vertical/prompt.md"><img src="grouped-distributions-bar-vertical/preview-card.svg" width="300" height="285" alt="Grouped bars, vertical"></a><br><strong>Grouped bars, vertical</strong><br><code>rainbow-transparent</code><br><a href="grouped-distributions-bar-vertical/prompt.md">Prompt and CSV</a> · <a href="grouped-distributions-bar-vertical/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="grouped-distributions-bar-horizontal/prompt.md"><img src="grouped-distributions-bar-horizontal/preview-card.svg" width="300" height="285" alt="Grouped bars, horizontal"></a><br><strong>Grouped bars, horizontal</strong><br><code>blue-yellow-transparent</code><br><a href="grouped-distributions-bar-horizontal/prompt.md">Prompt and CSV</a> · <a href="grouped-distributions-bar-horizontal/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="grouped-distributions-box-vertical/prompt.md"><img src="grouped-distributions-box-vertical/preview-card.svg" width="300" height="285" alt="Grouped boxes, vertical"></a><br><strong>Grouped boxes, vertical</strong><br><code>rainbow-transparent</code><br><a href="grouped-distributions-box-vertical/prompt.md">Prompt and CSV</a> · <a href="grouped-distributions-box-vertical/preview.png">Actual export</a></td>
</tr></table>

<table><tr>
<td align="center" width="300"><a href="grouped-distributions-box-horizontal/prompt.md"><img src="grouped-distributions-box-horizontal/preview-card.svg" width="300" height="285" alt="Grouped boxes, horizontal"></a><br><strong>Grouped boxes, horizontal</strong><br><code>blue-pink-purple-peach-transparent</code><br><a href="grouped-distributions-box-horizontal/prompt.md">Prompt and CSV</a> · <a href="grouped-distributions-box-horizontal/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="grouped-distributions-violin-vertical/prompt.md"><img src="grouped-distributions-violin-vertical/preview-card.svg" width="300" height="285" alt="Grouped violins, vertical"></a><br><strong>Grouped violins, vertical</strong><br><code>rainbow-transparent</code><br><a href="grouped-distributions-violin-vertical/prompt.md">Prompt and CSV</a> · <a href="grouped-distributions-violin-vertical/preview.png">Actual export</a></td>
</tr></table>

<table><tr>
<td align="center" width="300"><a href="grouped-distributions-violin-horizontal/prompt.md"><img src="grouped-distributions-violin-horizontal/preview-card.svg" width="300" height="285" alt="Grouped violins, horizontal"></a><br><strong>Grouped violins, horizontal</strong><br><code>muted-green-blue-purple-transparent</code><br><a href="grouped-distributions-violin-horizontal/prompt.md">Prompt and CSV</a> · <a href="grouped-distributions-violin-horizontal/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="grouped-distributions-legend-space/prompt.md"><img src="grouped-distributions-legend-space/preview-card.svg" width="300" height="285" alt="Bounded grouped bars"></a><br><strong>Bounded grouped bars</strong><br><code>rainbow-transparent</code><br><a href="grouped-distributions-legend-space/prompt.md">Prompt and CSV</a> · <a href="grouped-distributions-legend-space/preview.png">Actual export</a></td>
</tr></table>

### Broken box axes

<table><tr>
<td align="center" width="300"><a href="broken-box-vertical/prompt.md"><img src="broken-box-vertical/preview-card.svg" width="300" height="285" alt="Broken box axis, vertical"></a><br><strong>Broken box axis, vertical</strong><br><code>rainbow-transparent</code><br><a href="broken-box-vertical/prompt.md">Prompt and CSV</a> · <a href="broken-box-vertical/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="broken-box-horizontal/prompt.md"><img src="broken-box-horizontal/preview-card.svg" width="300" height="285" alt="Broken box axis, horizontal"></a><br><strong>Broken box axis, horizontal</strong><br><code>blue-yellow-transparent</code><br><a href="broken-box-horizontal/prompt.md">Prompt and CSV</a> · <a href="broken-box-horizontal/preview.png">Actual export</a></td>
</tr></table>

### Trend comparison

<table><tr>
<td align="center" width="300"><a href="trend-two-models/prompt.md"><img src="trend-two-models/preview-card.svg" width="300" height="285" alt="Two-model linear trend"></a><br><strong>Two-model linear trend</strong><br><code>muted-green-blue-purple</code><br><a href="trend-two-models/prompt.md">Prompt and CSV</a> · <a href="trend-two-models/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="trend-polynomial/prompt.md"><img src="trend-polynomial/preview-card.svg" width="300" height="285" alt="Exploratory polynomial trend"></a><br><strong>Exploratory polynomial trend</strong><br><code>muted-green-blue-purple</code><br><a href="trend-polynomial/prompt.md">Prompt and CSV</a> · <a href="trend-polynomial/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="trend-dual-metric/prompt.md"><img src="trend-dual-metric/preview-card.svg" width="300" height="285" alt="One-model dual-metric trend"></a><br><strong>One-model dual-metric trend</strong><br><code>muted-green-blue-purple</code><br><a href="trend-dual-metric/prompt.md">Prompt and CSV</a> · <a href="trend-dual-metric/preview.png">Actual export</a></td>
</tr></table>

<table><tr>
<td align="center" width="300"><a href="trend-multi-model/prompt.md"><img src="trend-multi-model/preview-card.svg" width="300" height="285" alt="Four-model linear trend"></a><br><strong>Four-model linear trend</strong><br><code>blue-pink-purple-peach-transparent</code><br><a href="trend-multi-model/prompt.md">Prompt and CSV</a> · <a href="trend-multi-model/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="trend-categorical-horizontal/prompt.md"><img src="trend-categorical-horizontal/preview-card.svg" width="300" height="285" alt="Categories on the horizontal axis"></a><br><strong>Categories on the horizontal axis</strong><br><code>blue-pink-purple-peach-transparent</code><br><a href="trend-categorical-horizontal/prompt.md">Prompt and CSV</a> · <a href="trend-categorical-horizontal/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="trend-categorical-vertical/prompt.md"><img src="trend-categorical-vertical/preview-card.svg" width="300" height="285" alt="Categories on the vertical axis"></a><br><strong>Categories on the vertical axis</strong><br><code>blue-yellow-transparent</code><br><a href="trend-categorical-vertical/prompt.md">Prompt and CSV</a> · <a href="trend-categorical-vertical/preview.png">Actual export</a></td>
</tr></table>

### Radar comparison

<table><tr>
<td align="center" width="300"><a href="radar-comparison/prompt.md"><img src="radar-comparison/preview-card.svg" width="300" height="285" alt="Radar model profiles"></a><br><strong>Radar model profiles</strong><br><code>muted-green-blue-purple</code><br><a href="radar-comparison/prompt.md">Prompt and CSV</a> · <a href="radar-comparison/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="radar-comparison-rainbow/prompt.md"><img src="radar-comparison-rainbow/preview-card.svg" width="300" height="285" alt="Radar model profiles"></a><br><strong>Radar model profiles</strong><br><code>rainbow-transparent</code><br><a href="radar-comparison-rainbow/prompt.md">Prompt and CSV</a> · <a href="radar-comparison-rainbow/preview.png">Actual export</a></td>
</tr></table>

<table><tr>
<td align="center" width="300"><a href="radar-comparison-pastel/prompt.md"><img src="radar-comparison-pastel/preview-card.svg" width="300" height="285" alt="Radar model profiles"></a><br><strong>Radar model profiles</strong><br><code>blue-pink-purple-peach-transparent</code><br><a href="radar-comparison-pastel/prompt.md">Prompt and CSV</a> · <a href="radar-comparison-pastel/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="radar-comparison-bands/prompt.md"><img src="radar-comparison-bands/preview-card.svg" width="300" height="285" alt="Radar: green tinted bands"></a><br><strong>Radar: green tinted bands</strong><br><code>muted-green-blue-purple</code><br><a href="radar-comparison-bands/prompt.md">Prompt and CSV</a> · <a href="radar-comparison-bands/preview.png">Actual export</a></td>
</tr></table>

### Grouped circular heatmaps and violins

Compare fixed synthetic inputs with 1, 3, 6, 8 or 12 groups, including singleton groups and strongly unequal group sizes. Sector angles preserve the item counts; automatic label thinning retains every heatmap tile. Model titles have equal clearance on both sides, and method/group palettes default to the heatmap palette. `palette` and `group_palette` provide independent choices; a fixed 12-slot group palette supplies distinct colors when the inherited heatmap palette is too short. An explicit group palette needs enough categorical slots. The light green-blue-purple and blue-yellow families each have twelve fixed coordinated group colors, keeping the inner bands coordinated with the score colors. Up to six groups retain the center count legend; larger group sets use a framed right-side guide. The center hole and guide rows adapt to the selected placement. The 1-, 3- and 8-group examples opt into one-sided matched-item tests of the explicitly designated Ours, with independent item differences and Holm correction, displaying significance instead of means. Other examples show descriptive means. Brackets appear only when all adjusted comparisons pass p < 0.05; every result remains recorded when brackets are omitted. Larger violin typography is measured in actual Arial. The complete violin and side-annotation block extends just beyond the rightmost displayed item label. The 1-, 8- and 12-group examples use pastel, blue-yellow and light green-blue-purple palettes respectively.

<table><tr>
<td align="center" width="300"><a href="grouped-circular-heatmap/prompt.md"><img src="grouped-circular-heatmap/preview-card.svg" width="300" height="285" alt="Circular heatmap: green-blue-purple"></a><br><strong>Circular heatmap: green-blue-purple</strong><br><code>muted-green-blue-purple-light</code><br><a href="grouped-circular-heatmap/prompt.md">Prompt and CSV</a> · <a href="grouped-circular-heatmap/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="grouped-circular-heatmap-blue-yellow/prompt.md"><img src="grouped-circular-heatmap-blue-yellow/preview-card.svg" width="300" height="285" alt="Circular heatmap: blue-yellow"></a><br><strong>Circular heatmap: blue-yellow</strong><br><code>blue-yellow</code><br><a href="grouped-circular-heatmap-blue-yellow/prompt.md">Prompt and CSV</a> · <a href="grouped-circular-heatmap-blue-yellow/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="grouped-circular-heatmap-pastel/prompt.md"><img src="grouped-circular-heatmap-pastel/preview-card.svg" width="300" height="285" alt="Circular heatmap: pastel"></a><br><strong>Circular heatmap: pastel</strong><br><code>blue-pink-purple-peach</code><br><a href="grouped-circular-heatmap-pastel/prompt.md">Prompt and CSV</a> · <a href="grouped-circular-heatmap-pastel/preview.png">Actual export</a></td>
</tr></table>

<table><tr>
<td align="center" width="300"><a href="grouped-circular-heatmap-one-group/prompt.md"><img src="grouped-circular-heatmap-one-group/preview-card.svg" width="300" height="285" alt="Circular heatmap: one group"></a><br><strong>Circular heatmap: one group</strong><br><code>blue-pink-purple-peach</code><br><a href="grouped-circular-heatmap-one-group/prompt.md">Prompt and CSV</a> · <a href="grouped-circular-heatmap-one-group/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="grouped-circular-heatmap-three-groups/prompt.md"><img src="grouped-circular-heatmap-three-groups/preview-card.svg" width="300" height="285" alt="Circular heatmap: three unequal groups"></a><br><strong>Circular heatmap: three unequal groups</strong><br><code>blue-yellow</code><br><a href="grouped-circular-heatmap-three-groups/prompt.md">Prompt and CSV</a> · <a href="grouped-circular-heatmap-three-groups/preview.png">Actual export</a></td>
</tr></table>

<table><tr>
<td align="center" width="300"><a href="grouped-circular-heatmap-eight-groups/prompt.md"><img src="grouped-circular-heatmap-eight-groups/preview-card.svg" width="300" height="285" alt="Circular heatmap: eight unequal groups"></a><br><strong>Circular heatmap: eight unequal groups</strong><br><code>blue-yellow</code><br><a href="grouped-circular-heatmap-eight-groups/prompt.md">Prompt and CSV</a> · <a href="grouped-circular-heatmap-eight-groups/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="grouped-circular-heatmap-twelve-groups/prompt.md"><img src="grouped-circular-heatmap-twelve-groups/preview-card.svg" width="300" height="285" alt="Circular heatmap: twelve small groups"></a><br><strong>Circular heatmap: twelve small groups</strong><br><code>muted-green-blue-purple-light</code><br><a href="grouped-circular-heatmap-twelve-groups/prompt.md">Prompt and CSV</a> · <a href="grouped-circular-heatmap-twelve-groups/preview.png">Actual export</a></td>
</tr></table>

### Palette appearance on the same data

<table><tr>
<td align="center" width="300"><a href="palette-muted-green-blue-purple/prompt.md"><img src="palette-muted-green-blue-purple/preview-card.svg" width="300" height="285" alt="Violin palette demonstration"></a><br><strong>Violin palette demonstration</strong><br><code>muted-green-blue-purple</code><br><a href="palette-muted-green-blue-purple/prompt.md">Prompt and CSV</a> · <a href="palette-muted-green-blue-purple/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="palette-muted-green-blue-purple-transparent/prompt.md"><img src="palette-muted-green-blue-purple-transparent/preview-card.svg" width="300" height="285" alt="Violin palette demonstration"></a><br><strong>Violin palette demonstration</strong><br><code>muted-green-blue-purple-transparent</code><br><a href="palette-muted-green-blue-purple-transparent/prompt.md">Prompt and CSV</a> · <a href="palette-muted-green-blue-purple-transparent/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="palette-rainbow/prompt.md"><img src="palette-rainbow/preview-card.svg" width="300" height="285" alt="Violin palette demonstration"></a><br><strong>Violin palette demonstration</strong><br><code>rainbow</code><br><a href="palette-rainbow/prompt.md">Prompt and CSV</a> · <a href="palette-rainbow/preview.png">Actual export</a></td>
</tr></table>

<table><tr>
<td align="center" width="300"><a href="palette-rainbow-transparent/prompt.md"><img src="palette-rainbow-transparent/preview-card.svg" width="300" height="285" alt="Violin palette demonstration"></a><br><strong>Violin palette demonstration</strong><br><code>rainbow-transparent</code><br><a href="palette-rainbow-transparent/prompt.md">Prompt and CSV</a> · <a href="palette-rainbow-transparent/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="palette-blue-yellow/prompt.md"><img src="palette-blue-yellow/preview-card.svg" width="300" height="285" alt="Violin palette demonstration"></a><br><strong>Violin palette demonstration</strong><br><code>blue-yellow</code><br><a href="palette-blue-yellow/prompt.md">Prompt and CSV</a> · <a href="palette-blue-yellow/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="palette-blue-yellow-transparent/prompt.md"><img src="palette-blue-yellow-transparent/preview-card.svg" width="300" height="285" alt="Violin palette demonstration"></a><br><strong>Violin palette demonstration</strong><br><code>blue-yellow-transparent</code><br><a href="palette-blue-yellow-transparent/prompt.md">Prompt and CSV</a> · <a href="palette-blue-yellow-transparent/preview.png">Actual export</a></td>
</tr></table>

<table><tr>
<td align="center" width="300"><a href="palette-blue-pink-purple-peach/prompt.md"><img src="palette-blue-pink-purple-peach/preview-card.svg" width="300" height="285" alt="Violin palette demonstration"></a><br><strong>Violin palette demonstration</strong><br><code>blue-pink-purple-peach</code><br><a href="palette-blue-pink-purple-peach/prompt.md">Prompt and CSV</a> · <a href="palette-blue-pink-purple-peach/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="palette-blue-pink-purple-peach-transparent/prompt.md"><img src="palette-blue-pink-purple-peach-transparent/preview-card.svg" width="300" height="285" alt="Violin palette demonstration"></a><br><strong>Violin palette demonstration</strong><br><code>blue-pink-purple-peach-transparent</code><br><a href="palette-blue-pink-purple-peach-transparent/prompt.md">Prompt and CSV</a> · <a href="palette-blue-pink-purple-peach-transparent/preview.png">Actual export</a></td>
</tr></table>

## Fixed palette references

Named palettes preserve fixed RGB assignments. Transparent variants apply mark-specific opacity. Each scientific preview identifies its actual palette. Click a palette reference to view the original-resolution image.

<table><tr>
<td align="center" width="900" colspan="2"><a href="palettes/palette-overview.png"><img src="palettes/palette-overview.png" width="900" alt="palette-overview"></a><br><code>palette-overview</code></td>
</tr><tr>
<td align="center" width="450"><a href="palettes/palette-muted-pastel-six.png"><img src="palettes/palette-muted-pastel-six.png" width="450" alt="palette-muted-pastel-six"></a><br><code>palette-muted-pastel-six</code></td>
<td align="center" width="450"><a href="palettes/palette-muted-balanced-six.png"><img src="palettes/palette-muted-balanced-six.png" width="450" alt="palette-muted-balanced-six"></a><br><code>palette-muted-balanced-six</code></td>
</tr></table>

## File organization

`examples/<figure-id>/prompt.md` is the user-facing example, `request.json` provides a minimal configuration structure where useful, and `preview.png` is the unchanged scientific export and `preview-card.svg` contains it in an equal-size display frame. Shared synthetic inputs live in `examples/data/`. Runtime instructions, scientific contracts, reusable renderers and fixed palette definitions live in `SKILL.md`, `references/`, `scripts/` and `palettes/`.
