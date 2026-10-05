# Fixed palette contract

A palette name selects fixed RGB colors and fixed opacity parameters for each mark family. The source of truth is `palettes/palettes.json`. Do not invent colors, resample categorical colors, or change saturation, opacity or darkening during automatic visual refinement. Adjust size, jitter, spacing or layout instead. A user-requested color change overrides the preset for that figure; record it as a custom override. Existing figure configurations retain their saved overrides.

| Palette | Fill alpha | Distribution point alpha | Distribution RGB darkening | Paired point alpha | Paired RGB darkening | Paired RGB lightening |
| --- | --- | --- | --- | --- | --- | --- |
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

For ordinary categorical identities with no focal method, map sorted raw IDs (R radix order) to the first N fixed slots. When color encodes methods and the brief designates a focal method (`highlight` or radar `focus_models`), use the palette’s fixed `focal_model_mapping`: the focal hue differs from every automatic comparator hue family. With no explicit visual designation, the exact raw ID `Ours` receives the same visual treatment. Neither a best-mean annotation nor observed performance selects this focal color or establishes a statistical hypothesis. Sort comparator raw IDs independently of input row order, legend order, display labels and ranking, then use the designated comparator slots below. Preserve this mapping across orientations and related figures, including opaque/transparent variants. No categorical interpolation or arbitrary recoloring is allowed. An authorized complete named `color_values` map, including an existing saved map, takes precedence and is preserved exactly. More than one visual focal method or more comparators than the preset supports requires an explicit named map; do not reuse the focal hue for opponents or silently interpolate. For multiple metrics, record which variable color encodes: model-color mode uses method IDs and `color_values`, while shared-axis lines and optional dual-axis `combo_color_by: metric` use metric IDs and `combo_metric_colors`. One metric color remains fixed across every method; a palette name does not silently switch the encoded variable. For dual-axis metric-color mode with exactly one bar and one line in the blue-yellow family only, an omitted `combo_metric_colors` map selects existing light-blue slot 3 (`#B5D0E0`) for bars and yellow slot 2 (`#F5C258`) for the line/icons, according to their mark roles. This preserves the fixed RGB definitions and opacity. An explicit named metric map takes precedence; shared-axis and other palette modes retain their deterministic identity-based assignment. Save the selected role/identity policy with the metric encoding.

The reserved method slots are one-based indices into the unchanged RGB lists:

| Palette family | Focal slot and hue | Comparator slots |
| --- | --- | --- |
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

`muted-balanced-twelve` is a fixed design extension for larger group guides. Its first six categorical slots preserve `muted-balanced-six`; additional slots are `#486F8A`, `#BA8955`, `#80944F`, `#6B577F`, `#A14D64`, `#397C72`. All twelve colors are fixed, with no categorical interpolation or recycling. Its continuous anchors remain those of the six-slot preset. See the [grouped circular contract](grouped-circular-heatmap.md) for coordinated palette defaults and explicit group overrides.

`muted-green-blue-purple-light` keeps a softer fixed range for circular heatmaps. Method categorical slots: `#78B695`, `#7DA6C5`, `#9A81BA`, `#B9DFC1`, `#B5CEDE`, `#C9B4DC`. Continuous stops: `#C4E6CB`, `#A1D6C1`, `#8DBCD8`, `#AAAED5`, `#AB91C4`. For grouped circular heatmaps, its separate fixed twelve-slot `group_categorical` list in `palettes/palettes.json` supplies soft green, blue and purple group bands and guide icons; those group slots never interpolate or recycle and do not alter method/focal assignments. Group mapping uses sorted raw group identities unless an established named map is supplied. This standalone preset changes RGB brightness while retaining the base family opacity and focal-slot policy; the existing darker presets and saved maps remain available.

For grouped circular heatmaps, `blue-yellow` also supplies a separate twelve-slot fixed `group_categorical` list in `palettes/palettes.json`. These coordinated blue/yellow group bands and guide icons preserve the preset’s existing method slots, continuous anchors, focal mapping and opacity. The group list never interpolates or recycles.

## Yellow-green categorical alternatives

