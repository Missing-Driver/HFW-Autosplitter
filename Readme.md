# HFW Autosplitter

An autosplitter for **Horizon Forbidden West**, built for use with [LiveSplit](https://livesplit.org/).

## Contents

- **`HFWFullAutosplitter.asl`** — the LiveSplit ASL script that handles splitting, load removal, and game state tracking.
- **`Splits/`** — a base split file (`NG+Full_Clean.lss`) to get started with.
- **`Tools/`** — a Cheat Engine table (`HFWBaseAddressFetcher.CT`) that automatically scans for the base addresses the script relies on, making it easier to update the ASL after a game patch changes them.
