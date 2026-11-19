# QRReader App Store screenshot editor

Editable Japanese and English decks, with light and dark variants. Each has four benefit slides: scan, check, history, copy/share. Native iPhone and iPad UI captures are preserved byte-for-byte in public/screenshots/apple/{device}/{appearance}/{locale}/. Source hashes and XCTest result locations are recorded in ../sources/manifest.json.

## Start

```sh
bun install
bun run dev --hostname 127.0.0.1 --port 3107
```

Open http://127.0.0.1:3107. Pick iPhone or iPad, and JA or EN. Export bundle generates four RGB PNGs per language in the selected device size: iPhone 1320×2868, iPad 2064×2752. The editor autosaves its current composition.

## Appearance presets

The saved originals live in ../projects/dark.json and ../projects/light.json. To select a preset, finish any browser edits/export first, then run one command below and refresh the editor. Selecting a preset replaces the current editor composition.

```sh
bun select-appearance.mjs dark
bun select-appearance.mjs light
```

## Image fidelity

- iPhone uses the template's original mockup.png; its screen ratio matches the iPhone 16 captures.
- iPad uses the template's existing IPad frame, proportioned for native 1640×2360 captures. The 13-inch output canvas is the promotional canvas, not a stretched app screen.
- The camera, result and its system share sheet remain dark in the actual app in both OS modes. History follows the OS light/dark setting. Both variants use captures from the corresponding OS appearance.
- English marketing copy uses native English app UI, dates and system share-sheet actions. The dedicated English capture tests assert the translated labels before taking screenshots; the owned simulator is configured with English and en_US before first boot.
- Sources contain test URL/history data. The simulator camera region uses a DEBUG placeholder background; it is not a photograph or a live feed. No UI has been repainted.
- All other platform/device decks are empty. Firebase settings and credentials are not included.

## Template credit

Built from [ParthJadhav/app-store-screenshots](https://github.com/ParthJadhav/app-store-screenshots), installed locally as a Codex skill. [Project showcase](https://www.parthjadhav.com/products/app-store-screenshots); the author welcomes shared results tagged @parthjadhav8. Upstream documentation is preserved in README.upstream.md. Nothing was uploaded or published by this task.
