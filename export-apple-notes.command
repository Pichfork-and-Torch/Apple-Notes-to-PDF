#!/bin/zsh
# Double-click to run Apple Notes to PDF v6.0.1
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
./export-apple-notes.sh "$@"
