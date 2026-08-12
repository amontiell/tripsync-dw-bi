-- ============================================================
-- TP4: Implementación de Triggers y Procedures — VERSIÓN CORREGIDA
-- Grupo 15 - Gestión de Datos - ITBA
-- ============================================================
-- Incluye los 4 procedures y 5 triggers originales del TP4.
-- Los que tenían bugs (marcados abajo) están corregidos e
-- integrados; el resto se mantiene igual al original.
-- ============================================================


-- ============================================================
-- PROCEDURES
-- ============================================================

-- ------------------------------------------------------------
-- 1. sp_resumen_viaje  (sin cambios)
-- ------------------------------------------------------------
CREATE PROCEDURE sp_resumen_viaje
    @id_viaje INT
AS
BEGIN
    SELECT
        v.id_viaje,
        v.descripcion AS viaje,
        v.fecha_inicio,
        v.fecha_final,
        v.estado,
        v.presupuesto_estimado,
        d.nombre AS destino,
        p.nombre AS pais,
        tt.nombre AS tipo_transporte,
        v.cantidad_participantes,
        v.cantidad_actividades,
        (SELECT SUM(ISNULL(g.monto, 0))
         FROM gasto g
         INNER JOIN usuario_por_viaje upv ON g.id_usuario_por_viaje = upv.id_usuario_por_viaje
         WHERE upv.id_viaje = v.id_viaje) AS total_gastado,
        (SELECT SUM(ISNULL(pa.monto, 0))
         FROM pago pa
         INNER JOIN usuario_por_viaje upv ON pa.id_usuario_por_viaje = upv.id_usuario_por_viaje
         WHERE upv.id_viaje = v.id_viaje) AS total_pagado
    FROM viaje v
    INNER JOIN destino d ON v.id_destino = d.id_destino
    INNER JOIN pais p ON d.id_pais = p.id_pais
    INNER JOIN tipo_transporte tt ON v.id_tipo_transporte = tt.id_tipo_transporte
    WHERE v.id_viaje = @id_viaje;
END;
GO


-- ------------------------------------------------------------
-- 2. sp_top_destinos_por_gasto  (sin cambios)
-- ------------------------------------------------------------
CREATE PROCEDURE sp_top_destinos_por_gasto
    @fecha_desde DATE,
    @fecha_hasta DATE
AS
BEGIN
    SELECT TOP 20
        d.nombre AS destino,
        p.nombre AS pais,
        COUNT(DISTINCT v.id_viaje) AS cantidad_viajes,
        COUNT(g.id_gasto) AS cantidad_gastos,
        SUM(ISNULL(g.monto, 0)) AS gasto_total,
        AVG(ISNULL(g.monto, 0)) AS gasto_promedio
    FROM destino d
    INNER JOIN pais p ON d.id_pais = p.id_pais
    INNER JOIN viaje v ON v.id_destino = d.id_destino
    INNER JOIN usuario_por_viaje upv ON upv.id_viaje = v.id_viaje
    LEFT JOIN gasto g ON g.id_usuario_por_viaje = upv.id_usuario_por_viaje
                    AND g.fecha BETWEEN @fecha_desde AND @fecha_hasta
    WHERE v.fecha_inicio BETWEEN @fecha_desde AND @fecha_hasta
    GROUP BY d.nombre, p.nombre
    ORDER BY gasto_total DESC;
END;
GO


-- ------------------------------------------------------------
-- 3. sp_balance_usuario_viaje  (sin cambios)
-- ------------------------------------------------------------
CREATE PROCEDURE sp_balance_usuario_viaje
    @id_usuario INT,
    @id_viaje INT,
    @total_gastado DECIMAL(12,2) OUTPUT,
    @total_pagado DECIMAL(12,2) OUTPUT,
    @saldo DECIMAL(12,2) OUTPUT
AS
BEGIN
    SELECT @total_gastado = SUM(ISNULL(g.monto * dg.participacion_gasto / 100, 0))
    FROM detalle_gasto dg
    INNER JOIN gasto g ON dg.id_gasto = g.id_gasto
    INNER JOIN usuario_por_viaje upv ON dg.id_usuario_por_viaje = upv.id_usuario_por_viaje
    WHERE upv.id_usuario = @id_usuario AND upv.id_viaje = @id_viaje;

    SELECT @total_pagado = SUM(ISNULL(p.monto, 0))
    FROM pago p
    INNER JOIN usuario_por_viaje upv ON p.id_usuario_por_viaje = upv.id_usuario_por_viaje
    WHERE upv.id_usuario = @id_usuario AND upv.id_viaje = @id_viaje;

    SET @saldo = ISNULL(@total_pagado, 0) - ISNULL(@total_gastado, 0);
