<!--
Avaliação 02 — Modelagem de DW — Parte II
Grupo:
  - Gustavo Oliveira Pessanha da Silva (DRE 122051824)
  - André Vinícius Lobo Giron (DRE 122050404)
-->

# Dicionário de Dados — Data Warehouse Integrado (Parte II)

**Trabalho:** Avaliação 02 — Parte II — Modelagem de Data Warehouse
**Grupo:**
- Gustavo Oliveira Pessanha da Silva — DRE 122051824
- André Vinícius Lobo Giron — DRE 122050404

**SGBD-alvo:** PostgreSQL 16
**Schema:** `dw`
**Artefato fonte do DDL:** `dw/01_schema_dw.sql`
**Artefato fonte da carga de `dim_tempo`:** `dw/02_dim_tempo_carga.sql`
**Modelo conceitual de referência:** `dimensional/modelo-dimensional.md`

---

## Convenções

- **PK** = chave primária; **FK** = chave estrangeira; **U** = chave única (`UNIQUE`); **N** = aceita `NULL`; **D** = possui `DEFAULT`.
- **`sk_*`** = *surrogate key*; emitidas via `GENERATED ALWAYS AS IDENTITY`, exceto `dim_tempo.sk_tempo` (*smart-key* inteira `YYYYMMDD`) e `dim_fonte.sk_fonte` (`SMALLINT` estável, atribuída manualmente).
- **Sentinelas** seguem a decisão D-10 do modelo dimensional: cada dimensão pequena tem uma linha-âncora para registros sem casamento (`sk_*=0` em `dim_fonte`, `dim_patio`, `dim_grupo`; `sk_tempo = 19000101` em `dim_tempo`). Detalhamos a sentinela em "Notas" de cada tabela.
- **SCD:** todas as dimensões são **tipo 1** (sobrescrita) conforme decisão D-04.
- **Domínios enumerados** são preservados via `CHECK IN (...)`; valores normalizados em UPPER_SNAKE quando a coluna vem de fonte textual diversa.
- **Tipos:** mantidos exatamente como aparecem no DDL canônico (`INTEGER`, `SMALLINT`, `BIGINT`, `VARCHAR(N)`, `TEXT`, `NUMERIC(P,S)`, `BOOLEAN`, `DATE`, `TIMESTAMP`).
- **Idempotência:** o script `dw/01_schema_dw.sql` faz `DROP SCHEMA IF EXISTS dw CASCADE; CREATE SCHEMA dw;` antes de qualquer DDL — reexecução nunca duplica objeto.
- **Role-playing:** dimensões `dim_tempo` e `dim_patio` são referenciadas múltiplas vezes em um mesmo fato; o papel é evidenciado no sufixo da FK (`sk_tempo_retirada_real`, `sk_patio_devolucao`).

---

## 1. Dimensões

### 1.1 `dim_tempo`

- **Descrição:** Dimensão tempo conformada, grão **dia**, compartilhada pelos três fatos. Pré-populada via função PL/pgSQL `popular_dim_tempo(data_inicio, data_fim)` definida em `dw/02_dim_tempo_carga.sql`.
- **Fonte:** *seed* PL/pgSQL (não há tabela OLTP equivalente).
- **Período coberto:** 2020-01-01 a 2030-12-31 (11 anos = 4 018 linhas com bissextos de 2020, 2024 e 2028) + 1 linha sentinela.
- **Cardinalidade:** **4 019 linhas** (4 018 datas + sentinela).
- **SCD:** não se aplica (dimensão estática derivada do calendário).

| Coluna | Tipo | Nulo? | Default | Domínio | Descrição |
|---|---|---|---|---|---|
| sk_tempo | INTEGER | Não | — | *Smart-key* `YYYYMMDD` positiva para datas válidas; sentinela = `-1` ("DATA DESCONHECIDA") conforme efetivamente inserida pelo *seed* `dw/02_dim_tempo_carga.sql` e pelo `COMMENT` do DDL. | Chave primária inteira derivada da data (`AAAAMMDD`). Permite `WHERE sk_tempo BETWEEN 20250101 AND 20251231` sem JOIN à dimensão. |
| data_completa | DATE | Sim | — | Data válida do calendário gregoriano ou `NULL` para a sentinela. | Data calendário em formato `DATE`; `NULL` apenas na linha sentinela. |
| ano | INTEGER | Não | — | 1900 (sentinela) ou 2020..2030 (carga padrão). | Ano gregoriano (`EXTRACT(YEAR FROM data_completa)`). |
| semestre | INTEGER | Não | — | {1, 2}. | Semestre do ano (1 = jan-jun; 2 = jul-dez). |
| trimestre | INTEGER | Não | — | {1, 2, 3, 4}. | Trimestre do ano (`EXTRACT(QUARTER FROM data_completa)`). |
| bimestre | INTEGER | Não | — | {1, 2, 3, 4, 5, 6}. | Bimestre do ano calculado por `((mes-1)/2)+1`. |
| mes_numero | INTEGER | Não | — | {1..12}. | Número do mês. |
| mes_nome | VARCHAR(20) | Não | — | Nome do mês em PT-BR (`Janeiro` .. `Dezembro`); `DESCONHECIDO` na sentinela. | Nome do mês escrito por extenso em português. |
| mes_abreviado | VARCHAR(5) | Não | — | Abreviação PT-BR de 3 letras (`Jan` .. `Dez`); `N/A` na sentinela. | Abreviação do mês em português. |
| semana_ano | INTEGER | Não | — | {1..53}. | Semana ISO do ano (`EXTRACT(WEEK FROM data_completa)`). |
| dia_mes | INTEGER | Não | — | {1..31}. | Dia do mês. |
| dia_ano | INTEGER | Não | — | {1..366}. | Dia juliano do ano (`EXTRACT(DOY FROM data_completa)`). |
| dia_semana_numero | INTEGER | Não | — | {0..6} (0 = Domingo, 6 = Sábado, padrão `EXTRACT(DOW)`). | Número do dia da semana. |
| dia_semana_nome | VARCHAR(20) | Não | — | `Domingo` .. `Sabado`; `DESCONHECIDO` na sentinela. | Nome do dia da semana em PT-BR. |
| eh_fim_de_semana | BOOLEAN | Não | — | `TRUE` quando `dia_semana_numero IN (0, 6)`. | Indicador booleano de fim de semana. |
| eh_feriado_nacional | BOOLEAN | Não | FALSE | `TRUE` para os 8 feriados nacionais fixos brasileiros (vide notas). | Indicador de feriado nacional brasileiro de data fixa. |
| descricao_periodo | VARCHAR(40) | Sim | — | Formato `Q{trimestre}/{ano}` (ex.: `Q2/2025`); `DATA DESCONHECIDA` na sentinela. | Rótulo legível para drill-down trimestre/ano. |

