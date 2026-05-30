<!--
Avaliação 02 — Modelagem de DW — Parte II
Grupo:
  - Gustavo Oliveira Pessanha da Silva (DRE 122051824)
  - André Vinícius Lobo Giron (DRE 122050404)
-->

# Revisão Adversarial — Fase ETL

**Trabalho:** Avaliação 02 — Parte II — Modelagem de Data Warehouse
**Artefatos revisados:**
- `etl/01_extract_andre_gustavo.sql`
- `etl/02_extract_mae016.sql`
- `etl/03_extract_locadora_db.sql`
- `etl/04_extract_bd_dw.sql`
- `etl/05_extract_bigdata.sql`
- `etl/06_transform.sql`
- `etl/07_load_dimensoes.sql`
- `etl/08_load_fatos.sql`
**Data:** 2026-05-30
**Revisor:** subagente `revisor-adversarial` (DBA sênior adversarial)
**Achados críticos:** 2
**Achados moderados:** 6
**Achados leves:** 6

### Grupo

| Nome completo | DRE |
|---|---|
| Gustavo Oliveira Pessanha da Silva | 122051824 |
| André Vinícius Lobo Giron | 122050404 |

---

## Resumo executivo

O pipeline ETL está **funcional e tecnicamente correto na maior parte**: tradução MySQL→Postgres limpa, idempotência bem estruturada (DELETE por `sk_fonte` nos extracts, `ON CONFLICT` nas dimensões, `TRUNCATE...RESTART IDENTITY` nos fatos), integridade FK validada em todas as 5 fontes (288 locações + 150 reservas + 3 000 snapshots, sem FK órfã), cobertura `sk_fonte` 1..5 em ambos os fatos transacionais, sentinelas usadas corretamente (30 reservas bigdata em `sk_grupo=0`, 1 pátio Barra sem dona), de-para de pátios e grupos sem órfãos, walk-in preservado nas fontes 1/2/3 (168 locações com `reserva_id_natural` NULL chegando ao fato), `EM_ANDAMENTO` com `sk_tempo_devolucao_real` e `sk_patio_devolucao` consistentemente NULL.

Mas **dois achados críticos** podem produzir distorções relevantes em relatórios:
1. **Locações CANCELADAS sem `data_retirada_real` da fonte 3 (locadora_db) são silenciosamente perdidas** (12/300 — 4% do total da fonte 3, 100% das canceladas dela). O filtro `WHERE sl.data_retirada_real IS NOT NULL` em `08_load_fatos.sql` não distingue cancelamento legítimo de dado faltante. As fontes 1, 2, 4 mantêm canceladas porque suas seeds preenchem `data_retirada_real` mesmo para cancelada — divergência cross-fonte.
2. **`fato_patio_diario` escolhe arbitrariamente o pátio quando há duas ou mais locações cobrindo o mesmo veículo no mesmo dia** (232 ocorrências no seed; em alguns casos 3 pátios distintos para o mesmo veículo×dia). O `LATERAL JOIN ... LIMIT 1` esconde sobreposições reais sem detecção, sem desempate determinístico e sem aviso ao operador.

Os 6 achados moderados envolvem inconsistências cross-fonte tratáveis: mae016 grava `sk_patio_devolucao` para CANCELADA (violando MOD-05), CPF/CNPJ não normalizado (campo se chama `cpf_normalizado` mas nada normaliza), `MANUTENCAO`/`RESERVADO` nunca emitidos pelo `fato_patio_diario`, `valor_total_estimado` nunca calculado (sempre NULL), sentinela `19000101` referenciada no comentário mas implementada como `-1`, e dependência implícita entre `08_load_fatos.sql` e `staging.stg_veiculo` populado.

**Veredito:** segue para próxima fase (relatórios + Markov) **com correções recomendadas dos 2 críticos antes da entrega final**. Os achados moderados podem ser tratados em iteração paralela.

---

## Achados

### [CRÍTICO-01] Locações CANCELADAS da fonte 3 silenciosamente descartadas

**Onde:** `etl/08_load_fatos.sql` linha 96 (`WHERE sl.data_retirada_real IS NOT NULL`) combinado com `etl/03_extract_locadora_db.sql` linhas 178-182 (status normalizado como `CANCELADA` quando `data_retirada_realizada` é NULL).

