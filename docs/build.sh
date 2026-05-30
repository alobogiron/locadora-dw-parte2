#!/usr/bin/env bash
# =====================================================================
#  Avaliacao 02 — Modelagem de DW — Parte II
#  Arquivo: docs/build.sh
#  Gera, a partir dos .md, os entregaveis .pdf e .odt dos dois relatorios,
#  regenerando antes as figuras (SVG -> PNG).
#  Grupo: Gustavo O. P. da Silva (122051824) · Andre V. L. Giron (122050404)
#
#  Uso:   bash docs/build.sh           (a partir da raiz do repositorio)
#  Requer: python3, libreoffice/soffice, pandoc, weasyprint
# =====================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOCS="$ROOT/docs"
FIG="$DOCS/figuras"
cd "$ROOT"

echo "==> [1/3] Gerando figuras SVG"
python3 "$FIG/gen_dimensional.py"
python3 "$FIG/gen_etl.py"

echo "==> [2/3] Rasterizando SVG -> PNG (LibreOffice)"
soffice --headless --convert-to png --outdir "$FIG" "$FIG"/dim_fig*.svg "$FIG"/etl_fig*.svg >/dev/null 2>&1
echo "    $(ls "$FIG"/*.png | wc -l) PNGs."

CSS="docs/estilo-relatorio.css"
COMMON_PDF="--resource-path=docs --css=$CSS --embed-resources --standalone \
  --toc --toc-depth=3 --pdf-engine=weasyprint"
COMMON_ODT="--resource-path=docs --toc --toc-depth=3"

echo "==> [3/3] Construindo PDF + ODT"
for r in relatorio-dimensional relatorio-etl; do
  echo "    -> $r.pdf"
  pandoc "docs/$r.md" $COMMON_PDF -o "docs/$r.pdf"
  echo "    -> $r.odt"
  pandoc "docs/$r.md" $COMMON_ODT -o "docs/$r.odt"
done

# Folha de rosto (documento de uma página, sem sumário)
echo "    -> folha-de-rosto.pdf"
pandoc docs/folha-de-rosto.md --resource-path=docs --css="$CSS" \
  --embed-resources --standalone --pdf-engine=weasyprint -o docs/folha-de-rosto.pdf
echo "    -> folha-de-rosto.odt"
pandoc docs/folha-de-rosto.md --resource-path=docs -o docs/folha-de-rosto.odt

echo "==> Concluido."
ls -la docs/relatorio-*.pdf docs/relatorio-*.odt docs/folha-de-rosto.pdf docs/folha-de-rosto.odt
