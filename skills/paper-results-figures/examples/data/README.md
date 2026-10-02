# Fixed synthetic inputs

These CSV files contain fictional scores and responses for learning the layouts. `Ours` is the focal method and performs best on higher-is-better score fixtures; weaker methods make distribution and profile differences visible. Method gaps and metric profiles deliberately vary irregularly, with different local rises and falls. No real study data is included.

- `paired-scores.csv`, `paired-size.csv`: one row per independent matched pair; both score columns share a [0,1] domain.
- `method-scores.csv`: 50 independent unit IDs matched across four methods, one unitless [0,1] score.
- `mixed-metrics.csv`: matched raw unitless scores and responses in separate units.
- `comparable-metrics.csv`: matched raw unitless [0,1] scores for three metrics.
- `grouped-scores.csv`, `broken-scores.csv`: 24 matched independent IDs across three methods; unitless [0,1] scores with broad visible distributions and an explicit empty interval in the broken fixture.
- `trend-linear.csv`, `trend-polynomial.csv`, `trend-multi.csv`: independent continuous response observations within models; reused ID text across models does not establish pairing.
- `trend-dual.csv`: one model, two response metrics in distinct original units.
- `category-three-metrics.csv`, `category-two-metrics.csv`: established category summaries without replicate uncertainty.
- `grouped_circular_sparse.csv`: three matched string IDs (including leading zeros), two groups and two methods, with a constant comparator for point/range fallback.
- `grouped_circular_scores.csv`: 120 matched item IDs across four methods, six unequal groups (56, 28, 20, 12, 3, 1 items), unitless [0,1] scores; group membership stays fixed across methods.
- `radar-scores.csv`: established summaries on eight common [0,1] axes; no replicate uncertainty.

Additional circular heatmap inputs vary group count and item density. All are complete item-level pairings across four methods, with fixed group membership and unitless [0,1] scores. For the opt-in significance examples, different synthetic items represent independent evaluation units and their paired method differences are independent across items; groups organize the display rather than define repeated clusters. This synthetic assumption must be established again for real data.

| CSV | Unique items | Groups | Items per group |
| --- | ---: | ---: | --- |
| [grouped_circular_one_group.csv](grouped_circular_one_group.csv) | 24 | 1 | 24 |
| [grouped_circular_three_groups.csv](grouped_circular_three_groups.csv) | 24 | 3 | 18, 5, 1 |
| [grouped_circular_eight_groups.csv](grouped_circular_eight_groups.csv) | 79 | 8 | 35, 18, 10, 6, 4, 3, 2, 1 |
| [grouped_circular_twelve_groups.csv](grouped_circular_twelve_groups.csv) | 24 | 12 | 2 in every group |
| [grouped_circular_dense.csv](grouped_circular_dense.csv) | 235 | 6 | 160, 40, 20, 10, 4, 1 |

Use a fixture directly, or provide CSV, TSV or XLSX data with your own scientific column meanings, pairing rules and metric directions. The agent inspects and adapts unambiguous input formats.
