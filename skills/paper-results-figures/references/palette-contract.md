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

For ordinary categorical identities with no focal method, select the first N fixed slots (with the small-set contrast rule below), apply `palette_order` to that selected set, and map sorted raw IDs (R radix order) to the resulting sequence. When color encodes methods and the brief designates a focal method (`highlight` or radar `focus_models`), use the palette’s fixed `focal_model_mapping`: the focal hue differs from every automatic comparator hue family. With no explicit visual designation, the exact raw ID `Ours` receives the same visual treatment. Neither a best-mean annotation nor observed performance selects this focal color or establishes a statistical hypothesis. Sort comparator raw IDs independently of input row order, legend order, display labels and ranking, then select the designated comparator subset below and apply `palette_order` within it. Preserve this mapping across orientations and related figures, including opaque/transparent variants. No categorical interpolation or arbitrary recoloring is allowed. An authorized complete named `color_values` map, including an existing saved map, takes precedence and is preserved exactly. More than one visual focal method or more comparators than the preset supports requires an explicit named map; do not reuse the focal hue for opponents or silently interpolate. For multiple metrics, record which variable color encodes: model-color mode uses method IDs and `color_values`, while shared-axis lines and optional dual-axis `combo_color_by: metric` use metric IDs and `combo_metric_colors`. One metric color remains fixed across every method; a palette name does not silently switch the encoded variable. For dual-axis metric-color mode with exactly one bar and one line in the blue-yellow family only, an omitted `combo_metric_colors` map selects existing light-blue slot 3 (`#B5D0E0`) for bars and yellow slot 2 (`#F5C258`) for the line/icons, according to their mark roles. This preserves the fixed RGB definitions and opacity. An explicit named metric map takes precedence; shared-axis and other palette modes retain their deterministic identity-based assignment. Save the selected role/identity policy with the metric encoding.

For automatic sets of two or three categorical colors, search the eligible fixed slots and maximize the smallest pairwise Euclidean CIELAB distance (sRGB converted with the R default D65 white point). For equal minima, prefer the larger minimum/maximum distance ratio, then the original slot order. Include the reserved focal color in the comparison when selecting comparators. A preset may declare `small_set_comparator_slots` for these small sets without changing its ordinary comparator capacity. The blue-pink-purple-peach family permits slots 1, 2, 3, 5 and 6 here: pink slot 2 is a distinct alternative to a close blue/purple pair beside reserved peach slot 4; four-or-more-method maps retain slots 1, 3, 5 and 6. This avoids a needlessly similar pair beside a different third color when the palette permits a better separated set. Apply `palette_order` only after selecting the set; opaque/transparent variants use the same base-RGB selection. Single colors and sets of four or more retain their existing eligible prefixes. Role restrictions and fixed palette capacity still apply; a two-hue palette may not offer three well-separated hues, so inspect the effective marks and use another palette or an authorized named map when needed. Explicit/saved named maps and the blue-yellow dual-axis bar/line role exception remain authoritative. This is a categorical selection heuristic, not a guarantee of perceptual uniformity or color-vision accessibility.

The reserved method slots are one-based indices into the unchanged RGB lists:

| Palette family | Focal slot and hue | Comparator slots |
| --- | --- | --- |
| `pastel-green-blue-purple-peach` | 4, peach | 1, 2, 3 (green/blue/purple) |
| `rainbow` and transparent variant | 10, rose | 1, 2, 3, 4, 6, 7, 9 |
| `muted-green-blue-purple` and transparent variant | 3, purple | 1, 2, 4, 5 (green/blue) |
| `muted-green-blue-purple-light` | 3, purple | 1, 2, 4, 5 (green/blue) |
| `blue-yellow` and transparent variant | 2, yellow | 1, 3, 5 (blue) |
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

The same category set and visual focal designation receive the same automatic mapping across metrics, orientations and plot families, even if rankings or row order change. Palette variants share the same RGB slots. A palette name alone cannot reserve a particular color for an arbitrary scientific identity forever: adding/removing/renaming categories can change a comparator’s sorted slot. The same designated focal method retains the preset’s reserved focal slot. For a related figure family, reuse its saved named map, including absent categories; append new categories to unused slots without reassigning existing entries. Store project-specific maps with external figure configurations, never in this generic skill. If no family map is available, use deterministic mapping and disclose that it is newly assigned. Do not claim persistent cross-project identity mapping.

Changing a palette name applies that palette's alpha defaults when opacity fields are null or omitted. Existing explicit values are preserved for reproducibility; clear them only when the user requests the preset. Existing exports are not regenerated by this update.

## Family-specific roles

- `muted-balanced-six` and `muted-balanced-twelve` share stored RGB definitions but retain different focal/comparator capacities. The twelve-slot extension preserves the six-color core and its continuous anchors.
- `muted-green-blue-purple-light` changes RGB brightness while retaining the base family's opacity and focal-slot policy. It and `blue-yellow` provide separate fixed twelve-slot `group_categorical` lists for circular group bands and guide icons. Group slots do not interpolate or recycle, and do not alter method colors. Follow the [circular contract](grouped-circular-heatmap.md) for coordination and capacity fallback.
- `warm-yellow-leaf-crisper` combines medium categorical colors with separate light anchors and an orange-yellow-green ramp. The ramp may supply an explicitly requested ordered categorical named map with recorded order/direction; it does not replace automatic unordered method colors. Automatic focal teal and warm comparator slots follow the table above. Other green slots remain available for ordinary categories or explicit maps. Opaque inside-bar fills require explicit `fill_alpha: 1`; other mark roles retain their preset defaults.
- `pastel-green-blue-purple-peach` retains its own pale peach independently of the deeper peach in `blue-pink-purple-peach`. Saved named maps always retain their original RGB values until the user requests remapping.

A requested special tone for a dominant category belongs in an external named map with its reason, not in the generic palette. Do not infer that assignment from observed scores. Inspect isolated and overlapping marks at the prescribed opacity.

## Family maintenance and compatibility

Families share identical RGB lists where appropriate; opacity-only variants override their mark profiles. Lighter-RGB and hue-companion options remain distinct fixed variants. Balanced six/twelve names share stored RGB colors but retain different focal/comparator capacities. All legacy preset names are preserved in the generated runtime index. Rebuild and verify it with `python3 scripts/build_palette_catalog.py` and `python3 scripts/build_palette_catalog.py --check`. Existing category-specific defaults, saved explicit opacity, named maps and scientific records remain authoritative.

## Categorical sequence controls

Color sequence is independent of opacity: use `palette_order: ordered` (default) for nearby hues together, or `palette_order: shuffled` with `palette_seed: 42` for a repeatable permutation of the same selected colors. The seed accepts nonnegative integers. Scientific model/data order, continuous gradients and reserved focal hues stay governed by their own contracts. Explicit named maps, including maps stored in a resolved configuration, take priority; remove those maps to apply a new automatic order.

The curated `ordered_slots` (and coordinated `group_ordered_slots` when present) are complete permutations of original one-based slots. Select the eligible subset first (using the small-set contrast rule for two/three colors), then permute it. Never replace colors, resample a palette, alter fill alpha, reorder scientific observations or assign a focal hue using performance. Shuffling saves and restores the random state so statistical sampling and point jitter remain independent. A random permutation can occasionally equal the ordered one.
