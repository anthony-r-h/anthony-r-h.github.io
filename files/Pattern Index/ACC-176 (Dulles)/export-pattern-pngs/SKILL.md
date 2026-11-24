---
name: export-pattern-pngs
description: Regenerate Dulles CAD pattern block PNGs from Redraw.dwg, retaining block filenames and 1080x1350 framing while rendering pink lines white at triple width.
---

# Export pattern PNGs

Use `scripts/export_patterns.py` for the Dulles pattern images. Paths default to this skill's parent directory: `Redraw.dwg` is the source and `Pat/` is the destination. The current selection is the 23 existing PNG basenames, each matching one model-space block insert. Do not export helper, stitch, or marker blocks separately.

## Render

The script requires Python, ezdxf 1.4.5, matplotlib 3.11.2, Pillow 13.0.0, and the installed AutoCAD Core Console. Keep Python dependencies in a temporary environment if they are unavailable; do not add them to the website's dependencies. The default converter is `C:/Program Files/Autodesk/AutoCAD 2022/accoreconsole.exe`; override with `--converter` if necessary.

Run from any working directory:

```powershell
python "<skill-directory>/scripts/export_patterns.py"
```

The converter needs access to the user's AutoCAD profile. A sandboxed run may fail with `Problem with setting up current profile`; use the execution tool's normal approval mechanism to retry with profile access. Do not modify the profile or source drawing to work around this.

The script converts a temporary DWG copy to DXF outside the repository, renders and validates the entire batch, then replaces the selected PNGs. It verifies the source DWG hash is unchanged. Never publish intermediate DXF/SVG/PDF vector exports. Use the latest saved drawing; unsaved application edits are not included.

Optional arguments:

- `--output <directory>`: stage a preview outside `Pat`.
- `--blocks BOT-01 FP-01 HND-01`: render only named blocks, or explicitly include a newly requested block.
- `--source <drawing.dwg>`: select another source.
- `--dxf <temporary-source.dxf>`: reuse a verified conversion of the current saved DWG while iterating. Omit for the final end-to-end run.

## Rendering contract

- PNG only, exactly 1080 x 1350 pixels, filename equal to the block name.
- Original dark background `#050015`, centered geometry, 85% maximum canvas occupancy, original orientation and aspect ratio.
- Resolved pink/magenta strokes become white, including inherited block/layer colors. Nominal screenshot stroke width changes from 1 to 3 pixels. This is an output styling change, not a DWG edit.
- Keep other line colors, labels, hatch patterns, stitching, and layer visibility. The rasterizer uses available fonts, so typography can differ from the CAD application's font substitution.

## Verify

Check the script's dimension/count/hash validation. Inspect representative broad, narrow, curved, and hatched blocks at full size, plus a contact sheet of the batch for clipping or missing content. Confirm no pink strokes remain and the filenames still match the intended block set. Inspect the git diff for unintended artifacts; keep temporary conversions and previews outside the repository. Do not modify unrelated user edits.