- **Chave primária:** `sk_tempo`.
- **Chaves estrangeiras:** nenhuma.
- **Chaves únicas adicionais:** nenhuma além da PK.
- **Checks declarados no DDL:** nenhum (domínios garantidos pela função de carga).
- **Índices declarados:** nenhum além do índice implícito da PK.
- **Sentinela:** `sk_tempo = 19000101`, `data_completa = DATE '1900-01-01'`, `ano = 1900`, `mes_nome = 'DESCONHECIDO'`, `mes_abreviado = 'N/A'`, `dia_semana_nome = 'DESCONHECIDO'`, `descricao_periodo = 'DATA DESCONHECIDA'` — inserida em `dw/02_dim_tempo_carga.sql` com `ON CONFLICT (sk_tempo) DO NOTHING`. As FKs de fato que referenciam "dado perdido" (não confundir com "evento ainda não ocorrido", que é NULL) devem apontar para `sk_tempo = 19000101`. Padrão Kimball cap. 6: smart-key reservada para semântica de sentinela.
- **Notas:**
  - Carga executa `popular_dim_tempo(DATE '2020-01-01', DATE '2030-12-31')`, gerando uma linha por dia do calendário.
  - O `UPDATE` final do script marca `eh_feriado_nacional = TRUE` para Confraternização Universal (01/01), Tiradentes (21/04), Dia do Trabalho (01/05), Independência (07/09), N. S. Aparecida (12/10), Finados (02/11), Proclamação da República (15/11) e Natal (25/12). Feriados móveis (Carnaval, Sexta-Feira da Paixão, Corpus Christi) não são marcados.
  - Função idempotente: ambos os `INSERT` (sentinela e *loop* diário) usam `ON CONFLICT (sk_tempo) DO NOTHING`.
  - `COMMENT ON TABLE`: "Dimensao tempo conformada (grao: dia). Smart-key YYYYMMDD. Sentinela sk_tempo=19000101 = DATA_DESCONHECIDA."
  - `COMMENT ON COLUMN sk_tempo`: "Smart-key inteira YYYYMMDD; 19000101 reservado para data desconhecida/nao aplicavel."

---

### 1.2 `dim_patio`

- **Descrição:** Dimensão pátio conformada. Cobre os seis pátios canônicos da associação de locadoras (Galeão, Santos Dumont, Rodoviária do Rio, Shopping Rio Sul, Shopping Nova América, Barra Shopping) mais uma linha sentinela.
- **Fonte:** consolidada pelo ETL a partir do *de-para* `staging.depara_patio`.
- **Cardinalidade:** **7 linhas** (6 pátios canônicos + 1 sentinela `PATIO_DESCONHECIDO`).
- **SCD:** tipo 1.

| Coluna | Tipo | Nulo? | Default | Domínio | Descrição |
|---|---|---|---|---|---|
| sk_patio | INTEGER | Não | IDENTITY | Inteiro positivo gerado por `GENERATED ALWAYS AS IDENTITY`; `0` reservado para a sentinela (inserida com `OVERRIDING SYSTEM VALUE`). | Chave subrogada do pátio. |
| nome_canonico | VARCHAR(80) | Não | — | Identificador canônico em UPPER_SNAKE (`AEROPORTO_GALEAO`, `AEROPORTO_SANTOS_DUMONT`, `RODOVIARIA_RIO`, `SHOPPING_RIO_SUL`, `SHOPPING_NOVA_AMERICA`, `SHOPPING_BARRA`, `PATIO_DESCONHECIDO`); `UNIQUE`. | Chave natural conformada do pátio — usada pelo ETL para *lookup*. |
| apelido | VARCHAR(40) | Não | — | Rótulo curto legível (`Galeão`, `Santos Dumont`, `Rodoviária`, `Rio Sul`, `Nova América`, `Barra`, `Desconhecido`). | Apelido amigável para uso em relatórios. |
| tipo_local | VARCHAR(20) | Não | — | `CHECK IN ('AEROPORTO','RODOVIARIA','SHOPPING','DESCONHECIDO')`. | Classificação do tipo de equipamento urbano onde o pátio está instalado. |
| cidade | VARCHAR(80) | Não | — | Texto livre (esperado: cidade brasileira); `N/A` na sentinela. | Cidade onde o pátio está localizado. |
| endereco_descritivo | VARCHAR(200) | Sim | — | Texto livre. | Endereço descritivo opcional do pátio. |
| capacidade_vagas_referencia | INTEGER | Sim | — | Inteiro não negativo esperado. | Capacidade de vagas declarada pelo cadastro (referência, não histórica). |
| flag_funciona_24h | BOOLEAN | Não | FALSE | {TRUE, FALSE}. | Indicador de operação 24 horas. |
| codigo_fonte_dona | VARCHAR(30) | Sim | — | Valor `codigo_fonte` correspondente em `dim_fonte` (FK lógica, não declarada); `NULL` para Barra Shopping (sexta empresa sem sistema-fonte, P-07). | Empresa associada dona deste pátio — habilita o cálculo de `fato_patio_diario.flag_frota_propria_no_patio`. |

- **Chave primária:** `sk_patio`.
- **Chaves estrangeiras:** nenhuma declarada no DDL. `codigo_fonte_dona` é FK **lógica** para `dim_fonte.codigo_fonte` (não declarada para evitar exigir `UNIQUE` em coluna de cadastro mutável).
- **Chaves únicas:** `nome_canonico` (`UNIQUE`).
- **Checks declarados:** `CHECK (tipo_local IN ('AEROPORTO','RODOVIARIA','SHOPPING','DESCONHECIDO'))`.
- **Índices declarados:** índice implícito da PK; índice implícito do `UNIQUE (nome_canonico)`.
- **Sentinela:** `sk_patio = 0`, `nome_canonico = 'PATIO_DESCONHECIDO'`, `apelido = 'Desconhecido'`, `tipo_local = 'DESCONHECIDO'`, `cidade = 'N/A'`, demais colunas `NULL`/`FALSE`, inserida com `OVERRIDING SYSTEM VALUE`.
- **Notas:**
  - `COMMENT ON TABLE`: "Dimensao patio conformada. 6 patios canonicos + 1 sentinela (PATIO_DESCONHECIDO)."
  - `COMMENT ON COLUMN nome_canonico`: "Chave natural conformada (UNIQUE) — usada pelo ETL para lookup."
  - `COMMENT ON COLUMN codigo_fonte_dona`: "Empresa associada dona deste patio (foreign key logico para dim_fonte.codigo_fonte). Habilita calculo de fato_patio_diario.flag_frota_propria_no_patio. NULL para Barra Shopping (sexta empresa sem sistema-fonte, P-07)."

---

### 1.3 `dim_veiculo`

