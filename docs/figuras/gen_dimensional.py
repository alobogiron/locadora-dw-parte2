# =====================================================================
#  Avaliacao 02 — Modelagem de DW — Parte II
#  Arquivo: docs/figuras/gen_dimensional.py
#  Gera as figuras do relatorio do modelo dimensional (SVG).
#  Grupo: Gustavo O. P. da Silva (122051824) · Andre V. L. Giron (122050404)
# =====================================================================
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from _lib import *

OUT = os.path.dirname(__file__)
def save(s, name): s.save(os.path.join(OUT, name)); print(name)


# ---------------------------------------------------------------------
# FIG 01 — Visao geral da integracao: 5 OLTP heterogeneos -> DW estrela
# ---------------------------------------------------------------------
def fig01():
    s = SVG(1180, 600)
    fig_title(s, 40, 44, "Visão geral da integração",
              "Cinco sistemas OLTP heterogêneos convergem para um único Data Warehouse estrela")
    sgbd = {1: "PostgreSQL", 2: "MySQL→PG", 3: "PostgreSQL", 4: "MySQL→PG", 5: "ANSI SQL"}
    x0, w, h, gap, y = 60, 250, 60, 16, 110
    for k in (1, 2, 3, 4, 5):
        stroke, fill, name = FONTES[k]
        s.box(x0, y, w, h, fill=fill, stroke=stroke, sw=1.6, rx=9)
        s.text(x0 + 52, y + 26, f"src_{name}", size=14.5, fill=stroke, weight="bold", anchor="start")
        s.text(x0 + 52, y + 45, sgbd[k], size=11.5, fill=MUTE, anchor="start")
        s.badge(x0 + 2, y + h/2, 15, str(k), fill=stroke, stroke=stroke)
        y += h + gap
    s.text(x0 + w/2, y + 4, "5 esquemas OLTP independentes", size=12.5, fill=MUTE, weight="bold")

    # staging
    sx = 470
    s.container(sx, 110, 230, 380, fill=STG[1], stroke=STG[0], title="staging")
    s.text(sx+115, 70+ -0, "", size=1)
    s.text(sx + 115, 64+ -0, "", size=1)
    s.vtext(sx + 115, 250, "Área de conformação", size=13, fill=STG[0])
    for i, t in enumerate(["normalização de texto", "de-para de pátio", "de-para de grupo",
                            "derivações & status", "tratamento de NULL"]):
        s.text(sx + 24, 290 + i*30, "•  " + t, size=12.5, fill=INK, anchor="start")
    s.vtext(sx + 115, 520, "7 stg_*  +  2 de-paras", size=12.5, fill=MUTE, weight="bold")

    # DW star (mini)
    dx, dcy = 960, 290
    s.container(880, 110, 250, 380, fill="#fbfdff", stroke=DIM[0], title="dw — esquema estrela")
    # central fact
    s.box(dx-58, dcy-26, 116, 52, fill=FACT[1], stroke=FACT[0], sw=1.7, rx=8,
          title="3 fatos", tsize=13.5, tcolor=FACT[0])
    import math
    dims = ["tempo", "patio", "veiculo", "grupo", "cliente", "fonte"]
    R = 118
    for i, d in enumerate(dims):
        ang = -90 + i*60
        cx = dx + R*math.cos(math.radians(ang))
        cy = dcy + R*math.sin(math.radians(ang))
        s.line(dx, dcy, cx, cy, stroke=LINE_LT, sw=1.4)
        s.chip(cx-44, cy-13, 88, 26, d, DIM[1], DIM[0], tcolor=DIM[0], size=11.5, rx=7)
    s.vtext(dx, 470, "6 dimensões conformadas", size=12, fill=MUTE, weight="bold")

    s.line(x0+w+6, dcy, sx-8, dcy, stroke=LINE, sw=3, arrow=True)
    s.text((x0+w+sx)/2, dcy-14, "Extract", size=12.5, fill=MUTE, weight="bold")
    s.line(sx+230+6, dcy, 880-8, dcy, stroke=LINE, sw=3, arrow=True)
    s.text((sx+230+880)/2, dcy-14, "Transform+Load", size=12.5, fill=MUTE, weight="bold")
    save(s, "dim_fig01_visao_geral.svg")


