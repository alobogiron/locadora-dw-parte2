<!--
Avaliação 02 — Modelagem de DW — Parte II
Grupo:
  - Gustavo Oliveira Pessanha da Silva (DRE 122051824)
  - André Vinícius Lobo Giron (DRE 122050404)
-->

# Diagrama do Esquema Estrela — Data Warehouse da Locadora Associada

**Trabalho:** Avaliação 02 — Parte II — Modelagem de Data Warehouse
**Notação:** Mermaid `erDiagram`
**Conteúdo:** 3 tabelas de fato (`FATO_LOCACAO`, `FATO_RESERVA`, `FATO_PATIO_DIARIO`) e 6 dimensões conformadas (`DIM_TEMPO`, `DIM_PATIO`, `DIM_VEICULO`, `DIM_GRUPO`, `DIM_CLIENTE`, `DIM_FONTE`).
**Versão:** v1.1 (após revisão dimensional 2026-05-30 — vide `docs/revisoes/revisao-dimensional.md`).

### Grupo

| Nome completo | DRE |
|---|---|
| Gustavo Oliveira Pessanha da Silva | 122051824 |
| André Vinícius Lobo Giron | 122050404 |

---

```mermaid
erDiagram
    FATO_LOCACAO {
        int sk_locacao PK
        bigint id_locacao_origem
        int sk_tempo_retirada_real FK
        int sk_tempo_devolucao_real FK "NULL se EM_ANDAMENTO"
        int sk_tempo_devolucao_prevista FK
        int sk_patio_retirada FK
        int sk_patio_devolucao FK "NULL se EM_ANDAMENTO"
        int sk_veiculo FK
        int sk_grupo FK
        int sk_cliente FK
        int sk_fonte FK
        string numero_contrato_fonte "NULL em 4/5 fontes"
        string status_locacao
        int qtd_locacoes
        int duracao_prevista_dias
        int duracao_real_dias
        int km_rodados
        number valor_diaria_aplicada
        number valor_total_estimado
        number valor_total_final
    }

    FATO_RESERVA {
        int sk_reserva PK
        bigint id_reserva_origem
        int sk_tempo_reserva FK
        int sk_tempo_retirada_prevista FK
        int sk_tempo_devolucao_prevista FK
        int sk_patio_retirada FK
        int sk_patio_devolucao FK
        int sk_grupo FK "sentinela 0 para bigdata"
        int sk_cliente FK
        int sk_fonte FK
        string status_reserva
        int qtd_reservas
        int qtd_veiculos_solicitados
        int duracao_prevista_dias
        int dias_antecedencia "nao-aditiva (media)"
        number valor_previsto
    }

    FATO_PATIO_DIARIO {
        int sk_patio_diario PK
        int sk_tempo FK
        int sk_patio FK
        int sk_veiculo FK
        int sk_grupo FK
        int sk_fonte FK
        string situacao
        bool flag_frota_propria_no_patio
        int qtd_veiculos
        int capacidade_vagas_patio
    }

    DIM_TEMPO {
        int sk_tempo PK
        date data_completa
        int ano
        int semestre
        int trimestre
        int bimestre
        int mes_numero
        string mes_nome
        string mes_abreviado
        int semana_ano
        int dia_mes
        int dia_ano
        int dia_semana_numero
        string dia_semana_nome
        bool eh_fim_de_semana
        bool eh_feriado_nacional
        string descricao_mes_ano
        string descricao_trimestre_ano
    }

    DIM_PATIO {
        int sk_patio PK
        string nome_canonico
        string apelido
        string tipo_local
        string cidade
        string endereco_descritivo
        int capacidade_vagas_referencia
        bool flag_funciona_24h
        string codigo_fonte_dona "NULL p/ Barra"
    }

    DIM_VEICULO {
        int sk_veiculo PK
        int sk_fonte_origem
        string placa
        string chassi
        string renavam
        string marca
        string modelo
        string cor
        int ano_fabricacao
        string mecanizacao
        bool tem_ar_condicionado
        bool tem_adaptacao_cadeirante
        int capacidade_pessoas
        int capacidade_porta_malas
        string categoria_dimensoes
        string situacao_atual
    }

    DIM_GRUPO {
        int sk_grupo PK
        string nome_grupo_normalizado
        string codigo_curto
        string classe_luxo
        number valor_diaria_referencia
        int franquia_km_diaria_referencia
        string descricao
    }

    DIM_CLIENTE {
        int sk_cliente PK
        int sk_fonte_origem
        string tipo_pessoa
        string nome
        string nome_fantasia
        string cidade_origem
        string uf_origem
        string email
        string telefone
        string cpf_normalizado
        string cnpj_normalizado
        bool flag_eh_pessoa_juridica
    }

    DIM_FONTE {
        int sk_fonte PK
        string codigo_fonte
        string nome_empresa_associada
        string sgbd_original
        string descricao
    }

    FATO_LOCACAO }o--|| DIM_TEMPO   : "retirada real / devolucao real / devolucao prevista (3 papeis)"
    FATO_LOCACAO }o--|| DIM_PATIO   : "retirada / devolucao (2 papeis)"
    FATO_LOCACAO }o--|| DIM_VEICULO : envolve
    FATO_LOCACAO }o--|| DIM_GRUPO   : pertence
    FATO_LOCACAO }o--|| DIM_CLIENTE : firma
    FATO_LOCACAO }o--|| DIM_FONTE   : origem

    FATO_RESERVA }o--|| DIM_TEMPO   : "reserva / retirada prevista / devolucao prevista (3 papeis)"
    FATO_RESERVA }o--|| DIM_PATIO   : "retirada / devolucao (2 papeis)"
    FATO_RESERVA }o--|| DIM_GRUPO   : solicita
    FATO_RESERVA }o--|| DIM_CLIENTE : realiza
    FATO_RESERVA }o--|| DIM_FONTE   : origem

    FATO_PATIO_DIARIO }o--|| DIM_TEMPO    : "dia do snapshot"
    FATO_PATIO_DIARIO }o--|| DIM_PATIO    : "onde o veiculo esta"
    FATO_PATIO_DIARIO }o--|| DIM_VEICULO  : "veiculo observado"
    FATO_PATIO_DIARIO }o--|| DIM_GRUPO    : segmenta
    FATO_PATIO_DIARIO }o--|| DIM_FONTE    : "origem da frota"
```
