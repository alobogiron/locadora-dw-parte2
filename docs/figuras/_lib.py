# =====================================================================
#  Avaliacao 02 — Modelagem de Data Warehouse — Parte II
#  Arquivo: docs/figuras/_lib.py
#  Objetivo: biblioteca de apoio para gerar as figuras dos relatorios
#            em SVG (vetorial). Sem dependencias externas: emite SVG
#            como texto. A rasterizacao p/ PNG e feita pelo build.
#  Grupo:
#    - Gustavo Oliveira Pessanha da Silva — DRE 122051824
#    - Andre Vinicius Lobo Giron           — DRE 122050404
# =====================================================================
"""Mini-biblioteca de composicao de SVG para diagramas dos relatorios.

Convencoes de projeto (identidade visual unica entre os dois relatorios):
- Fonte sem serifa (Liberation/DejaVu/Arial) — compativel com WeasyPrint e LibreOffice.
- Centralizacao vertical de texto feita manualmente (baseline = cy + size*0.35),
  evitando `dominant-baseline` (suporte irregular no rasterizador do LibreOffice).
- Cada uma das 5 fontes OLTP tem uma cor propria, reusada em todas as figuras.
"""

FONT = "Liberation Sans, DejaVu Sans, Arial, sans-serif"
MONO = "Liberation Mono, DejaVu Sans Mono, monospace"

# ---- Paleta -----------------------------------------------------------------
INK      = "#1f2937"   # texto principal
MUTE     = "#64748b"   # texto secundario
LINE     = "#475569"   # tracos/setas
LINE_LT  = "#94a3b8"   # tracos leves
PAPER    = "#ffffff"

# Cor por fonte OLTP (borda / preenchimento claro)
FONTES = {
    1: ("#4f46e5", "#e0e7ff", "andre_gustavo"),   # indigo
    2: ("#0d9488", "#ccfbf1", "mae016"),           # teal
    3: ("#d97706", "#fef3c7", "locadora_db"),       # amber
    4: ("#e11d48", "#ffe1e7", "bd_dw_26_1"),        # rose
    5: ("#7c3aed", "#ede9fe", "bigdata"),           # violet
}

# Camadas do pipeline
STG      = ("#475569", "#f1f5f9")   # staging (slate)
FACT     = ("#15803d", "#dcfce7")   # fatos (green)
DIM      = ("#1d4ed8", "#dbeafe")   # dimensoes (blue)
SENT     = ("#ea580c", "#fff7ed")   # sentinela (orange)
WARN     = ("#b91c1c", "#fee2e2")   # excluido / problema (red)
OK       = ("#15803d", "#dcfce7")   # ok (green)
NEUTRAL  = ("#334155", "#e2e8f0")   # neutro


def esc(s):
    return (str(s).replace("&", "&amp;").replace("<", "&lt;")
            .replace(">", "&gt;").replace('"', "&quot;"))