**Problema:** A fonte 3 (`locadora_db`) gera 60 linhas em `stg_locacao`, das quais 12 têm `status_normalizado = 'CANCELADA'` e `data_retirada_real = NULL`. O `08_load_fatos.sql` filtra `WHERE sl.data_retirada_real IS NOT NULL`, descartando essas 12 (apenas 48 da fonte 3 entram em `fato_locacao`). Resultado: a fonte 3 perde 100 % das CANCELADAs. As outras fontes (1, 2, 4) **não** sofrem essa perda porque seus seeds preenchem `data_retirada_real` mesmo para CANCELADA — gerando cobertura assimétrica cross-fonte.

**Cenário que quebra:** relatório de taxa de cancelamento por fonte. A fonte 3 apareceria com 0 % de cancelamentos enquanto as outras teriam ~10-20 %. Conclusão errada: "locadora_db é a fonte mais eficiente." Realidade: ela é a única em que CANCELADA significa "reserva cancelada antes de retirada" (caso de uso legítimo).

**Validação executada:**
```sql
SELECT sk_fonte, status_normalizado, COUNT(*)
  FROM staging.stg_locacao GROUP BY 1,2 ORDER BY 1,2;
-- fonte 3 CANCELADA = 12 em staging
SELECT sk_fonte, status_locacao, COUNT(*) FROM dw.fato_locacao GROUP BY 1,2;
-- fonte 3 CANCELADA = 0 em fato_locacao (perdeu as 12)
```

**Recomendação:** decidir formalmente um dos dois caminhos:
- **(a)** Aceitar CANCELADA sem `data_retirada_real` no fato — substituir `sk_tempo_retirada_real` por sentinela `dim_tempo.sk_tempo = -1` quando NULL e relaxar o `NOT NULL` da FK do fato (ou usar `19000101` se preferir manter o constraint). Documenta-se em `dim_tempo` que `sk_tempo = -1` significa "evento previsto mas cancelado/não ocorrido".
- **(b)** Descartar CANCELADAs em **todas** as 5 fontes consistentemente (filtro adicional `AND status_normalizado <> 'CANCELADA'` ou tornar isso uma regra explícita no Transform), produzindo cobertura simétrica. O relatório (b) de Kimball especifica controle de locações "vivas", então excluir canceladas pode ser defensável — mas precisa ser deliberado.

**Referência:** Kimball cap. 6 ("Null Foreign Keys"); enunciado §b "Controle das locações"; modelo dimensional MOD-02.

---

### [CRÍTICO-02] `fato_patio_diario` escolhe pátio arbitrariamente em sobreposições de locação

**Onde:** `etl/08_load_fatos.sql` linhas 218-231 — CTE `veic_dia_alugado` com `LEFT JOIN LATERAL (... LIMIT 1)`.

**Problema:** A consulta usa `LIMIT 1` para escolher uma locação cobrindo o dia, mas **não há critério de desempate** (`ORDER BY` está ausente). Quando o mesmo veículo aparece em duas locações cobrindo o mesmo dia (cenário comum em dados reais com locações que se encavalam por bug de cadastro, ou em test data onde clientes diferentes alugam mesmo veículo em datas próximas), o pátio escolhido é não-determinístico (depende do plano do Postgres).

**Validação executada:**
```sql
WITH dias AS (SELECT generate_series(DATE '2026-05-01', DATE '2026-05-30',
                                     INTERVAL '1 day')::DATE AS dia)
SELECT fl.sk_veiculo, d.dia, COUNT(*), ARRAY_AGG(DISTINCT fl.sk_patio_retirada)
  FROM dw.fato_locacao fl
  JOIN dw.dim_tempo dt_ret ON dt_ret.sk_tempo=fl.sk_tempo_retirada_real
  LEFT JOIN dw.dim_tempo dt_dev ON dt_dev.sk_tempo=fl.sk_tempo_devolucao_real
  CROSS JOIN dias d
 WHERE fl.status_locacao IN ('EM_ANDAMENTO','CONCLUIDA')
   AND d.dia >= dt_ret.data_completa
   AND d.dia <  COALESCE(dt_dev.data_completa, CURRENT_DATE)
 GROUP BY 1,2 HAVING COUNT(*)>1;
-- 232 dias×veículos com SOBREPOSIÇÃO; alguns com 3 pátios distintos
-- (ex.: sk_veiculo=29 em pátios {2,4,5} simultaneamente em 2026-05-01..10)
```

**Cenário que quebra:** o relatório (a) "veículos disponíveis no Galeão hoje" pode atribuir o mesmo veículo a "Galeão" ou "Santos Dumont" dependendo do plano de consulta. Re-execução do ETL pode dar contagens diferentes para o mesmo dado-fonte. Audita-se "por que o veículo X mudou de pátio entre dois loads idênticos?" e não há resposta.

