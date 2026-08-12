# TripSync — Data Warehouse y Business Intelligence

Modelado dimensional (Data Warehouse) y dashboards de Business Intelligence para **TripSync**, una app de gestión de viajes y gastos grupales. El proyecto completo (modelo OLTP, procedimientos almacenados y triggers) se desarrolló en varios TPs de la materia; este repositorio documenta específicamente la etapa de generación del DW y BI.

Trabajo práctico de la materia **Gestión de Datos** — ITBA. Trabajo grupal (4 integrantes).

## Modelo multidimensional

Esquema en estrella con `FACT_GASTO` como tabla de hechos central, registrando cada gasto asociado a un viaje. Dimensiones: fecha (con jerarquía fecha → mes → año), usuario, viaje, categoría de gasto, destino (con jerarquía destino → país), moneda, tipo de transporte y edad (con jerarquía edad → rango etario).

Ver `dw_tripsync.sql` para el código de creación y poblado de la Fact Table y las dimensiones adicionales.

## Dashboard de Business Intelligence (Power BI)

El tablero se organiza en 2 hojas:

**Hoja 1 — Comportamiento general de gastos**: vista panorámica de dónde, cuándo y cómo se viaja. Incluye KPIs (total de viajes, total gastado, gasto promedio), destinos más visitados, evolución mensual de viajes, distribución geográfica del gasto y gastos por tipo de transporte. Filtros por año, país y transporte.

**Hoja 2 — Análisis económico**: foco en cuánto y cómo se gasta. Incluye gastos por categoría, gastos por categoría y destino, gasto por trimestre y año, gasto promedio según duración del viaje, y evolución del gasto acumulado por año. Filtros por año, transporte, categoría y fecha.

Cada visualización del tablero fue diseñada con un objetivo de negocio concreto y acompañada de una interpretación orientada a decisiones (por ejemplo: priorización de acuerdos comerciales según el destino y categoría de mayor gasto, detección de caída sostenida en la cantidad de viajes mensuales, identificación de la fuerte concentración del gasto en la categoría Alojamiento y en transporte aéreo).

## Enfoque técnico

- **Modelado dimensional**: diseño de esquema en estrella, con dimensiones jerárquicas (fecha, edad, destino) para permitir distintos niveles de agregación en el análisis.
- **SQL**: generación de la Fact Table mediante joins sobre el modelo transaccional (OLTP), creación y poblado de dimensiones adicionales no presentes en el modelo original.
- **Business Intelligence**: diseño de un tablero de Power BI con 12 visualizaciones distintas (KPIs, treemap, gráfico de área, mapa geográfico, dona, embudo, barras apiladas, cascada), cada una vinculada a una decisión de negocio específica.

## Estructura del repositorio

```
dw_tripsync.sql              → script SQL: creación y poblado de la Fact Table y dimensiones
informe_dw_bi_tripsync.pdf   → informe completo: modelo dimensional, código SQL, y documentación detallada del tablero de Power BI
```