# ---------------------------------------------------------------------
# FIG 02 — Esquema estrela (constelacao de 3 fatos + 6 dimensoes)
# ---------------------------------------------------------------------
def fig02():
    s = SVG(1240, 760)
    fig_title(s, 40, 44, "Esquema estrela do Data Warehouse",
              "Constelação de fatos: 3 tabelas-fato compartilhando 6 dimensões conformadas")
    # rails
    LX, RX, DW, DH = 60, 980, 200, 96
    left = [("dim_tempo", 110), ("dim_patio", 330), ("dim_fonte", 550)]
    right = [("dim_veiculo", 110), ("dim_grupo", 330), ("dim_cliente", 550)]
    facts = [("fato_locacao", 95, "Transação"), ("fato_reserva", 330, "Transação"),
             ("fato_patio_diario", 565, "Snapshot")]
    FX, FW, FH = 500, 240, 120

    # edges (desenhar antes das caixas)
    def fcenter(i): return (FX, facts[i][1] + FH/2)
    def lanchor(j): return (LX + DW, left[j][1] + DH/2)
    def ranchor(j): return (RX, right[j][1] + DH/2)
    EDGE = "#cbd5e1"
    # mapa fato->dims (indice rail)
    L = {0:[0,1,2], 1:[0,1,2], 2:[0,1,2]}  # tempo,patio,fonte: todos
    Rm = {0:[0,1,2], 1:[1,2], 2:[0,1]}     # veic(0),grupo(1),cliente(2)
    for i,_ in enumerate(facts):
        fx, fy = fcenter(i)
        for j in L[i]:
            ax, ay = lanchor(j)
            s.path(f"M {ax:.0f},{ay:.0f} C {(ax+fx)/2:.0f},{ay:.0f} {(ax+fx)/2:.0f},{fy:.0f} {FX-FW/2:.0f},{fy:.0f}",
                   stroke=EDGE, sw=1.6)
        for j in Rm[i]:
            ax, ay = ranchor(j)
            s.path(f"M {FX+FW/2:.0f},{fy:.0f} C {(ax+fx)/2:.0f},{fy:.0f} {(ax+fx)/2:.0f},{ay:.0f} {ax:.0f},{ay:.0f}",
                   stroke=EDGE, sw=1.6)

    # dims
    for name, y in left:
        s.box(LX, y, DW, DH, fill=DIM[1], stroke=DIM[0], sw=1.6, rx=9, title=name, tsize=15, tcolor=DIM[0])
    for name, y in right:
        s.box(RX, y, DW, DH, fill=DIM[1], stroke=DIM[0], sw=1.6, rx=9, title=name, tsize=15, tcolor=DIM[0])
    # role badges
    s.chip(LX+DW-30, left[0][1]-12, 56, 24, "×3 papéis", "#fff", SENT[0], tcolor=SENT[0], size=10.5, rx=7)
    s.chip(LX+DW-30, left[1][1]-12, 56, 24, "×2 papéis", "#fff", SENT[0], tcolor=SENT[0], size=10.5, rx=7)

    # facts
    metr = {0:["grão: 1 locação", "(b) (d) Markov"],
            1:["grão: 1 reserva", "(c)"],
            2:["grão: 1 veículo×dia", "(a)"]}
    for i,(name, y, tipo) in enumerate(facts):
        s.box(FX-FW/2, y, FW, FH, fill=FACT[1], stroke=FACT[0], sw=2.2, rx=10, shadow=True)
        s.vtext(FX, y+30, name, size=16.5, fill=FACT[0], weight="bold")
        s.chip(FX-44, y+44, 88, 22, tipo, "#fff", FACT[0], tcolor=FACT[0], size=11, rx=8)
        for k,ln in enumerate(metr[i]):
            s.text(FX, y+92+k*18, ln, size=11.5, fill=MUTE)
    # legenda
    s.rect(40, 700, 1160, 44, fill="#f8fafc", stroke=LINE_LT, sw=1, rx=8)
    s.chip(60, 710, 130, 24, "■ fato", FACT[1], FACT[0], tcolor=FACT[0], size=12, rx=7)
    s.chip(200, 710, 150, 24, "■ dimensão", DIM[1], DIM[0], tcolor=DIM[0], size=12, rx=7)
    s.text(370, 727, "linha cinza = chave estrangeira (FK)   ·   ×N papéis = role-playing (mesma dimensão em N FKs)",
           size=12.5, fill=INK, anchor="start")
    save(s, "dim_fig02_estrela.svg")