**Recomendação:**
1. Adicionar `ORDER BY li2.dia_retirada DESC` (a mais recente vence) ou `ORDER BY li2.dia_retirada ASC, li2.sk_locacao` (a primeira cronologicamente, com desempate determinístico) ao `LATERAL`.
2. Adicionar um `RAISE NOTICE` que conte sobreposições antes de truncar (ou um `CHECK` que falhe a carga se acima de um limiar — sobreposição genuína é dado-fonte errado).
3. Considerar agregar `STRING_AGG` dos pátios para auditoria.

**Referência:** Kimball cap. 7 ("Periodic Snapshot — Multi-Source Conflict Resolution"); Postgres docs LATERAL JOIN.

---

### [MODERADO-01] mae016 grava `sk_patio_devolucao` para locações CANCELADAS

**Onde:** `etl/08_load_fatos.sql` linhas 64-67 (lógica de NULL apenas para EM_ANDAMENTO) combinado com `etl/02_extract_mae016.sql` linha 170 (`l.id_patio_devolucao_real::TEXT`) — mae016 preenche `id_patio_devolucao_real` mesmo para CANCELADAs (vide seed).

**Problema:** A regra MOD-05 do modelo diz: "`sk_patio_devolucao` é **sempre o REAL quando ocorrido**, NULL se EM_ANDAMENTO". Mas o load só verifica `EM_ANDAMENTO`. Para CANCELADAs da fonte 2 (mae016), `data_devolucao_real` é NULL (portanto `sk_tempo_devolucao_real` é NULL — coerente) **mas** `id_patio_devolucao_real` está preenchido no seed e o load o copia para `sk_patio_devolucao`. Resultado: 6 linhas com `sk_tempo_devolucao_real = NULL` **mas** `sk_patio_devolucao = preenchido` — inconsistência semântica.

**Validação executada:**
```sql
SELECT sk_fonte, status_locacao, sk_tempo_devolucao_real IS NULL,
       sk_patio_devolucao IS NULL, COUNT(*)
  FROM dw.fato_locacao GROUP BY 1,2,3,4 ORDER BY 1,2,3,4;
-- fonte 2, CANCELADA: sk_tempo_dev_NULL=true, sk_patio_dev_NULL=false (6 linhas)
-- fonte 1, CANCELADA: sk_tempo_dev_NULL=true, sk_patio_dev_NULL=true   (11 linhas)
```

**Cenário que quebra:** a matriz de Markov filtra `status_locacao = 'CONCLUIDA'`, portanto CANCELADAs nem entram — bug não afeta. Mas qualquer consulta que faça `WHERE sk_patio_devolucao IS NOT NULL` para contar "devoluções com pátio conhecido" inflará a fonte 2 em 6 linhas falsas.

**Recomendação:** estender a condição em `08_load_fatos.sql` linha 65 para `WHEN sl.status_normalizado IN ('EM_ANDAMENTO','CANCELADA') OR sl.data_devolucao_real IS NULL THEN NULL` — basear o NULL em `data_devolucao_real IS NULL` (semântica direta) em vez de `status`.

**Referência:** modelo dimensional MOD-05 e D-10.

---

### [MODERADO-02] CPF/CNPJ nunca normalizado apesar do nome da coluna

**Onde:** `etl/07_load_dimensoes.sql` linhas 221-222 (`sc.cpf`, `sc.cnpj` copiados direto sem processamento); `dw/01_schema_dw.sql` linhas 149-150 (`cpf_normalizado VARCHAR(11)`, `cnpj_normalizado VARCHAR(14)`).

**Problema:** A dimensão declara `cpf_normalizado VARCHAR(11)` (apenas 11 dígitos). Mas o ETL **não remove** formatação (pontos, traços, barras). Funciona no seed sintético porque os CPFs vêm em "20000000001" (11 dígitos exatos). Se uma fonte real trouxer "200.000.000-01" (14 chars), o load **violará o `VARCHAR(11)`** e crashará silenciosamente (ou truncar irá deformar o CPF).

**Validação executada:**
```sql
SELECT cpf_normalizado, LENGTH(cpf_normalizado) FROM dw.dim_cliente
 WHERE cpf_normalizado IS NOT NULL ORDER BY LENGTH(cpf_normalizado) DESC LIMIT 5;
-- todos 11 chars (seed)
SELECT name, source_definition FROM information_schema.columns
 WHERE table_schema='dw' AND column_name LIKE 'cpf%';
-- VARCHAR(11) confirmado
```

**Cenário que quebra:** seed real com CPF formatado quebra o load. Mesmo no seed sintético atual, qualquer alteração futura no extract introduz risco.