- **Descrição:** Dimensão veículo conformada, com granularidade de **uma linha por placa por fonte**. Sem dedup *cross-fonte* (decisão D-03).
- **Fonte:** `staging.stg_veiculo`, alimentada pelos cinco scripts `etl/0X_extract_*.sql`.
- **Cardinalidade esperada:** ordem de 10² a 10³ linhas (cinco fontes × ~50–500 veículos cada).
- **SCD:** tipo 1.

| Coluna | Tipo | Nulo? | Default | Domínio | Descrição |
|---|---|---|---|---|---|
| sk_veiculo | INTEGER | Não | IDENTITY | Inteiro positivo gerado por `GENERATED ALWAYS AS IDENTITY`. | Chave subrogada do veículo. |
| sk_fonte_origem | SMALLINT | Não | — | {1, 2, 3, 4, 5} (referencia `dim_fonte.sk_fonte`). FK lógica — não declarada para evitar bloquear *bulk-load* iterativo. | Fonte de origem do registro do veículo. |
| id_natural_origem | TEXT | Não | — | Texto, geralmente PK numérica convertida (`id_veiculo`, `Id_veiculo`, `IDVeiculo`). | Identificador natural do veículo no sistema-fonte. |
| placa | VARCHAR(20) | Sim | — | Placa Mercosul ou antiga (sem máscara obrigatória). | Placa do veículo. |
| chassi | VARCHAR(50) | Sim | — | Chassi alfanumérico (17 chars típicos). | Chassi (VIN). |
| renavam | VARCHAR(20) | Sim | — | RENAVAM numérico (11 chars típicos). | Código RENAVAM. |
| marca | VARCHAR(60) | Sim | — | Texto (`FIAT`, `VOLKSWAGEN`, ...) — normalizado em UPPER no Transform. | Marca/montadora do veículo. |
| modelo | VARCHAR(60) | Sim | — | Texto (`ARGO`, `GOL`, ...). | Modelo. |
| cor | VARCHAR(30) | Sim | — | Texto (`PRETO`, `BRANCO`, ...). | Cor predominante. |
| ano_fabricacao | INTEGER | Sim | — | Inteiro entre 1900 e ano corrente esperado. | Ano de fabricação. |
| mecanizacao | VARCHAR(20) | Não | `'DESCONHECIDA'` | `CHECK IN ('MANUAL','AUTOMATICA','DESCONHECIDA')`. | Tipo de câmbio. |
| tem_ar_condicionado | BOOLEAN | Sim | — | {TRUE, FALSE}. | Indicador de ar-condicionado. |
| tem_adaptacao_cadeirante | BOOLEAN | Sim | — | {TRUE, FALSE}. | Indicador de adaptação para cadeirante. |
| capacidade_pessoas | INTEGER | Sim | — | Inteiro positivo esperado. | Lotação de passageiros (somando motorista). |
| capacidade_porta_malas | INTEGER | Sim | — | Inteiro positivo esperado (litros). | Volume útil do porta-malas. |
| categoria_dimensoes | VARCHAR(40) | Sim | — | Texto livre (`COMPACTO`, `SUV MÉDIO`, etc.). | Classificação de tamanho física quando exposta pela fonte. |
| situacao_atual | VARCHAR(20) | Não | `'DESCONHECIDA'` | `CHECK IN ('DISPONIVEL','ALUGADO','MANUTENCAO','BAIXADO','RESERVADO','DESCONHECIDA')`. | Situação atual do veículo (snapshot — o histórico vive em `fato_patio_diario`). |

- **Chave primária:** `sk_veiculo`.
- **Chaves estrangeiras:** nenhuma declarada no DDL. `sk_fonte_origem` é FK **lógica** para `dim_fonte.sk_fonte`.
- **Chaves únicas:** `CONSTRAINT uq_dim_veiculo_origem UNIQUE (sk_fonte_origem, id_natural_origem)`.
- **Checks declarados:**
  - `CHECK (mecanizacao IN ('MANUAL','AUTOMATICA','DESCONHECIDA'))`
  - `CHECK (situacao_atual IN ('DISPONIVEL','ALUGADO','MANUTENCAO','BAIXADO','RESERVADO','DESCONHECIDA'))`
- **Índices declarados:** índice implícito da PK; índice implícito do `UNIQUE (sk_fonte_origem, id_natural_origem)`.
- **Sentinela:** não há sentinela específica desta dimensão (o modelo não declara `sk_veiculo = 0`). Veículos sem casamento devem ser descartados com `RAISE NOTICE` na carga do fato.
- **Notas:**
  - `COMMENT ON TABLE`: "Dimensao veiculo conformada. Chave natural composta (sk_fonte_origem, id_natural_origem) — sem dedup cross-fonte (D-03 do modelo)."
  - O JOIN com `dim_grupo` é feito via `dim_veiculo.id_natural_origem` → `stg_veiculo.grupo_id_natural` → `staging.depara_grupo.nome_canonico` → `dim_grupo.nome_grupo_normalizado` na fase de Load de fatos.

---

### 1.4 `dim_grupo`

- **Descrição:** Dimensão grupo/categoria de veículos conformada. Concentra atributos comerciais (classe de luxo, valor de diária de referência, franquia de km).
- **Fonte:** `staging.depara_grupo`, alimentado por *seed* + pelos extracts.
- **Cardinalidade esperada:** ordem de 10¹ linhas (6 a 15 grupos distintos após normalização) + 1 sentinela.
- **SCD:** tipo 1 (preço histórico congelado em `fato_locacao.valor_diaria_aplicada`).

| Coluna | Tipo | Nulo? | Default | Domínio | Descrição |
|---|---|---|---|---|---|
| sk_grupo | INTEGER | Não | IDENTITY | Inteiro positivo gerado por `GENERATED ALWAYS AS IDENTITY`; `0` reservado para a sentinela `GRUPO_NAO_INFORMADO` (inserida com `OVERRIDING SYSTEM VALUE`). | Chave subrogada do grupo. |
| nome_grupo_normalizado | VARCHAR(40) | Não | — | UPPER_SNAKE esperado (`ECONOMICO`, `COMPACTO`, `INTERMEDIARIO`, `SEDAN`, `SUV`, `UTILITARIO`, `LUXO`, `PREMIUM`, `MINIVAN`, `GRUPO_NAO_INFORMADO`); `UNIQUE`. | Chave natural conformada do grupo. |
| codigo_curto | VARCHAR(10) | Sim | — | Letras curtas (`A`, `B`, `C`, ...) quando a fonte expõe. | Código curto comercial. |
| classe_luxo | VARCHAR(20) | Não | `'DESCONHECIDA'` | `CHECK IN ('LUXO','INTERMEDIARIO','ECONOMICO','DESCONHECIDA')`. | Classe de luxo derivada/normalizada. |
| valor_diaria_referencia | NUMERIC(10,2) | Sim | — | Não negativo esperado. | Média aritmética simples das diárias expostas pelas 4 fontes que têm preço (LEVE-05). |
| franquia_km_diaria_referencia | INTEGER | Sim | — | Não negativo esperado (km). | Franquia de quilometragem diária de referência. |
| descricao | VARCHAR(300) | Sim | — | Texto livre. | Descrição textual proveniente da fonte mais completa. |

