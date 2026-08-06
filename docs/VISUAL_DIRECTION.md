# Retro Crawler Visual Direction

## Intent

Retro Crawler uses an original 16-bit-inspired science-fantasy style. The goal is the clarity, color discipline, expressive silhouettes, and sense of discovery associated with great console RPGs, paired with modern lighting, interface usability, and restrained animation. Assets must not reproduce identifiable characters, maps, logos, or compositions from existing games.

## Technical contract

- Design resolution: **640 x 360**.
- Display scaling: integer viewport scaling; never rely on fractional pixel scaling.
- Exploration grid: **8 x 8 pixels**.
- Texture filtering: nearest-neighbor for pixel artwork.
- Character footprint: readable within roughly **24 x 32 pixels** on the exploration canvas.
- Collision and interaction remain independent from decorative artwork.
- Critical text and controls must fit the design viewport without clipping.

## Palette hierarchy

The shared foundation is near-black navy (`#070B0E`), panel slate (`#12151B`), steel (`#3E4E60`), and cool text (`#BAC7D5`). Color communicates function:

- Cyan (`#7DD3FC`): navigation, focus, player-facing systems.
- Green (`#86EFAC`): safe actions, confirmation, available interactions.
- Amber (`#FCD34D`): caution, resources, optional opportunities.
- Rose (`#FB7185`): hostiles, damage, blocked routes, failure.
- Violet (`#C084FC`): unstable technology and arc anomalies.
- Orange (`#FB923C`): boss phases and emergency machinery.

Each generated region may introduce one environmental accent, but must preserve the functional colors above.

## Layer contract

1. Backdrop and distant environment.
2. Walkable floor, walls, and scenery.
3. Ground indicators, shadows, and interaction zones.
4. Characters, enemies, and immediate effects.
5. Exploration interface.
6. End-state surfaces.
7. Modal menus and announcements.
8. Full-screen transitions.

World sprites must never draw over modal or end-state surfaces.

## Environment rules

- Exploration environments occupy the primary viewport. Do not present the playable world as a complete room graph compressed into one screen.
- A logical expedition sector is at least one full exploration screen and may span several camera screens.
- Use a following camera inside a sector. The contract graph belongs in a separate map/minimap layer, not as the physical scale of play.
- Keep the exploration HUD to a slim status/prompt layer so scenery, actors, and landmarks dominate the screen.
- Every room needs a readable silhouette and at least one identifying landmark.
- Every sector needs authored composition: boundaries, paths, elevation or wall masses, large props, small dressing, interaction sockets, actor sockets, and deliberate negative space.
- Use large value groupings before small texture details.
- Animated ambience should be subtle and must not obscure routes or interaction markers.
- Current rooms receive the strongest outline and atmospheric accent.
- Optional routes use visual curiosity rather than stronger brightness than the critical route.
- Environmental storytelling should communicate purpose, damage, occupation, or change.

### Generated environment composition

Generation operates at multiple levels:

1. The seeded expedition graph selects sector roles and connectivity.
2. Each role selects an authored, theme-compatible full-screen or multi-screen sector template.
3. Portal sockets connect templates without changing the validated graph.
4. A deterministic dressing pass selects landmarks, props, decals, hazards, discoveries, resources, and ambient effects from authored sockets.
5. Event-driven transformations alter controlled template layers on revisits.

Random noise is not environmental design. Every template must remain readable with dressing disabled, and every generated variant must preserve navigation, collision, interaction clearance, visual hierarchy, and a recognizable landmark.

## Character and animation rules

- Silhouettes must remain recognizable without color.
- Idle animation should be restrained; walking needs clear directional intent.
- Every actor receives a ground contact shadow unless intentionally airborne.
- Important actions should have anticipation, impact, and recovery beats.
- Portraits may use greater detail, but must retain the sprite's defining shapes and palette.

## Interface rules

- One primary decision area per screen.
- Focus must always be visible with keyboard or controller.
- Modal surfaces use opaque or near-opaque backgrounds and sit above the world layer.
- Abbreviate live tactical information before clipping it; preserve full detail in tooltips or logs.
- Red is reserved for danger and failure, not ordinary decoration.

## AI-assisted asset workflow

AI-generated imagery may be used for concept exploration. Shippable assets require an original pixel-art pass that normalizes silhouette, palette, perspective, scale, and animation. Prompts and references should describe design principles rather than request imitation of a specific copyrighted game or artist.
