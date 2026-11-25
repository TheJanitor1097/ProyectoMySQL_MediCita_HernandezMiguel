USE medicita_ips;

-- F-1: Edad en años cumplidos a una fecha de referencia
DROP FUNCTION IF EXISTS fn_edad;

DELIMITER $$

CREATE FUNCTION fn_edad(p_fecha_nacimiento DATE, p_fecha_ref DATE)
RETURNS INT
DETERMINISTIC
NO SQL
BEGIN
    IF p_fecha_nacimiento IS NULL OR p_fecha_ref IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN TIMESTAMPDIFF(YEAR, p_fecha_nacimiento, p_fecha_ref);
END $$

DELIMITER ;

-- F-2: Índice de Masa Corporal (IMC) con 2 decimales
DROP FUNCTION IF EXISTS fn_imc;

DELIMITER $$

CREATE FUNCTION fn_imc(p_peso_kg DECIMAL(5,2), p_talla_cm DECIMAL(5,2))
RETURNS DECIMAL(5,2)
DETERMINISTIC
NO SQL
BEGIN
    IF p_peso_kg IS NULL OR p_talla_cm IS NULL OR p_talla_cm <= 0 THEN
        RETURN NULL;
    END IF;
    RETURN ROUND(p_peso_kg / POW(p_talla_cm / 100, 2), 2);
END $$

DELIMITER ;

-- F-3: Tarifa vigente de un servicio para un plan en una fecha dada
DROP FUNCTION IF EXISTS fn_tarifa_vigente;

DELIMITER $$

CREATE FUNCTION fn_tarifa_vigente(p_servicio BIGINT, p_plan BIGINT, p_fecha DATE)
RETURNS DECIMAL(12,2)
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_precio DECIMAL(12,2);

    SELECT price
    INTO v_precio
    FROM service_tariffs
    WHERE cups_service_id = p_servicio
      AND plan_id = p_plan
      AND valid_from <= p_fecha
      AND (valid_to IS NULL OR valid_to >= p_fecha)
    ORDER BY valid_from DESC
    LIMIT 1;

    IF v_precio IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No existe una tarifa vigente para el servicio y plan en la fecha indicada';
    END IF;

    RETURN v_precio;
END $$

DELIMITER ;

-- F-4: Saldo pendiente de una factura (las anuladas tienen saldo 0)
DROP FUNCTION IF EXISTS fn_saldo_factura;

DELIMITER $$

CREATE FUNCTION fn_saldo_factura(p_factura BIGINT)
RETURNS DECIMAL(12,2)
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(12,2);
    DECLARE v_estado VARCHAR(20);
    DECLARE v_abonado DECIMAL(12,2);

    SELECT total_amount, status
    INTO v_total, v_estado
    FROM invoices
    WHERE id = p_factura;

    IF v_estado IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La factura consultada no existe';
    END IF;

    IF v_estado = 'ANULADA' THEN
        RETURN 0.00;
    END IF;

    SELECT IFNULL(SUM(amount), 0.00)
    INTO v_abonado
    FROM payments
    WHERE invoice_id = p_factura;

    RETURN GREATEST(v_total - v_abonado, 0.00);
END $$

DELIMITER ;

-- F-5: Disponibilidad de un médico en un intervalo de tiempo (1 = Sí, 0 = No)
DROP FUNCTION IF EXISTS fn_medico_disponible;

DELIMITER $$

