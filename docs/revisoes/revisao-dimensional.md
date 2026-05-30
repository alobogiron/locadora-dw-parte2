<!--
Avaliação 02 — Modelagem de DW — Parte II
Grupo:
  - Gustavo Oliveira Pessanha da Silva (DRE 122051824)
  - André Vinícius Lobo Giron (DRE 122050404)
-->

# Revisão Adversarial — Fase Dimensional

**Trabalho:** Avaliação 02 — Parte II — Modelagem de Data Warehouse
**Artefatos revisados:**
- `dimensional/modelo-dimensional.md`
- `dimensional/diagrama-estrela.md`
**Data:** 2026-05-30
**Revisor:** subagente `revisor-adversarial` (DBA sênior adversarial)
**Achados críticos:** 4
**Achados moderados:** 6
**Achados leves:** 5

### Grupo

| Nome completo | DRE |
|---|---|
| Gustavo Oliveira Pessanha da Silva | 122051824 |
| André Vinícius Lobo Giron | 122050404 |

---

## Resumo executivo

O modelo dimensional está **bem fundamentado em Kimball**, cobre formalmente os 4 relatórios + Markov, e justifica as decisões de SCD-1, role-playing e `sk_cliente` sem dedup. **Porém há 4 lacunas críticas** que se não tratadas na fase ETL produzirão relatórios incompletos ou inconsistentes:

1. **Relatório (a) não pode quebrar por marca/modelo/mecanização** com a granularidade declarada de `fato_patio_diario` (sem `sk_veiculo`) — contradiz frontalmente o enunciado.
2. **Definição de grão de `fato_patio_diario` é internamente contraditória** (texto diz "× situação", mas as colunas pivoteiam situação).
3. **`locadora-db` não tem amarração `veiculo → patio`**: como o ETL vai derivar `fato_patio_diario` para essa fonte sem inventar dados? P-02 não trata o caso.
4. **`bigdata.Reserva` não tem `IDCategoria`** (apenas `QtVeiculosSolicitados` + `CentroCusto`): o `fato_reserva` exige `sk_grupo`, mas não há grupo na fonte. Como popular?

Sem resolver esses quatro pontos no ETL (ou ajustar o modelo agora), o trabalho corre risco de ter relatórios silenciosamente incorretos. As demais ressalvas são moderadas a leves.

---

## Achados

### [CRÍTICO-01] Relatório (a) não pode segmentar por marca/modelo/mecanização

**Onde:** `modelo-dimensional.md` §3.3 (granularidade `fato_patio_diario`), §2 (bus matrix), §1 (relatório a).

**Problema:** O enunciado diz textualmente: "*Pode haver agrupamento por marca do veículo, modelos e tipo de mecanização*". O modelo declara o grão de `fato_patio_diario` como "(dia × pátio × grupo × fonte × situação)" — **sem `sk_veiculo`** — e a bus matrix explicita "`dim_veiculo` — (granularidade por grupo, não por veículo)". A justificativa fala em "drill across para `dim_veiculo`", mas drill across em Kimball exige uma dimensão conformada compartilhada *entre fatos* — não existe nenhum outro fato no modelo que tenha simultaneamente `dim_patio`, `dim_veiculo` e o conceito de "disponível no pátio no dia X". O `fato_locacao` tem `dim_veiculo`+`dim_patio`, mas é um fato de **transação** (uma locação), não de **estoque** — não responde "quantos veículos da marca VW estão disponíveis no Galeão hoje".

**Cenário que quebra:** usuário pede "quantos VW Gol manuais estão disponíveis no Galeão neste momento, segmentados por origem". O modelo atual não consegue responder: `fato_patio_diario` agrega por grupo, perde a placa, e `fato_locacao` só sabe das placas que **saíram em locação**, não das que estão paradas no pátio.

