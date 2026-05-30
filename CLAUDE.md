# CLAUDE.md — Política do projeto (Parte II)

Este repositório é a **Parte II da Avaliação 02 de Modelagem de Data Warehouse**: modelo dimensional estrela + processo ETL integrando 5 fontes OLTP em um DW PostgreSQL.

## Identificação do grupo

`docs/grupo.md` é a fonte canônica de nomes e DREs. Todo artefato (markdown, SQL, PDF) deve conter no cabeçalho a identificação. O enunciado é explícito: arquivos sem identificação são descartados.

## Fontes consumidas (5 esquemas)

1. **locadora-dw-parte1** — Parte 1 do próprio grupo (Gustavo + André), Postgres, tratada em pé de igualdade com as demais
2. **mae016-bdd-dwh-projeto1** — Breno, Hygor, João
3. **locadora-db** — Tadeu, Vicente
4. **BD-DW-26.1** — Ana Clara, Mariana, Matheus, Paulo, Pedro, Ryan
5. **bigdata** — modelagem ANSI normalizada

Excluídos (motivos em `docs/relatorio-etl.md`): `EEL890-big-data`, `EEL890---Big-Data`, `locadora-oltp`.

## Pipeline obrigatório

Qualquer trabalho técnico neste repo DEVE seguir a ordem abaixo. Nunca pule etapas.

1. **Fase dimensional (conceitual)** → delegar ao subagente `modelador-dimensional`
2. **Revisão da fase dimensional** → delegar ao subagente `revisor-adversarial`
3. **Humano aprova ou pede iteração**
4. **DDL staging + DW + seed sintético** → delegar ao subagente `engenheiro-etl`
5. **Scripts ETL (Extract → Transform → Load)** → delegar ao subagente `engenheiro-etl`
6. **Revisão dos ETLs** → delegar ao subagente `revisor-adversarial`
7. **Humano aprova ou pede iteração**
8. **Relatórios + Matriz Markov + Dicionário** → delegar ao subagente `engenheiro-etl`
9. **Consolidação final (PDFs + README)** → delegar ao subagente `documentador`

## Regras de roteamento

- Pedidos "modele estrela", "desenhe fato/dimensão", "qual o grão" → `modelador-dimensional`
- Pedidos "DDL", "ETL", "extract/transform/load", "seed", "relatório SQL", "Markov" → `engenheiro-etl`
- Pedidos "revise", "verifique", "tem problema", "quebra alguma coisa", "cenário adversarial" → `revisor-adversarial`
- Pedidos "gera o PDF", "prepara entrega", "monta o README" → `documentador`

## Quando NÃO usar subagentes

- Perguntas conceituais do humano ("o que é SCD-2?") — responda direto, não delegue.
- Correções pequenas de digitação ou formato — faça direto.
- Dúvidas sobre o enunciado — leia `docs/enunciado.md` e responda direto.

## Humano no loop

Após cada subagente terminar, pare e mostre o resultado ao humano. NÃO encadeie subagentes automaticamente sem aprovação entre eles. Exceção: `revisor-adversarial` pode ser chamado imediatamente após cada fase para acelerar.

## Artefatos canônicos

| Fase | Arquivo produzido | Produzido por |
|---|---|---|
| Dimensional | `dimensional/modelo-dimensional.md` + `dimensional/diagrama-estrela.md` | `modelador-dimensional` |
| DDL staging | `staging/01_schema_fontes.sql`, `staging/03_schema_staging.sql`, `staging/04_tabelas_de_para.sql` | `engenheiro-etl` |
| Seed sintético | `staging/02_seed_fontes.sql` | `engenheiro-etl` |
| DDL DW | `dw/01_schema_dw.sql`, `dw/02_dim_tempo_carga.sql` | `engenheiro-etl` |
| Extract | `etl/01_extract_*.sql` a `etl/05_extract_*.sql` | `engenheiro-etl` |
| Transform | `etl/06_transform.sql` | `engenheiro-etl` |
| Load | `etl/07_load_dimensoes.sql`, `etl/08_load_fatos.sql` | `engenheiro-etl` |
| Relatórios + Markov | `relatorios/01_*.sql` a `relatorios/05_matriz_markov.sql` | `engenheiro-etl` |
| Dicionário | `dicionario/dicionario-dimensional.md` | `engenheiro-etl` |
| Revisões | `docs/revisoes/revisao-*.md` | `revisor-adversarial` |
| PDFs | `docs/relatorio-dimensional.{md,pdf}`, `docs/relatorio-etl.{md,pdf}` | `documentador` |
| README | `README.md` na raiz | `documentador` |

## SGBD e convenções técnicas

- **PostgreSQL 16** como SGBD único.
- Cada fonte vive em um schema separado: `src_andre_gustavo`, `src_mae016`, `src_locadora_db`, `src_bd_dw_26_1`, `src_bigdata`. Staging em `staging`. DW em `dw`.
- DDLs originais em MySQL (`mae016`, `BD-DW-26.1`) são traduzidos para Postgres com sintaxe ANSI:1999+.
- Surrogate keys (`sk_*`) em todas as dimensões via `SERIAL` ou `GENERATED ALWAYS AS IDENTITY`.
- `dim_tempo` com smart-key inteiro `YYYYMMDD`.
- SCD tipo 1 (sobrescrita).

## Regras de commit

Depois de cada fase aprovada pelo humano:

```
git add .
git commit -m "feat({fase}): {resumo curto}"
```

## Referências bibliográficas de apoio

Colocadas em `docs/referencias/` quando necessário:

- Kimball, R. — *The Data Warehouse Toolkit*, 3ª ed.
- Elmasri & Navathe, 7ª ed. — caps. 29, 30 (DW, OLAP).
