# Paper Results Figures

[中文](README.zh.md) · English

Create a reproducible manuscript figure by invoking `$paper-results-figures`, supplying your results and describing the comparison. Choose a preview below and copy its short prompt, or ask the agent to choose a suitable layout. CSV, TSV and XLSX inputs are supported through input inspection and adaptation; specify the worksheet when a workbook has several relevant sheets.

```text
Use $paper-results-figures to compare methods in INPUT_DATA_PATH.
Each observation_id is an independent unit matched across methods.
score is a unitless [0,1] score; higher is better. Highlight Ours.
Use a vertical violin plot with raw points and palette rainbow-transparent.
Save the result under OUTPUT_PARENT.
```

Replace the placeholders with your input path and output folder. State your metric meaning, observation unit, pairing and favorable direction when these cannot be inferred safely. To use a gallery prompt, choose its supplied CSV or substitute your own results. The agent prepares an unambiguous column mapping, creates the minimal rendering request, inspects the figure and exports the result.

## Adapt a gallery prompt

Each preview links to one copyable prompt with two clearly labeled parts. With the supplied synthetic CSV, change only `INPUT_DATA_PATH` and `OUTPUT_PARENT`. With your own CSV, TSV or XLSX, edit the **DATA SETTINGS** values; keep **FIGURE SETTINGS** for the displayed layout and palette.

| DATA SETTINGS item | What to change for your results |
| --- | --- |
| Input file / output parent | Your file and destination; add the worksheet name for XLSX when needed |
| Column mapping | Replace the example column names with your headers, or set an unambiguous mapping to `auto` |
| Metric definitions | Your metric names, units, scientifically established domains and favorable directions; use “no established domain” when appropriate |
| Sampling / pairing / input meaning | What a row or ID represents, whether observations are independent, whether methods are paired, and whether values are raw or summaries |
| Focal / reference method | Your actual method IDs; use `none` when no focal method or reference comparison is wanted |
| Test / order / selected IDs / omitted interval | Check any fields included by the chosen figure; replace the sample hypothesis, metric/category order, selected points or axis break as needed |
| Axis labels | Your scientific labels and units |

The example values describe the supplied fictional input. Headers can be detected from a file; independence, pairing, favorable direction and a test hypothesis need your scientific statement. A domain is not the observed minimum and maximum. The agent checks compatibility and asks about unresolved scientific meaning before dependent analysis. Fonts, dimensions, spacing and legend fitting come from the skill defaults.

## Available figures

| Scientific comparison | Layouts | Figure guide |
| --- | --- | --- |
| Two methods on matched observations | Paired scatter with optional colors, sizes and marginals | [Paired scatter](references/paired-comparison-scatter.md) |
| Methods on one metric | Bars, boxes, violins and mean lines in either orientation | [Single-metric comparison](references/mutl-comparison.md) |
| Several metrics across methods | Separate panels, dual axes, shared-axis lines and grouped distributions | [Multi-metric comparison](references/multi-metric-comparison.md) |
| Changes across a continuous covariate or categories | Regression fits and categorical profiles | [Trends](references/trend-comparsion.md) |
| Profiles over several axes | Radar with declared scientific domains | [Radar](references/radar-comparison.md) |
| Matched items within groups | Circular heatmap with optional matched-item violins | [Grouped circular heatmap](references/grouped-circular-heatmap.md) |

Each figure guide in `references/` contains its data requirements, options, defaults and statistical assumptions. Use the gallery below for copyable prompts and previews.

Use raw observations for distributions and paired differences. Supplied summaries cannot reconstruct replicates or uncertainty. Shared-axis metrics need identical established units and domains; radar domains must be scientifically justified. A dual-axis correlation annotation uses per-method mean pairs when requested, rather than pooling observations.

## Appearance and outputs

All text uses actual Arial. Defaults handle manuscript dimensions, readable ticks, label fitting and safe legend placement. Vertical method comparisons place the designated focal method at the left; horizontal comparisons place it at the bottom. Explicit scientific orders remain authoritative. Choose a fixed palette from the references below; layout-specific settings are documented in the figure guides.

