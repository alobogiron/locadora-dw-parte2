# =====================================================================
#  Avaliacao 02 — Modelagem de DW — Parte II
#  Arquivo: docs/figuras/gen_etl.py
#  Gera as figuras do relatorio do processo ETL (SVG).
#  Grupo: Gustavo O. P. da Silva (122051824) · Andre V. L. Giron (122050404)
# =====================================================================
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from _lib import *

OUT = os.path.dirname(__file__)
def save(s, name): s.save(os.path.join(OUT, name)); print(name)


# ---------------------------------------------------------------------
# FIG 01 — Arquitetura ETL (fontes -> staging -> DW)
# ---------------------------------------------------------------------
def fig01():
    s = SVG(1200, 600)
    fig_title(s, 40, 44, "Arquitetura do ETL",
              "Fluxo sequencial: Extract (por fonte) → Transform (conformação) → Load (dimensões e fatos)")
    x0, w, h, gap, y = 60, 250, 56, 14, 110
    for k in (1, 2, 3, 4, 5):
        stroke, fill, name = FONTES[k]
        s.box(x0, y, w, h, fill=fill, stroke=stroke, sw=1.6, rx=8, title=f"src_{name}",
              tsize=14.5, tcolor=stroke)
        s.badge(x0 + 2, y + h/2, 14, str(k), fill=stroke, stroke=stroke)
        y += h + gap
    s.text(x0 + w/2, y + 4, "01–05  Extract", size=13, fill=MUTE, weight="bold")

    sx = 480
    s.container(sx, 110, 250, 380, fill=STG[1], stroke=STG[0], title="staging")
    stg = ["stg_patio", "stg_grupo", "stg_veiculo", "stg_cliente",
           "stg_reserva", "stg_locacao", "stg_movimentacao_patio"]
    ty = 158
    for t in stg:
        s.chip(sx + 24, ty, 202, 26, t, "#fff", STG[0], tcolor=STG[0], size=12, rx=6)
        ty += 32
    s.chip(sx + 24, ty + 2, 202, 28, "depara_patio · depara_grupo", SENT[1], SENT[0],
           tcolor=SENT[0], size=11, rx=6)
    s.text(sx + 125, 506, "06  Transform", size=13, fill=MUTE, weight="bold")

    dx = 890
    s.container(dx, 110, 250, 380, fill="#fbfdff", stroke=DIM[0], title="dw — esquema estrela")
    s.text(dx + 125, 62 + 0, "", size=1)
    s.text(dx + 125, 156, "3 fatos", size=12.5, fill=FACT[0], weight="bold")
    for i, f in enumerate(["fato_locacao", "fato_reserva", "fato_patio_diario"]):
        s.chip(dx + 24, 168 + i*30, 202, 24, f, FACT[1], FACT[0], tcolor=FACT[0], size=11.5, rx=6)
    s.text(dx + 125, 282, "6 dimensões", size=12.5, fill=DIM[0], weight="bold")
    dims = ["tempo", "patio", "veiculo", "grupo", "cliente", "fonte"]
    for i, d in enumerate(dims):
        col = i % 2
        s.chip(dx + 24 + col*104, 294 + (i//2)*30, 98, 24, d, DIM[1], DIM[0], tcolor=DIM[0], size=11, rx=6)
    s.text(dx + 125, 506, "07–08  Load", size=13, fill=MUTE, weight="bold")

    s.line(x0 + w + 6, 290, sx - 8, 290, stroke=LINE, sw=3, arrow=True)
    s.line(sx + 250 + 6, 290, dx - 8, 290, stroke=LINE, sw=3, arrow=True)
    save(s, "etl_fig01_arquitetura.svg")


# ---------------------------------------------------------------------
# FIG 02 — Pipeline de execucao (estagios e scripts)
# ---------------------------------------------------------------------
def fig02():
    s = SVG(1300, 560)
    fig_title(s, 40, 44, "Pipeline de execução do ETL",
              "Sete estágios sequenciais; dentro de Extract e Relatórios, os scripts são independentes entre si")
    stages = [
        ("Staging\nDDL + seed", STG, ["01_schema_fontes", "02_seed_fontes", "03_schema_staging", "04_tabelas_de_para"]),
        ("DW\nDDL", DIM, ["dw/01_schema_dw", "dw/02_dim_tempo_carga"]),
        ("Extract\n(5 fontes)", NEUTRAL, ["01_andre_gustavo", "02_mae016", "03_locadora_db", "04_bd_dw", "05_bigdata"]),
        ("Transform", SENT, ["06_transform"]),
        ("Load", FACT, ["07_load_dimensoes", "08_load_fatos"]),
        ("Relatórios\n+ Markov", ("#7c3aed", "#ede9fe"), ["01_controle_patio", "02_controle_locacoes",
            "03_controle_reservas", "04_grupos", "05_matriz_markov"]),
    ]
    n = len(stages); cw = 190; gap = 16; x0 = 40; ytop = 110
    for i,(title, col, scripts) in enumerate(stages):
        x = x0 + i*(cw+gap)
        # cabeçalho do estágio
        s.box(x, ytop, cw, 56, fill=col[1], stroke=col[0], sw=1.8, rx=9)
        for j,ln in enumerate(title.split("\n")):
            s.text(x+cw/2, ytop+24+j*18, ln, size=13.5, fill=col[0], weight="bold")
        # scripts
        yy = ytop + 76
        for sc in scripts:
            s.rect(x+10, yy, cw-20, 30, fill="#fff", stroke=col[0], sw=1.2, rx=6)
            s.vtext(x+cw/2, yy+15, sc, size=10.5, fill=INK, family=MONO)
            yy += 36
        if i < n-1:
            ax = x+cw+2
            s.line(ax, ytop+28, ax+gap-4, ytop+28, stroke=LINE, sw=2.6, arrow=True)
    s.rect(40, 500, 1220, 44, fill="#f8fafc", stroke=LINE_LT, sw=1, rx=8)
    s.text(60, 528, "Idempotente: re-executar o pipeline completo produz resultado bit-a-bit idêntico "
           "(TRUNCATE … RESTART IDENTITY · ON CONFLICT DO UPDATE · DELETE WHERE sk_fonte = N).",
           size=12, fill=INK, anchor="start")
    save(s, "etl_fig02_pipeline.svg")


# ---------------------------------------------------------------------
# FIG 03 — Traducao MySQL -> PostgreSQL
# ---------------------------------------------------------------------
def fig03():
    pairs = [
        ("AUTO_INCREMENT", "GENERATED ALWAYS AS IDENTITY"),
        ("TINYINT(1)", "BOOLEAN"),
        ("TINYINT UNSIGNED", "SMALLINT"),
        ("INT UNSIGNED", "INTEGER  (+ CHECK ≥ 0)"),
        ("DATETIME", "TIMESTAMP"),
        ("ENUM('a','b','c')", "VARCHAR(n) CHECK (col IN (…))"),
        ("DECIMAL(p,s)", "NUMERIC(p,s)"),
        ("COMMENT 'txt' inline", "COMMENT ON COLUMN … IS 'txt'"),
        ("ENGINE=InnoDB / CHARSET", "(removido — default do Postgres)"),
    ]
    rh = 46; y0 = 130
    s = SVG(1120, y0 + len(pairs)*rh + 70)
    fig_title(s, 40, 44, "Tradução MySQL → PostgreSQL",
              "Conversões mecânicas aplicadas às fontes 2 (mae016) e 4 (bd_dw_26_1), sem perda semântica")
    LX, LW, RX, RW = 60, 360, 620, 440
    mysql = ("#00618a", "#e1f0f6"); pg = ("#316192", "#e7eef6")
    s.box(LX, y0-44, LW, 34, fill=mysql[1], stroke=mysql[0], sw=1.6, rx=8, title="MySQL (origem)", tsize=14, tcolor=mysql[0])
    s.box(RX, y0-44, RW, 34, fill=pg[1], stroke=pg[0], sw=1.6, rx=8, title="PostgreSQL 16 (ANSI SQL:1999+)", tsize=14, tcolor=pg[0])
    for i,(a,b) in enumerate(pairs):
        yy = y0 + i*rh
        s.rect(LX, yy, LW, rh-8, fill="#fff", stroke=LINE_LT, sw=1, rx=7)
        s.text(LX+18, yy+25, a, size=13, fill=INK, anchor="start", family=MONO)
        s.line(LX+LW+6, yy+(rh-8)/2, RX-6, yy+(rh-8)/2, stroke=LINE, sw=2, arrow=True)
        s.rect(RX, yy, RW, rh-8, fill=pg[1], stroke=pg[0], sw=1.1, rx=7)
        s.text(RX+18, yy+25, b, size=13, fill=pg[0], anchor="start", family=MONO)
    save(s, "etl_fig03_traducao.svg")


# ---------------------------------------------------------------------
# FIG 04 — Fontes integradas x excluidas
# ---------------------------------------------------------------------
def fig04():
    s = SVG(1180, 600)
    fig_title(s, 40, 44, "Seleção de fontes: 5 integradas, 3 excluídas",
              "Das 8 fontes-candidatas da turma, foram integradas as que expõem todos os atributos dos 4 relatórios")
    # left: integradas
    s.container(50, 110, 470, 430, fill="#f6fdf9", stroke=OK[0], title="✓  5 fontes integradas")
    chosen = [(1,"Parte I do próprio grupo"),(2,"Breno, Hygor, João"),(3,"Tadeu, Vicente"),
              (4,"Ana Clara, Mariana, Matheus, +"),(5,"modelagem ANSI normalizada")]
    for i,(k,desc) in enumerate(chosen):
        stroke, fill, name = FONTES[k]
        yy = 156 + i*72
        s.box(76, yy, 418, 56, fill=fill, stroke=stroke, sw=1.5, rx=9)
        s.badge(76+22, yy+28, 15, str(k), fill=stroke, stroke=stroke)
        s.text(76+50, yy+24, f"src_{name}", size=14, fill=stroke, weight="bold", anchor="start")
        s.text(76+50, yy+42, desc, size=11.5, fill=MUTE, anchor="start")
    # right: excluidas
    s.container(560, 110, 580, 430, fill="#fef6f6", stroke=WARN[0], title="✗  3 fontes excluídas — motivo técnico")
    excl = [("EEL890-big-data", "cidade não extraível (TEXT livre); reserva sem pátio de devolução; empresa-dona em string livre"),
            ("EEL890---Big-Data", "pátio de devolução só por caminho indireto de 4 JOINs (Locacao→Devolucao→Vaga→Patio); over-engineered"),
            ("locadora-oltp", "sem tabela de grupo de veículo e sem cidade do cliente — inviabiliza 2 dos 4 relatórios")]
    for i,(name, reason) in enumerate(excl):
        yy = 156 + i*120
        s.box(584, yy, 532, 102, fill="#fff", stroke=WARN[0], sw=1.5, rx=9)
        s.text(606, yy+30, name, size=14.5, fill=WARN[0], weight="bold", anchor="start", family=MONO)
        # wrap reason
        words = reason.split(); line=""; ly=yy+56
        for wd in words:
            if len(line)+len(wd) > 64:
                s.text(606, ly, line, size=12, fill=INK, anchor="start"); ly+=20; line=wd
            else: line=(line+" "+wd).strip()
        s.text(606, ly, line, size=12, fill=INK, anchor="start")
    save(s, "etl_fig04_excluidas.svg")


# ---------------------------------------------------------------------
# FIG 05 — Extract da fonte bigdata (a mais complexa)
# ---------------------------------------------------------------------
def fig05():
    s = SVG(1200, 600)
    st, fl, _ = FONTES[5]
    fig_title(s, 40, 44, "Extract da fonte bigdata (a mais complexa)",
              "Unificação de PF/PJ, resolução XOR de CentroCusto e pátio via Vaga — particularidades tratadas no extract")
    # source tables (left)
    src = [("PessoaFisica", 110), ("Empresa", 175), ("CentroCusto", 255),
           ("Vaga → Patio", 335), ("Reserva", 415), ("Motorista", 480)]
    for name, y in src:
        s.box(60, y, 220, 50, fill=fl, stroke=st, sw=1.5, rx=8, title=name, tsize=13.5, tcolor=st)
    # staging targets (right)
    tgt = [("stg_cliente", 130), ("stg_reserva", 300), ("stg_locacao", 380), ("stg_grupo (→ sentinela)", 460)]
    for name, y in tgt:
        s.box(820, y, 320, 50, fill=STG[1], stroke=STG[0], sw=1.6, rx=8, title=name, tsize=13.5, tcolor=STG[0])
    # middle annotations
    def edge(y1, y2, label, col=LINE, dash=None):
        s.path(f"M 280,{y1:.0f} C 480,{y1:.0f} 600,{y2:.0f} 820,{y2:.0f}", stroke=col, sw=1.8, arrow=True, dash=dash)
    edge(135, 145, "UNION ALL"); edge(200, 155, "UNION ALL")
    s.chip(470, 120, 150, 26, "UNION ALL  PF ∪ PJ", "#fff", st, tcolor=st, size=11, rx=8)
    s.text(545, 175, "id = 'PF_'||IDFisica  /  'PJ_'||IDEmpresa", size=11, fill=MUTE)
    edge(280, 315, "XOR")
    s.chip(440, 300, 230, 26, "CASE XOR (IDFisica / IDEmpresa)", "#fff", SENT[0], tcolor=SENT[0], size=10.5, rx=8)
    edge(360, 395, "Vaga→Patio")
    s.chip(440, 372, 250, 26, "IDVagaRetirada/Devolvida → IDPatio", "#fff", st, tcolor=st, size=10.5, rx=8)
    edge(440, 472, "sem IDCategoria")
    s.chip(430, 452, 260, 26, "Reserva sem IDCategoria → sk_grupo = 0", "#fff", WARN[0], tcolor=WARN[0], size=10.5, rx=8)
    edge(505, 405, "Motorista")
    save(s, "etl_fig05_extract_bigdata.svg")


# ---------------------------------------------------------------------
# FIG 06 — Transform em 7 etapas
# ---------------------------------------------------------------------
def fig06():
    s = SVG(1180, 470)
    fig_title(s, 40, 44, "Transform (etl/06_transform.sql) em 7 etapas",
              "Bloco PL/pgSQL idempotente que conforma simultaneamente as 5 fontes na staging")
    steps = [
        ("1", "Normalização", "UPPER(TRIM(COALESCE(…)))"),
        ("2", "De-para pátio", "→ nome_canonico_patio"),
        ("3", "De-para grupo", "→ nome_canonico_grupo"),
        ("4", "Status", "EM_ANDAMENTO/CONCLUIDA/…"),
        ("5", "Derivações", "duração e km"),
        ("6", "Tratar NULL", "CIDADE_DESCONHECIDA, …"),
        ("7", "Auditoria", "RAISE NOTICE de suspeitas"),
    ]
    n=len(steps); cw=146; gap=14; x0=40; y=150; h=150
    for i,(num,t,d) in enumerate(steps):
        x=x0+i*(cw+gap)
        col = SENT if num in ("2","3") else (OK if num=="7" else STG)
        s.box(x, y, cw, h, fill=col[1], stroke=col[0], sw=1.7, rx=10)
        s.badge(x+cw/2, y+34, 18, num, fill=col[0], stroke=col[0])
        s.vtext(x+cw/2, y+72, t, size=13, fill=col[0], weight="bold")
        # wrap d
        words=d.split(); line=""; ly=y+98
        for wd in words:
            if len(line)+len(wd)>18:
                s.text(x+cw/2, ly, line, size=10, fill=MUTE, family=MONO); ly+=15; line=wd
            else: line=(line+" "+wd).strip()
        s.text(x+cw/2, ly, line, size=10, fill=MUTE, family=MONO)
        if i<n-1:
            s.line(x+cw+1, y+h/2, x+cw+gap-3, y+h/2, stroke=LINE, sw=2.4, arrow=True)
    s.text(40, 360, "As etapas 2 e 3 aplicam as tabelas de-para (laranja); a etapa 7 apenas informa o operador "
           "antes do Load — nenhuma linha é descartada silenciosamente.", size=12.5, fill=INK, anchor="start")
    save(s, "etl_fig06_transform.svg")


# ---------------------------------------------------------------------
# FIG 07 — Load: ordem + lookup de surrogate key
# ---------------------------------------------------------------------
def fig07():
    s = SVG(1180, 620)
    fig_title(s, 40, 44, "Load: dimensões primeiro, depois fatos",
              "A ordem garante que toda FK de fato já encontre a surrogate key correspondente na dimensão")
    # fase 1 dims
    s.container(50, 110, 520, 250, fill="#fbfdff", stroke=DIM[0], title="Fase 1 — Dimensões  (ON CONFLICT DO UPDATE)")
    dims=["dim_fonte","dim_patio","dim_grupo","dim_veiculo","dim_cliente"]
    for i,d in enumerate(dims):
        x=76+i*92
        s.chip(x, 170, 84, 34, d.replace("dim_",""), DIM[1], DIM[0], tcolor=DIM[0], size=11.5, rx=8)
        if i<len(dims)-1:
            s.line(x+84, 187, x+92, 187, stroke=LINE, sw=2, arrow=True)
    s.text(76, 250, "sk_* atribuídas/estáveis; sentinelas preservadas (sk = 0 / 19000101).", size=12, fill=INK, anchor="start")
    s.text(76, 274, "dim_grupo.valor_diaria_referencia = AVG das 4 fontes que expõem preço.", size=12, fill=MUTE, anchor="start")
    s.text(76, 298, "dim_grupo.classe_luxo = MODE entre as fontes.", size=12, fill=MUTE, anchor="start")
    # fase 2 fatos
    s.container(610, 110, 520, 250, fill="#f6fdf9", stroke=FACT[0], title="Fase 2 — Fatos  (TRUNCATE … RESTART IDENTITY)")
    fts=["fato_locacao","fato_reserva","fato_patio_diario"]
    for i,f in enumerate(fts):
        x=636+i*162
        s.chip(x, 170, 150, 34, f, FACT[1], FACT[0], tcolor=FACT[0], size=11.5, rx=8)
        if i<len(fts)-1:
            s.line(x+150, 187, x+162, 187, stroke=LINE, sw=2, arrow=True)
    s.text(636, 250, "fato_patio_diario é derivado (snapshot por veículo×dia);", size=12, fill=INK, anchor="start")
    s.text(636, 274, "desempate determinístico em sobreposições (ORDER BY).", size=12, fill=MUTE, anchor="start")
    s.text(636, 298, "EM_ANDAMENTO → sk_tempo_devolucao_real = NULL.", size=12, fill=MUTE, anchor="start")
    # lookup mechanism
    s.container(50, 400, 1080, 180, fill="#f8fafc", stroke=LINE_LT, sw=1.4, title="Lookup de surrogate key (exemplo: veículo da locação)")
    boxes=[("stg_locacao", "veiculo_id_natural = '42'", STG, 90),
           ("dim_veiculo", "(sk_fonte, id_natural)\n→ procura a linha", DIM, 470),
           ("fato_locacao", "sk_veiculo = 137", FACT, 850)]
    for name,desc,col,x in boxes:
        s.box(x, 460, 250, 90, fill=col[1], stroke=col[0], sw=1.7, rx=10)
        s.vtext(x+125, 488, name, size=14, fill=col[0], weight="bold")
        for j,ln in enumerate(desc.split("\n")):
            s.text(x+125, 510+j*16, ln, size=11, fill=MUTE, family=MONO)
    s.line(90+250+4, 505, 470-4, 505, stroke=LINE, sw=2.6, arrow=True)
    s.text((90+250+470)/2, 495, "JOIN", size=11, fill=MUTE, weight="bold")
    s.line(470+250+4, 505, 850-4, 505, stroke=LINE, sw=2.6, arrow=True)
    s.text((470+250+850)/2, 495, "grava sk", size=11, fill=MUTE, weight="bold")
    save(s, "etl_fig07_load.svg")


# ---------------------------------------------------------------------
# FIG 08 — Idempotencia (3 mecanismos)
# ---------------------------------------------------------------------
def fig08():
    s = SVG(1160, 470)
    fig_title(s, 40, 44, "Três mecanismos de idempotência",
              "Re-executar qualquer etapa não duplica dados; o pipeline completo é reproduzível bit-a-bit")
    cards=[("Extract", "DELETE WHERE sk_fonte = N", "Cada extract limpa apenas a fatia da sua fonte antes de reinserir.", NEUTRAL),
           ("Load de fatos", "TRUNCATE … RESTART IDENTITY", "Zera o fato e reinicia as surrogate keys antes de cada carga completa.", FACT),
           ("Load de dimensões", "ON CONFLICT DO UPDATE", "UPSERT por chave natural: atualiza se existe, insere se não — preserva sentinelas.", DIM)]
    cw=346; x0=50; y=120; h=240
    for i,(t,code,desc,col) in enumerate(cards):
        x=x0+i*(cw+18)
        s.box(x, y, cw, h, fill=col[1], stroke=col[0], sw=2, rx=12, shadow=True)
        s.vtext(x+cw/2, y+36, t, size=16, fill=col[0], weight="bold")
        s.rect(x+22, y+58, cw-44, 38, fill="#0f172a", stroke="none", rx=7)
        s.vtext(x+cw/2, y+77, code, size=12.5, fill="#e2e8f0", family=MONO, weight="bold")
        words=desc.split(); line=""; ly=y+128
        for wd in words:
            if len(line)+len(wd)>40:
                s.text(x+cw/2, ly, line, size=12.5, fill=INK); ly+=20; line=wd
            else: line=(line+" "+wd).strip()
        s.text(x+cw/2, ly, line, size=12.5, fill=INK)
    s.rect(50, y+h+18, 1062, 40, fill=OK[1], stroke=OK[0], sw=1.4, rx=9)
    s.vtext(581, y+h+38, "re-execução completa do pipeline  →  resultado bit-a-bit idêntico", size=13.5, fill=OK[0], weight="bold")
    save(s, "etl_fig08_idempotencia.svg")


# ---------------------------------------------------------------------
# FIG 09 — Matriz de Markov 6x6 (heatmap)
# ---------------------------------------------------------------------
def fig09():
    labels=["Galeão","S.Dumont","Rodov.","Rio Sul","N.América","Barra"]
    M=[[.55,.15,.05,.20,.03,.02],
       [.25,.45,.10,.08,.07,.05],
       [.06,.10,.50,.10,.06,.18],
       [.22,.08,.10,.45,.10,.05],
       [.05,.07,.06,.10,.52,.20],
       [.04,.05,.18,.05,.18,.50]]
    cell=110; x0=300; y0=150
    s=SVG(x0+6*cell+200, y0+6*cell+120)
    fig_title(s, 40, 44, "Matriz de Markov 6×6 (forma WIDE)",
              "P(devolução em j | retirada em i). Diagonal destacada; cada linha soma 1,0 (matriz estocástica)")
    # column headers
    for j,l in enumerate(labels):
        s.box(x0+j*cell, y0-46, cell-6, 40, fill=DIM[1], stroke=DIM[0], sw=1.2, rx=6, title=l, tsize=11.5, tcolor=DIM[0])
    s.text(x0-12, y0-22, "retirada ↓ / devolução →", size=11, fill=MUTE, anchor="end")
    def shade(v):
        # interpolate white -> blue
        t=min(v/0.6,1.0)
        r=int(219-(219-37)*t); g=int(234-(234-99)*t); b=int(254-(254-235)*t)
        return f"#{r:02x}{g:02x}{b:02x}"
    for i in range(6):
        s.box(40, y0+i*cell, x0-60, cell-6, fill=DIM[1], stroke=DIM[0], sw=1.2, rx=6, title=labels[i], tsize=12.5, tcolor=DIM[0])
        for j in range(6):
            v=M[i][j]; x=x0+j*cell; y=y0+i*cell
            diag = i==j
            s.rect(x, y, cell-6, cell-6, fill=shade(v), stroke=(SENT[0] if diag else LINE_LT), sw=(2.4 if diag else 1))
            tc = "#fff" if v>=0.42 else INK
            s.vtext(x+(cell-6)/2, y+(cell-6)/2, f"{v:.2f}", size=15, fill=tc, weight="bold" if diag else "normal")
        # row sum
        rs=sum(M[i])
        s.chip(x0+6*cell+10, y0+i*cell+ (cell-6)/2-16, 150, 32, f"Σ = {rs:.2f}", OK[1], OK[0], tcolor=OK[0], size=13, rx=8)
    save(s, "etl_fig09_markov_matriz.svg")


# ---------------------------------------------------------------------
# FIG 10 — Achados das revisoes adversariais
# ---------------------------------------------------------------------
def fig10():
    s=SVG(1160, 520)
    fig_title(s, 40, 44, "Achados das revisões adversariais (todos resolvidos)",
              "Duas revisões por um DBA sênior adversarial após cada fase: 29 achados identificados e endereçados")
    def panel(x, title, crit, mod, leve, total):
        s.container(x, 110, 500, 330, fill="#f8fafc", stroke=LINE_LT, sw=1.4, title=title)
        segs=[("Críticos", crit, WARN), ("Moderados", mod, SENT), ("Leves", leve, ("#ca8a04","#fef9c3"))]
        yy=170
        for name,cnt,col in segs:
            s.text(x+34, yy+22, name, size=14, fill=col[0], anchor="start", weight="bold")
            # blocks
            for k in range(cnt):
                s.rect(x+190+k*42, yy, 34, 34, fill=col[1], stroke=col[0], sw=1.6, rx=6)
                s.vtext(x+190+k*42+17, yy+17, "!", size=15, fill=col[0], weight="bold")
            s.text(x+466, yy+22, f"× {cnt}", size=14, fill=col[0], anchor="end", weight="bold")
            yy+=58
        s.rect(x+34, yy+6, 432, 44, fill=OK[1], stroke=OK[0], sw=1.5, rx=9)
        s.vtext(x+34+216, yy+28, f"✓  {total} achados — todos resolvidos", size=14, fill=OK[0], weight="bold")
    panel(50, "Revisão da fase dimensional", 4, 6, 5, 15)
    panel(610, "Revisão da fase ETL", 2, 6, 6, 14)
    save(s, "etl_fig10_achados.svg")


for f in (fig01, fig02, fig03, fig04, fig05, fig06, fig07, fig08, fig09, fig10):
    f()
print("ETL OK")
