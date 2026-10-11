# Pastel four-color violin

Fixed synthetic input: [method-scores.csv](../data/method-scores.csv). For this fixture replace INPUT_DATA_PATH and OUTPUT_PARENT; for new data update all scientific settings before plotting.

```text
Use paper-results-figures to make a horizontal violin comparison.

DATA SETTINGS
- Input: INPUT_DATA_PATH. One raw Score per matched observation_id/model.
- Columns: model, score, observation_id; dimensionless Score domain [0,1].
- Higher is better; visual focal: Ours. No significance or uncertainty overlay.

FIGURE SETTINGS
- Named palette: pastel-green-blue-purple-peach.
- Four-panels-per-row size. Numeric means and ranking direction.
- No scatter. Red compact dashed numeric baseline 0.05, label Baseline = 0.05.
- Output parent: OUTPUT_PARENT. Keep full exports and reproducibility records together.
```

The palette reserves peach for an explicitly designated focal identity, independently of observed performance. Three comparators use its fixed green, blue and purple slots. Opacity and point transforms remain the preset's fixed mark-specific settings.