Each figure has its own folder under your output parent. It contains vector PDF, editable SVG, 600 dpi PNG, the resolved configuration, plotted data, statistics and the R session record. Keep the configuration and any saved input-preparation step to reproduce the figure. Refinements use the same figure folder and preserve scientific values.

## Synthetic previews

Every preview has an independent folder with a usable prompt and a link to a fixed supplied CSV. Synthetic `Ours` performs best on score fixtures and weaker methods make differences visible. The same inputs are reused across related layouts and palettes; prompts never ask the user to create data. Display cards have equal dimensions, with the original figure contained without stretching.

### Paired observations

<table><tr>
<td align="center" width="300"><a href="examples/paired-comparison-scatter/prompt.md"><img src="examples/paired-comparison-scatter/preview-card.svg" width="300" height="285" alt="Categorical paired scatter"></a><br><strong>Categorical paired scatter</strong><br><code>muted-green-blue-purple</code><br><a href="examples/paired-comparison-scatter/prompt.md">Prompt and CSV</a> · <a href="examples/paired-comparison-scatter/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="examples/paired-comparison-scatter-continuous/prompt.md"><img src="examples/paired-comparison-scatter-continuous/preview-card.svg" width="300" height="285" alt="Continuous-color paired scatter"></a><br><strong>Continuous-color paired scatter</strong><br><code>muted-green-blue-purple</code><br><a href="examples/paired-comparison-scatter-continuous/prompt.md">Prompt and CSV</a> · <a href="examples/paired-comparison-scatter-continuous/preview.png">Actual export</a></td>
</tr></table>

<table><tr>
<td align="center" width="300"><a href="examples/paired-comparison-scatter-size-stars/prompt.md"><img src="examples/paired-comparison-scatter-size-stars/preview-card.svg" width="300" height="285" alt="Point sizes and selected stars"></a><br><strong>Point sizes and selected stars</strong><br><code>muted-green-blue-purple</code><br><a href="examples/paired-comparison-scatter-size-stars/prompt.md">Prompt and CSV</a> · <a href="examples/paired-comparison-scatter-size-stars/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="examples/paired-comparison-scatter-marginals/prompt.md"><img src="examples/paired-comparison-scatter-marginals/preview-card.svg" width="300" height="285" alt="Marginal histograms and KDE"></a><br><strong>Marginal histograms and KDE</strong><br><code>rainbow-transparent</code><br><a href="examples/paired-comparison-scatter-marginals/prompt.md">Prompt and CSV</a> · <a href="examples/paired-comparison-scatter-marginals/preview.png">Actual export</a></td>
</tr></table>

### One metric across methods

<table><tr>
<td align="center" width="300"><a href="examples/mutl-comparison/prompt.md"><img src="examples/mutl-comparison/preview-card.svg" width="300" height="285" alt="Boxes, points and SD"></a><br><strong>Boxes, points and SD</strong><br><code>rainbow-transparent</code><br><a href="examples/mutl-comparison/prompt.md">Prompt and CSV</a> · <a href="examples/mutl-comparison/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="examples/mutl-comparison-violin/prompt.md"><img src="examples/mutl-comparison-violin/preview-card.svg" width="300" height="285" alt="Violins, points and SD"></a><br><strong>Violins, points and SD</strong><br><code>blue-pink-purple-peach-transparent</code><br><a href="examples/mutl-comparison-violin/prompt.md">Prompt and CSV</a> · <a href="examples/mutl-comparison-violin/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="examples/mutl-comparison-bar-horizontal/prompt.md"><img src="examples/mutl-comparison-bar-horizontal/preview-card.svg" width="300" height="285" alt="Horizontal mean bars"></a><br><strong>Horizontal mean bars</strong><br><code>blue-yellow</code><br><a href="examples/mutl-comparison-bar-horizontal/prompt.md">Prompt and CSV</a> · <a href="examples/mutl-comparison-bar-horizontal/preview.png">Actual export</a></td>
</tr></table>