class SVG:
    """Acumulador de elementos SVG com defs de marcadores de seta."""

    def __init__(self, w, h, bg=PAPER):
        self.w, self.h = w, h
        self.parts = []
        self.bg = bg
        self._markers = set()

    # ---- primitivas ----
    def rect(self, x, y, w, h, fill="none", stroke="none", sw=1, rx=0, dash=None, opacity=None):
        d = f' stroke-dasharray="{dash}"' if dash else ""
        o = f' opacity="{opacity}"' if opacity is not None else ""
        self.parts.append(
            f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" '
            f'rx="{rx}" ry="{rx}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"{d}{o}/>')
        return self

    def line(self, x1, y1, x2, y2, stroke=LINE, sw=2, dash=None, arrow=False, opacity=None):
        marker = ""
        if arrow:
            self._markers.add(stroke)
            marker = f' marker-end="url(#arr_{self._cid(stroke)})"'
        d = f' stroke-dasharray="{dash}"' if dash else ""
        o = f' opacity="{opacity}"' if opacity is not None else ""
        self.parts.append(
            f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" '
            f'stroke="{stroke}" stroke-width="{sw}"{d}{marker}{o}/>')
        return self

    def path(self, d, stroke=LINE, sw=2, fill="none", dash=None, arrow=False):
        marker = ""
        if arrow:
            self._markers.add(stroke)
            marker = f' marker-end="url(#arr_{self._cid(stroke)})"'
        da = f' stroke-dasharray="{dash}"' if dash else ""
        self.parts.append(
            f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"{da}{marker}/>')
        return self

    def polygon(self, pts, fill="none", stroke="none", sw=1):
        p = " ".join(f"{x:.1f},{y:.1f}" for x, y in pts)
        self.parts.append(f'<polygon points="{p}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>')
        return self

    def text(self, x, y, s, size=15, fill=INK, anchor="middle", weight="normal",
             family=None, italic=False, spacing=None):
        family = family or FONT
        it = ' font-style="italic"' if italic else ""
        ls = f' letter-spacing="{spacing}"' if spacing else ""
        self.parts.append(
            f'<text x="{x:.1f}" y="{y:.1f}" font-family="{family}" font-size="{size}" '
            f'font-weight="{weight}" fill="{fill}" text-anchor="{anchor}"{it}{ls}>{esc(s)}</text>')
        return self

    # ---- compostos ----
    def vtext(self, cx, cy, s, size=15, **kw):
        """Texto centrado verticalmente em cy."""
        return self.text(cx, cy + size * 0.35, s, size=size, **kw)

    def box(self, x, y, w, h, fill="#fff", stroke=INK, sw=1.5, rx=8, dash=None,
            title=None, tsize=16, tcolor=None, tweight="bold", lines=None,
            lsize=12, lcolor=None, lfamily=None, shadow=False):
        if shadow:
            self.rect(x + 3, y + 4, w, h, fill="#cbd5e1", rx=rx)
        self.rect(x, y, w, h, fill=fill, stroke=stroke, sw=sw, rx=rx, dash=dash)
        cx = x + w / 2
        tcolor = tcolor or stroke
        if title is not None and lines:
            self.vtext(cx, y + h * 0.34, title, size=tsize, fill=tcolor, weight=tweight)
            self._multiline(cx, y + h * 0.52, lines, lsize, lcolor or MUTE, lfamily, h, y)
        elif title is not None:
            self.vtext(cx, y + h / 2, title, size=tsize, fill=tcolor, weight=tweight)
        elif lines:
            self._multiline(cx, y + 6, lines, lsize, lcolor or INK, lfamily, h, y)
        return self

    def _multiline(self, cx, y0, lines, size, color, family, h=None, y=None):
        lh = size * 1.42
        for i, ln in enumerate(lines):
            anchor = "middle"
            self.text(cx, y0 + size + i * lh, ln, size=size, fill=color, anchor=anchor, family=family)
        return self

    def container(self, x, y, w, h, fill="#fff", stroke=INK, sw=1.8, rx=12,
                  title=None, tsize=17, tcolor=None, subtitle=None, dash=None):
        """Caixa-contêiner com título ancorado no topo (não centralizado)."""
        self.rect(x, y, w, h, fill=fill, stroke=stroke, sw=sw, rx=rx, dash=dash)
        if title is not None:
            self.text(x + w / 2, y + 26, title, size=tsize, fill=tcolor or stroke, weight="bold")
        if subtitle is not None:
            self.text(x + w / 2, y + 26 + tsize * 1.15, subtitle, size=tsize * 0.72, fill=MUTE)
        return self

    def chip(self, x, y, w, h, label, fill, stroke, tcolor=None, size=13, weight="bold", rx=11):
        self.rect(x, y, w, h, fill=fill, stroke=stroke, sw=1.4, rx=rx)
        self.vtext(x + w / 2, y + h / 2, label, size=size, fill=tcolor or stroke, weight=weight)
        return self

    def badge(self, cx, cy, r, label, fill, stroke, tcolor="#fff", size=14, weight="bold"):
        self.parts.append(f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="{r}" fill="{fill}" stroke="{stroke}" stroke-width="1.5"/>')
        self.vtext(cx, cy, label, size=size, fill=tcolor, weight=weight)
        return self

    def _cid(self, color):
        return color.replace("#", "")

    def _defs(self):
        out = ["<defs>"]
        for c in sorted(self._markers):
            cid = self._cid(c)
            out.append(
                f'<marker id="arr_{cid}" markerWidth="10" markerHeight="10" refX="8" refY="3.2" '
                f'orient="auto" markerUnits="userSpaceOnUse">'
                f'<path d="M0,0 L8,3.2 L0,6.4 Z" fill="{c}"/></marker>')
        out.append("</defs>")
        return "".join(out)

    def render(self):
        head = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.w}" height="{self.h}" '
                f'viewBox="0 0 {self.w} {self.h}" font-family="{FONT}">')
        bg = f'<rect x="0" y="0" width="{self.w}" height="{self.h}" fill="{self.bg}"/>'
        return head + self._defs() + bg + "".join(self.parts) + "</svg>"

    def save(self, path):
        with open(path, "w") as f:
            f.write(self.render())
        return path


def fig_title(svg, x, y, title, subtitle=None, w=None):
    """Cabecalho padronizado de figura (faixa superior)."""
    svg.text(x, y, title, size=20, fill=INK, anchor="start", weight="bold")
    if subtitle:
        svg.text(x, y + 22, subtitle, size=13.5, fill=MUTE, anchor="start")
    return svg
