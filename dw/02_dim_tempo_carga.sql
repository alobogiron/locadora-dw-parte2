-- =====================================================================
--  Avaliacao 02 — Modelagem de Data Warehouse — Parte II
--  Arquivo: dw/02_dim_tempo_carga.sql
--  Objetivo: Funcao PL/pgSQL para popular dw.dim_tempo, e carga inicial
--            do intervalo 2020-01-01 .. 2030-12-31.
--
--  Grupo:
--    - Gustavo Oliveira Pessanha da Silva — DRE 122051824
--    - Andre Vinicius Lobo Giron           — DRE 122050404
--
--  SGBD-alvo: PostgreSQL 16
--
--  Estrategia:
--    1. Inserir sentinela sk_tempo = 19000101 (DATA_DESCONHECIDA).
--    2. Criar funcao popular_dim_tempo(data_inicio DATE, data_fim DATE).
--    3. Executar a funcao para o intervalo padrao do projeto (2020..2030).
--    4. Marcar feriados nacionais brasileiros 2020-2030 num UPDATE final.
--
--  Smart-key: YYYYMMDD::INTEGER (ex.: 30 maio 2025 -> 20250530).
-- =====================================================================

SET search_path = dw;


-- =====================================================================
-- 1. Sentinela DATA_DESCONHECIDA
-- =====================================================================
-- ON CONFLICT: idempotencia para re-execucao.
INSERT INTO dim_tempo (
    sk_tempo, data_completa, ano, semestre, trimestre, bimestre,
    mes_numero, mes_nome, mes_abreviado, semana_ano,
    dia_mes, dia_ano, dia_semana_numero, dia_semana_nome,
    eh_fim_de_semana, eh_feriado_nacional, descricao_periodo
) VALUES (
    19000101, DATE '1900-01-01', 1900, 1, 1, 1,
    1, 'DESCONHECIDO', 'N/A', 1,
    1, 1, 0, 'DESCONHECIDO',
    FALSE, FALSE, 'DATA DESCONHECIDA'
) ON CONFLICT (sk_tempo) DO NOTHING;


-- =====================================================================
-- 2. Funcao popular_dim_tempo
-- =====================================================================
CREATE OR REPLACE FUNCTION popular_dim_tempo(
    data_inicio DATE,
    data_fim    DATE
) RETURNS INTEGER AS $$
DECLARE
    v_data     DATE;
    v_inseridos INTEGER := 0;
    -- Nomes em PT-BR
    v_meses TEXT[] := ARRAY[
        'Janeiro','Fevereiro','Marco','Abril','Maio','Junho',
        'Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'
    ];
    v_meses_abr TEXT[] := ARRAY[
        'Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'
    ];
    -- EXTRACT(DOW FROM ...) retorna 0=Domingo, 6=Sabado.
    v_dias_semana TEXT[] := ARRAY[
        'Domingo','Segunda','Terca','Quarta','Quinta','Sexta','Sabado'
    ];
BEGIN
    IF data_inicio > data_fim THEN
        RAISE EXCEPTION 'data_inicio (%) > data_fim (%)', data_inicio, data_fim;
    END IF;

    v_data := data_inicio;
    WHILE v_data <= data_fim LOOP
        INSERT INTO dim_tempo (
            sk_tempo,
            data_completa,
            ano,
            semestre,
            trimestre,
            bimestre,
            mes_numero,
            mes_nome,
            mes_abreviado,
            semana_ano,
            dia_mes,
            dia_ano,
            dia_semana_numero,
            dia_semana_nome,
            eh_fim_de_semana,
            eh_feriado_nacional,
            descricao_periodo
        ) VALUES (
            (EXTRACT(YEAR FROM v_data) * 10000
             + EXTRACT(MONTH FROM v_data) * 100
             + EXTRACT(DAY FROM v_data))::INTEGER,
            v_data,
            EXTRACT(YEAR     FROM v_data)::INTEGER,
            CASE WHEN EXTRACT(MONTH FROM v_data) <= 6 THEN 1 ELSE 2 END,
            EXTRACT(QUARTER  FROM v_data)::INTEGER,
            ((EXTRACT(MONTH FROM v_data)::INTEGER - 1) / 2) + 1,
            EXTRACT(MONTH    FROM v_data)::INTEGER,
            v_meses[EXTRACT(MONTH FROM v_data)::INTEGER],
            v_meses_abr[EXTRACT(MONTH FROM v_data)::INTEGER],
            EXTRACT(WEEK     FROM v_data)::INTEGER,
            EXTRACT(DAY      FROM v_data)::INTEGER,
            EXTRACT(DOY      FROM v_data)::INTEGER,
            EXTRACT(DOW      FROM v_data)::INTEGER,
            v_dias_semana[EXTRACT(DOW FROM v_data)::INTEGER + 1],
            (EXTRACT(DOW FROM v_data)::INTEGER IN (0, 6)),
            FALSE,  -- feriado: UPDATE posterior
            'Q' || EXTRACT(QUARTER FROM v_data)::TEXT || '/' || EXTRACT(YEAR FROM v_data)::TEXT
        ) ON CONFLICT (sk_tempo) DO NOTHING;

        v_inseridos := v_inseridos + 1;
        v_data := v_data + INTERVAL '1 day';
    END LOOP;

    RETURN v_inseridos;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION popular_dim_tempo(DATE, DATE) IS
  'Popula dw.dim_tempo no intervalo informado. Smart-key YYYYMMDD. Idempotente via ON CONFLICT.';


-- =====================================================================
-- 3. Carga inicial: 2020-01-01 a 2030-12-31
-- =====================================================================
SELECT popular_dim_tempo(DATE '2020-01-01', DATE '2030-12-31');


-- =====================================================================
-- 4. Marcar feriados nacionais brasileiros (2020-2030)
-- =====================================================================
-- Feriados de data fixa (8 anuais). Carnaval/Paixao/Corpus Christi sao moveis
-- e exigiriam tabela calculada — assumido fora de escopo desta entrega
-- (atributo eh defensivo; nenhum relatorio depende de feriado movel).

UPDATE dim_tempo
   SET eh_feriado_nacional = TRUE
 WHERE data_completa IS NOT NULL
   AND (
        (EXTRACT(MONTH FROM data_completa) =  1 AND EXTRACT(DAY FROM data_completa) =  1) OR -- Confraternizacao Universal
        (EXTRACT(MONTH FROM data_completa) =  4 AND EXTRACT(DAY FROM data_completa) = 21) OR -- Tiradentes
        (EXTRACT(MONTH FROM data_completa) =  5 AND EXTRACT(DAY FROM data_completa) =  1) OR -- Dia do Trabalho
        (EXTRACT(MONTH FROM data_completa) =  9 AND EXTRACT(DAY FROM data_completa) =  7) OR -- Independencia
        (EXTRACT(MONTH FROM data_completa) = 10 AND EXTRACT(DAY FROM data_completa) = 12) OR -- N. S. Aparecida
        (EXTRACT(MONTH FROM data_completa) = 11 AND EXTRACT(DAY FROM data_completa) =  2) OR -- Finados
        (EXTRACT(MONTH FROM data_completa) = 11 AND EXTRACT(DAY FROM data_completa) = 15) OR -- Proclamacao da Republica
        (EXTRACT(MONTH FROM data_completa) = 12 AND EXTRACT(DAY FROM data_completa) = 25)    -- Natal
   );


RESET search_path;

-- =====================================================================
-- Fim do arquivo: dw/02_dim_tempo_carga.sql
-- =====================================================================