<table><tr>
<td align="center" width="300"><a href="examples/mutl-comparison-reference-line/prompt.md"><img src="examples/mutl-comparison-reference-line/preview-card.svg" width="300" height="285" alt="Paired reference differences"></a><br><strong>Paired reference differences</strong><br><code>muted-green-blue-purple-transparent</code><br><a href="examples/mutl-comparison-reference-line/prompt.md">Prompt and CSV</a> · <a href="examples/mutl-comparison-reference-line/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="examples/mutl-comparison-four-column/prompt.md"><img src="examples/mutl-comparison-four-column/preview-card.svg" width="300" height="285" alt="Four-column manuscript profile"></a><br><strong>Four-column manuscript profile</strong><br><code>blue-yellow-transparent</code><br><a href="examples/mutl-comparison-four-column/prompt.md">Prompt and CSV</a> · <a href="examples/mutl-comparison-four-column/preview.png">Actual export</a></td>
</tr></table>

<table><tr>
<td align="center" width="300"><a href="examples/mutl-comparison-significance/prompt.md"><img src="examples/mutl-comparison-significance/preview-card.svg" width="300" height="285" alt="Vertical significance brackets"></a><br><strong>Vertical significance brackets</strong><br><code>rainbow-transparent</code><br><a href="examples/mutl-comparison-significance/prompt.md">Prompt and CSV</a> · <a href="examples/mutl-comparison-significance/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="examples/mutl-comparison-significance-horizontal/prompt.md"><img src="examples/mutl-comparison-significance-horizontal/preview-card.svg" width="300" height="285" alt="Horizontal significance brackets"></a><br><strong>Horizontal significance brackets</strong><br><code>blue-pink-purple-peach-transparent</code><br><a href="examples/mutl-comparison-significance-horizontal/prompt.md">Prompt and CSV</a> · <a href="examples/mutl-comparison-significance-horizontal/preview.png">Actual export</a></td>
</tr></table>

### Several metrics across methods

<table><tr>
<td align="center" width="300"><a href="examples/multi-metric-shared-rows/prompt.md"><img src="examples/multi-metric-shared-rows/preview-card.svg" width="300" height="285" alt="Parallel bars, outside values"></a><br><strong>Parallel bars, outside values</strong><br><code>rainbow-transparent</code><br><a href="examples/multi-metric-shared-rows/prompt.md">Prompt and CSV</a> · <a href="examples/multi-metric-shared-rows/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="examples/multi-metric-shared-rows-inside/prompt.md"><img src="examples/multi-metric-shared-rows-inside/preview-card.svg" width="300" height="285" alt="Parallel bars, inside values and SD"></a><br><strong>Parallel bars, inside values and SD</strong><br><code>blue-pink-purple-peach-transparent</code><br><a href="examples/multi-metric-shared-rows-inside/prompt.md">Prompt and CSV</a> · <a href="examples/multi-metric-shared-rows-inside/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="examples/multi-metric-shared-rows-no-sd/prompt.md"><img src="examples/multi-metric-shared-rows-no-sd/preview-card.svg" width="300" height="285" alt="Parallel bars, inside values without SD"></a><br><strong>Parallel bars, inside values without SD</strong><br><code>blue-yellow-transparent</code><br><a href="examples/multi-metric-shared-rows-no-sd/prompt.md">Prompt and CSV</a> · <a href="examples/multi-metric-shared-rows-no-sd/preview.png">Actual export</a></td>
</tr></table>

