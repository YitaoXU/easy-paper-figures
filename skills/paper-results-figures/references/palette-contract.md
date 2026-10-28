# Fixed palette contract

A palette name selects fixed RGB colors and fixed opacity parameters for each mark family. The canonical source is `palettes/palette-families.json`; `palettes/palettes.json` is its generated flat renderer index. Browse the [family catalog](palette-catalog.md) before choosing a preset. Do not invent colors, resample categorical colors, or change saturation, opacity or darkening during automatic visual refinement. Adjust size, jitter, spacing or layout instead. A user-requested color change overrides the preset for that figure; record it as a custom override. Existing figure configurations retain their saved overrides.

| Palette | Fill alpha | Distribution point alpha | Distribution RGB darkening | Paired point alpha | Paired RGB darkening | Paired RGB lightening |
| --- | --- | --- | --- | --- | --- | --- |
| `pastel-green-blue-purple-peach` | 0.40 | 0.55 | 0.20 | 0.60 | 0.00 | 0.00 |
| `rainbow` | 1.00 | 0.55 | 0.20 | 0.50 | 0.00 | 0.00 |
| `rainbow-transparent` | 0.40 | 0.55 | 0.20 | 0.70 | 0.00 | 0.00 |
| `muted-green-blue-purple` | 0.40 | 0.55 | 0.20 | 0.50 | 0.12 | 0.18 |
| `muted-green-blue-purple-light` | 0.40 | 0.55 | 0.20 | 0.50 | 0.12 | 0.00 |
| `muted-green-blue-purple-transparent` | 0.25 | 0.55 | 0.20 | 0.70 | 0.12 | 0.18 |
| `blue-yellow` | 1.00 | 0.55 | 0.20 | 0.70 | 0.00 | 0.00 |
| `blue-yellow-transparent` | 0.40 | 0.55 | 0.20 | 0.60 | 0.00 | 0.00 |
| `blue-pink-purple-peach` | 1.00 | 0.55 | 0.20 | 0.70 | 0.00 | 0.00 |
| `blue-pink-purple-peach-transparent` | 0.40 | 0.55 | 0.20 | 0.60 | 0.00 | 0.00 |
| `muted-pastel-six` | 1.00 | 0.55 | 0.20 | 1.00 | 0.00 | 0.00 |
| `muted-balanced-six` | 1.00 | 0.55 | 0.20 | 1.00 | 0.00 | 0.00 |
| `muted-balanced-twelve` | 1.00 | 0.55 | 0.20 | 1.00 | 0.00 | 0.00 |
| `yellow-green` | 0.40 | 0.55 | 0.20 | 0.70 | 0.00 | 0.00 |
| `yellow-green-red` | 0.40 | 0.55 | 0.20 | 0.70 | 0.00 | 0.00 |
| `blue-green-yellow` | 0.40 | 0.55 | 0.20 | 0.70 | 0.00 | 0.00 |
| `blue-green-coral` | 0.40 | 0.55 | 0.20 | 0.70 | 0.00 | 0.00 |
| `muted-reference-six` | 0.40 | 0.55 | 0.20 | 0.70 | 0.00 | 0.00 |
| `warm-yellow-leaf-crisper` | 0.40 | 0.55 | 0.20 | 0.70 | 0.00 | 0.00 |

The `rainbow-transparent` paired layout with `marginals: true` has a fixed readability profile: omitted/null paired `point_alpha` is 0.90 and `point_darken` is 0.20. Base RGB slots remain unchanged; multiply them by 0.80 before applying opacity to scatter marks and their guides. Marginal method anchors use the same transform with their separate histogram opacity. This layout exception leaves the table's ordinary paired defaults and every other mark family unchanged. Explicit/saved overrides remain authoritative.

Alpha is opacity: 1 is fully opaque. The base name does not promise fully opaque scatter. Distribution point darkening multiplies each RGB channel by 0.80 before applying alpha. Green-blue-purple paired points retain the fixed 0.88 darkening multiplier. The base and transparent green-blue-purple presets then blend those quantized 8-bit RGB channels with 18% white (`paired_point_lighten: 0.18`), producing a slightly lighter scatter while preserving category assignments and opacity. The separate circular `muted-green-blue-purple-light` preset retains zero paired lightening. Resolve paired `point_lighten` from the palette when omitted; an explicit value overrides it. Apply lightening after darkening as `round(darkened_channel * (1 - point_lighten) + 255 * point_lighten)`, before opacity. These transforms apply consistently to categorical points, continuous gradient stops, marginal method colors and their guides; they do not modify fills or distribution points; the rainbow marginal layout has the separate fixed exception above. Keep the base named mapping and save the effective point mapping separately, so rerendering never darkens or lightens twice. Explicit paired `point_darken: 0` and `point_lighten: 0` together request unchanged base RGB. Saved resolved values for both fields remain authoritative; older configurations without `point_lighten` adopt the current palette default. Borders and statistical annotations follow the shared style guide independently of category colors. Legacy `point_alpha` metadata is retained for compatibility; renderers use the explicit mark-family fields above.

