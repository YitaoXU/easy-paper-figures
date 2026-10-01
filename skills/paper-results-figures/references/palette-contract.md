# Fixed palette contract

A palette name selects fixed RGB colors and fixed opacity parameters for each mark family. The source of truth is `palettes/palettes.json`. Do not invent colors, resample categorical colors, or change saturation, opacity or darkening during automatic visual refinement. Adjust size, jitter, spacing or layout instead. A user-requested color change overrides the preset for that figure; record it as a custom override. Existing figure configurations retain their saved overrides.

| Palette | Fill alpha | Distribution point alpha | Distribution RGB darkening | Paired point alpha | Paired RGB darkening |
| --- | --- | --- | --- | --- | --- |
| `rainbow` | 1.00 | 0.55 | 0.20 | 0.50 | 0.00 |
| `rainbow-transparent` | 0.40 | 0.55 | 0.20 | 0.70 | 0.00 |
| `muted-green-blue-purple` | 0.40 | 0.55 | 0.20 | 0.50 | 0.12 |
| `muted-green-blue-purple-transparent` | 0.25 | 0.55 | 0.20 | 0.70 | 0.12 |
| `blue-yellow` | 1.00 | 0.55 | 0.20 | 0.70 | 0.00 |
| `blue-yellow-transparent` | 0.40 | 0.55 | 0.20 | 0.60 | 0.00 |
| `blue-pink-purple-peach` | 1.00 | 0.55 | 0.20 | 0.70 | 0.00 |
| `blue-pink-purple-peach-transparent` | 0.40 | 0.55 | 0.20 | 0.60 | 0.00 |
| `muted-pastel-six` | 1.00 | 0.55 | 0.20 | 1.00 | 0.00 |
| `muted-balanced-six` | 1.00 | 0.55 | 0.20 | 1.00 | 0.00 |

Alpha is opacity: 1 is fully opaque. The base name does not promise fully opaque scatter. Distribution point darkening multiplies each RGB channel by 0.80 before applying alpha. Green-blue-purple paired points use a separate fixed 0.88 multiplier, making the scatter slightly deeper while retaining the same base slots. This transform applies to categorical points, continuous gradient stops and their guides; it does not modify fills, distribution points, or rainbow presets. Keep the base named mapping and save the effective point mapping separately, so rerendering never darkens twice. An explicit paired `point_darken: 0` requests the unchanged base RGB. Borders and statistical annotations follow the shared style guide independently of category colors. Legacy `point_alpha` metadata is retained for compatibility; renderers use the explicit mark-family fields above.

Radar defaults to the fixed `muted-green-blue-purple` slots, fully opaque outlines/icons and unchanged base RGB (`line_darken: 0`). New automatic rainbow maps retain their category-wide 0.40 outline darkening. Optional polygon fills retain base RGB and palette fill opacity. Save base/effective maps separately and preserve explicit and legacy map precedence in [the radar contract](radar-comparison.md). Decorative radial bands use independent fixed colors with opacity 0.28 and encode no observed thresholds.

## Fixed categorical slots

For ordinary categorical identities with no focal method, map sorted raw IDs (R radix order) to the first N fixed slots. When color encodes methods and the brief designates a focal method (`highlight` or radar `focus_models`), use the palette’s fixed `focal_model_mapping`: the focal hue differs from every automatic comparator hue family. With no explicit visual designation, the exact raw ID `Ours` receives the same visual treatment. Neither a best-mean annotation nor observed performance selects this focal color or establishes a statistical hypothesis. Sort comparator raw IDs independently of input row order, legend order, display labels and ranking, then use the designated comparator slots below. Preserve this mapping across orientations and related figures, including opaque/transparent variants. No categorical interpolation or arbitrary recoloring is allowed. An authorized complete named `color_values` map, including an existing saved map, takes precedence and is preserved exactly. More than one visual focal method or more comparators than the preset supports requires an explicit named map; do not reuse the focal hue for opponents or silently interpolate. For multiple metrics, record which variable color encodes: model-color mode uses method IDs and `color_values`, while shared-axis lines and optional dual-axis `combo_color_by: metric` use metric IDs and `combo_metric_colors`. One metric color remains fixed across every method; a palette name does not silently switch the encoded variable. For dual-axis metric-color mode with exactly one bar and one line in the blue-yellow family only, an omitted `combo_metric_colors` map selects existing light-blue slot 3 (`#B5D0E0`) for bars and yellow slot 2 (`#F5C258`) for the line/icons, according to their mark roles. This preserves the fixed RGB definitions and opacity. An explicit named metric map takes precedence; shared-axis and other palette modes retain their deterministic identity-based assignment. Save the selected role/identity policy with the metric encoding.

The reserved method slots are one-based indices into the unchanged RGB lists:

| Palette family | Focal slot and hue | Comparator slots |
| --- | --- | --- |
| `rainbow` and transparent variant | 10, rose | 1, 2, 3, 4, 6, 7, 9 |
| `muted-green-blue-purple` and transparent variant | 3, purple | 1, 2, 4, 5 (green/blue) |
| `blue-yellow` and transparent variant | 2, yellow | 1, 3, 5 (blue) |
| `blue-pink-purple-peach` and transparent variant | 4, peach | 1, 3, 5, 6 (blue/purple) |
| `muted-pastel-six` | 5, peach | 1, 3, 4, 6 |
| `muted-balanced-six` | 5, rose | 1, 2, 3, 4, 6 |

Resolved `palette_mapping` or `model_palette_mapping` records the assignment policy, focal identities, exact base colors and assigned slots. Keep this provenance with saved configurations. These focal rules apply only to colors encoding methods: metric-colored shared axes and dual axes retain their metric identities/mark roles, while numerical covariates retain their continuous gradients. Color choice never alters observations, ordering, tests or domain scaling.

Rainbow slots (both variants):

`#C3CEBC`, `#D7E8C8`, `#A0C2D1`, `#ADA8C6`, `#E2BBBD`, `#C8C3DD`, `#93A3BD`, `#DDC9DF`, `#BACBE2`, `#D3858D`.

Green-blue-purple slots (both variants):

`#2F8668`, `#3A7FAA`, `#8953A2`, `#8BC9A0`, `#87B8DC`, `#BE96D0`.

The first three slots emphasize distinct green, blue and purple hues; the final three are lighter counterparts. Continuous stops are `#B3DFBA`, `#67B89A`, `#448EBB`, `#626DB2`, `#633E90`, increasing the visible light-to-dark range. This is an explicitly requested revision of the green-blue-purple family; saved base maps remain reproducible and are not silently replaced.

Blue-yellow slots (both variants):

`#87AAC4`, `#F5C258`, `#B5D0E0`, `#FAE5B9`, `#6392AC`, `#F8D389`.

The reference-derived RGB values have been lightened by explicit user request. The first four slots are medium blue, medium yellow, light blue and light yellow: two stronger and two lighter tones for a four-method comparison. This changes RGB rather than opacity; `blue-yellow` fills remain fully opaque (1.00), while `blue-yellow-transparent` fills remain 0.40. Both variants share these revised slots and continuous stops `#6392AC`, `#87AAC4`, `#B5D0E0`, `#FAE5B9`, `#F8D389`, `#F5C258`. Saved named maps remain reproducible; adopt the revision in an old figure only when remapping is explicitly requested.

Blue-pink-purple-peach slots (both variants):

`#7E8AB9`, `#DEAFC3`, `#A396B9`, `#F6D1B9`, `#96A3D0`, `#BAADD0`.

The two reference-derived families started from approximate displayed colors sampled from flat key/interior color regions of supplied raster references after converting their embedded display color profiles to sRGB; blue-yellow includes the explicit lightening revision above. For shaded point regions, representative interior color clusters were used rather than antialiased boundaries. They do not recover original source HEX values. Continuous stop order is stored separately in `palettes.json`; these illustrative gradients are not claimed to be perceptually uniform. A numeric color axis must state the covariate and its limits.

The existing standalone six-slot presets are preserved at full fill/paired opacity with no paired RGB darkening.

Muted-pastel-six slots:

`#CED2D4`, `#E9D8C4`, `#D9EAC4`, `#E9BFDB`, `#FAC3A7`, `#A2D9C6`.

Muted-balanced-six slots:

`#75A8C7`, `#F5C17D`, `#CCE29C`, `#A996B1`, `#DD7F8D`, `#96D6C9`.

Both are approximate sRGB reference colors. They remain standalone presets; no transparent variant is implied. Their fixed swatches are retained in the separate palette reference directories; development generation records remain outside the skill.

Continuous covariates use the stored continuous gradient stops and the applicable fixed mark-family transform; intermediate values necessarily interpolate. For paired scatter, display the same effective gradient and opacity on its framed numeric color axis, outside by default (vertical/right with auto orientation), or in verified safe measured internal space on explicit auto/inside request. Interior ticks use exactly the minimum, arithmetic midpoint and maximum of the color limits; exterior keeps requested breaks. Keep the gradient clear, with short inward ticks from the label-side boundary at the displayed breaks instead of lines crossing the gradient. Anchor colors remain available for a single ungrouped mark and continuous/palette references.

## Preserve category identity across figures

The same category set and visual focal designation receive the same automatic mapping across metrics, orientations and plot families, even if rankings or row order change. Palette variants share the same RGB slots. A palette name alone cannot reserve a particular color for an arbitrary scientific identity forever: adding/removing/renaming categories can change a comparator’s sorted slot. The same designated focal method retains the preset’s reserved focal slot. For a related figure family, reuse its saved named map, including absent categories; append new categories to unused slots without reassigning existing entries. Store project-specific maps with external figure configurations, never in this generic skill. If no family map is available, use deterministic mapping and disclose that it is newly assigned. Do not claim persistent cross-project identity mapping.

Changing a palette name applies that palette's alpha defaults when opacity fields are null or omitted. Existing explicit values are preserved for reproducibility; clear them only when the user requests the preset. Existing exports are not regenerated by this update.