<table><tr>
<td align="center" width="300"><a href="examples/multi-metric-stacked-bars/prompt.md"><img src="examples/multi-metric-stacked-bars/preview-card.svg" width="300" height="285" alt="Stacked vertical bar panels"></a><br><strong>Stacked vertical bar panels</strong><br><code>muted-green-blue-purple-transparent</code><br><a href="examples/multi-metric-stacked-bars/prompt.md">Prompt and CSV</a> · <a href="examples/multi-metric-stacked-bars/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="examples/multi-metric-shared-axis/prompt.md"><img src="examples/multi-metric-shared-axis/preview-card.svg" width="300" height="285" alt="Comparable mean lines on one axis"></a><br><strong>Comparable mean lines on one axis</strong><br><code>muted-green-blue-purple-transparent</code><br><a href="examples/multi-metric-shared-axis/prompt.md">Prompt and CSV</a> · <a href="examples/multi-metric-shared-axis/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="examples/multi-metric-shared-axis-bars/prompt.md"><img src="examples/multi-metric-shared-axis-bars/preview-card.svg" width="300" height="285" alt="Comparable mean lines with bars"></a><br><strong>Comparable mean lines with bars</strong><br><code>blue-pink-purple-peach-transparent</code><br><a href="examples/multi-metric-shared-axis-bars/prompt.md">Prompt and CSV</a> · <a href="examples/multi-metric-shared-axis-bars/preview.png">Actual export</a></td>
</tr></table>

<table><tr>
<td align="center" width="300"><a href="examples/multi-metric-comparison-dual-axis/prompt.md"><img src="examples/multi-metric-comparison-dual-axis/preview-card.svg" width="300" height="285" alt="Dual axes, model colors"></a><br><strong>Dual axes, model colors</strong><br><code>blue-yellow-transparent</code><br><a href="examples/multi-metric-comparison-dual-axis/prompt.md">Prompt and CSV</a> · <a href="examples/multi-metric-comparison-dual-axis/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="examples/multi-metric-comparison-dual-axis-by-metric/prompt.md"><img src="examples/multi-metric-comparison-dual-axis-by-metric/preview-card.svg" width="300" height="285" alt="Dual axes, metric colors"></a><br><strong>Dual axes, metric colors</strong><br><code>blue-yellow-transparent</code><br><a href="examples/multi-metric-comparison-dual-axis-by-metric/prompt.md">Prompt and CSV</a> · <a href="examples/multi-metric-comparison-dual-axis-by-metric/preview.png">Actual export</a></td>
</tr></table>

### Grouped distributions

<table><tr>
<td align="center" width="300"><a href="examples/grouped-distributions-bar-vertical/prompt.md"><img src="examples/grouped-distributions-bar-vertical/preview-card.svg" width="300" height="285" alt="Grouped bars, vertical"></a><br><strong>Grouped bars, vertical</strong><br><code>rainbow-transparent</code><br><a href="examples/grouped-distributions-bar-vertical/prompt.md">Prompt and CSV</a> · <a href="examples/grouped-distributions-bar-vertical/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="examples/grouped-distributions-bar-horizontal/prompt.md"><img src="examples/grouped-distributions-bar-horizontal/preview-card.svg" width="300" height="285" alt="Grouped bars, horizontal"></a><br><strong>Grouped bars, horizontal</strong><br><code>blue-yellow-transparent</code><br><a href="examples/grouped-distributions-bar-horizontal/prompt.md">Prompt and CSV</a> · <a href="examples/grouped-distributions-bar-horizontal/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="examples/grouped-distributions-box-vertical/prompt.md"><img src="examples/grouped-distributions-box-vertical/preview-card.svg" width="300" height="285" alt="Grouped boxes, vertical"></a><br><strong>Grouped boxes, vertical</strong><br><code>rainbow-transparent</code><br><a href="examples/grouped-distributions-box-vertical/prompt.md">Prompt and CSV</a> · <a href="examples/grouped-distributions-box-vertical/preview.png">Actual export</a></td>
</tr></table>

