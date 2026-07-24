# Apple Notes to PDF

**Export Apple Notes to PDF, HTML, and plain text on macOS â€” fully local, no cloud upload.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-12%2B-black)](https://github.com/Pitchfork-and-Torch/Apple-Notes-to-PDF)
[![Version](https://img.shields.io/badge/version-6.0.2-informational)](VERSION)

Apple Notes to PDF is a free open-source macOS tool that bulk-exports your Notes.app library into a single master PDF, a printable HTML archive, plain text, and attachment folders. Everything runs on your Mac with AppleScript/JXA â€” no accounts, no telemetry, no third-party servers.

If you searched for *export Apple Notes to PDF*, *backup Notes.app without iCloud*, or *convert Apple Notes to HTML*, this is that workflow.

---

## Quick start

1. Download the **[latest release zip](https://github.com/Pitchfork-and-Torch/Apple-Notes-to-PDF/releases/latest)**.
2. Unzip and keep these files together in one folder:
   - `Apple Notes to PDF.app`
   - `export-apple-notes.sh`
   - `render-note-to-pdf.applescript`
3. Double-click **Apple Notes to PDF.app**.

First run prompts for **Automation** access to Notes (and optionally Full Disk Access for attachments). The app opens the correct System Settings pane.

---

## Output

Creates `~/Desktop/Apple_Notes_Export_YYYY-MM-DD/` containing:

| File / folder | Description |
|---------------|-------------|
| `Apple_Notes_Master.pdf` | All notes as styled cards |
| `master.html` | Full archive (Print â†’ PDF in a browser for another copy) |
| `attachments/` | Exported images and media |
| Plain text | Included in the export flow |

---

## Safe test first (CLI)

```bash
./export-apple-notes.sh --help
./export-apple-notes.sh --version
./export-apple-notes.sh --limit 5
```

| Flag | Purpose |
|------|---------|
| `--limit N` | Export only the first N notes (smoke test) |
| `--output-dir DIR` | Custom export folder |
| `--dry-run` | Plan without a full write |
| `--no-attachments` | Skip media export |
| `--no-transcribe` | Skip audio transcription steps |
| `--version` | Print version and exit |
| `--help` | Full usage text |

---

## From source

```bash
git clone https://github.com/Pitchfork-and-Torch/Apple-Notes-to-PDF.git
cd Apple-Notes-to-PDF
./export-apple-notes.sh --limit 5
```

**Requirements:** macOS 12+, Notes.app, `zsh` (default shell on modern macOS).

---

## Why this exists

Apple doesn't ship a reliable â€œexport everythingâ€ path for Notes. People usually want:

1. A **local backup** they control (not only iCloud).
2. A **single PDF** they can archive, print, or share offline.
3. **HTML** they can open in any browser years later.

This project stitches Notes â†’ styled HTML â†’ PDF on-device so your notes never leave the machine during export.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Permission dialog / empty export | System Settings â†’ Privacy & Security â†’ **Automation** â†’ allow Terminal (or the `.app`) to control **Notes** |
| Attachments missing | Grant **Full Disk Access** to the same app, then re-run |
| PDF looks sparse | Open `master.html` in Safari and use **File â†’ Print â†’ Save as PDF** as a fallback |
| Wrong custom icon | Right-click the `.app` â†’ Get Info â†’ drag `logo.png` onto the small icon |
| Huge libraries | Start with `--limit 20`, confirm output, then run without a limit |

---

## FAQ

### Does this upload my notes to the cloud?

No. The export reads Notes locally and writes only to the folder you choose (default: Desktop). See [SECURITY.md](SECURITY.md).

### Does it work with iCloud Notes?

Yes, for notes already synced into Notes.app on the Mac. The tool reads whatever Notes exposes to Automation â€” it does not call iCloud APIs directly.

### Can I export only some notes?

Use ``--limit N`` for a prefix of the library, or ``--folder Work`` (case-insensitive substring match on the folder path).

### What macOS versions are supported?

macOS 12+ is the practical target. Older versions may work if Notes Automation still allows the scripts.

### How do I get the version?

```bash
./export-apple-notes.sh --version
# or
cat VERSION
```

### Is there telemetry or analytics?

No. No network calls for analytics, accounts, or crash reporting.

---

## Privacy & security

This tool reads your Notes **only on your machine** and writes files locally. No network calls, no accounts, no telemetry. See [SECURITY.md](SECURITY.md).

---

## Contributing

Bug reports and pull requests are welcome. Keep the product **local-first**: no cloud backends, no forced accounts. Match the existing shell/AppleScript style and keep help text accurate.

---

## License

MIT â€” see [LICENSE](LICENSE).

---

## Support the work

Apple Notes to PDF is **free and open source**. Bug reports and feature requests are welcome via [GitHub Issues](https://github.com/Pitchfork-and-Torch/Apple-Notes-to-PDF/issues).
