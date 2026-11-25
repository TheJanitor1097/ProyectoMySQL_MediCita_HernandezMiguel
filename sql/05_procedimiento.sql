USE medicita_ips;

-- P-1: Registrar un paciente con su teléfono principal
DROP PROCEDURE IF EXISTS sp_registrar_paciente;

DELIMITER $$

CREATE PROCEDURE sp_registrar_paciente(
    IN p_document_type_id BIGINT,
    IN p_document_number VARCHAR(30),
    IN p_first_name VARCHAR(80),
    IN p_last_name VARCHAR(80),
    IN p_birth_date DATE,
    IN p_gender ENUM('M', 'F', 'OTRO'),
    IN p_address VARCHAR(200),
    IN p_city VARCHAR(80),
    IN p_email VARCHAR(120),
    IN p_phone_number VARCHAR(20),
    OUT p_paciente_id BIGINT
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT COUNT(*)
    INTO v_existe
    FROM patients
    WHERE document_type_id = p_document_type_id
      AND document_number = p_document_number;

    IF v_existe > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ya existe un paciente con ese tipo y número de documento';
    END IF;

    IF p_phone_number IS NULL OR TRIM(p_phone_number) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El teléfono principal es obligatorio';
    END IF;

    START TRANSACTION;

    INSERT INTO patients (
        document_type_id, document_number, first_name, last_name,
        birth_date, gender, address, city, email
    ) VALUES (
        p_document_type_id, p_document_number, p_first_name, p_last_name,
        p_birth_date, p_gender, p_address, p_city, p_email
    );

    SET p_paciente_id = LAST_INSERT_ID();

    INSERT INTO patient_phones (patient_id, phone_number, is_primary)
    VALUES (p_paciente_id, TRIM(p_phone_number), 1);

    COMMIT;
END $$

DELIMITER ;

-- P-2: Cancelar una cita PROGRAMADA o CONFIRMADA con motivo obligatorio
DROP PROCEDURE IF EXISTS sp_cancelar_cita;

DELIMITER $$

CREATE PROCEDURE sp_cancelar_cita(
    IN p_cita BIGINT,
    IN p_motivo BIGINT,
    IN p_responsable BIGINT,
    IN p_fecha DATETIME
)
BEGIN
    DECLARE v_estado VARCHAR(20);
    DECLARE v_motivo_existe INT DEFAULT 0;

    SELECT status
    INTO v_estado
    FROM appointments
    WHERE id = p_cita;

    IF v_estado IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La cita indicada no existe';
    END IF;

    IF v_estado NOT IN ('PROGRAMADA', 'CONFIRMADA') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Solo se pueden cancelar citas en estado PROGRAMADA o CONFIRMADA';
    END IF;

    IF p_motivo IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El motivo de cancelación es obligatorio';
    END IF;

    SELECT COUNT(*)
    INTO v_motivo_existe
    FROM cancellation_reasons
    WHERE id = p_motivo;

    IF v_motivo_existe = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El motivo de cancelación no existe en el catálogo';
    END IF;

    UPDATE appointments
    SET status = 'CANCELADA',
        cancellation_reason_id = p_motivo,
        updated_by = p_responsable
    WHERE id = p_cita;
END $$

DELIMITER ;

-- P-3: Agendar una cita validando especialidad, sede, disponibilidad y consultorio
DROP PROCEDURE IF EXISTS sp_agendar_cita;

DELIMITER $$

CREATE PROCEDURE sp_agendar_cita(
    IN p_paciente BIGINT,
    IN p_medico BIGINT,
    IN p_especialidad BIGINT,
    IN p_consultorio BIGINT,
    IN p_tipo_cita BIGINT,
    IN p_inicio DATETIME,
    IN p_responsable BIGINT,
    OUT p_cita_id BIGINT
)
BEGIN
    DECLARE v_duracion INT;
    DECLARE v_fin DATETIME;
    DECLARE v_sede_id BIGINT;
    DECLARE v_tiene_especialidad INT DEFAULT 0;
    DECLARE v_atiende_sede INT DEFAULT 0;
    DECLARE v_disponible TINYINT DEFAULT 0;
    DECLARE v_consultorio_ocupado INT DEFAULT 0;

    -- Obtener duración del tipo de cita
    SELECT duration_minutes
    INTO v_duracion
    FROM appointment_types
    WHERE id = p_tipo_cita;

    IF v_duracion IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El tipo de cita no existe';
    END IF;

    SET v_fin = DATE_ADD(p_inicio, INTERVAL v_duracion MINUTE);

    -- 1. Validar que el médico tenga la especialidad
    SELECT COUNT(*)
    INTO v_tiene_especialidad
    FROM doctor_specialties
    WHERE doctor_id = p_medico
      AND specialty_id = p_especialidad;

    IF v_tiene_especialidad = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El médico no cuenta con la especialidad seleccionada';
    END IF;

    -- 2. Validar que el médico atienda en la sede del consultorio
    SELECT branch_id
    INTO v_sede_id
    FROM offices
    WHERE id = p_consultorio;

    IF v_sede_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El consultorio indicado no existe';
    END IF;

    SELECT COUNT(*)
    INTO v_atiende_sede
    FROM doctor_branches
    WHERE doctor_id = p_medico
      AND branch_id = v_sede_id;

    IF v_atiende_sede = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El médico no atiende en la sede de ese consultorio';
    END IF;

    -- 3. Validar disponibilidad del médico (horario, novedades y cruces)
    SET v_disponible = fn_medico_disponible(p_medico, p_inicio, v_duracion);
    IF v_disponible = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El médico no está disponible en el horario solicitado';
    END IF;

    -- 4. Validar que el consultorio esté libre
    SELECT COUNT(*)
    INTO v_consultorio_ocupado
    FROM appointments
    WHERE office_id = p_consultorio
      AND status <> 'CANCELADA'
      AND scheduled_start < v_fin
      AND scheduled_end > p_inicio;

    IF v_consultorio_ocupado > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El consultorio ya se encuentra ocupado en ese horario';
    END IF;

    INSERT INTO appointments (
        patient_id, doctor_id, specialty_id, office_id, appointment_type_id,
        scheduled_start, scheduled_end, status, created_by, updated_by
    ) VALUES (
        p_paciente, p_medico, p_especialidad, p_consultorio, p_tipo_cita,
        p_inicio, v_fin, 'PROGRAMADA', p_responsable, p_responsable
    );

    SET p_cita_id = LAST_INSERT_ID();
END $$

DELIMITER ;

-- P-4: Facturar una atención en una transacción (todo o nada)
DROP PROCEDURE IF EXISTS sp_facturar_atencion;

DELIMITER $$

CREATE PROCEDURE sp_facturar_atencion(
    IN p_atencion BIGINT,
    IN p_fecha DATE,
    OUT p_factura_id BIGINT
)
BEGIN
    DECLARE v_paciente_id BIGINT;
    DECLARE v_fecha_atencion DATE;
    DECLARE v_ya_facturada INT DEFAULT 0;
    DECLARE v_plan_id BIGINT;
    DECLARE v_copago_pct DECIMAL(5,2);
    DECLARE v_total DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_copago_valor DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_aseguradora_valor DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_servicios_count INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Validar que la atención exista
    SELECT a.patient_id, DATE(att.attention_date)
    INTO v_paciente_id, v_fecha_atencion
    FROM attentions AS att
    JOIN appointments AS a ON a.id = att.appointment_id
    WHERE att.id = p_atencion;

    IF v_paciente_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La atención indicada no existe';
    END IF;

    -- Rechazar doble facturación
    SELECT COUNT(*)
    INTO v_ya_facturada
    FROM invoices
    WHERE attention_id = p_atencion;

    IF v_ya_facturada > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Esta atención ya fue facturada previamente';
    END IF;

    -- Validar que tenga servicios prestados
    SELECT COUNT(*)
    INTO v_servicios_count
    FROM attention_procedures
    WHERE attention_id = p_atencion;

    IF v_servicios_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La atención no tiene servicios registrados para facturar';
    END IF;

    -- Buscar plan vigente del paciente a la fecha de la atención (si no tiene, PARTICULAR)
    SELECT pa.plan_id, pl.copay_percentage
    INTO v_plan_id, v_copago_pct
    FROM patient_affiliations AS pa
    JOIN plans AS pl ON pl.id = pa.plan_id
    WHERE pa.patient_id = v_paciente_id
      AND pa.status = 'ACTIVA'
      AND pa.start_date <= v_fecha_atencion
      AND (pa.end_date IS NULL OR pa.end_date >= v_fecha_atencion)
    ORDER BY pa.start_date DESC
    LIMIT 1;

    IF v_plan_id IS NULL THEN
        SELECT id, copay_percentage
        INTO v_plan_id, v_copago_pct
        FROM plans
        WHERE plan_type = 'PARTICULAR'
        LIMIT 1;
    END IF;

    START TRANSACTION;

    -- Crear cabecera de factura temporalmente en 0
    INSERT INTO invoices (
        attention_id, patient_id, plan_id, issue_date,
        total_amount, patient_copay, insurer_amount, status
    ) VALUES (
        p_atencion, v_paciente_id, v_plan_id, p_fecha,
        0.00, 0.00, 0.00, 'PENDIENTE'
    );

    SET p_factura_id = LAST_INSERT_ID();

    -- Insertar renglones copiando la tarifa vigente del día de la atención
    INSERT INTO invoice_items (invoice_id, cups_service_id, quantity, unit_price, subtotal)
    SELECT
        p_factura_id,
        ap.cups_service_id,
        ap.quantity,
        fn_tarifa_vigente(ap.cups_service_id, v_plan_id, v_fecha_atencion),
        ap.quantity * fn_tarifa_vigente(ap.cups_service_id, v_plan_id, v_fecha_atencion)
    FROM attention_procedures AS ap
    WHERE ap.attention_id = p_atencion;

    -- Calcular totales y actualizar cabecera
    SELECT IFNULL(SUM(subtotal), 0.00)
    INTO v_total
    FROM invoice_items
    WHERE invoice_id = p_factura_id;

    SET v_copago_valor = ROUND(v_total * (v_copago_pct / 100.0), 2);
    SET v_aseguradora_valor = v_total - v_copago_valor;

    UPDATE invoices
    SET total_amount = v_total,
        patient_copay = v_copago_valor,
        insurer_amount = v_aseguradora_valor
    WHERE id = p_factura_id;

    COMMIT;
END $$

DELIMITER ;

-- P-5: Reporte de producción por médico en un rango usando el CURSOR
DROP PROCEDURE IF EXISTS sp_reporte_produccion;

DELIMITER $$

CREATE PROCEDURE sp_reporte_produccion(
    IN p_desde DATE,
    IN p_hasta DATE
)
BEGIN
    DECLARE v_fin INT DEFAULT 0;
    DECLARE v_doctor_id BIGINT;
    DECLARE v_medico VARCHAR(170);
    DECLARE v_atenciones INT;
    DECLARE v_facturado DECIMAL(12,2);
    DECLARE v_promedio DECIMAL(12,2);

    DECLARE cur_medicos CURSOR FOR
        SELECT id, CONCAT(first_name, ' ', last_name)
        FROM doctors
        ORDER BY last_name ASC, first_name ASC;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin = 1;

    DROP TEMPORARY TABLE IF EXISTS tmp_reporte_produccion;
    CREATE TEMPORARY TABLE tmp_reporte_produccion (
        doctor_id BIGINT,
        medico VARCHAR(170),
        total_atenciones INT,
        valor_facturado DECIMAL(12,2),
        promedio_por_atencion DECIMAL(12,2)
    );

    OPEN cur_medicos;

    bucle_medicos: LOOP
        FETCH cur_medicos INTO v_doctor_id, v_medico;
        IF v_fin = 1 THEN
            LEAVE bucle_medicos;
        END IF;

        SELECT COUNT(att.id)
        INTO v_atenciones
        FROM attentions AS att
        JOIN appointments AS a ON a.id = att.appointment_id
        WHERE a.doctor_id = v_doctor_id
          AND DATE(att.attention_date) BETWEEN p_desde AND p_hasta;

        SELECT IFNULL(SUM(inv.total_amount), 0.00)
        INTO v_facturado
        FROM invoices AS inv
        JOIN attentions AS att ON att.id = inv.attention_id
        JOIN appointments AS a ON a.id = att.appointment_id
        WHERE a.doctor_id = v_doctor_id
          AND inv.status <> 'ANULADA'
          AND DATE(att.attention_date) BETWEEN p_desde AND p_hasta;

        SET v_promedio = IF(v_atenciones > 0, ROUND(v_facturado / v_atenciones, 2), 0.00);

        INSERT INTO tmp_reporte_produccion
        VALUES (v_doctor_id, v_medico, v_atenciones, v_facturado, v_promedio);
    END LOOP;

    CLOSE cur_medicos;

    SELECT * FROM tmp_reporte_produccion ORDER BY valor_facturado DESC, medico ASC;
    DROP TEMPORARY TABLE IF EXISTS tmp_reporte_produccion;
END $$

DELIMITER ;

-- PRUEBAS DE LOS 5 PROCEDIMIENTOS

-- Prueba P-1: Registrar paciente nuevo (funciona)
CALL sp_registrar_paciente(1, '1098999888', 'Camila', 'Ospina', '1994-05-20', 'F', 'Cra 40 # 50-12', 'Bucaramanga', 'cospina@mail.com', '3159998877', @nuevo_pac);
SELECT @nuevo_pac AS paciente_creado;

-- Caso que falla P-1 (documento repetido):
-- Error esperado: ERROR 1644 (45000): Ya existe un paciente con ese tipo y número de documento
-- CALL sp_registrar_paciente(1, '1098999888', 'Otra', 'Persona', '1990-01-01', 'F', 'Calle 1', 'Bucaramanga', NULL, '3001234567', @fallo_pac);

-- Prueba P-3: Agendar cita válida (Dra. Salazar, Cardiología, Cañaveral 101, martes 2026-12-01 10:00)
CALL sp_agendar_cita(@nuevo_pac, 1, 3, 4, 3, '2026-12-01 10:00:00', 5, @nueva_cita);
SELECT @nueva_cita AS cita_agendada;

-- Caso que falla P-3 (médico no tiene la especialidad 6 = Ginecología):
-- Error esperado: ERROR 1644 (45000): El médico no cuenta con la especialidad seleccionada
-- CALL sp_agendar_cita(@nuevo_pac, 1, 6, 4, 3, '2026-12-01 11:00:00', 5, @fallo_cita);

-- Prueba P-2: Cancelar la cita recién creada con motivo 2 (Viaje)
CALL sp_cancelar_cita(@nueva_cita, 2, 1, '2026-11-30 10:00:00');
SELECT id, status, cancellation_reason_id FROM appointments WHERE id = @nueva_cita;

-- Caso que falla P-2 (intentar cancelar una cita ya ATENDIDA):
-- Error esperado: ERROR 1644 (45000): Solo se pueden cancelar citas en estado PROGRAMADA o CONFIRMADA
-- CALL sp_cancelar_cita(1, 2, 1, '2026-11-30 10:00:00');

-- Prueba P-4: Facturar atención 13 (que dejamos sin facturar en el DML)
CALL sp_facturar_atencion(13, '2026-11-09', @nueva_factura);
SELECT * FROM invoices WHERE id = @nueva_factura;

-- Caso que falla P-4 (intentar facturar de nuevo la atención 13):
-- Error esperado: ERROR 1644 (45000): Esta atención ya fue facturada previamente
-- CALL sp_facturar_atencion(13, '2026-11-09', @fallo_factura);

-- Prueba P-5: Reporte de producción de noviembre 2026 con cursor
CALL sp_reporte_produccion('2026-11-01', '2026-11-30');