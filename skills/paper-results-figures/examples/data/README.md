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
- `radar-scores.csv`: established summaries on eight common [0,1] axes; no replicate uncertainty.

Use a fixture directly, or provide CSV, TSV or XLSX data with your own scientific column meanings, pairing rules and metric directions. The agent inspects and adapts unambiguous input formats.