<table><tr>
<td align="center" width="300"><a href="examples/grouped-distributions-box-horizontal/prompt.md"><img src="examples/grouped-distributions-box-horizontal/preview-card.svg" width="300" height="285" alt="Grouped boxes, horizontal"></a><br><strong>Grouped boxes, horizontal</strong><br><code>blue-pink-purple-peach-transparent</code><br><a href="examples/grouped-distributions-box-horizontal/prompt.md">Prompt and CSV</a> · <a href="examples/grouped-distributions-box-horizontal/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="examples/grouped-distributions-violin-vertical/prompt.md"><img src="examples/grouped-distributions-violin-vertical/preview-card.svg" width="300" height="285" alt="Grouped violins, vertical"></a><br><strong>Grouped violins, vertical</strong><br><code>rainbow-transparent</code><br><a href="examples/grouped-distributions-violin-vertical/prompt.md">Prompt and CSV</a> · <a href="examples/grouped-distributions-violin-vertical/preview.png">Actual export</a></td>
</tr></table>

<table><tr>
<td align="center" width="300"><a href="examples/grouped-distributions-violin-horizontal/prompt.md"><img src="examples/grouped-distributions-violin-horizontal/preview-card.svg" width="300" height="285" alt="Grouped violins, horizontal"></a><br><strong>Grouped violins, horizontal</strong><br><code>muted-green-blue-purple-transparent</code><br><a href="examples/grouped-distributions-violin-horizontal/prompt.md">Prompt and CSV</a> · <a href="examples/grouped-distributions-violin-horizontal/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="examples/grouped-distributions-legend-space/prompt.md"><img src="examples/grouped-distributions-legend-space/preview-card.svg" width="300" height="285" alt="Bounded grouped bars"></a><br><strong>Bounded grouped bars</strong><br><code>rainbow-transparent</code><br><a href="examples/grouped-distributions-legend-space/prompt.md">Prompt and CSV</a> · <a href="examples/grouped-distributions-legend-space/preview.png">Actual export</a></td>
</tr></table>

### Broken box axes

<table><tr>
<td align="center" width="300"><a href="examples/broken-box-vertical/prompt.md"><img src="examples/broken-box-vertical/preview-card.svg" width="300" height="285" alt="Broken box axis, vertical"></a><br><strong>Broken box axis, vertical</strong><br><code>rainbow-transparent</code><br><a href="examples/broken-box-vertical/prompt.md">Prompt and CSV</a> · <a href="examples/broken-box-vertical/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="examples/broken-box-horizontal/prompt.md"><img src="examples/broken-box-horizontal/preview-card.svg" width="300" height="285" alt="Broken box axis, horizontal"></a><br><strong>Broken box axis, horizontal</strong><br><code>blue-yellow-transparent</code><br><a href="examples/broken-box-horizontal/prompt.md">Prompt and CSV</a> · <a href="examples/broken-box-horizontal/preview.png">Actual export</a></td>
</tr></table>

### Trend comparison

<table><tr>
<td align="center" width="300"><a href="examples/trend-two-models/prompt.md"><img src="examples/trend-two-models/preview-card.svg" width="300" height="285" alt="Two-model linear trend"></a><br><strong>Two-model linear trend</strong><br><code>muted-green-blue-purple</code><br><a href="examples/trend-two-models/prompt.md">Prompt and CSV</a> · <a href="examples/trend-two-models/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="examples/trend-polynomial/prompt.md"><img src="examples/trend-polynomial/preview-card.svg" width="300" height="285" alt="Exploratory polynomial trend"></a><br><strong>Exploratory polynomial trend</strong><br><code>muted-green-blue-purple</code><br><a href="examples/trend-polynomial/prompt.md">Prompt and CSV</a> · <a href="examples/trend-polynomial/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="examples/trend-dual-metric/prompt.md"><img src="examples/trend-dual-metric/preview-card.svg" width="300" height="285" alt="One-model dual-metric trend"></a><br><strong>One-model dual-metric trend</strong><br><code>muted-green-blue-purple</code><br><a href="examples/trend-dual-metric/prompt.md">Prompt and CSV</a> · <a href="examples/trend-dual-metric/preview.png">Actual export</a></td>
</tr></table>