**Recomendação:** ou **(a)** adicionar `sk_veiculo` em `fato_patio_diario` mudando o grão para "(dia × pátio × veículo × situação)" — vira tabela bem maior, mas atende o enunciado; ou **(b)** introduzir um quarto fato `fato_estoque_veiculo_diario` em grão de veículo; ou **(c)** documentar explicitamente em P-XX que o agrupamento por marca/modelo/mecanização do enunciado **não é coberto pela fase atual**, e mencionar isso no relatório final. A opção (c) é honesta mas reduz a entrega.

**Referência:** Kimball cap. 5 ("Fact Table Grain") e cap. 7 ("Periodic Snapshot — Drill Across Considerations"); enunciado §a "Controle de pátio".

---

### [CRÍTICO-02] Grão de `fato_patio_diario` contraditório entre texto e schema

**Onde:** `modelo-dimensional.md` §3.3 — grão declarado vs lista de métricas.

**Problema:** O texto declara: *"Uma linha por combinação (dia × pátio × grupo × fonte da frota × **situação do veículo**)"*. Mas então lista colunas `qtd_veiculos_disponiveis`, `qtd_veiculos_alugados`, `qtd_veiculos_manutencao`, `qtd_veiculos_reservados` — ou seja, **a situação está pivoteada em colunas**, o que significa que **a situação NÃO entra no grão** (o grão real é dia × pátio × grupo × fonte). As duas formulações são incompatíveis: ou cada linha representa uma situação com uma única métrica `qtd_veiculos`, ou cada linha agrega todas as situações com 4 métricas em colunas. A definição vigente no modelo é ambígua e o engenheiro-etl não saberá qual implementar.

**Cenário que quebra:** o engenheiro-etl implementa o schema literal do diagrama (colunas pivoteadas) e o ETL produz uma linha por dia/pátio/grupo/fonte — não uma por situação. Depois alguém pergunta "qual a granularidade real?" e ninguém consegue responder.

**Recomendação:** decidir e documentar. Recomendamos pivot em colunas (manter as 4 colunas `qtd_*`) e corrigir o texto para *"Uma linha por combinação (dia × pátio × grupo × fonte)"*. Justificativa: o relatório (a) e a matriz Markov favorecem o formato pivoteado para SQL ad-hoc.

**Referência:** Kimball cap. 1 ("Declare the Grain") — o grão deve ser declarado em UMA frase sem ambiguidade.

---

### [CRÍTICO-03] `locadora-db` não tem amarração veículo → pátio

**Onde:** `modelo-dimensional.md` §1, §3.3, P-02; cruzamento com `docs/grupos-fonte/locadora-db/schema.sql` linhas 52-67.

**Problema:** A tabela `veiculo` da fonte `locadora-db` **não possui FK para `patio`**. Só tem `grupo_id` e `empresa_id`. A tabela `vaga` existe (linhas 100-106) mas tem só `status` ('livre'/'ocupada'), sem FK para veiculo. Não há nenhum modo de saber em qual dos 6 pátios cada veículo dessa fonte está num dado dia. A pendência P-02 ("snapshot derivado") não trata esse caso — apenas diz que será derivado "do estado atual e do histórico de locações". Mas para um veículo `disponivel` que nunca foi locado, não há nada para derivar dele.

**Cenário que quebra:** ao executar o relatório (a), os veículos da fonte `locadora-db` ficam fora da contagem por pátio (ou são atribuídos arbitrariamente). O resultado para "veículos disponíveis no Galeão" será sistematicamente subestimado proporcionalmente ao volume da fonte.

**Recomendação:** documentar explicitamente em P-08 (ou nova pendência) que para `locadora-db` o ETL fará uma atribuição arbitrária de pátio (round-robin entre os 6 canônicos) na fase de seed sintético — e que esse fato pesará no relatório final. Alternativa pior: descartar todos os veículos dessa fonte do `fato_patio_diario` (mas então o relatório (a) deixa de cobrir 1/5 das fontes).

**Referência:** enunciado §a; `docs/grupos-fonte/locadora-db/schema.sql:52-67` (tabela `veiculo` sem FK para `patio`).

---

