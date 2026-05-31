<!--
Avaliação 02 — Modelagem de DW — Parte II
Grupo:
  - Gustavo Oliveira Pessanha da Silva (DRE 122051824)
  - André Vinícius Lobo Giron (DRE 122050404)
-->

# Locadora de Veículos — Avaliação 02 Parte II (Data Warehouse Integrado)

Repositório da **Parte II** da Avaliação 02 da disciplina **Modelagem de Data Warehouse** (EEL890 — UFRJ). Escopo: projeto do **modelo dimensional estrela** e do **processo ETL** integrando **5 esquemas OLTP** (Parte I do próprio grupo + 4 esquemas de outros grupos da turma) em um Data Warehouse PostgreSQL único, com 4 relatórios gerenciais globais e matriz de Markov de movimentação da frota.

## Grupo

| Nome completo | DRE |
|---|---|
| Gustavo Oliveira Pessanha da Silva | 122051824 |
| André Vinícius Lobo Giron | 122050404 |

## Descrição do projeto

Cinco bases OLTP independentes — cada uma modelada por um grupo da turma para uma das seis locadoras associadas — convivem como schemas separados em um cluster PostgreSQL. O processo ETL extrai delas, conforma chaves heterogêneas em uma área de **staging**, e carrega o esquema estrela do **Data Warehouse**. A partir do DW geramos:

- **4 relatórios gerenciais** (a-d) exigidos pelo enunciado: controle de pátio, controle de locações, controle de reservas e ranking de grupos mais alugados cruzados com cidade de origem dos clientes.
- **Matriz estocástica 6×6** de movimentação entre pátios — insumo da análise de previsão de ocupação por cadeia de Markov.

O esquema estrela tem **3 fatos** (`fato_locacao` transação, `fato_reserva` transação, `fato_patio_diario` snapshot periódico no grão veículo × dia) e **6 dimensões conformadas** (`dim_tempo`, `dim_patio`, `dim_veiculo`, `dim_grupo`, `dim_cliente`, `dim_fonte`).

## Fontes consumidas

| # | Grupo | Diretório fonte | Schema Postgres alvo |
|---|---|---|---|
| 1 | Gustavo + André (própria Parte I) | `docs/grupos-fonte/locadora-dw-parte1/` | `src_andre_gustavo` |
| 2 | Breno, Hygor, João | `docs/grupos-fonte/mae016/` | `src_mae016` |
| 3 | Tadeu, Vicente | `docs/grupos-fonte/locadora-db/` | `src_locadora_db` |
| 4 | Ana Clara, Mariana, Matheus, Paulo, Pedro, Ryan | `docs/grupos-fonte/bd-dw-26-1/` | `src_bd_dw_26_1` |
| 5 | (modelagem ANSI normalizada) | `docs/grupos-fonte/bigdata/` | `src_bigdata` |

Grupos excluídos do projeto: `EEL890-big-data`, `EEL890---Big-Data`, `locadora-oltp`. Motivos técnicos detalhados em `docs/relatorio-etl.pdf` §4.

## Estrutura do repositório