# ---------------------------------------------------------------------
# FIG 03 — Bus matrix Kimball (heatmap)
# ---------------------------------------------------------------------
def fig03():
    dims = ["dim_tempo", "dim_patio", "dim_veiculo", "dim_grupo", "dim_cliente", "dim_fonte"]
    rows = [
        ("fato_locacao", ["3", "2", "1", "1", "1", "1"]),
        ("fato_reserva", ["3", "2", "—", "1*", "1", "1"]),
        ("fato_patio_diario", ["1", "1", "1", "1", "—", "1"]),
    ]
    cw, rh, x0, y0 = 150, 70, 300, 130
    s = SVG(x0 + len(dims)*cw + 40, y0 + len(rows)*rh + 120)
    fig_title(s, 40, 44, "Bus matrix (Kimball)",
              "Participação de cada dimensão nos três processos de negócio (nº = quantidade de papéis/FKs)")
    # header
    for j, d in enumerate(dims):
        s.box(x0+j*cw, y0-46, cw-8, 40, fill=DIM[1], stroke=DIM[0], sw=1.4, rx=7,
              title=d.replace("dim_",""), tsize=13, tcolor=DIM[0])
    for i,(fname, cells) in enumerate(rows):
        yy = y0+i*rh
        s.box(40, yy, x0-60, rh-8, fill=FACT[1], stroke=FACT[0], sw=1.6, rx=8,
              title=fname, tsize=14.5, tcolor=FACT[0])
        for j, c in enumerate(cells):
            cx, cy = x0+j*cw, yy
            if c == "—":
                s.box(cx, cy, cw-8, rh-8, fill="#f8fafc", stroke=LINE_LT, sw=1, rx=7)
                s.vtext(cx+(cw-8)/2, cy+(rh-8)/2, "—", size=16, fill=MUTE)
            else:
                star = c.endswith("*")
                n = c.rstrip("*")
                fill = SENT[1] if star else ("#bfdbfe" if n in ("2","3") else DIM[1])
                stroke = SENT[0] if star else DIM[0]
                s.box(cx, cy, cw-8, rh-8, fill=fill, stroke=stroke, sw=1.6, rx=7)
                s.vtext(cx+(cw-8)/2, cy+(rh-8)/2-2, "✓", size=15, fill=stroke, weight="bold")
                disp = f"{n}{'*' if star else ''} papel" + ("es" if n in ("2","3") else "")
                s.text(cx+(cw-8)/2, cy+(rh-8)/2+16, disp, size=10.5, fill=stroke)
    yleg = y0+len(rows)*rh+20
    s.text(40, yleg+10, "✓ = dimensão participa do fato    ·    número = quantidade de FKs (role-playing)    ·    "
           "1* = sentinela GRUPO_NAO_INFORMADO p/ reservas da bigdata (P-10)    ·    — = não se aplica",
           size=12, fill=INK, anchor="start")
    save(s, "dim_fig03_busmatrix.svg")