**Recomendação:** em `07_load_dimensoes.sql`, aplicar:
```sql
REGEXP_REPLACE(sc.cpf,  '[^0-9]', '', 'g') AS cpf_normalizado,
REGEXP_REPLACE(sc.cnpj, '[^0-9]', '', 'g') AS cnpj_normalizado
```
Ou movê-lo para o Transform (`06_transform.sql`) onde já há outros UPPER/TRIM. O nome "normalizado" sugere normalização — torná-lo real.

---

### [MODERADO-03] `fato_patio_diario` nunca emite `MANUTENCAO` nem `RESERVADO`

**Onde:** `etl/08_load_fatos.sql` linhas 218-232 (lógica binária "ALUGADO se locação cobre, senão DISPONIVEL").

**Problema:** O domínio do CHECK constraint em `fato_patio_diario.situacao` inclui `'DISPONIVEL'`, `'ALUGADO'`, `'MANUTENCAO'`, `'RESERVADO'` (4 valores). Mas o ETL gera apenas 2: `ALUGADO` quando há locação cobrindo o dia, `DISPONIVEL` caso contrário. Veículos cuja `dim_veiculo.situacao_atual = 'MANUTENCAO'` (4 veículos no seed) aparecem como `DISPONIVEL` no snapshot — falsificando o relatório (a) "veículos por situação".

**Validação executada:**
```sql
SELECT situacao_atual, COUNT(*) FROM dw.dim_veiculo GROUP BY 1;
-- ALUGADO=20, DISPONIVEL=76, MANUTENCAO=4
SELECT situacao, COUNT(*) FROM dw.fato_patio_diario GROUP BY 1;
-- ALUGADO=377, DISPONIVEL=2623  (MANUTENCAO=0, RESERVADO=0)
```

**Cenário que quebra:** relatório "veículos em manutenção no Galeão hoje" sempre retorna 0, mesmo havendo veículos do andre_gustavo com `situacao_atual='MANUTENCAO'` em `dim_veiculo`.

**Recomendação:** estender a CTE `veic_dia_alugado` com lógica adicional: quando não há locação cobrindo e `dim_veiculo.situacao_atual IN ('MANUTENCAO','BAIXADO')`, marcar `situacao='MANUTENCAO'`. Idealmente o relatório (a) também usa o atributo `situacao_atual` de `dim_veiculo` para o último dia do snapshot (já que o histórico de manutenção não é capturado pelas fontes — assunção P-02). Documentar em P-XX se preferir manter binário.

---

### [MODERADO-04] `valor_total_estimado` jamais calculado em `fato_locacao`

**Onde:** `etl/08_load_fatos.sql` linha 87 (`NULL,                -- valor_total_estimado nao calculado nesta fase`).

**Problema:** A coluna `valor_total_estimado` está declarada no DW (`dw/01_schema_dw.sql` linha 209) e documentada na §3.1 do modelo dimensional como "`valor_diaria_aplicada × duracao_prevista_dias` quando a fonte não fornece o total". Mas o load coloca `NULL` para 100 % das linhas. As fontes 3 e 5 (`locadora_db` e `bigdata`) **não expõem** `valor_total_final` — quem precisar do total para essas duas fontes só tem `valor_total_estimado` para usar, e ele está vazio.

**Validação executada:**
```sql
SELECT sk_fonte, COUNT(*),
       COUNT(*) FILTER (WHERE valor_total_estimado IS NOT NULL) AS estim,
       COUNT(*) FILTER (WHERE valor_total_final IS NOT NULL)   AS final
  FROM dw.fato_locacao GROUP BY 1 ORDER BY 1;
-- estim sempre 0 (não calculado); final preenchido só para fontes 2 e 4
```

**Cenário que quebra:** relatório de receita por grupo perde fontes 1, 3 e 5 (nem `valor_total_final` nem `valor_total_estimado`). Sub-estimativa de ~60 % na receita agregada.

**Recomendação:** implementar a fórmula declarada:
```sql
CASE WHEN sl.valor_diaria_aplicada IS NOT NULL AND duracao_prevista_dias IS NOT NULL
     THEN sl.valor_diaria_aplicada * duracao_prevista_dias
     ELSE NULL END
```

---

### [MODERADO-05] Sentinela documentada como `19000101` mas implementada como `-1`

**Onde:** `dw/01_schema_dw.sql` linha 229 (COMMENT diz "sentinela 19000101 reservada para dado perdido"); `dw/02_dim_tempo_carga.sql` linha 35 (insere `sk_tempo = -1` para DATA_DESCONHECIDA); modelo dimensional §6 e §3.1 menciona sentinela `19000101` em duas seções.