`yellow-green` uses fixed slots `#D5B14A`, `#6E9D72`, `#E9CE7A`, `#A5C39B`, `#A9872E`, `#3F7661`: medium gold/green, light gold/green and deep gold/green. `yellow-green-red` uses `#D6B14C`, `#639B77`, `#C97070`, `#E9D58C`, `#ACC9A5`, `#DDA5A1`: three medium hues followed by their lighter counterparts. Both presets use paired opacity 0.70 without RGB darkening or lightening. These six-slot alternatives are categorical design palettes, not a ranking, significance or ordered scientific scale. Sort ordinary category identities using the fixed mapping rule above; keep the resulting map with related figures. Their continuous stops are explicitly stored separately and are not claimed to be perceptually uniform.


## Soft blue-green alternatives and reference coordination

`blue-green-yellow` stores medium blue/green/yellow slots `#7BAAC2`, `#83B59E`, `#D8BA69`, followed by `#B2CDD9`, `#B8D0B1`, `#E5D69C`. `blue-green-coral` stores medium blue/green/coral slots `#7DAAC2`, `#81B79D`, `#D8998E`, followed by `#B7CAD7`, `#B7D1B8`, `#E7BBB1`. Both use paired opacity 0.70 and unchanged base RGB.

`muted-reference-six` coordinates blue, green, lavender, warm yellow, rose and turquoise: `#8EABC0`, `#94B5A1`, `#AD9AB7`, `#D9BF7C`, `#CC99A4`, `#91BCB4`. Its medium-light range visually matches a supplied scientific multi-panel reference without claiming to recover original source colors. Its paired opacity is 0.70, with no darkening or lightening. The existing `rainbow`, `muted-balanced-six` and `blue-pink-purple-peach` presets remain separate available alternatives; select them rather than creating redundant approximate variants.

The new six-slot palettes use fixed categorical assignments and the same stored stops for illustrative continuous gradients; those gradients are not perceptually uniform. An explicit user request to give a dominant category a moderate tone may be represented by a project-specific named map using the selected fixed colors. Keep that map with the figure family, record its reason, and preserve it across metrics. Do not embed actual scientific identities in the reusable palette or infer a special color from observed scores. Dense groups should retain a visible medium tone at the requested opacity; inspect both isolated marks and overlapping marks before accepting a requested adjustment.


## Warm yellow and leaf-green coordination

`warm-yellow-leaf-crisper` uses six fixed medium-tone categorical slots: `#D18A05`, `#E0B338`, `#228A76`, `#E98452`, `#399F5C`, `#8BA735` (golden orange, yellow, teal, apricot orange, leaf green and yellow green). Paired points use opacity 0.70 with no RGB darkening or lightening; fill opacity is 0.40, while distribution points retain opacity 0.55 and RGB darkening 0.20. The two orange slots differ in hue and lightness, and the two green slots separate leaf green from yellow green, including at the fixed paired opacity. These are design colors selected for a warm scientific figure family, not recovered original source values or an ordered scientific scale. Existing saved named maps remain unchanged unless the user requests adoption.

Its separate light anchors are `#FFBC78`, `#FFEC9E`, `#B5E0BA` (orange, yellow and leaf green). The continuous ramp uses ten fixed light colors, from orange through yellow to green: `#FFBC78`, `#FFC680`, `#FFD089`, `#FFDC91`, `#FFE799`, `#FCEE9E`, `#EBECA7`, `#D9E7AD`, `#C5E4B2`, `#B5E0BA`. Read the exact slots from `palettes.json`; these are design colors, not a perceptually uniform quantitative scale. The ramp may also supply an explicitly requested ordered categorical named map, with a recorded order/direction, without creating another orange-yellow-green preset. Do not infer score ordering or replace the automatic unordered model policy. Keep saved maps stable across related metrics. Opaque inside-bar fills require an explicit `fill_alpha: 1`; other mark roles retain the preset opacity contract.

The medium categorical and light ramp colors serve different mark roles within this one family. Automatic unordered model colors continue reserving teal slot 3 for the designated focal identity and warm slots 1, 2 and 4 for comparators. The other green slots remain available for ordinary categorical covariates and explicit named maps, but are excluded from automatic comparator assignments so they do not share the focal hue family.