Radar defaults to the fixed `muted-green-blue-purple` slots, fully opaque outlines/icons and unchanged base RGB (`line_darken: 0`). New automatic rainbow maps retain their category-wide 0.40 outline darkening. Optional polygon fills retain base RGB and palette fill opacity. Save base/effective maps separately and preserve explicit and legacy map precedence in [the radar contract](radar-comparison.md). Decorative radial bands use independent fixed colors with opacity 0.28 and encode no observed thresholds.

## Fixed categorical slots

Automatic assignments follow the selected family's policy below. Explicit/saved named maps always take precedence; a palette change never silently rewrites an existing figure's map. Colors do not reorder scientific observations, choose a hypothesis or change numeric values. `palette_order: shuffled` explicitly permutes the selected colors instead of using the ordered presentation.

- **Green → blue → purple:** `muted-green-blue-purple` and its transparent/light variants assign the fixed hues in this sequence to the resolved display order. Read method comparisons left-to-right when vertical and bottom-to-top when horizontal; other categorical guides use their declared level/model/metric/group order. Within each hue, fixed shade slots stay together. There is no separately reserved purple focal hue in this family. Focal labels/line emphasis remain independent. Preserve a saved named map when identity consistency across differently ordered related figures takes precedence over a fresh sequence.
- **Balanced blue/yellow:** ordinary categorical sets and method comparisons use equal blue/yellow counts whenever their total is even: 2 → 1+1, 4 → 2+2, 6 → 3+3. Coordinated circular groups support the same rule up to 12 slots. Odd sets use the nearest balance with one extra blue; a lone explicitly designated focal method retains yellow. A focal method keeps yellow slot 2, and its slot counts toward the quota, so comparators may also be yellow. No colors are invented or recycled.
- **Other families:** map sorted raw IDs (R radix order) to the selected slots. Method maps reserve the declared focal hue for explicit `highlight`/`focus_models`, or exact raw ID `Ours` when no focal is designated. Comparator IDs are sorted independently of row/display/performance order. More focal identities or categories than available slots require an authorized named map or another palette.

For ordinary automatic sets of two or three colors outside the family's sequence/balance constraints, maximize the minimum pairwise Euclidean CIELAB distance (sRGB with R's D65 white point); break equal minima by minimum/maximum distance ratio, then original slot order. Include reserved focal colors. `small_set_comparator_slots` permits the blue-pink-purple-peach family's pink slot in small sets; four-or-more-method maps retain its ordinary comparator slots. This is a contrast heuristic, not a guarantee of perceptual uniformity or color-vision accessibility. Family sequence/balance rules, explicit maps and the dual-axis mark-role exception take priority.

Multiple metrics record which variable color encodes: method colors use `color_values`; shared-axis and explicit dual-axis metric colors use `combo_metric_colors`. A color identifies one metric across every method. For blue-yellow dual axes with exactly one bar and one line metric, omitted metric maps retain light-blue slot 3 (`#B5D0E0`) for bars and yellow slot 2 (`#F5C258`) for the line/icons. This already satisfies the two-color balance. Explicit maps take precedence; a palette name does not switch the encoded variable.

The reserved method slots below are one-based indices into the fixed RGB lists; green-blue-purple instead uses its display-sequence policy:

| Palette family | Focal slot and hue | Comparator slots |
| --- | --- | --- |
| `pastel-green-blue-purple-peach` | 4, peach | 1, 2, 3 (green/blue/purple) |
| `rainbow` and transparent variant | 10, rose | 1, 2, 3, 4, 6, 7, 9 |
| `muted-green-blue-purple` and transparent variant | No reserved hue | Display sequence, up to six methods |
| `muted-green-blue-purple-light` | No reserved hue | Display sequence, up to six methods |
| `blue-yellow` and transparent variant | 2, yellow, counted in balance | 1, 3, 4, 5, 6; select to balance blue/yellow |
| `blue-pink-purple-peach` and transparent variant | 4, peach | 1, 3, 5, 6 (blue/purple) |
| `muted-pastel-six` | 5, peach | 1, 3, 4, 6 |
| `muted-balanced-six` | 5, rose | 1, 2, 3, 4, 6 |
| `muted-balanced-twelve` | 5, rose | 1, 2, 3, 4, 6, 7, 8, 9, 10, 12 |
| `yellow-green` | 1, yellow | 2, 4, 6 (green) |
| `yellow-green-red` | 3, red | 1, 2, 4, 5 (yellow/green) |
| `blue-green-yellow` | 3, yellow | 1, 2, 4, 5 (blue/green) |
| `blue-green-coral` | 3, coral | 1, 2, 4, 5 (blue/green) |
| `muted-reference-six` | 3, purple | 1, 2, 4, 5, 6 |
| `warm-yellow-leaf-crisper` | 3, teal | 1, 2, 4 (gold/yellow/orange) |

