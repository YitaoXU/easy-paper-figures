#!/usr/bin/env python3
"""Materialize fixed palette families into the compatible runtime and catalog."""
import argparse
import copy
import json
import re
from pathlib import Path


def materialize(registry):
    if registry.get("schema_version") != 1:
        raise ValueError("Unsupported palette-family schema")
    result, family_ids = {}, set()
    for family in registry["families"]:
        if family["id"] in family_ids or family["tier"] not in {"common", "extended"}:
            raise ValueError("Duplicate family or invalid tier")
        family_ids.add(family["id"])
        names = []
        for variant in family["variants"]:
            name = variant["name"]
            if name in result:
                raise ValueError(f"Duplicate preset: {name}")
            palette = copy.deepcopy(family["base"])
            for key in variant.get("remove_fields", []):
                palette.pop(key, None)
            palette.update(copy.deepcopy(variant.get("overrides", {})))
            for key in ("categorical", "continuous", "anchors"):
                colors = palette[key]
                if not colors or any(not re.fullmatch(r"#[0-9A-Fa-f]{6}", c) for c in colors):
                    raise ValueError(f"Invalid fixed colors: {name}/{key}")
            if len(set(palette["categorical"])) != len(palette["categorical"]):
                raise ValueError(f"Repeated categorical slots: {name}")
            for key, value in palette.items():
                if key.endswith(("_alpha", "_darken", "_lighten")):
                    if not isinstance(value, (int, float)) or not 0 <= value <= 1:
                        raise ValueError(f"Invalid mark profile: {name}/{key}")
            for colors_key, order_key in (("categorical", "ordered_slots"), ("group_categorical", "group_ordered_slots")):
                if colors_key in palette:
                    order = palette.get(order_key)
                    if not isinstance(order, list) or any(type(x) is not int for x in order) or sorted(order) != list(range(1, len(palette[colors_key]) + 1)):
                        raise ValueError(f"Invalid complete color order: {name}/{order_key}")
            roles = palette["focal_model_mapping"]
            slots = roles["focal_slots"] + roles["comparator_slots"]
            if len(set(slots)) != len(slots) or any(not 1 <= x <= len(palette["categorical"]) for x in slots):
                raise ValueError(f"Invalid focal/comparator slots: {name}")
            small = roles.get("small_set_comparator_slots")
            if small is not None and (not small or any(type(x) is not int for x in small)
                    or len(set(small)) != len(small) or set(small) & set(roles["focal_slots"])
                    or any(not 1 <= x <= len(palette["categorical"]) for x in small)):
                raise ValueError(f"Invalid small-set comparator slots: {name}")
            result[name] = palette
            names.append(name)
        if family["recommended_preset"] not in names:
            raise ValueError("Recommended preset is not a family variant")
    order = registry["preset_order"]
    if len(order) != len(set(order)) or set(order) != set(result):
        raise ValueError("Preset order must cover every fixed name exactly once")
    return {name: result[name] for name in order}


def catalog(registry, palettes):
    lines = [
        "# Palette families", "",
        "Start with the six common families below. Choose a variant for opacity, brightness, hue companion or method capacity; the variant name is the configuration's `palette` value.", "",
        "The canonical source is `palettes/palette-families.json`. Run `python3 scripts/build_palette_catalog.py` after editing it. `palettes/palettes.json` is the generated, flat runtime index used by every renderer; all legacy names retain their exact RGB slots, mark opacity/transforms and focal/comparator capacity.", "",
        "## Common families", "",
        "| Family | Recommended `palette` | Variants | Fixed slots / methods with one focal |",
        "| --- | --- | --- | --- |",
    ]
    for tier in ("common", "extended"):
        if tier == "extended":
            lines += ["", "## Extended families", "", "These remain available for existing figure families and specific hue requirements.", "",
                      "| Family | Recommended `palette` | Variants | Fixed slots / methods with one focal |", "| --- | --- | --- | --- |"]
        for family in registry["families"]:
            if family["tier"] != tier:
                continue
            variants = "; ".join(f"`{v['name']}` ({v['label']})" for v in family["variants"])
            capacities = []
            for variant in family["variants"]:
                palette = palettes[variant["name"]]
                roles = palette["focal_model_mapping"]
                capacity = len(roles["focal_slots"]) + len(roles["comparator_slots"])
                capacities.append(f"{len(palette['categorical'])} / {capacity}")
            lines.append(f"| {family['title']} | `{family['recommended_preset']}` | {variants} | {'; '.join(capacities)} |")
    lines += [
        "",
        "## Consolidation rules", "",
        "- Exact RGB duplicates share a family base. Opacity-only variants retain their own mark profiles.",
        "- Lighter RGB and hue-companion variants are grouped for discovery, with every distinct fixed color retained.",
        "- Balanced six/twelve names share the same stored RGB list but have different focal/comparator capacities; those policies remain separate variants.",
        "- Near-looking colors are not exact aliases. A family grouping does not remap saved categories or quantize colors.",
        "- Existing renderer-specific defaults and named color overrides remain authoritative. Illustrative continuous stops are not perceptually uniform.",
        "", "[Fixed palette contract](palette-contract.md)", "",
    ]
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Validate generated files without writing")
    args = parser.parse_args()
    skill = Path(__file__).resolve().parent.parent
    registry = json.loads((skill / "palettes/palette-families.json").read_text())
    palettes = materialize(registry)
    outputs = {
        skill / "palettes/palettes.json": json.dumps(palettes, indent=2) + "\n",
        skill / "references/palette-catalog.md": catalog(registry, palettes),
    }
    for path, content in outputs.items():
        if args.check:
            if not path.exists() or path.read_text() != content:
                raise SystemExit(f"Stale generated palette file: {path.name}")
        else:
            path.write_text(content)
    print(f"{'Checked' if args.check else 'Built'} {len(palettes)} presets in {len(registry['families'])} families.")


if __name__ == "__main__":
    main()