### [CRÍTICO-04] `bigdata.Reserva` não tem categoria de veículo

**Onde:** `modelo-dimensional.md` §3.2 (`fato_reserva` referencia `sk_grupo`), §5.2 (de-para de grupo); cruzamento com `docs/grupos-fonte/bigdata/create_table.sql` linhas 270-296.

**Problema:** O `fato_reserva` exige FK `sk_grupo` (uma reserva é "por grupo"). Mas a fonte `bigdata` modela `Reserva` apenas com `QtVeiculosSolicitados`, `DtReserva`, `DtRetiradaPrevista`, `DtLimiteRetirada`, `Status`, `IDCentroCusto`. **Não há `IDCategoria` em `Reserva`**. As 4 outras fontes têm a categoria/grupo na reserva (`reserva.grupo_id` em locadora-dw-parte1; `RESERVA.id_grupo` em mae016; `reserva.grupo_id` em locadora-db; `Reserva.Id_categoria` em bd-dw-26-1).

**Cenário que quebra:** ao popular `fato_reserva` a partir da bigdata, não há valor para `sk_grupo`. Opções: usar sentinela "GRUPO_DESCONHECIDO" (e o relatório c terá uma linha enorme nessa categoria) ou descartar as reservas da bigdata (perde-se 1/5 da cobertura do relatório c).

**Recomendação:** documentar essa lacuna em P-XX e decidir formalmente entre **(a)** linha sentinela "GRUPO_NAO_INFORMADO" em `dim_grupo` (já há precedente de sentinela em §4.2 para `dim_patio`); **(b)** descartar reservas da `bigdata`; ou **(c)** atribuição sintética por round-robin no seed. Sem isso, o engenheiro-etl tomará a decisão sozinho de forma indocumentada.

**Referência:** enunciado §c; `docs/grupos-fonte/bigdata/create_table.sql:270-296`.

---

### [MODERADO-01] `dias_antecedencia` classificado como aditivo é semanticamente incorreto

**Onde:** `modelo-dimensional.md` §3.2, tabela de métricas de `fato_reserva`.

**Problema:** A métrica está marcada como "aditiva". Somar dias_antecedencia de várias reservas não tem sentido analítico — o uso natural é **média** (qual a antecedência média das reservas para o Galeão?). Métricas cuja operação natural é média são **não-aditivas** em Kimball; a soma só serve como passo intermediário para o cálculo da média.

**Cenário que quebra:** um relatório agrega `SUM(dias_antecedencia)` segmentado por pátio. O número resultante (ex.: "1 234 dias") não significa nada — não é a antecedência total, não é a média. Confunde o usuário.

**Recomendação:** reclassificar como **não-aditiva** (média). Mesma observação vale para `duracao_prevista_dias` e `duracao_real_dias` em `fato_locacao`, mas nesses dois há uso somatório legítimo (tempo total de uso de veículos) — então a marcação atual "aditiva" é defensável, embora um aviso na descrição ajude.

**Referência:** Kimball cap. 1 ("Additivity of Facts"); Elmasri & Navathe cap. 29 ("Aggregate Functions in OLAP").

---

### [MODERADO-02] Locação em andamento — tratamento de `sk_tempo_devolucao_real` é ambíguo

**Onde:** `modelo-dimensional.md` §3.1 (lista `sk_tempo_devolucao_real`), §4.1 (sentinela `19000101`), §8 D-10 (sentinela).

**Problema:** Para uma locação `EM_ANDAMENTO`, o que vai em `sk_tempo_devolucao_real`? D-10 diz "linhas órfãs em fatos referenciam a sentinela em vez de NULL". Mas uma locação em andamento **não é órfã** — é um estado válido e esperado, com semântica "ainda não devolvido". Tratar com sentinela `19000101` ("DATA_DESCONHECIDA") perde a semântica de "em andamento" e mistura com "data faltante por bug de ETL". Permitir NULL preserva a semântica, ao custo de quebrar `INNER JOIN` (resolvível com `LEFT JOIN` consciente).