- **Chave primária:** `sk_grupo`.
- **Chaves estrangeiras:** nenhuma.
- **Chaves únicas:** `nome_grupo_normalizado` (`UNIQUE`).
- **Checks declarados:** `CHECK (classe_luxo IN ('LUXO','INTERMEDIARIO','ECONOMICO','DESCONHECIDA'))`.
- **Índices declarados:** índice implícito da PK; índice implícito do `UNIQUE (nome_grupo_normalizado)`.
- **Sentinela:** `sk_grupo = 0`, `nome_grupo_normalizado = 'GRUPO_NAO_INFORMADO'`, `classe_luxo = 'DESCONHECIDA'`, demais colunas `NULL`. Destino das reservas da fonte `bigdata` que não modela `IDCategoria` em `Reserva` (CRÍTICO-04, P-10).
- **Notas:**
  - `COMMENT ON TABLE`: "Dimensao grupo/categoria conformada. nome_grupo_normalizado eh a chave natural."
  - O preço histórico aplicado em cada locação fica em `fato_locacao.valor_diaria_aplicada`; `valor_diaria_referencia` é apenas a tarifa-âncora atual da dimensão.

---

### 1.5 `dim_cliente`

- **Descrição:** Dimensão cliente conformada, com granularidade de **uma linha por cliente por fonte**. Sem dedup *cross-fonte* por CPF/CNPJ (decisão D-03).
- **Fonte:** `staging.stg_cliente`, alimentada pelos cinco scripts de Extract.
- **Cardinalidade esperada:** ordem de 10³ a 10⁴ linhas.
- **SCD:** tipo 1.

| Coluna | Tipo | Nulo? | Default | Domínio | Descrição |
|---|---|---|---|---|---|
| sk_cliente | INTEGER | Não | IDENTITY | Inteiro positivo gerado por `GENERATED ALWAYS AS IDENTITY`. | Chave subrogada do cliente. |
| sk_fonte_origem | SMALLINT | Não | — | {1..5} — FK lógica para `dim_fonte.sk_fonte`. | Fonte de origem do cadastro. |
| id_natural_origem | TEXT | Não | — | Texto (PK numérica convertida ou identificador unificado para `bigdata`, conforme MOD-03). | Identificador natural do cliente na fonte. |
| tipo_pessoa | VARCHAR(2) | Não | `'PF'` | `CHECK IN ('PF','PJ')`. | Discriminador PF/PJ. |
| nome | VARCHAR(200) | Não | — | Texto livre. | Nome (PF) ou razão social (PJ). |
| nome_fantasia | VARCHAR(200) | Sim | — | Texto livre. | Nome fantasia (apenas PJ; `NULL` para PF). |
| cidade_origem | VARCHAR(80) | Não | `'DESCONHECIDA'` | Texto livre normalizado em UPPER; `'DESCONHECIDA'` quando a fonte não expõe (§5.3 do modelo). | Cidade declarada de origem do cliente — eixo central dos relatórios (c) e (d). |
| uf_origem | VARCHAR(2) | Sim | — | UF brasileira (`RJ`, `SP`, ...) ou `'XX'` quando ausente. | UF de origem (quando exposta pela fonte). |
| email | VARCHAR(200) | Sim | — | E-mail. | E-mail principal (quando exposto). |
| telefone | VARCHAR(40) | Sim | — | Telefone com ou sem máscara. | Telefone principal (quando exposto). |
| cpf_normalizado | VARCHAR(11) | Sim | — | Dígitos do CPF sem máscara (11 dígitos). | CPF — apenas PF; **não** usado para dedup *cross-fonte*. |
| cnpj_normalizado | VARCHAR(14) | Sim | — | Dígitos do CNPJ sem máscara (14 dígitos). | CNPJ — apenas PJ; **não** usado para dedup *cross-fonte*. |
| flag_eh_pessoa_juridica | BOOLEAN | Não | FALSE | {TRUE, FALSE}. | `TRUE` quando `tipo_pessoa = 'PJ'`. Substitui a antiga `flag_tem_condutor_associado` (LEVE-01). |

- **Chave primária:** `sk_cliente`.
- **Chaves estrangeiras:** nenhuma declarada no DDL. `sk_fonte_origem` é FK lógica para `dim_fonte.sk_fonte`.
- **Chaves únicas:** `CONSTRAINT uq_dim_cliente_origem UNIQUE (sk_fonte_origem, id_natural_origem)`.
- **Checks declarados:** `CHECK (tipo_pessoa IN ('PF','PJ'))`.
- **Índices declarados:** índice implícito da PK; índice implícito do `UNIQUE (sk_fonte_origem, id_natural_origem)`.
- **Sentinela:** não há sentinela específica desta dimensão.
- **Notas:**
  - `COMMENT ON TABLE`: "Dimensao cliente conformada. Chave natural composta — sem dedup cross-fonte (D-03 do modelo)."
  - `COMMENT ON COLUMN cidade_origem`: "Default DESCONHECIDA quando a fonte nao expoe (vide §5.3 do modelo). Sem dedup cross-fonte."
  - `COMMENT ON COLUMN flag_eh_pessoa_juridica`: "TRUE quando tipo_pessoa=PJ. Substitui antiga flag_tem_condutor_associado (LEVE-01 da revisao)."

---

### 1.6 `dim_fonte`

- **Descrição:** Dimensão fonte/empresa associada — também age como *audit dimension* (decisão D-06). PK explícita (não IDENTITY) por ser cadastro fixo conhecido a priori.
- **Fonte:** carga manual em `etl/07_load_dimensoes.sql` (5 linhas reais + 1 sentinela já inserida no próprio `dw/01_schema_dw.sql`).
- **Cardinalidade:** exatamente **6 linhas** (5 fontes reais + 1 sentinela).
- **SCD:** tipo 1 (na prática, estática).