<table><tr>
<td align="center" width="300"><a href="examples/trend-multi-model/prompt.md"><img src="examples/trend-multi-model/preview-card.svg" width="300" height="285" alt="Four-model linear trend"></a><br><strong>Four-model linear trend</strong><br><code>blue-pink-purple-peach-transparent</code><br><a href="examples/trend-multi-model/prompt.md">Prompt and CSV</a> · <a href="examples/trend-multi-model/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="examples/trend-categorical-horizontal/prompt.md"><img src="examples/trend-categorical-horizontal/preview-card.svg" width="300" height="285" alt="Categories on the horizontal axis"></a><br><strong>Categories on the horizontal axis</strong><br><code>blue-pink-purple-peach-transparent</code><br><a href="examples/trend-categorical-horizontal/prompt.md">Prompt and CSV</a> · <a href="examples/trend-categorical-horizontal/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="examples/trend-categorical-vertical/prompt.md"><img src="examples/trend-categorical-vertical/preview-card.svg" width="300" height="285" alt="Categories on the vertical axis"></a><br><strong>Categories on the vertical axis</strong><br><code>blue-yellow-transparent</code><br><a href="examples/trend-categorical-vertical/prompt.md">Prompt and CSV</a> · <a href="examples/trend-categorical-vertical/preview.png">Actual export</a></td>
</tr></table>

### Radar comparison

<table><tr>
<td align="center" width="300"><a href="examples/radar-comparison/prompt.md"><img src="examples/radar-comparison/preview-card.svg" width="300" height="285" alt="Radar model profiles"></a><br><strong>Radar model profiles</strong><br><code>muted-green-blue-purple</code><br><a href="examples/radar-comparison/prompt.md">Prompt and CSV</a> · <a href="examples/radar-comparison/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="examples/radar-comparison-rainbow/prompt.md"><img src="examples/radar-comparison-rainbow/preview-card.svg" width="300" height="285" alt="Radar model profiles"></a><br><strong>Radar model profiles</strong><br><code>rainbow-transparent</code><br><a href="examples/radar-comparison-rainbow/prompt.md">Prompt and CSV</a> · <a href="examples/radar-comparison-rainbow/preview.png">Actual export</a></td>
</tr></table>

<table><tr>
<td align="center" width="300"><a href="examples/radar-comparison-pastel/prompt.md"><img src="examples/radar-comparison-pastel/preview-card.svg" width="300" height="285" alt="Radar model profiles"></a><br><strong>Radar model profiles</strong><br><code>blue-pink-purple-peach-transparent</code><br><a href="examples/radar-comparison-pastel/prompt.md">Prompt and CSV</a> · <a href="examples/radar-comparison-pastel/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="examples/radar-comparison-bands/prompt.md"><img src="examples/radar-comparison-bands/preview-card.svg" width="300" height="285" alt="Radar: green tinted bands"></a><br><strong>Radar: green tinted bands</strong><br><code>muted-green-blue-purple</code><br><a href="examples/radar-comparison-bands/prompt.md">Prompt and CSV</a> · <a href="examples/radar-comparison-bands/preview.png">Actual export</a></td>
</tr></table>

### Grouped circular heatmaps and violins

<table><tr>
<td align="center" width="300"><a href="examples/grouped-circular-heatmap-blue-yellow/prompt.md"><img src="examples/grouped-circular-heatmap-blue-yellow/preview-card.svg" width="300" height="285" alt="Circular heatmap: blue-yellow"></a><br><strong>Circular heatmap: blue-yellow</strong><br><code>blue-yellow</code><br><a href="examples/grouped-circular-heatmap-blue-yellow/prompt.md">Prompt and CSV</a> · <a href="examples/grouped-circular-heatmap-blue-yellow/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="examples/grouped-circular-heatmap-pastel/prompt.md"><img src="examples/grouped-circular-heatmap-pastel/preview-card.svg" width="300" height="285" alt="Circular heatmap: pastel"></a><br><strong>Circular heatmap: pastel</strong><br><code>blue-pink-purple-peach</code><br><a href="examples/grouped-circular-heatmap-pastel/prompt.md">Prompt and CSV</a> · <a href="examples/grouped-circular-heatmap-pastel/preview.png">Actual export</a></td>
</tr></table>

