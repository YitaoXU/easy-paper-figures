# Repository Agent Instructions

These instructions apply to development of all reusable plotting skills in this repository. Use this workflow for skill iterations as defined below, including changes to skill instructions or documentation, default appearance, input handling, rendering code, palettes, and existing or new categories. Each skill iteration must complete a fresh independent plotting run before it is reported as finished. An ordinary new-data figure or a dataset-specific adjustment is not a skill iteration unless the reusable skill is changed.

## Scope of an iteration

A skill iteration changes the reusable plotting skill or its execution-facing documentation, including skill instructions, user plotting prompts, rendering code, defaults, input handling, scientific calculations or supported encodings. Apply the independent plotting workflow to these changes.

Repository-level presentation changes—such as editing the root README introduction, navigation, selecting or arranging already accepted previews, correcting links or changing preview display dimensions—require documentation and presentation checks only. Verify links, English/Chinese consistency, image sizing and accurate descriptions. Edits solely to repository maintenance policy, including this AGENTS.md, require documentation consistency checks rather than plotting validation when they do not change plotting behavior or execution-facing skill instructions.

These repository-level changes trigger independent plotting validation only when they also revise a plotting prompt, change plotting behavior, introduce a new or modified figure, or make a new claim about the skill’s scientific or rendering capabilities. Choose coverage based on the actual change, rather than the filename or the presence of figure images.

## Choose coverage

Test the behavior and layouts affected by the revision. A documentation-only skill iteration still needs at least one representative figure generated from raw data; repository-level changes covered by the scope exception above do not. Changes shared across categories need representative coverage of every affected rendering path; rebuild all documented previews when the change or acceptance claim concerns the full gallery. Do not rerender unrelated real project figures without authorization.

## Run a clean agent

1. Finish the updated skill and applicable checks, then freeze the version to be tested. Use a new subagent without inherited conversation history (`fork_turns: none` when supported), rather than reusing a developer or a previous evaluator.
2. Provide only the updated skill, representative raw input or fixed palette definitions, a user-style scientific/visual brief and an isolated output destination. Establish the metric, sampling unit, pairing, improvement direction and requested encodings. An original user reference may be supplied when it defines the requested appearance.
3. Do not provide previous generated figures, finished configurations, processed answers, expected statistics, implementation hints or hidden cosmetic parameters. The agent may read the routed contracts, canonical schemas and reusable scripts, but must not inspect gallery preview images, developer conversations or historical run artifacts. A runtime-only skill snapshot can enforce this separation; it retains the entry point, relevant references/contracts, scripts and palettes, without prior preview images or run outputs.
4. Let the agent inspect raw inputs, create its own minimal request, render with the skill defaults, inspect and refine only when actual input requires it. It must preserve scientific values and record any adaptation or refinement. Use the committed fixed synthetic CSV fixtures and the published user-style prompt for repeatable acceptance. Do not ask the evaluator to generate data. Additional fixed fixtures may be added when checking a new input shape; keep their provenance in `.private`.

## Preserve evidence and review

Keep one folder per tested figure outside the distributable skill. Retain:

- The exact prompt sent to the agent and the raw input or an unchanged source snapshot with provenance.
- The agent-created minimal request and the final resolved configuration.
- The actual effect image, full applicable exports, scientific records, plotted data and session record.
- The inspection/test report, including required encodings, numerical consistency, actual Arial, printed dimensions, ticks, legend/annotation fit and any refinements or limitations.
- A reproduction command or script and saved-configuration replay evidence for scientific figures.

Inspect actual images and relevant calculations yourself; a successful tool exit or agent summary alone is insufficient. Review the changed behavior against the scientific brief without prescribing the answer to the evaluator. Record the tested skill version or resource hashes so the prompt and image remain attributable to that iteration.

Repair observed failures in reusable instructions/defaults/code, then run another fresh independent pass from the same unmodified brief when verifying the repair. Preserve earlier evidence; do not conceal the issue with extra per-test cosmetic parameters. Do not report the iteration as complete until a reviewed export passes. If delegation is unavailable, explicitly report the required independent check as incomplete.

After a passing run, update affected public previews, prompt links and verification metadata when their content changed. Keep public examples generic and synthetic; full run records and machine-specific paths stay outside the distributable skill. Synchronize the English and Chinese user guides and any installed copy maintained by the current task. Keep this maintenance policy in this repository-level AGENTS.md rather than duplicating it in distributable skill instructions or user guides. A documentation-only skill iteration does not require replacing already unchanged preview images.

## Development and publication boundaries

Keep all development scripts, historical runs, complete test outputs, frozen runtime snapshots and machine records in the Git-ignored `.private/` folder. Use one dedicated figure folder per independent run and preserve failed passes. Public `examples/<figure-id>/` folders contain the usable Prompt, an optional minimal schema request and accepted preview; shared fixed synthetic inputs live in `examples/data/`. Fixtures deliberately include a strong fictional `Ours` and weaker methods; this does not authorize ranking or changing real user data. All vertical method comparisons place the focal method on the left and horizontal comparisons at the bottom unless an explicit scientific order is supplied. Keep compact hashes/status metadata in `.private/verification.json` after actual image and numerical review; do not publish verification records or test metadata. README previews use consistent display dimensions within each row and preserve original aspect ratios. Fixed palette references can use larger display widths for legibility.