# ---------------------------------------------------------------------
# FIG 04 — fato_locacao em detalhe (role-playing + metricas)
# ---------------------------------------------------------------------
def fig04():
    s = SVG(1360, 700)
    fig_title(s, 40, 44, "fato_locacao em detalhe",
              "Role-playing de dim_tempo (3 papéis) e dim_patio (2 papéis) + métricas e sua aditividade")
    DX, DW = 50, 200          # dimensões à esquerda
    CX, CW = 300, 104          # chips de papel
    LBLX = 414                 # rótulos dos papéis
    FX, FY, FW, FH = 600, 250, 250, 190   # caixa-fato central
    # central fact
    s.box(FX, FY, FW, FH, fill=FACT[1], stroke=FACT[0], sw=2.4, rx=12, shadow=True)
    s.vtext(FX+FW/2, FY+34, "fato_locacao", size=19, fill=FACT[0], weight="bold")
    s.chip(FX+FW/2-62, FY+52, 124, 24, "Fato de Transação", "#fff", FACT[0], tcolor=FACT[0], size=11.5, rx=8)
    s.text(FX+FW/2, FY+112, "grão = uma locação", size=13, fill=INK)
    s.text(FX+FW/2, FY+134, "(em qualquer das 5 fontes)", size=11.5, fill=MUTE)
    s.text(FX+FW/2, FY+166, "serve (b), (d) e a matriz Markov", size=11.5, fill=MUTE, italic=True)

    # tempo (3 roles) — esquerda
    roles_t = ["retirada real", "devolução real (NULL se em curso)", "devolução prevista"]
    s.box(DX, 110, DW, 70, fill=DIM[1], stroke=DIM[0], sw=1.8, rx=10, title="dim_tempo", tsize=16, tcolor=DIM[0])
    for i, r in enumerate(roles_t):
        yy = 120 + i*64
        s.path(f"M {DX+DW},145 C {CX-20},145 {CX-20},{yy+14:.0f} {CX},{yy+14:.0f}", stroke=DIM[0], sw=1.6, arrow=True)
        s.chip(CX, yy, CW, 28, f"papel {i+1}", "#fff", SENT[0], tcolor=SENT[0], size=11, rx=8)
        s.text(LBLX, yy+19, r, size=11.5, fill=INK, anchor="start")
    # patio (2 roles) — esquerda inferior
    s.box(DX, 330, DW, 70, fill=DIM[1], stroke=DIM[0], sw=1.8, rx=10, title="dim_patio", tsize=16, tcolor=DIM[0])
    roles_p = ["pátio de retirada", "pátio de devolução (NULL se em curso)"]
    for i, r in enumerate(roles_p):
        yy = 330 + i*64
        s.path(f"M {DX+DW},365 C {CX-20},365 {CX-20},{yy+14:.0f} {CX},{yy+14:.0f}", stroke=DIM[0], sw=1.6, arrow=True)
        s.chip(CX, yy, CW, 28, f"papel {i+1}", "#fff", SENT[0], tcolor=SENT[0], size=11, rx=8)
        s.text(LBLX, yy+19, r, size=11.5, fill=INK, anchor="start")
    # outras dims simples — esquerda baixo
    for i, d in enumerate(["dim_veiculo", "dim_grupo", "dim_cliente", "dim_fonte"]):
        yy = 500+i*40
        s.chip(DX, yy, DW, 30, d, DIM[1], DIM[0], tcolor=DIM[0], size=12.5, rx=8)
        s.path(f"M {DX+DW},{yy+15:.0f} C {FX-120},{yy+15:.0f} {FX-90},{FY+FH/2:.0f} {FX:.0f},{FY+FH/2+20:.0f}",
               stroke=LINE_LT, sw=1.4)

    # metricas — direita
    mx = 920
    s.container(mx, 110, 400, 470, fill="#f8fafc", stroke=LINE_LT, sw=1.4, title="Métricas e aditividade")
    mets = [("qtd_locacoes", "aditiva", OK),
            ("duracao_prevista_dias", "aditiva", OK),
            ("duracao_real_dias", "aditiva", OK),
            ("km_rodados", "aditiva", OK),
            ("valor_total_estimado", "aditiva", OK),
            ("valor_total_final", "aditiva", OK),
            ("valor_diaria_aplicada", "NÃO-aditiva", WARN)]
    for i,(m, cls, col) in enumerate(mets):
        yy = 156 + i*54
        s.rect(mx+20, yy, 360, 44, fill="#fff", stroke=LINE_LT, sw=1, rx=8)
        s.text(mx+34, yy+27, m, size=12.5, fill=INK, anchor="start", family=MONO)
        s.chip(mx+266, yy+9, 110, 26, cls, col[1], col[0], tcolor=col[0], size=10.5, rx=8)
    save(s, "dim_fig04_fato_locacao.svg")