| Coluna | Tipo | Nulo? | Default | Domínio | Descrição |
|---|---|---|---|---|---|
| sk_fonte | SMALLINT | Não | — | {0..5} — `0` = sentinela; `1` = `andre_gustavo`; `2` = `mae016`; `3` = `locadora_db`; `4` = `bd_dw_26_1`; `5` = `bigdata`. | Chave subrogada estável da fonte. Atribuída manualmente para garantir mapeamento determinístico nos extracts. |
| codigo_fonte | VARCHAR(30) | Não | — | *Slug* curto em snake_case (`andre_gustavo`, `mae016`, `locadora_db`, `bd_dw_26_1`, `bigdata`, `FONTE_DESCONHECIDA`); `UNIQUE`. | Chave natural conformada da fonte. |
| nome_empresa_associada | VARCHAR(100) | Não | — | Texto livre legível. | Rótulo legível da empresa associada (ex.: "Grupo Gustavo+André"). |
| sgbd_original | VARCHAR(20) | Não | — | `POSTGRES` \| `MYSQL` \| `ANSI` \| `N/A`. | SGBD original da fonte OLTP antes da tradução. |
| descricao | VARCHAR(300) | Sim | — | Texto livre. | Descrição contextual (autores do grupo-fonte, observações). |

- **Chave primária:** `sk_fonte`.
- **Chaves estrangeiras:** nenhuma.
- **Chaves únicas:** `codigo_fonte` (`UNIQUE`).
- **Checks declarados:** nenhum (domínio garantido pelo controle de carga).
- **Índices declarados:** índice implícito da PK; índice implícito do `UNIQUE (codigo_fonte)`.
- **Sentinela:** `sk_fonte = 0`, `codigo_fonte = 'FONTE_DESCONHECIDA'`, `nome_empresa_associada = 'Fonte desconhecida (sentinela)'`, `sgbd_original = 'N/A'`, `descricao = 'Linha sentinela para registros sem fonte identificada.'` — inserida diretamente em `dw/01_schema_dw.sql`.
- **Notas:**
  - `COMMENT ON TABLE`: "Dimensao fonte conformada. 5 fontes + 1 sentinela (sk_fonte=0). sk_fonte explicita (nao IDENTITY) por ser estavel pela convencao do projeto."

---

## 2. Fatos

### 2.1 `fato_locacao`

- **Descrição:** Tabela de fato de **transação**: uma linha por contrato de locação registrado em qualquer das cinco fontes-origem.
- **Grão:** uma linha por locação (contrato).
- **Tipo:** *transaction fact table* (Kimball cap. 1).
- **Fonte:** `staging.stg_locacao` após Transform — carregada em `etl/08_load_fatos.sql`.
- **Cardinalidade esperada (com *seed* sintético):** ~288 linhas (60 locações × 5 fontes, descontando exceções).

| Coluna | Tipo | Nulo? | Default | Domínio | Descrição |
|---|---|---|---|---|---|
| sk_locacao | INTEGER | Não | IDENTITY | Inteiro positivo gerado por `GENERATED ALWAYS AS IDENTITY`. | Chave subrogada da locação. |
| sk_tempo_retirada_real | INTEGER | Não | — | Referencia `dim_tempo.sk_tempo` (`YYYYMMDD` válido ou sentinela `-1`). | FK *role-playing* `dim_tempo AS dim_tempo_retirada_real`. |
| sk_tempo_devolucao_real | INTEGER | Sim | — | Referencia `dim_tempo.sk_tempo`; `NULL` quando a locação está `EM_ANDAMENTO`. | FK *role-playing* `dim_tempo AS dim_tempo_devolucao_real`. MOD-02: `NULL` preserva "ainda não ocorreu"; sentinela `-1` reservada para "dado perdido" (vide §1.1 — divergência vs `19000101` do modelo). |
| sk_tempo_devolucao_prevista | INTEGER | Não | — | Referencia `dim_tempo.sk_tempo`. | FK *role-playing* `dim_tempo AS dim_tempo_devolucao_prevista`. |
| sk_patio_retirada | INTEGER | Não | — | Referencia `dim_patio.sk_patio`. | FK *role-playing* `dim_patio AS dim_patio_retirada`. |
| sk_patio_devolucao | INTEGER | Sim | — | Referencia `dim_patio.sk_patio`; `NULL` quando a locação está `EM_ANDAMENTO`. | FK *role-playing* `dim_patio AS dim_patio_devolucao`. MOD-05: SEMPRE o REAL quando a fonte distingue previsto vs realizado. Input da matriz de Markov. |
| sk_veiculo | INTEGER | Não | — | Referencia `dim_veiculo.sk_veiculo`. | FK do veículo locado. |
| sk_grupo | INTEGER | Não | — | Referencia `dim_grupo.sk_grupo`. | FK do grupo/categoria contratado. |
| sk_cliente | INTEGER | Não | — | Referencia `dim_cliente.sk_cliente`. | FK do cliente contratante. |
| sk_fonte | SMALLINT | Não | — | Referencia `dim_fonte.sk_fonte`; esperado ∈ {1..5}. | FK da fonte/empresa associada que originou o registro. |
| id_locacao_origem | BIGINT | Não | — | PK numérica original da fonte. | *Degenerate dimension* principal — habilita auditoria reversa em 5/5 fontes (MOD-04). |
| numero_contrato_fonte | VARCHAR(50) | Sim | — | Texto livre (`CT-000001`, etc.). | *Degenerate dimension* secundária — somente `andre_gustavo` expõe; `NULL` em 4/5 fontes. |
| status_locacao | VARCHAR(20) | Não | — | `CHECK IN ('EM_ANDAMENTO','CONCLUIDA','CANCELADA','DESCONHECIDO')`. | Status atual da locação. |
| qtd_locacoes | INTEGER | Não | `1` | `CHECK (qtd_locacoes = 1)`. | Contador degenerado fixo em 1 por linha — viabiliza `SUM(qtd_locacoes)` em qualquer recorte. |
| duracao_prevista_dias | INTEGER | Sim | — | Inteiro ≥ 0 esperado. | Dias entre retirada e devolução prevista. |
| duracao_real_dias | INTEGER | Sim | — | Inteiro ≥ 0 esperado; `NULL` enquanto a locação estiver `EM_ANDAMENTO`. | Dias entre retirada e devolução real. |
| km_rodados | INTEGER | Sim | — | Inteiro ≥ 0 esperado; `NULL` até a devolução. | `km_devolucao − km_retirada`. |
| valor_diaria_aplicada | NUMERIC(12,2) | Sim | — | Não negativo esperado. | Tarifa unitária congelada no momento da locação (não-aditiva — usar média ponderada). |
| valor_total_estimado | NUMERIC(12,2) | Sim | — | Não negativo esperado. | `valor_diaria_aplicada × duracao_prevista_dias` quando a fonte não fornece o total. |
| valor_total_final | NUMERIC(12,2) | Sim | — | Não negativo esperado. | Valor cobrado ao final da locação; `NULL` enquanto não finalizada. |
| sk_fonte_id_natural | TEXT | Não | — | Texto (identificador composto fonte+id usado para idempotência). | Identificador de carga para auditoria e UNIQUE com `sk_fonte`. |
| data_carga_dw | TIMESTAMP | Não | `CURRENT_TIMESTAMP` | Timestamp da carga do registro no DW. | Auditoria — quando esta linha foi inserida no fato. |

