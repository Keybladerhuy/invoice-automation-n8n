#!/usr/bin/env bash
# Converts the sample Markdown invoices to PDF using pandoc.
# Requires: pandoc + a LaTeX engine with CJK support.
#
# Quick install (macOS):
#   brew install pandoc
#   brew install --cask basictex        # lighter (~90MB, adds tlmgr)
#   sudo tlmgr update --self
#   sudo tlmgr install collection-fontsrecommended cjk-gs-integrate xecjk
#
# Or the full MacTeX cask (4GB, no extra steps):
#   brew install --cask mactex-no-gui

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ── Preflight checks ────────────────────────────────────────────────────────
check_cmd() {
  if ! command -v "$1" &>/dev/null; then
    echo "ERROR: '$1' not found." >&2
    return 1
  fi
}

PANDOC_OK=1
LATEX_OK=1

check_cmd pandoc || PANDOC_OK=0
check_cmd xelatex || LATEX_OK=0

if [[ $PANDOC_OK -eq 0 ]]; then
  echo ""
  echo "Install pandoc:   brew install pandoc"
  echo ""
  exit 1
fi

if [[ $LATEX_OK -eq 0 ]]; then
  echo ""
  echo "xelatex not found. Options:"
  echo "  Lightweight:  brew install --cask basictex"
  echo "                sudo tlmgr install collection-fontsrecommended cjk-gs-integrate xecjk"
  echo "  Full install: brew install --cask mactex-no-gui"
  echo ""
  exit 1
fi

# ── Build function ───────────────────────────────────────────────────────────
build_pdf() {
  local src="$1"
  local out="${src%.md}.pdf"
  echo "Building $out ..."
  pandoc "$src" \
    --pdf-engine=xelatex \
    -V geometry:margin=2cm \
    -V mainfont="Noto Sans" \
    -V CJKmainfont="Noto Sans CJK JP" \
    -V fontsize=11pt \
    -V colorlinks=true \
    -V linkcolor=blue \
    -o "$out"
  echo "  ✓ Created $out"
}

# ── Convert all sample invoices ──────────────────────────────────────────────
build_pdf "invoice_en_01.md"
build_pdf "invoice_jp_01.md"
build_pdf "invoice_mixed_01.md"

echo ""
echo "All PDFs built successfully."
echo "Attach these to a test Gmail message to trigger the workflow."
