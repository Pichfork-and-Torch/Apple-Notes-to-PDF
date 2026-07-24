# Security

## What this tool does

Apple Notes to PDF runs **entirely on your Mac**. It reads your local Apple Notes database and writes exports to a folder you choose (default: Desktop). It does **not** upload notes, credentials, or exports to any server.

## Permissions required

| Permission | Why |
|------------|-----|
| Automation (Notes) | Read note titles, folders, and body text via AppleScript |
| Full Disk Access (optional) | Export attachments from the Notes library |

Grant only what you need. Test safely with `--limit 5` before a full export.

## What we never collect

- No analytics, telemetry, or phone-home endpoints in the source
- No API keys or cloud credentials in this repository
- No sample note content shipped in releases

## Reporting a vulnerability

Open a [GitHub issue](https://github.com/Pitchfork-and-Torch/Apple-Notes-to-PDF/issues) (no public exploit details until fixed if critical). For sensitive reports, use GitHub private vulnerability reporting if enabled on the repo.

## Installing safely

1. Download releases only from [official GitHub releases](https://github.com/Pitchfork-and-Torch/Apple-Notes-to-PDF/releases).
2. Prefer cloning and reading `export-apple-notes.sh` before running.
3. Do not run unsigned scripts from third-party mirrors.