- **Chave primária:** `sk_locacao`.
- **Chaves estrangeiras:**
  - `fk_floc_tempo_ret_real`: `sk_tempo_retirada_real` → `dim_tempo(sk_tempo)`
  - `fk_floc_tempo_dev_real`: `sk_tempo_devolucao_real` → `dim_tempo(sk_tempo)`
  - `fk_floc_tempo_dev_prev`: `sk_tempo_devolucao_prevista` → `dim_tempo(sk_tempo)`
  - `fk_floc_patio_retirada`: `sk_patio_retirada` → `dim_patio(sk_patio)`
  - `fk_floc_patio_devolucao`: `sk_patio_devolucao` → `dim_patio(sk_patio)`
  - `fk_floc_veiculo`: `sk_veiculo` → `dim_veiculo(sk_veiculo)`
  - `fk_floc_grupo`: `sk_grupo` → `dim_grupo(sk_grupo)`
  - `fk_floc_cliente`: `sk_cliente` → `dim_cliente(sk_cliente)`
  - `fk_floc_fonte`: `sk_fonte` → `dim_fonte(sk_fonte)`
- **Chaves únicas:** `CONSTRAINT uq_floc_origem UNIQUE (sk_fonte, sk_fonte_id_natural)` — garante idempotência por origem.
- **Checks declarados:**
  - `CHECK (status_locacao IN ('EM_ANDAMENTO','CONCLUIDA','CANCELADA','DESCONHECIDO'))`
  - `CHECK (qtd_locacoes = 1)`
- **Índices declarados:**
  - `ix_floc_tempo_ret_real (sk_tempo_retirada_real)`
  - `ix_floc_tempo_dev_real (sk_tempo_devolucao_real)`
  - `ix_floc_patio_ret (sk_patio_retirada)`
  - `ix_floc_patio_dev (sk_patio_devolucao)`
  - `ix_floc_veiculo (sk_veiculo)`
  - `ix_floc_grupo (sk_grupo)`
  - `ix_floc_cliente (sk_cliente)`
  - `ix_floc_fonte (sk_fonte)`
  - `ix_floc_status (status_locacao)`
- **Notas:**
  - `COMMENT ON TABLE`: "Fato de transacao: uma linha por contrato de locacao. Role-playing em dim_tempo (3) e dim_patio (2)."
  - `COMMENT ON COLUMN sk_tempo_devolucao_real`: "NULL para locacoes EM_ANDAMENTO ou CANCELADA sem devolucao. MOD-02: NULL preserva 'ainda nao ocorreu'; sentinela 19000101 reservada para 'dado perdido'." *(Observação: o COMMENT do DDL menciona `19000101`, mas a sentinela efetivamente inserida em `dim_tempo` é `-1`; a regra semântica permanece — qualquer "dado de data perdido" referencia a sentinela.)*
  - `COMMENT ON COLUMN sk_patio_devolucao`: "Role-playing dim_patio AS dim_patio_devolucao. MOD-05: SEMPRE o REAL quando a fonte distingue previsto vs realizado. NULL se EM_ANDAMENTO. Input da matriz de Markov."
  - `COMMENT ON COLUMN sk_patio_retirada`: "Role-playing: dim_patio AS dim_patio_retirada."
  - `COMMENT ON COLUMN id_locacao_origem`: "PK numerica da locacao no sistema-fonte. Habilita auditoria reversa em 5/5 fontes (MOD-04)."
  - Matriz de Markov é derivada agregando este fato por `(sk_patio_retirada, sk_patio_devolucao)` para `status_locacao = 'CONCLUIDA'` (decisão D-09).

---

### 2.2 `fato_reserva`

- **Descrição:** Tabela de fato de **transação**: uma linha por reserva registrada em qualquer das cinco fontes-origem.
- **Grão:** uma linha por reserva.
- **Tipo:** *transaction fact table* (Kimball cap. 1).
- **Fonte:** `staging.stg_reserva` após Transform — carregada em `etl/08_load_fatos.sql`.
- **Cardinalidade esperada (com *seed* sintético):** ~150 linhas (30 reservas × 5 fontes).

| Coluna | Tipo | Nulo? | Default | Domínio | Descrição |
|---|---|---|---|---|---|
| sk_reserva | INTEGER | Não | IDENTITY | Inteiro positivo gerado por `GENERATED ALWAYS AS IDENTITY`. | Chave subrogada da reserva. |
| sk_tempo_reserva | INTEGER | Não | — | Referencia `dim_tempo.sk_tempo`. | FK *role-playing* `dim_tempo AS dim_tempo_reserva` (data em que a reserva foi feita). |
| sk_tempo_retirada_prevista | INTEGER | Não | — | Referencia `dim_tempo.sk_tempo`. | FK *role-playing* `dim_tempo AS dim_tempo_retirada_prevista`. |
| sk_tempo_devolucao_prevista | INTEGER | Não | — | Referencia `dim_tempo.sk_tempo`. | FK *role-playing* `dim_tempo AS dim_tempo_devolucao_prevista`. |
| sk_patio_retirada | INTEGER | Não | — | Referencia `dim_patio.sk_patio`. | FK *role-playing* `dim_patio AS dim_patio_retirada`. |
| sk_patio_devolucao | INTEGER | Não | — | Referencia `dim_patio.sk_patio`. | FK *role-playing* `dim_patio AS dim_patio_devolucao`. |
| sk_grupo | INTEGER | Não | — | Referencia `dim_grupo.sk_grupo`; reservas da `bigdata` apontam para sentinela `sk_grupo = 0`. | FK do grupo solicitado. |
| sk_cliente | INTEGER | Não | — | Referencia `dim_cliente.sk_cliente`. | FK do cliente que realizou a reserva. |
| sk_fonte | SMALLINT | Não | — | Referencia `dim_fonte.sk_fonte`; esperado ∈ {1..5}. | FK da fonte/empresa associada. |
| id_reserva_origem | BIGINT | Não | — | PK numérica original da fonte. | *Degenerate dimension* — habilita auditoria reversa em 5/5 fontes. |
| status_reserva | VARCHAR(30) | Não | — | `CHECK IN ('CONFIRMADA','EM_FILA_ESPERA','CANCELADA','CONCRETIZADA','DESCONHECIDO')`. | Status atual da reserva (normalizado pelo Transform). |
| qtd_reservas | INTEGER | Não | `1` | `CHECK (qtd_reservas = 1)`. | Contador degenerado fixo em 1 — viabiliza contagens por qualquer recorte. |
| qtd_veiculos_solicitados | INTEGER | Não | `1` | `CHECK (qtd_veiculos_solicitados >= 1)`. | Número de veículos pedidos na reserva (a fonte `bigdata` expõe; demais defaultam a 1). |
| duracao_prevista_dias | INTEGER | Sim | — | Inteiro ≥ 0 esperado. | Dias entre retirada e devolução previstas. |
| dias_antecedencia | INTEGER | Sim | — | Inteiro ≥ 0 esperado. | Dias entre a data da reserva e a retirada prevista. **Não-aditiva** (usar `AVG`/`MEDIAN`) — MOD-01. |
| valor_previsto | NUMERIC(12,2) | Sim | — | Não negativo esperado. | Valor estimado da reserva quando exposto pela fonte. |
| sk_fonte_id_natural | TEXT | Não | — | Identificador composto fonte+id natural. | Identificador de carga para auditoria/UNIQUE. |
| data_carga_dw | TIMESTAMP | Não | `CURRENT_TIMESTAMP` | Timestamp da carga no DW. | Auditoria — quando esta linha foi inserida no fato. |