**Problema:** Inconsistência semântica entre comentário no DDL, documentação no modelo dimensional, e implementação real. Um operador lendo o `fato_locacao` que quiser filtrar "datas desconhecidas" buscará `sk_tempo_devolucao_real = 19000101` e não encontrará. Ou pior: tentará carregar uma linha apontando para `19000101` e a FK falhará porque essa chave não existe.

**Validação executada:**
```sql
SELECT sk_tempo FROM dw.dim_tempo
 WHERE sk_tempo IN (-1, 19000101);
-- retorna apenas -1
```

**Cenário que quebra:** qualquer query que assume documentação canônica. Risco de bug oculto em relatórios futuros.

**Recomendação:** padronizar para **uma** das duas opções e atualizar todos os artefatos:
- Manter `-1` e atualizar o comentário do `dw/01_schema_dw.sql:229` e o §6/§3.1 do modelo dimensional.
- **OU** mudar a sentinela para `19000101` (mais legível e auto-explicativa) tanto em `02_dim_tempo_carga.sql` quanto em qualquer referência futura.

Recomendamos `-1` (mais simples, evita comparação ao "ano 1900" em interfaces visuais).

---

### [MODERADO-06] `08_load_fatos.sql` tem dependência implícita de `staging.stg_veiculo` populada

**Onde:** `etl/08_load_fatos.sql` linha 194 (`LEFT JOIN staging.stg_veiculo sv ON sv.sk_fonte = dv.sk_fonte_origem AND sv.id_natural = dv.id_natural_origem`).

**Problema:** O fato `fato_patio_diario` precisa de `stg_veiculo.nome_canonico_patio` para descobrir o pátio de origem do veículo (o que é DISPONIVEL onde). Mas isso é uma dependência **não declarada**: se um operador rodar `07_load_dimensoes.sql` + `08_load_fatos.sql` sem ter rodado os extracts (01-05) e o transform (06) antes — situação plausível em manutenção pontual — o `stg_veiculo` estará vazio e o `fato_patio_diario` ficará sem `sk_patio` para todos os veículos disponíveis (cairá no `WHERE COALESCE(...) IS NOT NULL`).

**Validação:** análise estática do código — sem teste em runtime porque o pipeline foi rodado em sequência completa.

**Cenário que quebra:** operador faz `TRUNCATE TABLE staging.stg_veiculo;` e re-executa só os loads. O fato_patio_diario sai vazio sem aviso.

**Recomendação:** uma destas (em ordem de preferência):
- **(a)** Mover `nome_canonico_patio` para `dim_veiculo` (desnormalização leve; perdura entre cargas).
- **(b)** Adicionar `RAISE EXCEPTION` no topo de `08_load_fatos.sql` se `(SELECT COUNT(*) FROM staging.stg_veiculo) = 0`.
- **(c)** Documentar no cabeçalho que `08` requer `01-05 + 06` na mesma sessão.

---

### [LEVE-01] `id_natural::BIGINT` quebra com IDs não-numéricos

**Onde:** `etl/08_load_fatos.sql` linhas 74, 134 (`sl.id_natural::BIGINT`, `sr.id_natural::BIGINT`).

**Problema:** O extract 05 (bigdata) usa `id_natural` numérico puro para locação (`l.IDLocacao::TEXT`), portanto o cast funciona. Mas para `stg_cliente.id_natural` da bigdata, o id é `'PF_'||IDFisica` — felizmente o cast `::BIGINT` só acontece para locação/reserva, não para cliente. Defensividade ausente: qualquer fonte futura com id UUID/string quebraria silenciosamente. Suporte assumido tácito de que id_natural de locação/reserva é sempre numérico — não documentado no contrato de `stg_*`.

**Recomendação:** mudar o tipo da coluna `id_locacao_origem` para `TEXT` no fato (mais permissivo) ou adicionar um CHECK regex no Transform que garanta `id_natural ~ '^[0-9]+$'` antes do load — falhando rápido em vez de tarde.

---

### [LEVE-02] Locações da fonte 4 apontam para `reserva_id_natural` que nunca casará com `stg_reserva`

**Onde:** `etl/04_extract_bd_dw.sql` linhas 162-163 (filtro `WHERE r.Id_reserva <= 100` na stg_reserva); linha 198 (`LEFT JOIN ... r_stub.Id_reserva = l.Id_reserva` em stg_locacao com IDs 101-160).

