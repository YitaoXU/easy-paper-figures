# Palette families

Start with the six common families below. Choose a variant for opacity, brightness, hue companion or method capacity; the variant name is the configuration's `palette` value.

The canonical source is `palettes/palette-families.json`. Run `python3 scripts/build_palette_catalog.py` after editing it. `palettes/palettes.json` is the generated, flat runtime index used by every renderer; all legacy names retain their exact RGB slots, mark opacity/transforms and focal/comparator capacity.

## Common families

| Family | Recommended `palette` | Variants | Fixed slots / methods with one focal |
| --- | --- | --- | --- |
| Pastel four-color | `pastel-green-blue-purple-peach` | `pastel-green-blue-purple-peach` (Soft four-color) | 4 / 4 |
| Green / blue / purple | `muted-green-blue-purple` | `muted-green-blue-purple` (Classic); `muted-green-blue-purple-transparent` (Softer opacity); `muted-green-blue-purple-light` (Lighter RGB) | 6 / 5; 6 / 5; 6 / 5 |
| Muted rainbow | `rainbow-transparent` | `rainbow` (Opaque fill); `rainbow-transparent` (Soft fill) | 10 / 8; 10 / 8 |
| Blue / yellow | `blue-yellow-transparent` | `blue-yellow` (Opaque fill); `blue-yellow-transparent` (Soft fill) | 6 / 4; 6 / 4 |
| Blue / pink / purple / peach | `blue-pink-purple-peach-transparent` | `blue-pink-purple-peach` (Opaque fill); `blue-pink-purple-peach-transparent` (Soft fill) | 6 / 5; 6 / 5 |
| Balanced multicolor | `muted-balanced-twelve` | `muted-balanced-six` (Six-method focal capacity); `muted-balanced-twelve` (Twelve categorical slots) | 12 / 6; 12 / 11 |

## Extended families

These remain available for existing figure families and specific hue requirements.

| Family | Recommended `palette` | Variants | Fixed slots / methods with one focal |
| --- | --- | --- | --- |
| Pastel six-color | `muted-pastel-six` | `muted-pastel-six` (Opaque pastel) | 6 / 5 |
| Reference six-color | `muted-reference-six` | `muted-reference-six` (Soft six-color) | 6 / 6 |
| Blue / green companions | `blue-green-yellow` | `blue-green-yellow` (Yellow companion); `blue-green-coral` (Coral companion) | 6 / 5; 6 / 5 |
| Yellow / green companions | `yellow-green` | `yellow-green` (Two hue families); `yellow-green-red` (Red companion) | 6 / 4; 6 / 5 |
| Warm yellow / leaf green | `warm-yellow-leaf-crisper` | `warm-yellow-leaf-crisper` (Medium categorical / light ramp) | 6 / 4 |

## Pastel four-color preset

`pastel-green-blue-purple-peach` preserves four fixed slots: pale green `#D9EAC4`, pale blue `#B5D0E0`, muted purple `#A396B9`, peach `#F6D1B9`. Distribution fills use opacity 0.40; raw distribution points use opacity 0.55 and RGB darkening 0.20. Paired points use opacity 0.60 with no RGB darkening. One focal method reserves peach; up to three comparators use green, blue and purple, independently of observed performance. Ordinary categories use the fixed ordered slots. Larger automatic method comparisons require a family with sufficient focal/comparator capacity or an authorized named map.

## Consolidation rules

- Exact RGB duplicates share a family base. Opacity-only variants retain their own mark profiles.
- Lighter RGB and hue-companion variants are grouped for discovery, with every distinct fixed color retained.
- Balanced six/twelve names share the same stored RGB list but have different focal/comparator capacities; those policies remain separate variants.
- Near-looking colors are not exact aliases. A family grouping does not remap saved categories or quantize colors.
- Existing renderer-specific defaults and named color overrides remain authoritative. Illustrative continuous stops are not perceptually uniform.

[Fixed palette contract](palette-contract.md)