CREATE FUNCTION fn_medico_disponible(p_medico BIGINT, p_inicio DATETIME, p_duracion_min INT)
RETURNS TINYINT
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_fin DATETIME;
    DECLARE v_dia_semana TINYINT;
    DECLARE v_en_horario INT DEFAULT 0;
    DECLARE v_en_novedad INT DEFAULT 0;
    DECLARE v_cruce_citas INT DEFAULT 0;

    SET v_fin = DATE_ADD(p_inicio, INTERVAL p_duracion_min MINUTE);
    SET v_dia_semana = WEEKDAY(p_inicio) + 1;

    -- 1. Validar que el intervalo caiga completo dentro de su horario semanal
    SELECT COUNT(*)
    INTO v_en_horario
    FROM doctor_schedules
    WHERE doctor_id = p_medico
      AND day_of_week = v_dia_semana
      AND start_time <= TIME(p_inicio)
      AND end_time >= TIME(v_fin);

    IF v_en_horario = 0 THEN
        RETURN 0;
    END IF;

    -- 2. Validar que no tenga novedad (vacaciones, incapacidad, capacitación) ese día
    SELECT COUNT(*)
    INTO v_en_novedad
    FROM doctor_leaves
    WHERE doctor_id = p_medico
      AND DATE(p_inicio) BETWEEN start_date AND end_date;

    IF v_en_novedad > 0 THEN
        RETURN 0;
    END IF;

    -- 3. Validar que no se cruce con otra cita no cancelada
    SELECT COUNT(*)
    INTO v_cruce_citas
    FROM appointments
    WHERE doctor_id = p_medico
      AND status <> 'CANCELADA'
      AND scheduled_start < v_fin
      AND scheduled_end > p_inicio;

    IF v_cruce_citas > 0 THEN
        RETURN 0;
    END IF;

    RETURN 1;
END $$

DELIMITER ;

-- PRUEBAS DE LAS 5 FUNCIONES

-- Prueba F-1: Edad al corte 2026-11-30
SELECT
    fn_edad('1955-03-14', '2026-11-30') AS edad_carlos,
    fn_edad('2014-06-18', '2026-11-30') AS edad_mateo;

-- Prueba F-2: IMC normal y caso con talla 0 (devuelve NULL)
SELECT
    fn_imc(82.00, 172.00) AS imc_valido,
    fn_imc(70.00, 0) AS imc_talla_cero;

-- Prueba F-3: Tarifa histórica (septiembre) vs tarifa actual (noviembre)
SELECT
    fn_tarifa_vigente(2, 1, '2026-09-15') AS tarifa_septiembre,
    fn_tarifa_vigente(2, 1, '2026-11-15') AS tarifa_noviembre;

-- En un caso de falla en F-3 (servicio/plan sin tarifa):
-- Saldra este error: ERROR 1644 (45000): No existe una tarifa vigente para el servicio y plan en la fecha indicada
-- SELECT fn_tarifa_vigente(16, 1, '2026-11-15'); (Ejemplo de falla)

-- Prueba F-4: Saldo de factura pagada (1), parcial (4) y anulada (5)
SELECT
    fn_saldo_factura(1) AS saldo_pagada,
    fn_saldo_factura(4) AS saldo_parcial,
    fn_saldo_factura(5) AS saldo_anulada;

-- Prueba F-5: Dra. Salazar (id 1) el martes 2026-12-01
-- A las 09:30 está libre (1), a las 08:40 se cruza con cita 21 (0), el 2026-12-08 tiene capacitación (0)
SELECT
    fn_medico_disponible(1, '2026-12-01 09:30:00', 30) AS disponible_libre,
    fn_medico_disponible(1, '2026-12-01 08:40:00', 30) AS ocupado_cruce,
    fn_medico_disponible(1, '2026-12-08 09:00:00', 30) AS ocupado_novedad;

-- Estas de aqui fueron pruebas para ver si funcionan correctamente, las dejare por el bien de la trama

-- FUNCIONES CON DATOS DE LAS TABLAS

-- 1. Edad de todos los pacientes al corte usando fn_edad
SELECT
    CONCAT(first_name, ' ', last_name) AS paciente,
    birth_date,
    fn_edad(birth_date, '2026-11-30') AS edad
FROM patients
ORDER BY edad DESC;

-- 2. IMC de cada toma de signos vitales usando fn_imc (y filtrando en el WHERE)
SELECT
    attention_id,
    weight_kg,
    height_cm,
    fn_imc(weight_kg, height_cm) AS imc
FROM vital_signs
WHERE fn_imc(weight_kg, height_cm) >= 25.00
ORDER BY imc DESC;

-- 3. Facturas que todavía deben plata usando fn_saldo_factura		
SELECT
    id AS factura_id,
    status,
    total_amount,
    fn_saldo_factura(id) AS saldo_pendiente
FROM invoices
WHERE fn_saldo_factura(id) > 0
ORDER BY saldo_pendiente DESC;