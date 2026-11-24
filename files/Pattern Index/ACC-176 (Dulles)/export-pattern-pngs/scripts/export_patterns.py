"""Render the existing Pat block selection from a disposable DWG conversion."""
import argparse
import hashlib
from pathlib import Path
import shutil
import subprocess
import tempfile

import ezdxf
from ezdxf import bbox
from ezdxf.addons.drawing import Frontend, RenderContext
from ezdxf.addons.drawing.config import Configuration, BackgroundPolicy
from ezdxf.addons.drawing.matplotlib import MatplotlibBackend
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
BACKGROUND = "#050015"
WIDTH, HEIGHT, DPI = 1080, 1350, 100


class PatternFrontend(Frontend):
    def override_properties(self, entity, properties):
        color = properties.color[:7]
        r, g, b = (int(color[i:i + 2], 16) for i in (1, 3, 5))
        pink = r > 100 and b > 100 and g < min(r, b) * 0.6
        # CAD screenshots use nominal one-pixel strokes; matplotlib uses points.
        properties.lineweight = (3 if pink else 1) * 72 / DPI
        if pink:
            properties.color = "#ffffff"


def render(dxf, output, names):
    doc = ezdxf.readfile(dxf)
    inserts = {}
    for entity in doc.modelspace().query("INSERT"):
        inserts.setdefault(entity.dxf.name, []).append(entity)
    for name in names:
        if len(inserts.get(name, [])) != 1:
            raise ValueError(f"Expected exactly one model-space insert for {name}")
    output.mkdir(parents=True, exist_ok=True)
    config = Configuration(background_policy=BackgroundPolicy.CUSTOM,
                           custom_bg_color=BACKGROUND, min_lineweight=0,
                           lineweight_scaling=1)
    for name in names:
        entity = inserts[name][0]
        bounds = bbox.extents([entity])
        if not bounds.has_data:
            raise ValueError(f"No geometry for {name}")
        cx, cy = bounds.center.x, bounds.center.y
        scale = max(bounds.size.x / (WIDTH * 0.85),
                    bounds.size.y / (HEIGHT * 0.85))
        fig = plt.figure(figsize=(WIDTH / DPI, HEIGHT / DPI), dpi=DPI,
                         facecolor=BACKGROUND)
        ax = fig.add_axes([0, 0, 1, 1])
        ax.set_axis_off()
        ctx = RenderContext(doc)
        ctx.set_current_layout(doc.modelspace())
        backend = MatplotlibBackend(ax)
        frontend = PatternFrontend(ctx, backend, config=config)
        frontend.draw_entities([entity])
        backend.finalize()
        fig.set_size_inches(WIDTH / DPI, HEIGHT / DPI)
        ax.set_xlim(cx - WIDTH * scale / 2, cx + WIDTH * scale / 2)
        ax.set_ylim(cy - HEIGHT * scale / 2, cy + HEIGHT * scale / 2)
        ax.set_aspect("equal", adjustable="box")
        target = output / f"{name}.png"
        fig.savefig(target, dpi=DPI, facecolor=BACKGROUND)
        plt.close(fig)
        with Image.open(target) as image:
            if image.size != (WIDTH, HEIGHT):
                raise ValueError(f"Incorrect dimensions: {target}")
            image.convert("RGB").save(target)
        print(target.name, flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=ROOT / "Redraw.dwg")
    parser.add_argument("--output", type=Path, default=ROOT / "Pat")
    parser.add_argument("--dxf", type=Path, help="Use an already converted local DXF")
    parser.add_argument("--blocks", nargs="+", help="Default: existing Pat PNG names")
    parser.add_argument("--converter", type=Path, default=Path(
        "C:/Program Files/Autodesk/AutoCAD 2022/accoreconsole.exe"))
    args = parser.parse_args()
    names = args.blocks or sorted(p.stem for p in (ROOT / "Pat").glob("*.png"))
    if not names or any(Path(n).name != n or "/" in n or "\\" in n for n in names):
        raise ValueError("Block names must be nonempty, plain filenames")
    before = hashlib.sha256(args.source.read_bytes()).hexdigest()
    with tempfile.TemporaryDirectory(prefix="dulles-render-") as directory:
        scratch = Path(directory)
        dxf = args.dxf
        if dxf is None:
            copy = scratch / "source.dwg"
            shutil.copy2(args.source, copy)
            dxf = scratch / "source.dxf"
            script = scratch / "export.scr"
            script.write_text('(setvar "FILEDIA" 0)\n'
                f'(command "_.DXFOUT" "{dxf.as_posix()}" "_V" "2013" "16")\n'
                '_.QUIT\n_Y\n', encoding="ascii")
            result = subprocess.run([str(args.converter), "/i", str(copy),
                "/s", str(script)], cwd=scratch, capture_output=True, timeout=180)
            if result.returncode or not dxf.is_file():
                raise RuntimeError(result.stdout.decode("utf-16-le", errors="replace"))
        # Stage the complete batch before replacing any published PNGs.
        staged = scratch / "png"
        render(dxf, staged, names)
        if hashlib.sha256(args.source.read_bytes()).hexdigest() != before:
            raise RuntimeError("Source DWG changed during export")
        args.output.mkdir(parents=True, exist_ok=True)
        for name in names:
            shutil.copy2(staged / f"{name}.png", args.output / f"{name}.png")
    print(f"Validated {len(names)} PNGs at {WIDTH}x{HEIGHT}; source DWG unchanged.")


if __name__ == "__main__":
    main()
