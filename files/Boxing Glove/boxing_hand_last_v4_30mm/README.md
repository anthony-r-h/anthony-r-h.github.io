## Final methodology

We built a **measurement-driven right-hand and forearm fitting last** for boxing-glove pattern development in CLO3D.

### Inputs

The geometry is constrained by the supplied measurements:

- wrist to middle fingertip
- palm length
- knuckle circumference
- wrist circumference
- individual finger lengths
- thumb length
- forearm circumference
- forearm length

Where only circumference was available, the section was represented as an ellipse with a plausible width-to-depth ratio, then sized to reproduce the measured circumference.

### Anatomical scaffold

The hand is modeled from a simplified articulated structure rather than a scanned or statistical hand model.

It includes:

- tapered forearm
- wrist transition
- multi-section palm envelope
- curved MCP/knuckle line
- three phalange segments per finger
- separate thumb chain
- thenar and hypothenar volumes

Finger segment lengths use generic adult anatomical proportions while preserving the measured total finger lengths.

### Pose

The hand is posed around a virtual **30 mm diameter grip bar**.

The pose is intentionally a little looser than a fully clenched fist because the purpose is pattern development and fitting volume.

Approximate finger flexion:

- MCP: 58°
- PIP: 70°
- DIP: 36°

The thumb is opposed toward the fingers but remains slightly separated so the glove thumb can be patterned independently.

### Surface construction

The anatomical components are built as overlapping volumetric forms, then converted into one continuous surface using:

1. voxelized volume construction
2. signed-distance-field smoothing
3. marching-cubes surface extraction
4. light Taubin smoothing

This produces a single smooth, watertight mesh suitable for CLO3D collision and draping.

The model is intentionally a **fitting last**, not a detailed anatomical model. Fine features such as tendons, skin folds, bone prominences, and exact soft-tissue distribution are omitted because they are not useful for the patterning task.

## Other options considered

| Approach | Strength | Limitation |
|---|---|---|
| **Simple geometric hand** | Very easy to parameterize | Anatomy becomes visibly crude |
| **Current procedural anatomical last** | Measurement-driven, editable, lightweight, adequate for patterning | Not individually anatomically exact |
| **MakeHuman / rigged base mesh** | Better native anatomy and topology | More work to fit precisely to hand measurements |
| **MANO** | Strong anatomical/statistical basis, poseable | Considerably more complexity than required here |
| **3D scan of the actual hand** | Best individual geometry | Requires scanning and still needs pose manipulation |
| **Photogrammetry / phone scan** | Accessible way to capture individual shape | Difficult to capture fingers and thumb cleanly in the required pose |

For this use case, the procedural anatomical last is the practical middle ground: **more anatomically credible than primitives, much simpler than MANO, and directly controlled by the measurements relevant to glove fit.**