**Cenário que quebra:** o relatório (b) "tempo restante para devolução" filtra locações `EM_ANDAMENTO` e tenta calcular `dim_tempo_prevista.data - CURRENT_DATE`. Se `sk_tempo_devolucao_real` for sentinela `19000101`, o usuário precisa lembrar de excluir essa data; se for NULL, o `WHERE sk_tempo_devolucao_real IS NULL` é a forma natural.

**Recomendação:** documentar explicitamente em D-10 (ou nova decisão) qual política se aplica a `sk_tempo_devolucao_real` em locações `EM_ANDAMENTO`: permitir NULL (e justificar com semântica "ainda não ocorreu") em vez de usar sentinela. O texto atual deixa em aberto e o engenheiro-etl decidirá ad-hoc.

**Referência:** Kimball cap. 6 ("Handling Null Date Foreign Keys") — discute explicitamente este caso e recomenda NULL para eventos que ainda não ocorreram, sentinela para eventos cujos dados se perderam.

---

### [MODERADO-03] `cidade_origem` de cliente PJ da `bigdata` é ambígua

**Onde:** `modelo-dimensional.md` §4.5 (`dim_cliente.cidade_origem`), §5.3 (linha bigdata: "via FK para `Endereco.Cidade`"); cruzamento com `docs/grupos-fonte/bigdata/create_table.sql` linhas 165-185 (`Empresa`) e 270-296 (`Reserva`→`CentroCusto`).

**Problema:** Na bigdata, `Reserva` aponta para `CentroCusto`, que aponta **para Empresa OU PessoaFisica** (CHECK XOR). A cidade do cliente da reserva está em `PessoaFisica.IDEndereco → Endereco.Cidade` (caso PF) ou em `Empresa.IDEndereco → Endereco.Cidade` (caso PJ). O modelo dimensional menciona "via FK para `Endereco.Cidade`" mas não detalha o caminho dual. O engenheiro-etl pode confundir os dois e perder metade das reservas no relatório (c).

**Cenário que quebra:** reserva da bigdata feita por uma empresa (CentroCusto.IDEmpresa NOT NULL, IDFisica NULL). O ETL escolhe o caminho errado (`PessoaFisica` ou `Empresa`) e o cliente acaba com cidade "DESCONHECIDA", caindo fora do agrupamento por cidade no relatório (c).

**Recomendação:** acrescentar em §5.3 um esboço de pseudocódigo do caminho de JOIN para cada fonte. Particularmente: "para bigdata, derivar cidade via `COALESCE(Empresa.IDEndereco, PessoaFisica.IDEndereco)` em função de qual lado do CentroCusto está preenchido". Não modifica o modelo, mas elimina ambiguidade na fase ETL.

**Referência:** `docs/grupos-fonte/bigdata/create_table.sql:216-240` (CentroCusto XOR).

---

### [MODERADO-04] `numero_contrato_fonte` será NULL na maioria das fontes

**Onde:** `modelo-dimensional.md` §3.1 (degenerate dimension `numero_contrato_fonte`); cruzamento com os 5 DDLs.

**Problema:** Apenas `locadora-dw-parte1` (fonte do próprio grupo) tem `locacao.numero_contrato VARCHAR(30) NOT NULL UNIQUE`. As outras 4 fontes (mae016, locadora-db, bd-dw-26-1, bigdata) **não expõem número de contrato**. Portanto a degenerate dimension `numero_contrato_fonte` terá ~80% dos valores NULL no DW final. Em si não é um erro, mas degenerate dimensions servem para identificar a transação na fonte — se 4/5 das fontes não têm, o valor analítico é baixo.

**Cenário que quebra:** auditoria reversa: "encontre no OLTP a transação que originou esta linha do DW". Para 4/5 das fontes, `numero_contrato_fonte` é NULL e a única forma de voltar à fonte é via `sk_fonte + id_locacao_origem` — mas `id_locacao_origem` não está na tabela.

