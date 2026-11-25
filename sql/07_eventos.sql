USE medicita_ips;

-- Encender el reloj de eventos de MySQL
SET GLOBAL event_scheduler = ON;
SHOW VARIABLES LIKE 'event_scheduler';

-- E-1: Marcar inasistencias de citas PROGRAMADA o CONFIRMADA antes del corte
DROP EVENT IF EXISTS evt_marcar_inasistencias_diario;

DELIMITER $$

CREATE EVENT evt_marcar_inasistencias_diario
ON SCHEDULE AT CURRENT_TIMESTAMP + INTERVAL 2 SECOND
ON COMPLETION PRESERVE
DO
BEGIN
    -- Al cambiar el estado, el trigger T-3 registra automáticamente el historial
    UPDATE appointments
    SET status = 'NO_ASISTIO',
        updated_by = 10
    WHERE status IN ('PROGRAMADA', 'CONFIRMADA')
      AND scheduled_start < '2026-12-01 00:00:00';
END $$

DELIMITER ;

-- E-2: Generar recordatorios pendientes para citas del día siguiente al corte
DROP EVENT IF EXISTS evt_generar_recordatorios_diario;

DELIMITER $$

CREATE EVENT evt_generar_recordatorios_diario
ON SCHEDULE AT CURRENT_TIMESTAMP + INTERVAL 2 SECOND
ON COMPLETION PRESERVE
DO
BEGIN
    INSERT INTO appointment_reminders (appointment_id, channel, scheduled_for, status)
    SELECT
        a.id,
        'WHATSAPP',
        '2026-11-30 18:00:00',
        'PENDIENTE'
    FROM appointments AS a
    WHERE a.status IN ('PROGRAMADA', 'CONFIRMADA')
      AND DATE(a.scheduled_start) = DATE_ADD('2026-11-30', INTERVAL 1 DAY)
      AND NOT EXISTS (
          SELECT 1
          FROM appointment_reminders AS ar
          WHERE ar.appointment_id = a.id
      );
END $$

DELIMITER ;

-- E-3: Inactivar afiliaciones cuya fecha de fin ya pasó al corte
DROP EVENT IF EXISTS evt_vencer_afiliaciones_diario;

DELIMITER $$

CREATE EVENT evt_vencer_afiliaciones_diario
ON SCHEDULE AT CURRENT_TIMESTAMP + INTERVAL 2 SECOND
ON COMPLETION PRESERVE
DO
BEGIN
    UPDATE patient_affiliations
    SET status = 'INACTIVA'
    WHERE status = 'ACTIVA'
      AND end_date IS NOT NULL
      AND end_date < '2026-11-30';
END $$

DELIMITER ;

-- E-4: Marcar como VENCIDA las facturas PENDIENTE/PARCIAL con más de 30 días
DROP EVENT IF EXISTS evt_marcar_facturas_vencidas_diario;

DELIMITER $$

CREATE EVENT evt_marcar_facturas_vencidas_diario
ON SCHEDULE AT CURRENT_TIMESTAMP + INTERVAL 2 SECOND
ON COMPLETION PRESERVE
DO
BEGIN
    UPDATE invoices
    SET status = 'VENCIDA'
    WHERE status IN ('PENDIENTE', 'PARCIAL')
      AND DATEDIFF('2026-11-30', issue_date) > 30;
END $$

DELIMITER ;

-- E-5: Resumen mensual de producción por médico (prueba: noviembre 2026)
DROP EVENT IF EXISTS evt_resumen_produccion_mensual;

DELIMITER $$

CREATE EVENT evt_resumen_produccion_mensual
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_TIMESTAMP + INTERVAL 2 SECOND
ON COMPLETION PRESERVE
DO
BEGIN
    INSERT INTO monthly_production_summary (year_month_code, doctor_id, total_attentions, total_billed)
    SELECT
        '2026-11',
        d.id,
        COUNT(DISTINCT att.id),
        IFNULL(SUM(CASE WHEN inv.status <> 'ANULADA' THEN inv.total_amount ELSE 0 END), 0.00)
    FROM doctors AS d
    LEFT JOIN appointments AS a
        ON a.doctor_id = d.id
    LEFT JOIN attentions AS att
        ON att.appointment_id = a.id
       AND att.attention_date >= '2026-11-01 00:00:00'
       AND att.attention_date < '2026-12-01 00:00:00'
    LEFT JOIN invoices AS inv
        ON inv.attention_id = att.id
    GROUP BY d.id
    ON DUPLICATE KEY UPDATE
        total_attentions = VALUES(total_attentions),
        total_billed = VALUES(total_billed),
        generated_at = CURRENT_TIMESTAMP;
END $$

DELIMITER ;

-- ESPERAR LA EJECUCIÓN DE LOS EVENTOS Y VERIFICAR RESULTADOS
SELECT SLEEP(4) AS esperando_ejecucion_eventos;

-- Verificar E-1: Cita 20 debe pasar a NO_ASISTIO y tener registro en el historial
SELECT id, scheduled_start, status, updated_by
FROM appointments
WHERE id = 20;

SELECT appointment_id, previous_status, new_status, changed_by
FROM appointment_status_history
WHERE appointment_id = 20;

-- Verificar E-2: Recordatorios creados para las citas del 2026-12-01 (citas 21, 22 y 23)
SELECT appointment_id, channel, scheduled_for, status
FROM appointment_reminders
WHERE appointment_id IN (21, 22, 23)
ORDER BY appointment_id;

-- Verificar E-3: Afiliación del paciente 5 (vencía 2026-11-15) debe quedar INACTIVA
SELECT id, patient_id, end_date, status
FROM patient_affiliations
WHERE patient_id = 5;

-- Verificar E-4: Facturas 2 y 4 (> 30 días sin pagar completas) deben quedar VENCIDA
SELECT id, issue_date, total_amount, status
FROM invoices
WHERE id IN (2, 4)
ORDER BY id;

-- Verificar E-5: Resumen de producción de noviembre 2026 generado automáticamente
SELECT year_month_code, doctor_id, total_attentions, total_billed
FROM monthly_production_summary
WHERE year_month_code = '2026-11'
ORDER BY total_billed DESC, doctor_id ASC;

-- APAGAR EVENTOS DE PRUEBA Y VERIFICAR ESTADO EN INFORMATION_SCHEMA (Sip, esto lo hizo la IA :(
ALTER EVENT evt_marcar_inasistencias_diario DISABLE;
ALTER EVENT evt_generar_recordatorios_diario DISABLE;
ALTER EVENT evt_vencer_afiliaciones_diario DISABLE;
ALTER EVENT evt_marcar_facturas_vencidas_diario DISABLE;
ALTER EVENT evt_resumen_produccion_mensual DISABLE;

SELECT
    event_name,
    status,
    last_executed IS NOT NULL AS se_ejecuto
FROM information_schema.EVENTS
WHERE event_schema = 'medicita_ips'
ORDER BY event_name;