Resolved `palette_mapping` or `model_palette_mapping` records the assignment policy, focal identities, exact base colors and assigned slots. Keep this provenance with saved configurations. These focal rules apply only to colors encoding methods: metric-colored shared axes and dual axes retain their metric identities/mark roles, while numerical covariates retain their continuous gradients. Color choice never alters observations, ordering, tests or domain scaling.

## Fixed color definitions and continuous guides

Read exact RGB slots, continuous stops, anchors and coordinated group colors from `palettes/palettes.json`; the [family catalog](palette-catalog.md) lists available names and capacities. These values are generated from `palette-families.json`, not reconstructed from preview pixels. Reference-derived palettes approximate displayed sRGB colors; they do not recover original source HEX values. Design gradients are illustrative, not perceptually uniform.

Continuous covariates interpolate the stored stops with the applicable mark-family transform. State the covariate and its limits. Paired points and their numeric guide use the same effective gradient and opacity; see [paired guides](paired-comparison-scatter.md) for placement, complete-frame measurement and tick rules. Numeric-looking category IDs remain categorical.

## Preserve category identity across figures

For a related figure family, reuse its saved named map, including absent categories, rather than remapping when rankings change. Append new categories only with unused fixed slots under an established policy. Green-blue-purple's fresh automatic map follows display order; its saved map intentionally takes precedence when that order later changes. Other families use deterministic raw-identity assignment, but adding/removing/renaming categories can change selected slots. Keep project-specific maps with the external figure configuration, never in the generic skill, and do not claim persistent cross-project identity mapping.

Changing a palette name applies that palette's alpha defaults when opacity fields are null or omitted. Existing explicit values are preserved for reproducibility; clear them only when the user requests the preset. Existing exports are not regenerated by this update.

## Family-specific roles

- `muted-balanced-six` and `muted-balanced-twelve` share stored RGB definitions but retain different focal/comparator capacities. The twelve-slot extension preserves the six-color core and its continuous anchors.
- `muted-green-blue-purple-light` changes RGB brightness while retaining the base family's opacity and green→blue→purple display policy. It and `blue-yellow` provide separate fixed twelve-slot `group_categorical` lists for circular group bands and guide icons. Group slots do not interpolate or recycle, and do not alter method colors. Follow the [circular contract](grouped-circular-heatmap.md) for coordination and capacity fallback.
- `warm-yellow-leaf-crisper` combines medium categorical colors with separate light anchors and an orange-yellow-green ramp. The ramp may supply an explicitly requested ordered categorical named map with recorded order/direction; it does not replace automatic unordered method colors. Automatic focal teal and warm comparator slots follow the table above. Other green slots remain available for ordinary categories or explicit maps. Opaque inside-bar fills require explicit `fill_alpha: 1`; other mark roles retain their preset defaults.
- `blue-pink-purple-peach` uses blue `#6F95BC` and purple `#A087B8`, with lighter partners `#9EBFDC` and `#C4ABD5`, to separate the two hue families. Pink, peach and opacity are unchanged; the transparent variant uses the same RGB slots.
- `pastel-green-blue-purple-peach` retains its own pale peach independently of the deeper peach in `blue-pink-purple-peach`. Saved named maps always retain their original RGB values until the user requests remapping.

A requested special tone for a dominant category belongs in an external named map with its reason, not in the generic palette. Do not infer that assignment from observed scores. Inspect isolated and overlapping marks at the prescribed opacity.

## Family maintenance and compatibility

Families share identical RGB lists where appropriate; opacity-only variants override their mark profiles. Lighter-RGB and hue-companion options remain distinct fixed variants. Balanced six/twelve names share stored RGB colors but retain different focal/comparator capacities. All legacy preset names are preserved in the generated runtime index. Rebuild and verify it with `python3 scripts/build_palette_catalog.py` and `python3 scripts/build_palette_catalog.py --check`. Existing category-specific defaults, saved explicit opacity, named maps and scientific records remain authoritative.

## Categorical sequence controls

Color sequence is independent of opacity: use `palette_order: ordered` (default) for nearby hues together, or `palette_order: shuffled` with `palette_seed: 42` for a repeatable permutation of the same selected colors. The seed accepts nonnegative integers. Scientific model/data order and continuous gradients stay unchanged; family-specific focal and balance policies still apply. Explicit named maps, including maps stored in a resolved configuration, take priority; remove those maps to apply a new automatic order.

The curated `ordered_slots` (and coordinated `group_ordered_slots` when present) are complete permutations of original one-based slots. Select the eligible subset under its family sequence/balance or small-set contrast rule, then permute it. Never replace colors, resample a palette, alter fill alpha, reorder scientific observations or assign a focal hue using performance. Shuffling saves and restores the random state so statistical sampling and point jitter remain independent. A random permutation can occasionally equal the ordered one.