END;
GO


-- ------------------------------------------------------------
-- 4. sp_desvio_presupuesto_viaje  *** CORREGIDO ***
-- ------------------------------------------------------------
-- Bug original: dividía por v.presupuesto_estimado sin
-- protección; si el campo es NULL o 0 (es NULLable en el
-- modelo), el cálculo fallaba o devolvía basura.
-- Fix: NULLIF(v.presupuesto_estimado, 0) en el denominador.
-- ------------------------------------------------------------
CREATE PROCEDURE sp_desvio_presupuesto_viaje
    @id_viaje INT
AS
BEGIN
    SELECT
        v.id_viaje,
        v.descripcion AS viaje,
        d.nombre AS destino,
        v.fecha_inicio,
        v.fecha_final,
        v.presupuesto_estimado,
        SUM(ISNULL(g.monto, 0)) AS gasto_real,
        SUM(ISNULL(g.monto, 0)) - v.presupuesto_estimado AS diferencia_absoluta,
        ROUND(
            ((SUM(ISNULL(g.monto, 0)) - v.presupuesto_estimado)
                / NULLIF(v.presupuesto_estimado, 0)) * 100,  -- CORREGIDO
            2
        ) AS porcentaje_desviacion
    FROM viaje v
    INNER JOIN destino d ON v.id_destino = d.id_destino
    LEFT JOIN usuario_por_viaje upv ON upv.id_viaje = v.id_viaje
    LEFT JOIN gasto g ON g.id_usuario_por_viaje = upv.id_usuario_por_viaje
    WHERE v.id_viaje = @id_viaje
    GROUP BY v.id_viaje, v.descripcion, d.nombre, v.fecha_inicio, v.fecha_final, v.presupuesto_estimado;
END;
GO


-- ------------------------------------------------------------
-- 5. sp_ranking_usuarios_por_participacion  *** CORREGIDO ***
-- ------------------------------------------------------------
-- Bug original: SUM(DISTINCT ISNULL(g.monto, 0)) descartaba
-- gastos con montos coincidentes, subestimando el total.
-- Fix: se elimina el DISTINCT de esa suma.
-- ------------------------------------------------------------
CREATE PROCEDURE sp_ranking_usuarios_por_participacion
    @fecha_desde DATE,
    @fecha_hasta DATE
AS
BEGIN
    SELECT TOP 30
        u.id_usuario,
        u.nombre + ' ' + u.apellido AS usuario,
        u.email,
        COUNT(DISTINCT upv.id_viaje) AS cantidad_viajes,
        COUNT(DISTINCT pea.id_actividad) AS cantidad_actividades,
        SUM(ISNULL(g.monto, 0)) AS gasto_total,  -- CORREGIDO: sin DISTINCT
        (SELECT SUM(ISNULL(p.monto, 0))
         FROM pago p
         INNER JOIN usuario_por_viaje upv2 ON p.id_usuario_por_viaje = upv2.id_usuario_por_viaje
         WHERE upv2.id_usuario = u.id_usuario
           AND p.fecha_pago BETWEEN @fecha_desde AND @fecha_hasta) AS pago_total
    FROM usuario u
    INNER JOIN usuario_por_viaje upv ON u.id_usuario = upv.id_usuario
    INNER JOIN viaje v ON upv.id_viaje = v.id_viaje
    LEFT JOIN participacion_en_actividad pea ON pea.id_usuario_por_viaje = upv.id_usuario_por_viaje
                    AND pea.estado_asistencia = 'Asistió'
    LEFT JOIN gasto g ON g.id_usuario_por_viaje = upv.id_usuario_por_viaje
            AND g.fecha BETWEEN @fecha_desde AND @fecha_hasta
    WHERE v.fecha_inicio BETWEEN @fecha_desde AND @fecha_hasta
    GROUP BY u.id_usuario, u.nombre, u.apellido, u.email
    ORDER BY cantidad_viajes DESC, cantidad_actividades DESC, gasto_total DESC;
END;
GO


-- ============================================================
-- TRIGGERS
-- ============================================================

-- ------------------------------------------------------------
-- TRIGGER 1: trg_actividad_insert  (sin cambios)
-- ------------------------------------------------------------
CREATE TRIGGER trg_actividad_insert
ON actividad
FOR INSERT
AS
BEGIN
    BEGIN TRY
        UPDATE viaje
        SET cantidad_actividades = cantidad_actividades + 1
        WHERE id_viaje IN (SELECT id_viaje FROM inserted);
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RAISERROR ('Error al actualizar el contador de actividades: %s', 16, 1, @ErrorMessage);
    END CATCH