# ---------------------------------------------------------------------
# FIG 05 — Os tres graos (transacao x transacao x snapshot)
# ---------------------------------------------------------------------
def fig05():
    s = SVG(1180, 470)
    fig_title(s, 40, 44, "Os três grãos de fato",
              "Cada processo de negócio tem grão e tipo Kimball próprios — por isso três fatos, não um")
    cards = [
        ("fato_locacao", "Transação", "1 linha por locação", "evento pontual: contrato de aluguel efetivado",
         "✔ contagem aditiva no tempo", FACT),
        ("fato_reserva", "Transação", "1 linha por reserva", "evento pontual: intenção registrada antes da retirada",
         "✔ contagem aditiva no tempo", FACT),
        ("fato_patio_diario", "Snapshot periódico", "1 linha por veículo × dia", "fotografia diária do estoque do pátio",
         "✖ contagem semi-aditiva no tempo (AVG/MIN/MAX)", ("#0369a1", "#e0f2fe")),
    ]
    cw, x0, y0, ch = 360, 50, 120, 280
    for i,(name, tipo, grao, desc, adit, col) in enumerate(cards):
        x = x0 + i*(cw+13)
        s.box(x, y0, cw, ch, fill=col[1], stroke=col[0], sw=2, rx=12, shadow=True)
        s.vtext(x+cw/2, y0+38, name, size=17.5, fill=col[0], weight="bold")
        s.chip(x+cw/2-78, y0+58, 156, 28, tipo, "#fff", col[0], tcolor=col[0], size=12.5, rx=9)
        s.text(x+cw/2, y0+126, "GRÃO", size=11, fill=MUTE, weight="bold", spacing="1.5")
        s.vtext(x+cw/2, y0+150, grao, size=14, fill=INK, weight="bold")
        s.text(x+24, y0+196, desc, size=11.8, fill=INK, anchor="start") if False else None
        # wrap desc manually
        words = desc.split(); line=""; ly=y0+196
        for wd in words:
            if len(line)+len(wd) > 42:
                s.text(x+cw/2, ly, line, size=11.8, fill=MUTE); ly+=18; line=wd
            else: line = (line+" "+wd).strip()
        s.text(x+cw/2, ly, line, size=11.8, fill=MUTE)
        s.rect(x+20, y0+ch-44, cw-40, 30, fill="#ffffff", stroke=col[0], sw=1.2, rx=8)
        s.vtext(x+cw/2, y0+ch-29, adit, size=11, fill=col[0], weight="bold")
    save(s, "dim_fig05_graos.svg")


# ---------------------------------------------------------------------
# FIG 06 — Conformacao de chaves: dim_patio (de-para)
# ---------------------------------------------------------------------
def fig06():
    s = SVG(1180, 560)
    fig_title(s, 40, 44, "Conformação de chaves: os 6 pátios canônicos",
              "Cinco vocabulários distintos colapsam em uma chave natural única via staging.depara_patio")
    variants = {
        1: ['"Aeroporto do Galeão"', '"Galeão"', '"GIG"'],
        2: ['"Santos Dumont"', '"SDU"'],
        3: ['"Rodoviária Novo Rio"', '"Rodoviária"'],
        4: ['"Shopping Rio Sul"', '"Botafogo"'],
        5: ['"Shopping Nova América"', '"NAM"', '"Barra Shopping"'],
    }
    # left: source variant clouds
    y = 110
    for k in (1,2,3,4,5):
        stroke, fill, name = FONTES[k]
        s.badge(70, y+22, 14, str(k), fill=stroke, stroke=stroke)
        s.text(92, y+10, f"src_{name}", size=12.5, fill=stroke, weight="bold", anchor="start")
        xx = 92
        for v in variants[k]:
            wdt = 12 + len(v)*7
            s.chip(xx, y+18, wdt, 26, v, fill, stroke, tcolor=stroke, size=11, rx=8, weight="normal")
            s.line(xx+wdt, y+31, 470, 280, stroke=LINE_LT, sw=1)
            xx += wdt + 8
        y += 78
    # center: depara
    s.box(470, 250, 200, 70, fill=SENT[1], stroke=SENT[0], sw=2, rx=10,
          title="depara_patio", tsize=15, tcolor=SENT[0])
    s.text(570, 305, "(sk_fonte, id) → canônico", size=10.5, fill=SENT[0])
    s.line(670, 285, 740, 285, stroke=LINE, sw=3, arrow=True)
    # right: canonical list
    canon = ["AEROPORTO_GALEAO", "AEROPORTO_SANTOS_DUMONT", "RODOVIARIA_RIO",
             "SHOPPING_RIO_SUL", "SHOPPING_NOVA_AMERICA", "SHOPPING_BARRA"]
    s.container(760, 110, 380, 360, fill="#fbfdff", stroke=DIM[0], title="dim_patio — chave natural única")
    for i,c in enumerate(canon):
        s.chip(784, 160+i*44, 332, 32, c, DIM[1], DIM[0], tcolor=DIM[0], size=12, rx=8)
    s.text(950, 460, "6 pátios canônicos + 1 sentinela PATIO_DESCONHECIDO", size=11.5, fill=MUTE)
    save(s, "dim_fig06_conformacao_patio.svg")