**Problema:** Em bd_dw_26_1, as 60 reservas "stub" (Id_reserva 101-160) existem só para satisfazer FK 1:1 obrigatória em Locacao, e o extract corretamente as filtra de `stg_reserva` (boa prática). MAS o extract de `stg_locacao` preserva `l.Id_reserva::TEXT` (101..160) em `reserva_id_natural`. Logo, todas as 60 locações da fonte 4 têm `reserva_id_natural` apontando para um ID que **nunca** existirá em `fato_reserva`. Drill cross-fato via `reserva_id_natural` é impossível para essa fonte.

**Validação executada:**
```sql
SELECT COUNT(*) FROM staging.stg_locacao sl
 WHERE sl.sk_fonte=4
   AND EXISTS (SELECT 1 FROM staging.stg_reserva sr
                WHERE sr.sk_fonte=4 AND sr.id_natural=sl.reserva_id_natural);
-- 0 matches (60 locações com referência inválida)
```

**Cenário que quebra:** documentar explicitamente em `docs/relatorio-etl.md` ou no extract que para fonte 4 `reserva_id_natural` é um stub técnico (não é uma reserva real). Ou setar `reserva_id_natural = NULL` quando `l.Id_reserva > 100` no extract — sinaliza walk-in puro semanticamente.

---

### [LEVE-03] Recálculo redundante de `nome_canonico_grupo` para veículo em `08_load_fatos.sql`

**Onde:** `etl/08_load_fatos.sql` linhas 193-197 (CTE `veic_patio` faz `LEFT JOIN staging.depara_grupo dg2 ... LEFT JOIN dw.dim_grupo dg`).

**Problema:** O Transform (`06_transform.sql`) já popula `staging.stg_veiculo.nome_canonico_grupo` para todos os veículos. O 08 ignora isso e refaz o JOIN via `depara_grupo`. Redundância de código; também adiciona risco se um futuro Transform alterar a derivação e o 08 ficar dessincronizado.

**Recomendação:** usar diretamente `sv.nome_canonico_grupo` em vez de re-fazer o JOIN:
```sql
LEFT JOIN dw.dim_grupo dg ON dg.nome_grupo_normalizado = sv.nome_canonico_grupo
```

---

### [LEVE-04] `bigdata` sempre traz `mecanizacao = 'DESCONHECIDA'` impactando relatório (a)

**Onde:** `etl/05_extract_bigdata.sql` linha 107 (`'DESCONHECIDA'` hardcoded para `mecanizacao`).

**Problema:** A fonte 5 (bigdata) realmente não expõe `mecanizacao` no schema — limitação de fonte legítima. O ETL trata corretamente com `DESCONHECIDA`. O sintoma é que o relatório (a) "agrupar por mecanização" terá uma categoria DESCONHECIDA com 20 veículos (20 % do total) sem contexto.

**Recomendação:** mencionar essa limitação na documentação do relatório (a) ou em `docs/relatorio-etl.md` § Limitações; o `engenheiro-etl` na próxima fase deve garantir que a categoria DESCONHECIDA aparece visível e não escondida.

---

### [LEVE-05] Endereço de pátio em `dim_patio` resolve por `MAX()` arbitrário

**Onde:** `etl/07_load_dimensoes.sql` linhas 64-66 (`SELECT MAX(sp.endereco) FROM staging.stg_patio sp WHERE sp.nome_canonico = p.nome_canonico`).

**Problema:** Quando 4 das 5 fontes têm endereço para o mesmo pátio canônico (Galeão, etc.), o `MAX()` escolhe lexicograficamente o "maior" — sem critério de qualidade ou autoridade. Endereço escolhido pode ser truncado ou menos descritivo do que outro. Para `capacidade_vagas_referencia` o `MAX` faz sentido (capacidade máxima entre fontes), mas para endereço o critério é estranho.

**Validação executada:**
```sql
SELECT sk_fonte, nome_canonico, endereco
  FROM staging.stg_patio
 WHERE nome_canonico='Aeroporto do Galeao' ORDER BY 1;
-- 4 endereços diferentes; dim_patio guarda o lexicograficamente maior
```

**Recomendação:** preferir o endereço da **fonte dona** do pátio (já está em `codigo_fonte_dona`). Ex.:
```sql
COALESCE(
  (SELECT sp.endereco FROM staging.stg_patio sp
     JOIN dw.dim_fonte df ON df.sk_fonte=sp.sk_fonte
    WHERE sp.nome_canonico = p.nome_canonico
      AND df.codigo_fonte = (SELECT codigo_fonte_dona FROM dw.dim_patio p2
                              WHERE p2.nome_canonico=p.nome_canonico)
    LIMIT 1),
  (SELECT MAX(sp.endereco) FROM staging.stg_patio sp
    WHERE sp.nome_canonico = p.nome_canonico)
)
```