**Recomendação:** ou **(a)** remover `numero_contrato_fonte` do fato (não acrescenta valor); ou **(b)** acrescentar uma segunda degenerate dimension `id_locacao_origem INT` (PK da locação na fonte) — esse seria preenchido por 5/5 das fontes e serve auditoria reversa. Recomenda-se (b).

**Referência:** Kimball cap. 3 ("Degenerate Dimensions") — auditoria reversa.

---

### [MODERADO-05] mae016 — 3 caminhos de pátio na Locacao não tratados explicitamente

**Onde:** `modelo-dimensional.md` §3.1 (FKs `sk_patio_retirada`, `sk_patio_devolucao`); cruzamento com `docs/grupos-fonte/mae016/01_create_table.sql` linhas 78-93.

**Problema:** A fonte `mae016` modela 3 pátios distintos em `Locacao`: `id_patio_retirada`, `id_patio_devolucao_previsto`, `id_patio_devolucao_real` (esse último NULLABLE). O modelo dimensional só tem 2 colunas (`sk_patio_retirada`, `sk_patio_devolucao`) e não diz qual de "previsto" ou "real" alimentar. Para a matriz Markov, deve ser **real** (movimentação efetiva). Para "para onde planejei devolver", deve ser **previsto**.

**Cenário que quebra:** matriz Markov calculada a partir de `patio_devolucao = id_patio_devolucao_previsto` em vez de `id_patio_devolucao_real` — viraria a "matriz de devolução planejada", não a "matriz de devolução efetiva". Resultado teoricamente diferente e tecnicamente errado segundo o enunciado.

**Recomendação:** explicitar em §3.1 que `sk_patio_devolucao` corresponde sempre ao **real** quando a fonte distingue, e NULL/sentinela quando a locação está EM_ANDAMENTO. Em fontes que só têm previsto (ou só têm um campo), usar o que houver. Documentar a regra em uma frase.

**Referência:** `docs/grupos-fonte/mae016/01_create_table.sql:78-93`; enunciado §Markov.

---

### [MODERADO-06] Reserva cancelada — política de inclusão no relatório (c) não definida

**Onde:** `modelo-dimensional.md` §3.2 (status_reserva: CONFIRMADA, EM_FILA_ESPERA, CANCELADA, CONCRETIZADA); §1 (relatório c).

**Problema:** O relatório (c) pede "controle de reservas por grupo, pátio, antecedência, cidade". O modelo armazena `status_reserva` (incluindo `CANCELADA`) mas não diz se canceladas entram nas contagens do (c). Sem essa decisão, o engenheiro-etl pode incluir todas (inflando o número) ou só CONFIRMADA+EM_FILA_ESPERA+CONCRETIZADA (mais útil, mas arbitrário).

**Cenário que quebra:** cliente reserva 10× para o Galeão na semana, cancela 8, fica com 2. Sem filtro definido, o relatório (c) reporta "10 reservas para Galeão" — número correto contabilmente, mas enganoso operacionalmente.

**Recomendação:** documentar em §3.2 (ou em nova pendência) que o relatório (c) filtra por padrão `status_reserva IN ('CONFIRMADA','EM_FILA_ESPERA','CONCRETIZADA')` — excluindo canceladas. Permitir override via parâmetro do relatório.

**Referência:** enunciado §c (interpretação operacional).

---

### [LEVE-01] `flag_tem_condutor_associado` é inconsistente cross-fonte

**Onde:** `modelo-dimensional.md` §4.5.

**Problema:** A flag é definida como "true para PJ quando a fonte expõe condutores; false para PF". Mas `mae016` e `locadora-db` modelam condutor para **qualquer** cliente (não só PJ). Isso quebra a regra interna. A flag não é "tem condutor associado" — é "é cliente PJ E a fonte registrou condutor".

**Recomendação:** simplificar para `flag_eh_pessoa_juridica BOOLEAN` ou remover a flag. Não é usada em nenhum dos 4 relatórios.

---