<table><tr>
<td align="center" width="300"><a href="examples/grouped-circular-heatmap-one-group/prompt.md"><img src="examples/grouped-circular-heatmap-one-group/preview-card.svg" width="300" height="285" alt="Circular heatmap: one group"></a><br><strong>Circular heatmap: one group</strong><br><code>blue-pink-purple-peach</code><br><a href="examples/grouped-circular-heatmap-one-group/prompt.md">Prompt and CSV</a> · <a href="examples/grouped-circular-heatmap-one-group/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="examples/grouped-circular-heatmap-three-groups/prompt.md"><img src="examples/grouped-circular-heatmap-three-groups/preview-card.svg" width="300" height="285" alt="Circular heatmap: three unequal groups"></a><br><strong>Circular heatmap: three unequal groups</strong><br><code>blue-yellow</code><br><a href="examples/grouped-circular-heatmap-three-groups/prompt.md">Prompt and CSV</a> · <a href="examples/grouped-circular-heatmap-three-groups/preview.png">Actual export</a></td>
</tr></table>

<table><tr>
<td align="center" width="300"><a href="examples/grouped-circular-heatmap-eight-groups/prompt.md"><img src="examples/grouped-circular-heatmap-eight-groups/preview-card.svg" width="300" height="285" alt="Circular heatmap: eight unequal groups"></a><br><strong>Circular heatmap: eight unequal groups</strong><br><code>blue-yellow</code><br><a href="examples/grouped-circular-heatmap-eight-groups/prompt.md">Prompt and CSV</a> · <a href="examples/grouped-circular-heatmap-eight-groups/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="examples/grouped-circular-heatmap-twelve-groups/prompt.md"><img src="examples/grouped-circular-heatmap-twelve-groups/preview-card.svg" width="300" height="285" alt="Circular heatmap: twelve small groups"></a><br><strong>Circular heatmap: twelve small groups</strong><br><code>muted-green-blue-purple-light</code><br><a href="examples/grouped-circular-heatmap-twelve-groups/prompt.md">Prompt and CSV</a> · <a href="examples/grouped-circular-heatmap-twelve-groups/preview.png">Actual export</a></td>
</tr></table>

### Palette appearance on the same data

<table><tr>
<td align="center" width="300"><a href="examples/palette-muted-green-blue-purple/prompt.md"><img src="examples/palette-muted-green-blue-purple/preview-card.svg" width="300" height="285" alt="Violin palette demonstration"></a><br><strong>Violin palette demonstration</strong><br><code>muted-green-blue-purple</code><br><a href="examples/palette-muted-green-blue-purple/prompt.md">Prompt and CSV</a> · <a href="examples/palette-muted-green-blue-purple/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="examples/palette-muted-green-blue-purple-transparent/prompt.md"><img src="examples/palette-muted-green-blue-purple-transparent/preview-card.svg" width="300" height="285" alt="Violin palette demonstration"></a><br><strong>Violin palette demonstration</strong><br><code>muted-green-blue-purple-transparent</code><br><a href="examples/palette-muted-green-blue-purple-transparent/prompt.md">Prompt and CSV</a> · <a href="examples/palette-muted-green-blue-purple-transparent/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="examples/palette-rainbow/prompt.md"><img src="examples/palette-rainbow/preview-card.svg" width="300" height="285" alt="Violin palette demonstration"></a><br><strong>Violin palette demonstration</strong><br><code>rainbow</code><br><a href="examples/palette-rainbow/prompt.md">Prompt and CSV</a> · <a href="examples/palette-rainbow/preview.png">Actual export</a></td>
</tr></table>