- **Chave primária:** `sk_reserva`.
- **Chaves estrangeiras:**
  - `fk_fres_tempo_reserva`: `sk_tempo_reserva` → `dim_tempo(sk_tempo)`
  - `fk_fres_tempo_ret_prev`: `sk_tempo_retirada_prevista` → `dim_tempo(sk_tempo)`
  - `fk_fres_tempo_dev_prev`: `sk_tempo_devolucao_prevista` → `dim_tempo(sk_tempo)`
  - `fk_fres_patio_retirada`: `sk_patio_retirada` → `dim_patio(sk_patio)`
  - `fk_fres_patio_devolucao`: `sk_patio_devolucao` → `dim_patio(sk_patio)`
  - `fk_fres_grupo`: `sk_grupo` → `dim_grupo(sk_grupo)`
  - `fk_fres_cliente`: `sk_cliente` → `dim_cliente(sk_cliente)`
  - `fk_fres_fonte`: `sk_fonte` → `dim_fonte(sk_fonte)`
- **Chaves únicas:** `CONSTRAINT uq_fres_origem UNIQUE (sk_fonte, sk_fonte_id_natural)`.
- **Checks declarados:**
  - `CHECK (status_reserva IN ('CONFIRMADA','EM_FILA_ESPERA','CANCELADA','CONCRETIZADA','DESCONHECIDO'))`
  - `CHECK (qtd_reservas = 1)`
  - `CHECK (qtd_veiculos_solicitados >= 1)`
- **Índices declarados:**
  - `ix_fres_tempo_res (sk_tempo_reserva)`
  - `ix_fres_tempo_ret_p (sk_tempo_retirada_prevista)`
  - `ix_fres_patio_ret (sk_patio_retirada)`
  - `ix_fres_grupo (sk_grupo)`
  - `ix_fres_cliente (sk_cliente)`
  - `ix_fres_fonte (sk_fonte)`
  - `ix_fres_status (status_reserva)`
- **Notas:**
  - `COMMENT ON TABLE`: "Fato de transacao: uma linha por reserva. Sem sk_veiculo (reserva eh por grupo, nao por veiculo — P-05 do modelo)."
  - `COMMENT ON COLUMN sk_grupo`: "Para reservas da fonte bigdata aponta para sk_grupo=0 (sentinela GRUPO_NAO_INFORMADO — vide CRITICO-04 e P-10)."
  - `COMMENT ON COLUMN id_reserva_origem`: "PK numerica da reserva na fonte. Auditoria reversa em 5/5 fontes."
  - O relatório (c) filtra por padrão `status_reserva IN ('CONFIRMADA','EM_FILA_ESPERA','CONCRETIZADA')` — exclui `CANCELADA` (MOD-06).

---

### 2.3 `fato_patio_diario`

- **Descrição:** Tabela de fato de **snapshot periódico** (versão v1.1 pós-revisão CRÍTICO-01/CRÍTICO-02). Grão fino: **uma linha por veículo por dia**, habilitando corte por marca/modelo/mecanização exigido no relatório (a).
- **Grão:** uma linha por veículo por dia (`UNIQUE (sk_tempo, sk_veiculo)`).
- **Tipo:** *periodic snapshot fact table* (Kimball cap. 7).
- **Fonte:** derivado pelo ETL a partir do estado da frota + histórico de locações (P-02).
- **Cardinalidade esperada:** ~4 018 dias × ~100 veículos (seed) ≈ ~400 mil linhas; em produção, milhões.

| Coluna | Tipo | Nulo? | Default | Domínio | Descrição |
|---|---|---|---|---|---|
| sk_patio_diario | INTEGER | Não | IDENTITY | Inteiro positivo gerado por `GENERATED ALWAYS AS IDENTITY`. | Chave subrogada do snapshot. |
| sk_tempo | INTEGER | Não | — | Referencia `dim_tempo.sk_tempo`. | FK do dia do snapshot. |
| sk_patio | INTEGER | Não | — | Referencia `dim_patio.sk_patio`. | FK do pátio onde o veículo está nesse dia. |
| sk_veiculo | INTEGER | Não | — | Referencia `dim_veiculo.sk_veiculo`. | FK do veículo observado — habilita corte por marca/modelo/mecanização (novo na v1.1, CRÍTICO-01). |
| sk_grupo | INTEGER | Não | — | Referencia `dim_grupo.sk_grupo`. | FK do grupo do veículo — desnormalizada a partir de `dim_veiculo` para acelerar consultas comuns. |
| sk_fonte | SMALLINT | Não | — | Referencia `dim_fonte.sk_fonte`; esperado ∈ {1..5}. | FK da empresa proprietária da frota — eixo do recorte "frota da empresa dona vs associadas" do relatório (a). |
| situacao | VARCHAR(15) | Não | — | `CHECK IN ('DISPONIVEL','ALUGADO','MANUTENCAO','RESERVADO')`. | Situação do veículo no dia (atributo degenerado; pivot feito na consulta). |
| flag_frota_propria_no_patio | BOOLEAN | Não | FALSE | {TRUE, FALSE}. | `TRUE` quando `sk_fonte` do veículo coincide com `codigo_fonte_dona` do pátio observado. Habilita o relatório (a) "frota da empresa dona vs associadas" sem JOIN adicional. |
| qtd_veiculos | INTEGER | Não | `1` | `CHECK (qtd_veiculos = 1)`. | Métrica única fixa = 1. Semi-aditiva no tempo; aditiva nas demais dimensões. |
| capacidade_vagas_patio | INTEGER | Sim | — | Inteiro ≥ 0 esperado. | Capacidade do pátio replicada no fato (acelera relatório (a) sem JOIN extra). |
| data_carga_dw | TIMESTAMP | Não | `CURRENT_TIMESTAMP` | Timestamp da carga no DW. | Auditoria — quando esta linha foi inserida no fato. |

