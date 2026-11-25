USE medicita_ips;

-- T-1: Validar rangos fisiológicos de signos vitales antes de insertar
DROP TRIGGER IF EXISTS trg_vital_signs_before_insert;

DELIMITER $$

CREATE TRIGGER trg_vital_signs_before_insert
BEFORE INSERT ON vital_signs
FOR EACH ROW
BEGIN
    IF NEW.systolic_bp < 60 OR NEW.systolic_bp > 260 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Presión sistólica fuera de rango permitido (60 a 260)';
    END IF;

    IF NEW.diastolic_bp < 30 OR NEW.diastolic_bp > 160 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Presión diastólica fuera de rango permitido (30 a 160)';
    END IF;

    IF NEW.diastolic_bp >= NEW.systolic_bp THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La presión diastólica debe ser menor que la sistólica';
    END IF;

    IF NEW.temperature_c < 30.0 OR NEW.temperature_c > 45.0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Temperatura fuera de rango permitido (30 a 45 °C)';
    END IF;

    IF NEW.heart_rate < 20 OR NEW.heart_rate > 250 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Frecuencia cardíaca fuera de rango permitido (20 a 250)';
    END IF;
END $$

DELIMITER ;

-- T-2: Impedir el borrado físico de facturas (exigencia DIAN y auditoría)
DROP TRIGGER IF EXISTS trg_invoices_before_delete;

DELIMITER $$

CREATE TRIGGER trg_invoices_before_delete
BEFORE DELETE ON invoices
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Las facturas no se borran: anúlela';
END $$

DELIMITER ;

-- T-3: Auditar cada cambio de estado de una cita en appointment_status_history
DROP TRIGGER IF EXISTS trg_appointments_after_update;

DELIMITER $$

CREATE TRIGGER trg_appointments_after_update
AFTER UPDATE ON appointments
FOR EACH ROW
BEGIN
    IF NOT (OLD.status <=> NEW.status) THEN
        INSERT INTO appointment_status_history (
            appointment_id, previous_status, new_status, changed_at, changed_by
        ) VALUES (
            NEW.id, OLD.status, NEW.status, NOW(), NEW.updated_by
        );
    END IF;
END $$

DELIMITER ;

-- T-4: Actualizar estado de la factura (PARCIAL o PAGADA) tras cada abono
DROP TRIGGER IF EXISTS trg_payments_after_insert;

DELIMITER $$

CREATE TRIGGER trg_payments_after_insert
AFTER INSERT ON payments
FOR EACH ROW
BEGIN
    DECLARE v_total DECIMAL(12,2);
    DECLARE v_abonado DECIMAL(12,2);

    SELECT total_amount
    INTO v_total
    FROM invoices
    WHERE id = NEW.invoice_id;

    SELECT IFNULL(SUM(amount), 0.00)
    INTO v_abonado
    FROM payments
    WHERE invoice_id = NEW.invoice_id;

    IF v_abonado >= v_total THEN
        UPDATE invoices
        SET status = 'PAGADA'
        WHERE id = NEW.invoice_id;
    ELSEIF v_abonado > 0 THEN
        UPDATE invoices
        SET status = 'PARCIAL'
        WHERE id = NEW.invoice_id;
    END IF;
END $$

DELIMITER ;

-- T-5: Bloquear formulación de medicamentos cuyo principio activo causa alergia
DROP TRIGGER IF EXISTS trg_prescription_items_before_insert;

DELIMITER $$

CREATE TRIGGER trg_prescription_items_before_insert
BEFORE INSERT ON prescription_items
FOR EACH ROW
BEGIN
    DECLARE v_patient_id BIGINT;
    DECLARE v_ingredient_id BIGINT;
    DECLARE v_es_alergico INT DEFAULT 0;

    -- Obtener el paciente dueño de la fórmula
    SELECT a.patient_id
    INTO v_patient_id
    FROM prescriptions AS pr
    JOIN attentions AS att ON att.id = pr.attention_id
    JOIN appointments AS a ON a.id = att.appointment_id
    WHERE pr.id = NEW.prescription_id;

    -- Obtener el principio activo del medicamento
    SELECT active_ingredient_id
    INTO v_ingredient_id
    FROM medications
    WHERE id = NEW.medication_id;

    -- Verificar si el paciente tiene registrada esa alergia
    SELECT COUNT(*)
    INTO v_es_alergico
    FROM patient_allergies
    WHERE patient_id = v_patient_id
      AND active_ingredient_id = v_ingredient_id;

    IF v_es_alergico > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Alerta clínica: el paciente es alérgico al principio activo de este medicamento';
    END IF;
END $$

DELIMITER ;

-- PRUEBAS DE LOS 5 TRIGGERS

-- Prueba T-1 (caso que falla: presión sistólica absurda de 1200)
-- Error esperado: ERROR 1644 (45000): Presión sistólica fuera de rango permitido (60 a 260)
-- INSERT INTO vital_signs (attention_id, systolic_bp, diastolic_bp, heart_rate, temperature_c, weight_kg, height_cm)
-- VALUES (14, 1200, 80, 75, 36.5, 70.00, 170.00);

-- Prueba T-2 (caso que falla: intentar borrar la factura 1)
-- ⚠Error esperado: ERROR 1644 (45000): Las facturas no se borran: anúlela
-- DELETE FROM invoices WHERE id = 1;

-- Prueba T-3: Cambiar estado de la cita 22 de PROGRAMADA a CONFIRMADA y revisar historial
UPDATE appointments
SET status = 'CONFIRMADA', updated_by = 4
WHERE id = 22;

SELECT appointment_id, previous_status, new_status, changed_by
FROM appointment_status_history
WHERE appointment_id = 22;

-- Prueba T-4: Abonar a la factura 10 (PENDIENTE, total 115.000) en dos pagos
INSERT INTO payments (invoice_id, amount, payment_method, paid_at)
VALUES (10, 50000.00, 'EFECTIVO', '2026-11-20 10:00:00');
SELECT id, total_amount, status FROM invoices WHERE id = 10; -- Debe quedar PARCIAL

INSERT INTO payments (invoice_id, amount, payment_method, paid_at)
VALUES (10, 65000.00, 'PSE', '2026-11-25 11:00:00');
SELECT id, total_amount, status FROM invoices WHERE id = 10; -- Debe quedar PAGADA

-- Prueba T-5 (caso que funciona: fórmula 1 es de Carlos, alérgico a Penicilina, le damos Acetaminofén)
INSERT INTO prescription_items (prescription_id, medication_id, dosage, frequency, duration_days)
VALUES (1, 3, '500 mg', 'Cada 8 horas', 5);
SELECT * FROM prescription_items WHERE prescription_id = 1;

-- Prueba T-5 (caso que falla: intentar formularle Penicilina G a Carlos en la fórmula 1)
-- ⚠Error esperado: ERROR 1644 (45000): Alerta clínica: el paciente es alérgico al principio activo de este medicamento
-- INSERT INTO prescription_items (prescription_id, medication_id, dosage, frequency, duration_days)
-- VALUES (1, 1, '1.2M UI', 'Dosis única', 1);