#!/usr/bin/env bash
# Regenerate Playdeck.xcodeproj from project.yml (requires XcodeGen on macOS).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "XcodeGen not found. Install with: brew install xcodegen"
  echo "The checked-in Playdeck.xcodeproj can be used until then."
  exit 1
fi

xcodegen generate
echo "Generated Playdeck.xcodeproj"
