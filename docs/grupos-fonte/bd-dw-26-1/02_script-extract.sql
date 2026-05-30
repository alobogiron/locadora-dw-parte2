-- Ana Clara de Jesus Nascimento, DRE 124388471
-- Mariana Rocha de Moraes, DRE 122147926
-- Matheus Mangia Terra Suzano, DRE 123378716
-- Paulo Henrique Cotta de Assumpção, DRE 122156268
-- Pedro Nunes de Oliveira Pessanha, DRE 123177330
-- Ryan Domingos dos Santos Saraiva, DRE 123137429

USE locadora_dw_staging;

-- LIMPEZA DA STAGING AREA

TRUNCATE TABLE Stg_patio;
TRUNCATE TABLE Stg_veiculo;
TRUNCATE TABLE Stg_cliente;
TRUNCATE TABLE Stg_motorista;
TRUNCATE TABLE Stg_locacao;

-- PROCESSOS DE EXTRAÇÃO (ETL)

INSERT INTO Stg_patio (
    Sistema_Origem,
    Id_patio_oltp, 
    Nome_patio, 
    Cidade, 
    Uf, 
    Capacidade
)
SELECT DISTINCT
    'Grupo 01 - Alpha', -- Identificação da base de dados de origem (nossa equipe)
    P.Id_patio, 
    P.Nome_patio, 
    E.Cidade, 
    E.Uf, 
    P.Capacidade
FROM locadora_dw.Patio P
JOIN locadora_dw.Endereco E ON P.Id_endereco = E.Id_endereco;

INSERT INTO Stg_veiculo (
    Sistema_Origem,
    Id_veiculo_oltp, 
    Placa, 
    Marca, 
    Modelo, 
    Categoria_Nome, 
    Ano, 
    Tipo_Cambio, 
    Empresa_Dona
)
SELECT DISTINCT
    'Grupo 01 - Alpha',
    V.Id_veiculo, 
    V.Placa, 
    V.Marca, 
    V.Modelo, 
    C.Nome_categoria, 
    V.Ano, 
    V.Tipo_cambio, 
    Emp.Nome_empresa
FROM locadora_dw.Veiculo V
JOIN locadora_dw.Categoria C ON V.Id_categoria = C.Id_categoria
JOIN locadora_dw.Empresa Emp ON V.Id_empresa = Emp.Id_empresa;

INSERT INTO Stg_cliente (
    Sistema_Origem,
    Id_cliente_oltp, 
    Tipo_Cliente, 
    Nome_ou_Razao_Social, 
    Cidade, 
    Uf
)
SELECT DISTINCT
    'Grupo 01 - Alpha',
    C.Id_cliente, 
    C.Tipo_cliente,
    COALESCE(PF.Nome_cliente, PJ.Razao_social),
    E.Cidade, 
    E.Uf
FROM locadora_dw.Cliente C
JOIN locadora_dw.Endereco E ON C.Id_endereco = E.Id_endereco
LEFT JOIN locadora_dw.Cliente_pf PF ON C.Id_cliente = PF.Id_cliente
LEFT JOIN locadora_dw.Cliente_pj PJ ON C.Id_cliente = PJ.Id_cliente;

INSERT INTO Stg_motorista (
    Sistema_Origem,
    Id_motorista_oltp, 
    Nome_motorista, 
    Categoria_Cnh, 
    Genero_motorista, 
    Data_Nascimento
)
SELECT DISTINCT
    'Grupo 01 - Alpha',
    Id_motorista, 
    Nome_motorista, 
    Categoria_cnh, 
    Genero_motorista, 
    Data_nascimento_motorista
FROM locadora_dw.Motorista;

INSERT INTO Stg_locacao (
    Sistema_Origem,
    Id_locacao_oltp, 
    Id_patio_retirada_oltp, 
    Id_patio_devolucao_oltp, 
    Id_veiculo_oltp, 
    Id_cliente_oltp, 
    Id_motorista_oltp, 
    Data_Retirada, 
    Data_Devolucao, 
    Km_Retirada, 
    Km_Devolucao, 
    Valor_Total
)
SELECT 
    'Grupo 01 - Alpha',
    L.Id_locacao, 
    L.Id_patio_real_retirada, 
    L.Id_patio_real_devolucao,
    L.Id_veiculo, 
    R.Id_cliente, 
    L.Id_motorista,
    L.Data_hora_retirada_real, 
    L.Data_hora_devolucao_real,
    L.Km_retirada, 
    L.Km_devolucao, 
    L.Valor_total_final
FROM locadora_dw.Locacao L
JOIN locadora_dw.Reserva R ON L.Id_reserva = R.Id_reserva;