<table><tr>
<td align="center" width="300"><a href="examples/palette-rainbow-transparent/prompt.md"><img src="examples/palette-rainbow-transparent/preview-card.svg" width="300" height="285" alt="Violin palette demonstration"></a><br><strong>Violin palette demonstration</strong><br><code>rainbow-transparent</code><br><a href="examples/palette-rainbow-transparent/prompt.md">Prompt and CSV</a> · <a href="examples/palette-rainbow-transparent/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="examples/palette-blue-yellow/prompt.md"><img src="examples/palette-blue-yellow/preview-card.svg" width="300" height="285" alt="Violin palette demonstration"></a><br><strong>Violin palette demonstration</strong><br><code>blue-yellow</code><br><a href="examples/palette-blue-yellow/prompt.md">Prompt and CSV</a> · <a href="examples/palette-blue-yellow/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="examples/palette-blue-yellow-transparent/prompt.md"><img src="examples/palette-blue-yellow-transparent/preview-card.svg" width="300" height="285" alt="Violin palette demonstration"></a><br><strong>Violin palette demonstration</strong><br><code>blue-yellow-transparent</code><br><a href="examples/palette-blue-yellow-transparent/prompt.md">Prompt and CSV</a> · <a href="examples/palette-blue-yellow-transparent/preview.png">Actual export</a></td>
</tr></table>

<table><tr>
<td align="center" width="300"><a href="examples/palette-blue-pink-purple-peach/prompt.md"><img src="examples/palette-blue-pink-purple-peach/preview-card.svg" width="300" height="285" alt="Violin palette demonstration"></a><br><strong>Violin palette demonstration</strong><br><code>blue-pink-purple-peach</code><br><a href="examples/palette-blue-pink-purple-peach/prompt.md">Prompt and CSV</a> · <a href="examples/palette-blue-pink-purple-peach/preview.png">Actual export</a></td>
<td align="center" width="300"><a href="examples/palette-blue-pink-purple-peach-transparent/prompt.md"><img src="examples/palette-blue-pink-purple-peach-transparent/preview-card.svg" width="300" height="285" alt="Violin palette demonstration"></a><br><strong>Violin palette demonstration</strong><br><code>blue-pink-purple-peach-transparent</code><br><a href="examples/palette-blue-pink-purple-peach-transparent/prompt.md">Prompt and CSV</a> · <a href="examples/palette-blue-pink-purple-peach-transparent/preview.png">Actual export</a></td>
</tr></table>

## Fixed palette references

Named palettes preserve fixed RGB assignments. Transparent variants apply mark-specific opacity. Each scientific preview identifies its actual palette. Click a palette reference to view the original-resolution image.

<table><tr>
<td align="center" width="900" colspan="2"><a href="examples/palettes/palette-overview.png"><img src="examples/palettes/palette-overview.png" width="900" alt="palette-overview"></a><br><code>palette-overview</code></td>
</tr><tr>
<td align="center" width="450"><a href="examples/palettes/palette-muted-pastel-six.png"><img src="examples/palettes/palette-muted-pastel-six.png" width="450" alt="palette-muted-pastel-six"></a><br><code>palette-muted-pastel-six</code></td>
<td align="center" width="450"><a href="examples/palettes/palette-muted-balanced-six.png"><img src="examples/palettes/palette-muted-balanced-six.png" width="450" alt="palette-muted-balanced-six"></a><br><code>palette-muted-balanced-six</code></td>
</tr></table>

## File organization

`examples/<figure-id>/prompt.md` is the user-facing example, `request.json` provides a minimal configuration structure where useful, and `preview.png` is the unchanged scientific export and `preview-card.svg` contains it in an equal-size display frame. Shared synthetic inputs live in `examples/data/`. Runtime instructions, scientific contracts, reusable renderers and fixed palette definitions live in `SKILL.md`, `references/`, `scripts/` and `palettes/`.


## Extend a figure or palette

When a different encoding is needed, provide the result data and a reference figure, then identify the visual elements to retain. The agent inspects the scientific meaning and chooses or adapts a reusable layout.