# ---------------------------------------------------------------------
# FIG 07 — smart-key de dim_tempo (YYYYMMDD)
# ---------------------------------------------------------------------
def fig07():
    s = SVG(1180, 520)
    fig_title(s, 40, 44, "A smart-key de dim_tempo",
              "Chave inteira YYYYMMDD: legível, ordenável e estável — dispensa JOIN para filtrar por período")
    # big key
    digits = [("2025", "ano", DIM), ("05", "mês", FACT), ("30", "dia", SENT)]
    x0 = 300; xx = x0; y = 130; H = 96
    for txt, lbl, col in digits:
        wdt = 60*len(txt)/2 + 40
        s.box(xx, y, wdt, H, fill=col[1], stroke=col[0], sw=2.2, rx=12)
        s.vtext(xx+wdt/2, y+H/2, txt, size=44, fill=col[0], weight="bold", )
        s.text(xx+wdt/2, y+H+26, lbl, size=14, fill=col[0], weight="bold")
        xx += wdt + 10
    s.text(x0, y-16, "sk_tempo  =", size=18, fill=INK, anchor="start", weight="bold", family=MONO)
    s.text(xx+20, y+H/2+8, "= 20250530", size=22, fill=INK, anchor="start", family=MONO)

    # propriedades
    props = [
        ("Legível", "o valor é a própria data — facilita depurar SELECTs nos fatos"),
        ("Ordenável", "WHERE sk_tempo BETWEEN 20250101 AND 20251231 filtra o ano inteiro sem JOIN"),
        ("Estável", "não depende da ordem de carga (≠ SERIAL)"),
        ("Sentinela", "sk_tempo = 19000101 representa “data desconhecida/perdida”"),
    ]
    for i,(t, d) in enumerate(props):
        yy = 300 + i*52
        s.chip(60, yy, 150, 34, t, OK[1], OK[0], tcolor=OK[0], size=13.5, rx=9)
        s.text(230, yy+23, d, size=13, fill=INK, anchor="start")
    s.rect(40, 280, 1100, 230, fill="none", stroke=LINE_LT, sw=1, rx=10)
    s.text(60, 280-0+0, "", size=1)
    save(s, "dim_fig07_smartkey_tempo.svg")


# ---------------------------------------------------------------------
# FIG 08 — SCD tipo 1 (sobrescrita)
# ---------------------------------------------------------------------
def fig08():
    s = SVG(1120, 470)
    fig_title(s, 40, 44, "SCD Tipo 1 (sobrescrita) em todas as dimensões",
              "Mudança de atributo sobrescreve o valor antigo — o histórico relevante já está congelado nos fatos")
    def row_table(x, y, title, rows, hi=None, col=DIM):
        w = 420; rh = 40
        s.box(x, y, w, 36, fill=col[1], stroke=col[0], sw=1.6, rx=8, title=title, tsize=14, tcolor=col[0])
        for i,(a,b) in enumerate(rows):
            yy = y+36+i*rh
            fill = SENT[1] if hi==i else "#fff"
            stroke = SENT[0] if hi==i else LINE_LT
            s.rect(x, yy, w, rh, fill=fill, stroke=stroke, sw=1.2)
            s.text(x+16, yy+25, a, size=12.5, fill=INK, anchor="start", family=MONO)
            s.text(x+w-16, yy+25, b, size=12.5, fill=INK if hi!=i else SENT[0],
                   anchor="end", weight="bold" if hi==i else "normal")
        return w
    rowsA = [("sk_cliente", "42"), ("nome", "ACME LTDA"), ("cidade_origem", "Niterói")]
    rowsB = [("sk_cliente", "42"), ("nome", "ACME LTDA"), ("cidade_origem", "Rio de Janeiro")]
    row_table(60, 130, "dim_cliente — antes", rowsA, hi=2)
    s.line(500, 220, 600, 220, stroke=LINE, sw=3, arrow=True)
    s.chip(470, 170, 160, 30, "cliente muda de cidade", "#fff", SENT[0], tcolor=SENT[0], size=11.5, rx=8)
    row_table(640, 130, "dim_cliente — depois", rowsB, hi=2)
    s.rect(60, 320, 1000, 110, fill="#f8fafc", stroke=LINE_LT, sw=1, rx=10)
    s.text(84, 356, "Mesma sk_cliente (42) — o valor antigo “Niterói” é perdido (sobrescrito).",
           size=13.5, fill=INK, anchor="start")
    s.text(84, 384, "Justificativa (D-04): os relatórios são agregados; o histórico de tarifa já fica congelado em",
           size=13, fill=MUTE, anchor="start")
    s.text(84, 406, "fato_locacao.valor_diaria_aplicada. SCD-2 ficou como evolução futura.",
           size=13, fill=MUTE, anchor="start")
    save(s, "dim_fig08_scd1.svg")