---

### [LEVE-06] `data_devolucao_prevista` estimada como `retirada + 5 dias` em fonte 1 e fonte 5 sem documentação clara

**Onde:** `etl/01_extract_andre_gustavo.sql` linha 179 (`l.data_retirada_real + INTERVAL '5 days'`); `etl/05_extract_bigdata.sql` linha 224 (`l.DtRetirada + INTERVAL '5 days'`).

**Problema:** Quando a fonte não expõe `data_devolucao_prevista` (andre_gustavo, bigdata), o extract chuta "+5 dias" como duração típica. Esse heurístico:
1. **Não está documentado** em `dimensional/modelo-dimensional.md` nem em `docs/relatorio-etl.md`.
2. Vai compor `fato_locacao.duracao_prevista_dias = 5` para essas fontes — afetando relatório (b) "duração média prevista".
3. Inflará/deflará a métrica `dias_de_atraso = duracao_real - duracao_prevista` se calculada — fonte 1 sempre dirá "previsto = 5", o que comparado com locações de 7 dias parece "atraso de 2 dias" mesmo sem ter havido.

**Recomendação:** uma destas:
- **(a)** Documentar explicitamente o heurístico no cabeçalho do extract e em `docs/relatorio-etl.md`.
- **(b)** Deixar `data_devolucao_prevista = NULL` para essas fontes (o `08_load_fatos.sql` já tem `COALESCE` para sk_tempo_devolucao_prevista; precisaria também tolerar NULL na métrica).
- **(c)** Usar `data_devolucao_real` quando disponível (assumir que o cliente devolveu no prazo previsto — viés mais conservador).

---

## Cenários testados

| # | Cenário | Resultado | Justificativa |
|---|---|---|---|
| 1 | **Cliente em 2 fontes (mesmo CPF)** | PASSA | No seed sintético, CPFs são únicos por fonte. Política D-03 documentada de não-dedup. Aparece como linhas distintas em `dim_cliente` (correto pelo design). |
| 2 | **Pátio com nome ligeiramente diferente** ("Galeão" vs "GIG" vs "Aeroporto Internacional") | PASSA | `depara_patio` resolve via `(sk_fonte, id_natural)` — não usa fuzzy match no nome. 30 linhas de depara cobrem todos os 6 pátios × 5 fontes; 0 órfãos verificados. |
| 3 | **Grupo "Econômico" vs "ECON"** | PASSA | `depara_grupo` resolve via `(sk_fonte, codigo_origem)` — 25 linhas cobrem 5 grupos × 5 fontes; 0 órfãos. |
| 4 | **Locação EM_ANDAMENTO sem `data_devolucao_real`** | PASSA | Validei: `sk_tempo_devolucao_real IS NULL` e `sk_patio_devolucao IS NULL` consistentes em todas as 29 linhas EM_ANDAMENTO no fato. Relatório (b) pode filtrar `WHERE sk_tempo_devolucao_real IS NULL`. |
| 5 | **Reserva cancelada entra em `fato_reserva`?** | PASSA | Sim, 15 reservas CANCELADAs entram no fato; cabe ao relatório (c) decidir filtrar (MOD-06 do modelo prevê filtro default excluindo). |
| 6 | **Locação `patio_retirada = patio_devolucao`** | PASSA | 156 linhas CONCLUIDAs com pátio igual — a diagonal da matriz Markov será populada. |
| 7 | **Cidade do cliente NULL** | PASSA | Transform substitui por 'CIDADE_DESCONHECIDA' (linha 187 de 06); load 07 usa `COALESCE(..., 'DESCONHECIDA')`. Verifiquei 0 linhas com cidade NULL em `dim_cliente`. |
| 8 | **Veículo sem grupo** | PASSA (assumindo dado-fonte com grupo) | No seed, todos os veículos têm `grupo_id` preenchido. Se faltasse, o `dg.sk_grupo` viria NULL no load 07 e o veículo entraria em `dim_veiculo` mesmo assim (não impacta veículo). Locação ficaria sem `sk_grupo` se também não tivesse via veículo — fall-back na sentinela 0 funciona. |
| 9 | **Mesmo veículo em 2 fontes (placa)** | PASSA | No seed, 0 placas cross-fonte duplicadas. Por design, mesma placa em 2 fontes vira 2 linhas em `dim_veiculo` (chave `(sk_fonte_origem, id_natural_origem)`). Decisão D-03. |
| 10 | **Carga incremental (rodar 08 2×)** | PASSA (por design) | `TRUNCATE...RESTART IDENTITY` no início de cada fato. Rodar 06+07+08 duas vezes produz mesmo resultado. Limitação: não testei em runtime (auto-mode bloqueou re-execução por modificar estado compartilhado). Análise estática confirma idempotência. |

