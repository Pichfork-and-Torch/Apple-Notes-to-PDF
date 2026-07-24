# Builds a clean release zip (no .DS_Store, no __MACOSX).
# Usage: .\scripts\build-release.ps1 [-AppSource "path\to\Apple Notes to PDF.app"]

param(
    [string]$AppSource = "",
    [string]$Version = (Get-Content (Join-Path $PSScriptRoot "..\VERSION") -Raw).Trim()
)

$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$dist = Join-Path $root "dist"
$staging = Join-Path $dist "Apple-Notes-to-PDF-v$Version"
$zipPath = Join-Path $dist "Apple-Notes-to-PDF-v$Version.zip"

if (Test-Path $dist) { Remove-Item $dist -Recurse -Force }
New-Item -ItemType Directory -Path $staging -Force | Out-Null

$include = @(
    "export-apple-notes.sh",
    "export-apple-notes.command",
    "render-note-to-pdf.applescript",
    "README.md",
    "LICENSE",
    "SECURITY.md",
    "VERSION",
    "logo.png",
    "logo.icns"
)

foreach ($item in $include) {
    Copy-Item (Join-Path $root $item) (Join-Path $staging $item)
}

if (-not $AppSource) {
    throw "Provide -AppSource pointing to 'Apple Notes to PDF.app' bundle."
}
Copy-Item -Path $AppSource -Destination (Join-Path $staging "Apple Notes to PDF.app") -Recurse

if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path (Join-Path $staging "*") -DestinationPath $zipPath -CompressionLevel Optimal
Write-Host "Built: $zipPath"