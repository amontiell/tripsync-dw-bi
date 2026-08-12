# TripSync — Base de Datos Relacional

Modelo de datos y objetos de base de datos (SQL Server) del proyecto **TripSync**, una plataforma de gestión colaborativa de viajes (organización de itinerarios, gastos compartidos y pagos entre participantes), desarrollado para la materia Gestión de Datos (ITBA).

Este repositorio reúne las tres entregas del diseño e implementación de la base:

```
tripsync-database/
├── 01-modelo-logico-fisico/
│   └── tp2_modelo_logico_fisico.sql
├── 02-implementacion-fisica/
│   └── tp3_ddl_checks.sql
├── 03-triggers-procedures/
│   └── tp4_triggers_procedures_corregido.sql
```

## Contenido

**01 — Modelo Lógico y Físico**
Diagrama entidad-relación y primera definición de tablas del dominio: usuarios, viajes, destinos, gastos, pagos y participación en actividades.

**02 — Implementación del Modelo Físico**
DDL completo (tablas, claves foráneas) y constraints de negocio (`CHECK`) sobre campos críticos: estados válidos de un viaje, coherencia de fechas, rangos de porcentaje en gastos compartidos, formato de documento, entre otros. Cada constraint incluye su caso de inserción válida e inválida como evidencia de testing.

**03 — Triggers y Procedures**
Cinco triggers (actualización automática de contadores, validación de fechas de gasto, detección de gasto elevado, validación de destino activo, bloqueo de cambio de email) y cinco stored procedures (resumen de viaje, ranking de destinos por gasto, balance de usuario, desvío de presupuesto, ranking de usuarios por participación).

## Evolución del modelo

El esquema fue refinado entre TP2 y TP3 a partir de feedback sobre tipos de datos y constraints: por ejemplo, `email` pasó de `text` a `varchar(40)`, `tipo_documento` de `text` a `varchar(15)`, y `participacion_gasto` de `varchar(50)` a `DECIMAL(5,2)` (necesario para que el check `BETWEEN 0 AND 100` tuviera sentido). También se renombró `tipo_transporte`/`id_transporte` a `id_tipo_transporte` para mayor claridad semántica.

## Corrección post-entrega (TP4)

Tras una revisión posterior a la entrega, se corrigieron dos bugs de lógica:

- **`trg_detectar_gasto_elevado`**: el trigger original asumía una única fila insertada en `inserted`, dando resultados no determinísticos con inserts multi-fila, y no verificaba si el usuario ya estaba registrado (generaba duplicados). Se corrigió para procesar todos los usuarios afectados por el INSERT y evitar duplicados con `NOT EXISTS`.
- **`sp_ranking_usuarios_por_participacion`**: la suma de gastos usaba `SUM(DISTINCT ...)`, lo que descartaba gastos con montos coincidentes y subestimaba el total. Se eliminó el `DISTINCT` innecesario.
- **`sp_desvio_presupuesto_viaje`**: se agregó `NULLIF` en el denominador para evitar división por cero/NULL cuando un viaje no tiene presupuesto cargado.

El archivo `tp4_triggers_procedures_corregido.sql` incluye ya la versión corregida de los tres objetos.

## Stack

SQL Server (T-SQL)

## Autoras

Grupo 15 — Comisión D, Gestión de Datos (ITBA)
Campasso, Matilde · Montiel, Agostina · Lee, Aylin Florencia · Yoo, Sabrina