- **Chave primária:** `sk_patio_diario`.
- **Chaves estrangeiras:**
  - `fk_fpd_tempo`: `sk_tempo` → `dim_tempo(sk_tempo)`
  - `fk_fpd_patio`: `sk_patio` → `dim_patio(sk_patio)`
  - `fk_fpd_veiculo`: `sk_veiculo` → `dim_veiculo(sk_veiculo)`
  - `fk_fpd_grupo`: `sk_grupo` → `dim_grupo(sk_grupo)`
  - `fk_fpd_fonte`: `sk_fonte` → `dim_fonte(sk_fonte)`
- **Chaves únicas:** `CONSTRAINT uq_fpd_grain UNIQUE (sk_tempo, sk_veiculo)` — formaliza o grão "1 veículo × 1 dia".
- **Checks declarados:**
  - `CHECK (situacao IN ('DISPONIVEL','ALUGADO','MANUTENCAO','RESERVADO'))`
  - `CHECK (qtd_veiculos = 1)`
- **Índices declarados:**
  - `ix_fpd_tempo (sk_tempo)`
  - `ix_fpd_patio (sk_patio)`
  - `ix_fpd_veiculo (sk_veiculo)`
  - `ix_fpd_grupo (sk_grupo)`
  - `ix_fpd_fonte (sk_fonte)`
  - `ix_fpd_situacao (situacao)`
- **Notas:**
  - `COMMENT ON TABLE`: "Fato de snapshot periodico. Grao: UMA LINHA POR VEICULO POR DIA (v1.1). Habilita relatorio (a) com corte por marca/modelo/mecanizacao via JOIN com dim_veiculo."
  - `COMMENT ON COLUMN qtd_veiculos`: "Metrica unica fixa=1. Semi-aditiva no tempo (somar entre dias conta o mesmo veiculo varias vezes); aditiva nas demais dimensoes (somar entre patios/grupos/veiculos eh natural)."
  - `COMMENT ON COLUMN situacao`: "Atributo degenerado. Pivot em colunas via COUNT(*) FILTER (WHERE situacao=X) na consulta — mais flexivel que pre-agregar."
  - `COMMENT ON COLUMN flag_frota_propria_no_patio`: "TRUE quando sk_fonte do veiculo coincide com a fonte dona do patio. Habilita relatorio (a) 'frota da empresa dona vs associadas' sem JOIN adicional."

---

## 3. Restrições de Integridade Globais

| ID | Regra | Onde |
|---|---|---|
| G-01 | Toda FK de fato resolve para uma linha existente na dimensão referenciada (vide listas de FK por fato). | `CONSTRAINT fk_*` em cada `fato_*`. |
| G-02 | `fato_locacao.sk_tempo_devolucao_real` e `fato_locacao.sk_patio_devolucao` são **NULL** apenas quando `status_locacao = 'EM_ANDAMENTO'`. Demais status devem preencher essas FKs. | Regra de negócio aplicada no Transform; D-10/MOD-02. |
| G-03 | `dim_patio` tem 6 linhas canônicas + 1 sentinela `sk_patio = 0`. Linhas-fonte não casadas no *de-para* são descartadas no Transform (não usam a sentinela em produção). | `staging.depara_patio` + Transform; D-10. |
| G-04 | Reservas oriundas da fonte `bigdata` (`sk_fonte = 5`) referenciam sempre `sk_grupo = 0` (sentinela `GRUPO_NAO_INFORMADO`). | Carga `etl/08_load_fatos.sql`; P-10. |
| G-05 | `fato_patio_diario.flag_frota_propria_no_patio = (codigo_fonte do veículo == codigo_fonte_dona do pátio)`. | Derivado no Load via JOIN com `dim_fonte` e `dim_patio`; relatório (a). |
| G-06 | Idempotência por origem: `UNIQUE (sk_fonte, sk_fonte_id_natural)` em `fato_locacao` (`uq_floc_origem`) e em `fato_reserva` (`uq_fres_origem`). Reexecução do Load não duplica linhas. | `CONSTRAINT uq_floc_origem` e `uq_fres_origem`. |
| G-07 | Idempotência por grão: `UNIQUE (sk_tempo, sk_veiculo)` em `fato_patio_diario` (`uq_fpd_grain`). Nunca há dois snapshots do mesmo veículo no mesmo dia. | `CONSTRAINT uq_fpd_grain`. |
| G-08 | Dimensões com sentinela: `dim_fonte.sk_fonte = 0` (`FONTE_DESCONHECIDA`), `dim_patio.sk_patio = 0` (`PATIO_DESCONHECIDO`), `dim_grupo.sk_grupo = 0` (`GRUPO_NAO_INFORMADO`), `dim_tempo.sk_tempo = 19000101` (`DATA_DESCONHECIDA`, smart-key reservada). Inseridas no próprio `dw/01_schema_dw.sql` (via `OVERRIDING SYSTEM VALUE` nas IDENTITY) e em `dw/02_dim_tempo_carga.sql` (com `ON CONFLICT DO NOTHING`). | D-10 revisado. |
| G-09 | Unicidade de chaves naturais conformadas: `dim_patio.nome_canonico`, `dim_grupo.nome_grupo_normalizado`, `dim_fonte.codigo_fonte`. Em `dim_veiculo` e `dim_cliente`, unicidade é composta `(sk_fonte_origem, id_natural_origem)`. | `UNIQUE` em cada dimensão. |
| G-10 | Domínios enumerados garantidos via `CHECK IN (...)`: `dim_patio.tipo_local`, `dim_veiculo.mecanizacao`, `dim_veiculo.situacao_atual`, `dim_grupo.classe_luxo`, `dim_cliente.tipo_pessoa`, `fato_locacao.status_locacao`, `fato_reserva.status_reserva`, `fato_patio_diario.situacao`. | `CHECK` em cada coluna. |
| G-11 | Contadores fixos em 1: `fato_locacao.qtd_locacoes`, `fato_reserva.qtd_reservas`, `fato_patio_diario.qtd_veiculos`. | `CHECK (... = 1)` em cada coluna. |
| G-12 | `fato_reserva.qtd_veiculos_solicitados >= 1`. | `CHECK` na coluna. |
| G-13 | `data_carga_dw` é preenchida automaticamente em todos os três fatos (default `CURRENT_TIMESTAMP`) — habilita auditoria de janela de carga. | `DEFAULT CURRENT_TIMESTAMP`. |
| G-14 | Drop & create idempotente: `dw/01_schema_dw.sql` começa com `DROP SCHEMA IF EXISTS dw CASCADE; CREATE SCHEMA dw;`. Toda execução parte de estado limpo. | Cabeçalho do script DDL. |

---