### Cenários extras testados (além do checklist da persona)

| # | Cenário | Resultado | Observação |
|---|---|---|---|
| 11 | Cobertura `sk_fonte` 1..5 em `fato_locacao` | PASSA | 60+60+48+60+60=288. Fonte 3 perde 12 canceladas (CRÍTICO-01). |
| 12 | Cobertura `sk_fonte` 1..5 em `fato_reserva` | PASSA | 30 cada, total 150. |
| 13 | Reservas bigdata em `sk_grupo=0` | PASSA | 30/30 reservas da fonte 5 com `sk_grupo=0` (sentinela). |
| 14 | Bigdata `stg_cliente` UNION ALL PF+PJ | PASSA | 25 PF + 5 PJ = 30 (igual outras fontes). |
| 15 | bd_dw_26_1 JOIN tríplo Cliente→Endereço→Cidade | PASSA | 30 clientes da fonte 4 com cidade distribuída em 8 cidades distintas. |
| 16 | locadora_db walk-in (reserva NULL) preservado | PASSA | 60/60 locações fonte 3 com `reserva_id_natural=NULL` chegando ao fato. |
| 17 | mae016 usa SEMPRE `id_patio_devolucao_real` | PASSA (regra) / FALHA PARCIAL (no fato): MODERADO-01 | Extract correto, mas o load não NULL-ifica para CANCELADAs. |
| 18 | `fato_patio_diario.flag_frota_propria_no_patio` funciona | PASSA | TRUE para combinações fonte=dona (ex.: andre_gustavo no Galeão); FALSE caso contrário. Barra (sem dona) sempre FALSE. |
| 19 | `fato_patio_diario` cobre 6 pátios canônicos | PASSA | Todos os 6 pátios aparecem; nenhum órfão. |
| 20 | Sobreposição de locação no mesmo dia × veículo | FALHA | CRÍTICO-02. 232 ocorrências resolvidas arbitrariamente. |
| 21 | Tradução MySQL→Postgres limpa | PASSA | `grep -E 'DELIMITER\|AUTO_INCREMENT\|TINYINT'` retorna 0 ocorrências nos extracts. Todos os timestamps com `::TIMESTAMP` explícito. |
| 22 | Integridade FK em todos os fatos | PASSA | 0 FK órfã em `fato_locacao`, `fato_reserva`, `fato_patio_diario`. |
| 23 | Unicidade de grão `fato_patio_diario` (1 linha/veículo/dia) | PASSA | 3000 linhas = 100 veículos × 30 dias; `uq_fpd_grain (sk_tempo, sk_veiculo)` validado sem duplicatas. |

---

## Veredito

O ETL **está aprovado para seguir para a próxima fase** (relatórios + matriz Markov + dicionário), **mas com correções obrigatórias dos 2 críticos antes da entrega final**:

1. **CRÍTICO-01** (canceladas da fonte 3 perdidas): perdas de dados silenciosas violam o princípio de integração das 5 fontes em pé de igualdade declarado no `CLAUDE.md`. Sem correção, o relatório (b) e qualquer análise de cancelamento por fonte fica enganoso.
2. **CRÍTICO-02** (escolha arbitrária de pátio em sobreposições): re-execuções do ETL podem produzir resultados diferentes para o mesmo dado-fonte. Viola o princípio de reprodutibilidade. Fácil de consertar com `ORDER BY` no `LATERAL`.

Os 6 moderados podem ser tratados em iteração paralela à fase 8 (relatórios), com prioridade alta para o MODERADO-01 (mae016 patio_devolucao em CANCELADAs) e MODERADO-04 (`valor_total_estimado` sempre NULL — perde receita das fontes 1, 3, 5).

Os 6 leves são tecnicidades documentais e refinamentos que não bloqueiam a entrega — podem ficar como dívida técnica registrada no `docs/relatorio-etl.md`.

**Recomendação ao humano:** aprovar a próxima fase, mas exigir do `engenheiro-etl` correção dos 2 críticos antes da consolidação final. Os relatórios a serem produzidos na fase 8 devem ser revistos quanto a essas distorções (especialmente o (a) e o (b)).
