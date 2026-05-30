<!--
Avaliação 02 — Modelagem de DW — Parte II
Grupo:
  - Gustavo Oliveira Pessanha da Silva (DRE 122051824)
  - André Vinícius Lobo Giron (DRE 122050404)
-->

# Folha de Rosto — Avaliação 02 (PARTE II)

**Disciplina:** Modelagem de Data Warehouse — EEL890 (UFRJ)
**Avaliação:** 02 — Parte II — Projeto de DW e ETL Integrado
**Tema:** Locadora de veículos — pátios compartilhados entre 6 empresas associadas

---

## Componentes do Grupo

| Nome completo | DRE |
|---|---|
| Gustavo Oliveira Pessanha da Silva | 122051824 |
| André Vinícius Lobo Giron | 122050404 |

---

## Postagem individual (preenchido pelo componente que posta esta folha)

| Campo | Conteúdo |
|---|---|
| Nome completo (de quem posta) | _______________________________________ |
| DRE | _______________________________________ |
| Data da postagem | _______________________________________ |

---

## Link do repositório GitHub

> **(preencher após `git push` final)**: `https://github.com/<usuario>/locadora-dw-parte2`

---

## Artefatos entregues

| Artefato | Caminho no repositório |
|---|---|
| Relatório do modelo dimensional (PDF) | `docs/relatorio-dimensional.pdf` |
| Relatório do modelo dimensional (ODF) | `docs/relatorio-dimensional.odt` |
| Relatório do processo ETL (PDF) | `docs/relatorio-etl.pdf` |
| Relatório do processo ETL (ODF) | `docs/relatorio-etl.odt` |
| Esquemas dos outros grupos (justificativa do ETL) | `docs/grupos-fonte/{mae016, locadora-db, bd-dw-26-1, bigdata}/` |
| Esquema da própria Parte 1 (referência) | `docs/grupos-fonte/locadora-dw-parte1/` |
| Scripts SQL — DDL das fontes em staging | `staging/01_schema_fontes.sql`, `staging/02_seed_fontes.sql` |
| Scripts SQL — DDL da staging area | `staging/03_schema_staging.sql`, `staging/04_tabelas_de_para.sql` |
| Scripts SQL — DDL do DW (esquema estrela) | `dw/01_schema_dw.sql`, `dw/02_dim_tempo_carga.sql` |
| Scripts SQL — Extração ETL | `etl/01_extract_*.sql` a `etl/05_extract_*.sql` |
| Scripts SQL — Transformação ETL | `etl/06_transform.sql` |
| Scripts SQL — Carga ETL | `etl/07_load_dimensoes.sql`, `etl/08_load_fatos.sql` |
| Scripts SQL — Relatórios Gerenciais (a–d) | `relatorios/01_*.sql` a `relatorios/04_*.sql` |
| Script SQL — Matriz de Markov | `relatorios/05_matriz_markov.sql` |
| Dicionário de dados do DW | `dicionario/dicionario-dimensional.md` |