```
locadora-dw-parte2/
├── README.md                       <- este arquivo
├── CLAUDE.md                       <- política do projeto e workflow de subagentes
├── .claude/agents/                 <- 4 subagentes (modelador-dimensional, engenheiro-etl, revisor-adversarial, documentador)
├── docs/
│   ├── enunciado.md                <- enunciado oficial da Parte II
│   ├── grupo.md                    <- nomes + DREs canônicos
│   ├── folha-de-rosto.{md,pdf,odt} <- folha de rosto da entrega
│   ├── relatorio-dimensional.{md,pdf,odt}  <- Relatório 1: modelo estrela (ilustrado, 9 figuras)
│   ├── relatorio-etl.{md,pdf,odt}          <- Relatório 2: processo ETL (ilustrado, 10 figuras)
│   ├── estilo-relatorio.css        <- folha de estilo dos PDFs (WeasyPrint)
│   ├── build.sh                    <- build reprodutível: figuras → PDF + ODT
│   ├── figuras/                    <- 19 figuras (geradores Python + SVG + PNG)
│   ├── grupos-fonte/               <- cópia auto-contida das 5 fontes
│   └── revisoes/                   <- revisões adversariais por fase
├── dimensional/                    <- modelo dimensional conceitual (modelo-dimensional.md + diagrama-estrela.md)
├── staging/                        <- DDL das 5 fontes em src_*, da staging, e tabelas de de-para
├── dw/                             <- DDL do esquema estrela + carga de dim_tempo
├── etl/                            <- Extract (5 fontes) + Transform + Load (dimensoes, fatos)
├── relatorios/                     <- 4 relatórios gerenciais + matriz de Markov
└── dicionario/                     <- dicionário do esquema estrela
```

## SGBD e convenções

PostgreSQL 16 como SGBD único. Os DDLs de MySQL (`mae016`, `bd_dw_26_1`) foram traduzidos para Postgres mantendo sintaxe ANSI SQL:1999+ (conversões mecânicas: `AUTO_INCREMENT` → `GENERATED ALWAYS AS IDENTITY`, `TINYINT(1)` → `BOOLEAN`, `DATETIME` → `TIMESTAMP`, `ENUM` → `VARCHAR + CHECK`). Todas as dimensões são SCD tipo 1; `dim_tempo` usa smart-key inteira `YYYYMMDD`.

## Como executar end-to-end

Pipeline completo (PostgreSQL 16 instalado e `psql` no PATH):

```bash
# 1. Criar a base
createdb locadora_dw_parte2

# 2. DDL das 5 fontes + seed sintético + DDL da staging + de-paras
psql -d locadora_dw_parte2 -f staging/01_schema_fontes.sql
psql -d locadora_dw_parte2 -f staging/02_seed_fontes.sql
psql -d locadora_dw_parte2 -f staging/03_schema_staging.sql
psql -d locadora_dw_parte2 -f staging/04_tabelas_de_para.sql

# 3. DDL do DW + carga de dim_tempo
psql -d locadora_dw_parte2 -f dw/01_schema_dw.sql
psql -d locadora_dw_parte2 -f dw/02_dim_tempo_carga.sql

# 4. Extract (5 fontes, em qualquer ordem entre si)
psql -d locadora_dw_parte2 -f etl/01_extract_andre_gustavo.sql
psql -d locadora_dw_parte2 -f etl/02_extract_mae016.sql
psql -d locadora_dw_parte2 -f etl/03_extract_locadora_db.sql
psql -d locadora_dw_parte2 -f etl/04_extract_bd_dw.sql
psql -d locadora_dw_parte2 -f etl/05_extract_bigdata.sql

# 5. Transform + Load
psql -d locadora_dw_parte2 -f etl/06_transform.sql
psql -d locadora_dw_parte2 -f etl/07_load_dimensoes.sql
psql -d locadora_dw_parte2 -f etl/08_load_fatos.sql

# 6. Relatórios + Matriz de Markov (independentes; qualquer ordem)
psql -d locadora_dw_parte2 -f relatorios/01_controle_patio.sql
psql -d locadora_dw_parte2 -f relatorios/02_controle_locacoes.sql
psql -d locadora_dw_parte2 -f relatorios/03_controle_reservas.sql
psql -d locadora_dw_parte2 -f relatorios/04_grupos_mais_alugados.sql
psql -d locadora_dw_parte2 -f relatorios/05_matriz_markov.sql
```

Total: 14 arquivos SQL executados em sequência. O pipeline é **idempotente** — re-execução produz resultado bit-a-bit idêntico (via `DROP SCHEMA ... CASCADE`, `TRUNCATE ... RESTART IDENTITY`, `ON CONFLICT DO UPDATE` e `DELETE WHERE sk_fonte = N`).

