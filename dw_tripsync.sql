-- =========================================================
-- FACT TABLE: fact_gasto
-- =========================================================

SELECT
    CAST(g.fecha AS DATE) AS ID_FECHA,
    u.id_usuario,
    v.id_viaje,
    c.id_categoria,
    d.id_destino,
    m.id_moneda,
    tt.id_tipo_transporte,
    DATEDIFF(YEAR, u.fecha_nacimiento, g.fecha) AS id_edad,
    1 AS CANTIDAD,
    g.monto AS MONTO,
    DATEDIFF(DAY, v.fecha_inicio, v.fecha_final) AS DURACION,
    DATEDIFF(YEAR, u.fecha_nacimiento, g.fecha) AS EDAD
INTO fact_gasto
FROM GASTO g
INNER JOIN USUARIO_POR_VIAJE upv ON g.id_usuario_por_viaje = upv.id_usuario_por_viaje
INNER JOIN USUARIO u ON upv.id_usuario = u.id_usuario
INNER JOIN VIAJE v ON upv.id_viaje = v.id_viaje
INNER JOIN CATEGORIA c ON g.id_categoria = c.id_categoria
INNER JOIN MONEDA m ON g.id_moneda = m.id_moneda
INNER JOIN DESTINO d ON v.id_destino = d.id_destino
INNER JOIN TIPO_TRANSPORTE tt ON v.id_tipo_transporte = tt.id_tipo_transporte;

-- =========================================================
-- DIMENSIONES ADICIONALES
-- =========================================================

CREATE TABLE dim_rango_edad (
    id_rango_edad INT NOT NULL,
    descripcion VARCHAR(100),
    CONSTRAINT pk_rango_edad PRIMARY KEY (id_rango_edad)
);

CREATE TABLE dim_edad (
    id_edad INT NOT NULL,
    id_rango_edad INT NOT NULL,
    CONSTRAINT pk_edad PRIMARY KEY (id_edad)
);

CREATE TABLE DIM_ANIO (
    ID_ANIO INT,
    DESCRIPCION CHAR(4) NOT NULL
);

CREATE TABLE DIM_MES (
    ID_MES INT NOT NULL,
    DESCRIPCION CHAR(8) NOT NULL,
    ID_ANIO INT
);

CREATE TABLE DIM_FECHA (
    ID_FECHA DATE NOT NULL,
    DESCRIPCION CHAR(10) NOT NULL,
    ID_MES INT NOT NULL
);

-- =========================================================
-- POBLADO DE DIMENSIONES
-- =========================================================

INSERT INTO dbo.DIM_RANGO_EDAD (id_rango_edad, descripcion) VALUES
(0, 'Menores'),
(1, 'Adultos'),
(2, 'Adultos mayores'),
(3, 'Ancianos');

-- dim_edad se puebla mapeando cada edad individual (1-120) a su rango correspondiente
-- (ver informe completo para el detalle de los 120 valores insertados)

INSERT INTO DIM_FECHA
SELECT DISTINCT
    CAST(ID_FECHA AS DATE) AS FECHA,
    CONCAT(FORMAT(YEAR(ID_FECHA), '0000'), '-', FORMAT(MONTH(ID_FECHA), '00'), '-', FORMAT(DAY(ID_FECHA), '00')) AS DESCRIPCION,
    CONCAT(FORMAT(YEAR(ID_FECHA), '0000'), FORMAT(MONTH(ID_FECHA), '00')) AS ID_MES
FROM FACT_GASTO
ORDER BY FECHA;

INSERT INTO DIM_MES
SELECT DISTINCT
    CONCAT(FORMAT(YEAR(ID_FECHA), '0000'), FORMAT(MONTH(ID_FECHA), '00')) AS ID_MES,
    CONCAT(FORMAT(YEAR(ID_FECHA), '0000'), '-', FORMAT(MONTH(ID_FECHA), '00')) AS DESCRIPCION,
    YEAR(ID_FECHA) AS ID_ANIO
FROM FACT_GASTO
ORDER BY CONCAT(FORMAT(YEAR(ID_FECHA), '0000'), '-', FORMAT(MONTH(ID_FECHA), '00'));

INSERT INTO DIM_ANIO
SELECT DISTINCT
    YEAR(ID_FECHA),
    CONVERT(VARCHAR(4), YEAR(ID_FECHA))
FROM FACT_GASTO
ORDER BY YEAR(ID_FECHA);