END;
GO


-- ------------------------------------------------------------
-- TRIGGER 2: trg_validar_fecha_gasto_update  (sin cambios)
-- ------------------------------------------------------------
CREATE TRIGGER trg_validar_fecha_gasto_update
ON gasto
FOR UPDATE
AS
BEGIN
    BEGIN TRY
        DECLARE @cantidad INT

        SELECT @cantidad = COUNT(*)
        FROM inserted i
        JOIN usuario_por_viaje upv ON i.id_usuario_por_viaje = upv.id_usuario_por_viaje
        JOIN viaje v ON upv.id_viaje = v.id_viaje
        WHERE i.fecha < v.fecha_inicio
           OR i.fecha > v.fecha_final

        IF @cantidad > 0
        BEGIN
            RAISERROR('La fecha del gasto está fuera del viaje', 16, 1)
        END
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMensaje VARCHAR(100)
        SET @ErrorMensaje = ERROR_MESSAGE()
        RAISERROR(@ErrorMensaje, 16, 1);
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
    END CATCH
END;
GO


-- ------------------------------------------------------------
-- TRIGGER 3: trg_detectar_gasto_elevado  *** CORREGIDO ***
-- ------------------------------------------------------------
-- Bug original: SELECT @id_usuario = ... FROM inserted asumía
-- una sola fila insertada (resultado no determinístico con
-- inserts multi-fila) y no chequeaba si el usuario ya estaba
-- registrado, generando duplicados.
-- Fix: procesa todos los usuarios afectados + NOT EXISTS.
-- ------------------------------------------------------------
CREATE TRIGGER trg_detectar_gasto_elevado
ON gasto
FOR INSERT
AS
BEGIN
    BEGIN TRY
        DECLARE @limite DECIMAL(10,2) = 50000.00;

        ;WITH usuarios_afectados AS (
            SELECT DISTINCT upv.id_usuario
            FROM inserted i
            JOIN usuario_por_viaje upv ON i.id_usuario_por_viaje = upv.id_usuario_por_viaje
        ),
        totales AS (
            SELECT ua.id_usuario, SUM(g.monto) AS total
            FROM usuarios_afectados ua
            JOIN usuario_por_viaje upv ON upv.id_usuario = ua.id_usuario
            JOIN gasto g ON g.id_usuario_por_viaje = upv.id_usuario_por_viaje
            GROUP BY ua.id_usuario
        )
        INSERT INTO usuarios_gasto_elevado (id_usuario, nombre_usuario, monto_gasto_total, fecha_deteccion)
        SELECT u.id_usuario, u.nombre + ' ' + u.apellido, t.total, GETDATE()
        FROM totales t
        JOIN usuario u ON u.id_usuario = t.id_usuario
        WHERE t.total > @limite
          AND NOT EXISTS (
              SELECT 1 FROM usuarios_gasto_elevado uge
              WHERE uge.id_usuario = t.id_usuario
          );

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END;
GO


-- ------------------------------------------------------------
-- TRIGGER 4: trg_validar_destino_activo  (sin cambios)
-- ------------------------------------------------------------
CREATE TRIGGER trg_validar_destino_activo
ON viaje
FOR INSERT
AS
BEGIN
    BEGIN TRY
        DECLARE @cantidad INT;

        SELECT @cantidad = COUNT(*)
        FROM inserted i
        INNER JOIN destino d ON i.id_destino = d.id_destino
        WHERE d.fecha_baja IS NOT NULL;

        IF @cantidad > 0
        BEGIN
            RAISERROR(
                'Error de Negocio: No se puede crear un viaje con un destino dado de baja.',
                16, 1
            );
        END
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000);
        SET @ErrorMessage = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO


-- ------------------------------------------------------------
-- TRIGGER 5: trg_no_cambiar_mail  (sin cambios)
-- ------------------------------------------------------------
CREATE TRIGGER trg_no_cambiar_mail
ON usuario
FOR UPDATE
AS
BEGIN
    BEGIN TRY
        IF (SELECT COUNT(*)
            FROM inserted i
            JOIN deleted d ON i.id_usuario = d.id_usuario
            WHERE i.email <> d.email) > 0
        BEGIN
            RAISERROR ('Prohibido cambiar el mail', 16, 1);
        END
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END;
GO