### [LEVE-02] `descricao_periodo` em `dim_tempo` tem rótulo ambíguo

**Onde:** `modelo-dimensional.md` §4.1 e §6.

**Problema:** o atributo está descrito como "rótulo 'Q2/2025', 'Janeiro 2025'". Dois rótulos diferentes para o mesmo atributo geram inconsistência. Decidir uma forma e fixar.

**Recomendação:** fixar um único formato (sugestão: `mes_nome || ' ' || ano`) ou desdobrar em dois atributos (`descricao_mes_ano`, `descricao_trimestre_ano`).

---

### [LEVE-03] `dim_tempo` cardinalidade declarada não bate

**Onde:** `modelo-dimensional.md` §4.1 diz "~4 015 linhas (2020-2030)"; §6 diz "4 018 linhas considerando bissextos".

**Problema:** divergência de 3 linhas entre dois números no mesmo documento. A conta correta é 11 anos × 365 + 3 bissextos (2020, 2024, 2028) = 4 018. O número certo é 4 018.

**Recomendação:** corrigir §4.1 para 4 018.

---

### [LEVE-04] `dim_tempo.eh_feriado_nacional` — sem definição da fonte da lista

**Onde:** `modelo-dimensional.md` §4.1 e §6.

**Problema:** atributo declarado mas a lista de feriados a usar não está documentada. Há diferenças entre lista Lei 662/1949 (nacional pura) e listas estendidas. Em 11 anos × ~12 feriados nacionais = 132 linhas marcadas — relevante para análises sazonais.

**Recomendação:** documentar em §6 a fonte (ex.: "feriados nacionais conforme Lei 662/1949 + Lei 6.802/1980 + Lei 10.607/2002", ou referenciar `python-holidays` BR).

---

### [LEVE-05] `valor_diaria_referencia` em `dim_grupo` — política de cálculo vaga

**Onde:** `modelo-dimensional.md` §4.4, §5.2 ("Preço de referência: média dos preços por grupo entre as fontes que expõem").

**Problema:** `locadora-db` não expõe preço (confirmado em `docs/grupos-fonte/locadora-db/schema.sql:43-47` — tabela `grupo_veiculo` só tem `nome` e `categoria`). A "média entre fontes que expõem" deixa de fora 1/5 das fontes. Aceitável, mas a fórmula deve dizer "média não ponderada das outras 4 fontes" ou "mediana" para evitar viés.

**Recomendação:** fixar a fórmula em uma frase: "média aritmética simples dos `valor_diaria` por grupo nas 4 fontes que expõem preço".

---

## Cenários testados

Os 10 cenários do checklist da persona, executados mentalmente contra o modelo:

| #  | Cenário | Resultado | Observação |
|----|---------|-----------|------------|
| 1  | Cliente em 2 fontes (mesmo CPF) — conta como 1 ou 2 em `dim_cliente`? | **PASSA** | D-03 documenta política explícita: 2 linhas distintas. Impacto no (d) discutido e aceito (cf. tradeoff: cidade pode divergir). |
| 2  | Pátio com nome ligeiramente diferente ("Galeão" vs "Aeroporto do Galeão" vs "AEROPORTO INTERNACIONAL DO GALEÃO") | **PASSA** | §5.1 lista as variantes; `staging.de_para_patio` resolve. |
| 3  | Grupo "Econômico" vs "Económico" vs "ECON" | **FALHA PARCIAL** | §5.2 menciona o de-para mas P-06 adia o vocabulário canônico para o ETL. Aceitável, mas torna o checklist incompleto nesta fase. |
| 4  | Locação `EM_ANDAMENTO` sem `data_devolucao_real` — aparece no (b) com `dias_restantes < 0`? | **FALHA PARCIAL** | Modelo não diz se `sk_tempo_devolucao_real` é NULL ou sentinela; aspecto fundamental para o (b). Cf. MODERADO-02. |
| 5  | Reserva cancelada entra no relatório (c)? | **FALHA PARCIAL** | Status existe na dimensão mas não há política definida. Cf. MODERADO-06. |
| 6  | Locação com `patio_retirada = patio_devolucao` — entra na diagonal da Markov? | **PASSA** | D-09 explicita: agregação `(sk_patio_retirada, sk_patio_devolucao)` sem `<>` — diagonal incluída. |
| 7  | Cidade do cliente NULL (fonte sem Endereco) | **FALHA PARCIAL** | Modelo permite mas sentinela "CIDADE_DESCONHECIDA" em `dim_cliente.cidade_origem` não está declarada. Relatório (c) terá NULL agrupado ou grupo arbitrário. |
| 8  | Veículo sem grupo em alguma fonte | **PASSA** | Os 5 DDLs analisados: todos têm FK obrigatória de veículo para grupo. Não há cenário real. |
| 9  | Mesmo veículo em 2 fontes (placa repetida) — duplica `dim_veiculo`? | **PASSA** | §5.4 documenta política `(sk_fonte, placa_normalizada)` — 2 linhas distintas. Consistente com `sk_cliente`. |
| 10 | Carga incremental — `08_load_fatos.sql` 2x duplica? | **FORA DE ESCOPO** | Cenário de fase ETL, não dimensional. Não revisado aqui. |