# ---------------------------------------------------------------------
# FIG 09 — Cadeia de Markov dos 6 patios
# ---------------------------------------------------------------------
def fig09():
    import math
    s = SVG(1180, 810)
    fig_title(s, 40, 44, "Matriz de Markov da movimentação da frota",
              "Derivada de fato_locacao: P(devolução no pátio j | retirada no pátio i), por par retirada→devolução")
    cx, cy, R, rad = 590, 415, 228, 47
    nodes = ["Galeão", "Santos\nDumont", "Rodoviária", "Rio Sul", "Nova\nAmérica", "Barra"]
    pts = []
    for i in range(6):
        ang = -90 + i*60
        x = cx + R*math.cos(math.radians(ang)); y = cy + R*math.sin(math.radians(ang))
        pts.append((x,y))
    # transições só entre vizinhos no ciclo (sem cruzar o centro) + laços
    loops = [0.55,0.45,0.50,0.48,0.52,0.50]
    ring  = [(0,1,0.25),(1,2,0.30),(2,3,0.28),(3,4,0.30),(4,5,0.26),(5,0,0.28),
             (1,0,0.30),(0,5,0.17)]
    for a,b,p in ring:
        x1,y1 = pts[a]; x2,y2 = pts[b]
        # encurta para a borda dos círculos
        ang = math.atan2(y2-y1, x2-x1)
        sx, sy = x1+math.cos(ang)*rad, y1+math.sin(ang)*rad
        ex, ey = x2-math.cos(ang)*(rad+6), y2-math.sin(ang)*(rad+6)
        mx, my = (sx+ex)/2, (sy+ey)/2
        ddx, ddy = (mx-cx), (my-cy); nn = math.hypot(ddx,ddy) or 1
        bow = 30 if (a,b) not in ((1,0),(0,5)) else -34
        ctrlx, ctrly = mx + ddx/nn*bow, my + ddy/nn*bow
        s.path(f"M {sx:.0f},{sy:.0f} Q {ctrlx:.0f},{ctrly:.0f} {ex:.0f},{ey:.0f}",
               stroke=LINE, sw=1.2+p*4, arrow=True)
        s.text(ctrlx + ddx/nn*12, ctrly + ddy/nn*12, f"{p:.2f}", size=11, fill=MUTE, weight="bold")
    for i,(x,y) in enumerate(pts):
        ang = -90 + i*60
        ox, oy = math.cos(math.radians(ang)), math.sin(math.radians(ang))
        lx, ly = x+ox*rad, y+oy*rad
        s.path(f"M {x+ox*rad-16:.0f},{y+oy*rad-2:.0f} C {lx-30+ox*30:.0f},{ly-34+oy*30:.0f} "
               f"{lx+30+ox*30:.0f},{ly-34+oy*30:.0f} {x+ox*rad+16:.0f},{y+oy*rad-2:.0f}",
               stroke=SENT[0], sw=2.0, arrow=True)
        s.text(lx+ox*30, ly+oy*30+4, f"{loops[i]:.2f}", size=11.5, fill=SENT[0], weight="bold")
    for i,(x,y) in enumerate(pts):
        s.parts.append(f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{rad}" fill="{DIM[1]}" stroke="{DIM[0]}" stroke-width="2.4"/>')
        parts_n = nodes[i].split("\n")
        for j,ln in enumerate(parts_n):
            s.text(x, y + (j-(len(parts_n)-1)/2)*15 + 5, ln, size=12.5, fill=DIM[0], weight="bold")
    s.rect(40, 748, 1100, 46, fill="#f8fafc", stroke=LINE_LT, sw=1, rx=8)
    s.text(60, 776, "Setas (cinza) = transições retirada→devolução, espessura ∝ probabilidade   ·   "
           "laços (laranja) = devolução no mesmo pátio   ·   cada linha da matriz soma 1,0",
           size=12, fill=INK, anchor="start")
    save(s, "dim_fig09_markov.svg")


for f in (fig01, fig02, fig03, fig04, fig05, fig06, fig07, fig08, fig09):
    f()
print("DIMENSIONAL OK")