**Cenários adicionais testados (além da persona):**

| #   | Cenário extra | Resultado |
|-----|---------------|-----------|
| 11  | Relatório (a) por marca/modelo/mecanização — coberto? | **FALHA** | Cf. CRÍTICO-01. |
| 12  | Grão `fato_patio_diario` é único? | **FALHA** | Cf. CRÍTICO-02. |
| 13  | `locadora-db` veículo → pátio: existe? | **FALHA** | Cf. CRÍTICO-03. |
| 14  | `bigdata.Reserva` → grupo: existe? | **FALHA** | Cf. CRÍTICO-04. |
| 15  | Matriz Markov 6×6 (incl. diagonal) é gerável? | **PASSA** | D-09 + diagonal confirmada via cenário 6. Soma por linha = 1.0 é responsabilidade do ETL. |
| 16  | Bus matrix permite drill-across entre `fato_locacao` e `fato_reserva` por `(dim_grupo, dim_patio, dim_cliente, dim_fonte)`? | **PASSA** | §2 — todas as 4 dimensões são compartilhadas. |

---

## Veredito

**Itera.** O modelo está conceitualmente sólido e ancorado em Kimball, com decisões bem fundamentadas (D-01 a D-10). Mas há **4 lacunas críticas** que, se não tratadas antes da fase ETL, causarão um dos três cenários: (i) relatório (a) entregue **incompleto** (sem marca/modelo/mecanização — CRÍTICO-01); (ii) ETL produzido sobre um grão ambíguo, gerando schema diferente da intenção (CRÍTICO-02); (iii) fontes parcialmente perdidas no `fato_patio_diario` e `fato_reserva` por ausência de dados-chave nas OLTPs originais (CRÍTICO-03, CRÍTICO-04).

Os 4 críticos não exigem refatoração ampla do modelo — exigem **decisões explícitas e documentadas** que reduzam ambiguidade para a fase ETL. Recomenda-se uma iteração curta do `modelador-dimensional` para tratar especificamente:

1. Adicionar `sk_veiculo` em `fato_patio_diario` OU registrar limitação explícita do relatório (a) em P-09.
2. Reescrever o grão de `fato_patio_diario` em UMA frase clara, alinhada ao schema do diagrama.
3. Acrescentar P-09 ou P-10 documentando a estratégia para `locadora-db` (sem patio→veiculo) e `bigdata.Reserva` (sem categoria).

Os MODERADOS são mais leves — podem ser corrigidos junto ou deixados para o `engenheiro-etl` tratar com as decisões explícitas. Os LEVES são higiene, podem aguardar a fase de relatório PDF final.

**Aprovado para próxima fase APÓS** as 4 correções críticas e idealmente os 6 moderados.
