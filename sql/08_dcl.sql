-- DCL es una de las opciones de SQL la cual desconozco en su mayoria pues en mi anterior grupo de SQL jamas la mencionaron, obviamente estare preparado para el examen
-- Pero lastimosamente esta seccion si esta hecha enteramente con IA </3

USE medicita_ips;

-- ============================================================================
-- 1. PROCEDIMIENTO DE APOYO DEL DCL: sp_anular_factura
-- ============================================================================

 -- Esta seccion de aqui dio error con la IA eeeh, significa que teoricamente hablando soy superior a Gemini, ejem, claramente nunca tuve errores asi en los otros scripts
DROP PROCEDURE IF EXISTS medicita_ips.sp_anular_factura;

DELIMITER $$

CREATE PROCEDURE medicita_ips.sp_anular_factura(
    IN p_factura BIGINT,
    IN p_fecha DATE,
    IN p_motivo VARCHAR(255)
)
BEGIN
    DECLARE v_estado VARCHAR(20);
    DECLARE v_abonos INT DEFAULT 0;

    IF p_motivo IS NULL OR TRIM(p_motivo) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El motivo de anulación es obligatorio';
    END IF;

    SELECT status
    INTO v_estado
    FROM medicita_ips.invoices
    WHERE id = p_factura;

    IF v_estado IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La factura indicada no existe';
    END IF;

    IF v_estado = 'ANULADA' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La factura ya se encuentra anulada';
    END IF;

    SELECT COUNT(*)
    INTO v_abonos
    FROM medicita_ips.payments
    WHERE invoice_id = p_factura;

    IF v_abonos > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No se puede anular una factura que ya tiene abonos registrados';
    END IF;

    UPDATE medicita_ips.invoices
    SET status = 'ANULADA',
        cancellation_date = p_fecha,
        cancellation_reason = TRIM(p_motivo)
    WHERE id = p_factura;
END $$

DELIMITER ;

-- ============================================================================
-- 2. LIMPIEZA PREVIA (PARA HACER EL SCRIPT REPRODUCIBLE)
-- ============================================================================
DROP USER IF EXISTS
    'usr_recepcion'@'localhost',
    'usr_medico'@'localhost',
    'usr_facturacion'@'localhost',
    'usr_auditor'@'localhost',
    'usr_admin_bd'@'localhost';

DROP ROLE IF EXISTS
    'rol_recepcion',
    'rol_medico',
    'rol_facturacion',
    'rol_auditor',
    'rol_admin_bd';

-- ============================================================================
-- 3. CREACIÓN DE ROLES Y ASIGNACIÓN DE PRIVILEGIOS (MÍNIMO PRIVILEGIO)
-- ============================================================================
CREATE ROLE
    'rol_recepcion',
    'rol_medico',
    'rol_facturacion',
    'rol_auditor',
    'rol_admin_bd';

-- --- ROL 1: rol_recepcion ---
-- Puede: consultar pacientes, médicos, agenda y catálogos, y operar solo por procedimientos
GRANT SELECT ON medicita_ips.patients TO 'rol_recepcion';
GRANT SELECT ON medicita_ips.patient_phones TO 'rol_recepcion';
GRANT SELECT ON medicita_ips.emergency_contacts TO 'rol_recepcion';
GRANT SELECT ON medicita_ips.patient_affiliations TO 'rol_recepcion';
GRANT SELECT ON medicita_ips.doctors TO 'rol_recepcion';
GRANT SELECT ON medicita_ips.doctor_specialties TO 'rol_recepcion';
GRANT SELECT ON medicita_ips.doctor_branches TO 'rol_recepcion';
GRANT SELECT ON medicita_ips.doctor_schedules TO 'rol_recepcion';
GRANT SELECT ON medicita_ips.doctor_leaves TO 'rol_recepcion';
GRANT SELECT ON medicita_ips.appointments TO 'rol_recepcion';
GRANT SELECT ON medicita_ips.branches TO 'rol_recepcion';
GRANT SELECT ON medicita_ips.offices TO 'rol_recepcion';
GRANT SELECT ON medicita_ips.document_types TO 'rol_recepcion';
GRANT SELECT ON medicita_ips.specialties TO 'rol_recepcion';
GRANT SELECT ON medicita_ips.appointment_types TO 'rol_recepcion';
GRANT SELECT ON medicita_ips.cancellation_reasons TO 'rol_recepcion';
GRANT EXECUTE ON PROCEDURE medicita_ips.sp_registrar_paciente TO 'rol_recepcion';
GRANT EXECUTE ON PROCEDURE medicita_ips.sp_agendar_cita TO 'rol_recepcion';
GRANT EXECUTE ON PROCEDURE medicita_ips.sp_cancelar_cita TO 'rol_recepcion';

-- --- ROL 2: rol_medico ---
-- Puede: consultar pacientes y agenda, y registrar datos clínicos (sin DELETE ni facturación)
GRANT SELECT ON medicita_ips.patients TO 'rol_medico';
GRANT SELECT ON medicita_ips.patient_allergies TO 'rol_medico';
GRANT SELECT ON medicita_ips.appointments TO 'rol_medico';
GRANT SELECT ON medicita_ips.cie10_codes TO 'rol_medico';
GRANT SELECT ON medicita_ips.cups_services TO 'rol_medico';
GRANT SELECT ON medicita_ips.medications TO 'rol_medico';
GRANT SELECT ON medicita_ips.active_ingredients TO 'rol_medico';
GRANT SELECT ON medicita_ips.lab_tests TO 'rol_medico';
GRANT SELECT, INSERT, UPDATE ON medicita_ips.attentions TO 'rol_medico';
GRANT SELECT, INSERT, UPDATE ON medicita_ips.vital_signs TO 'rol_medico';
GRANT SELECT, INSERT, UPDATE ON medicita_ips.attention_diagnoses TO 'rol_medico';
GRANT SELECT, INSERT, UPDATE ON medicita_ips.attention_procedures TO 'rol_medico';
GRANT SELECT, INSERT, UPDATE ON medicita_ips.prescriptions TO 'rol_medico';
GRANT SELECT, INSERT, UPDATE ON medicita_ips.prescription_items TO 'rol_medico';
GRANT SELECT, INSERT, UPDATE ON medicita_ips.lab_orders TO 'rol_medico';
GRANT SELECT, INSERT, UPDATE ON medicita_ips.lab_order_items TO 'rol_medico';

-- --- ROL 3: rol_facturacion ---
-- Puede: consultar atenciones/tarifas/facturas, registrar abonos y facturar/anular por SP
GRANT SELECT ON medicita_ips.attentions TO 'rol_facturacion';
GRANT SELECT ON medicita_ips.attention_procedures TO 'rol_facturacion';
GRANT SELECT ON medicita_ips.cups_services TO 'rol_facturacion';
GRANT SELECT ON medicita_ips.insurers TO 'rol_facturacion';
GRANT SELECT ON medicita_ips.plans TO 'rol_facturacion';
GRANT SELECT ON medicita_ips.patient_affiliations TO 'rol_facturacion';
GRANT SELECT ON medicita_ips.service_tariffs TO 'rol_facturacion';
GRANT SELECT ON medicita_ips.invoices TO 'rol_facturacion';
GRANT SELECT ON medicita_ips.invoice_items TO 'rol_facturacion';
GRANT SELECT, INSERT ON medicita_ips.payments TO 'rol_facturacion';
GRANT EXECUTE ON PROCEDURE medicita_ips.sp_facturar_atencion TO 'rol_facturacion';
GRANT EXECUTE ON PROCEDURE medicita_ips.sp_anular_factura TO 'rol_facturacion';

-- --- ROL 4: rol_auditor ---
-- Puede: leer todo excepto documento y contacto de pacientes (permiso por columnas)
GRANT SELECT (id, first_name, last_name, birth_date, gender, city) ON medicita_ips.patients TO 'rol_auditor';
GRANT SELECT ON medicita_ips.branches TO 'rol_auditor';
GRANT SELECT ON medicita_ips.offices TO 'rol_auditor';
GRANT SELECT ON medicita_ips.doctors TO 'rol_auditor';
GRANT SELECT ON medicita_ips.appointments TO 'rol_auditor';
GRANT SELECT ON medicita_ips.appointment_status_history TO 'rol_auditor';
GRANT SELECT ON medicita_ips.attentions TO 'rol_auditor';
GRANT SELECT ON medicita_ips.vital_signs TO 'rol_auditor';
GRANT SELECT ON medicita_ips.attention_diagnoses TO 'rol_auditor';
GRANT SELECT ON medicita_ips.prescriptions TO 'rol_auditor';
GRANT SELECT ON medicita_ips.prescription_items TO 'rol_auditor';
GRANT SELECT ON medicita_ips.lab_orders TO 'rol_auditor';
GRANT SELECT ON medicita_ips.lab_order_items TO 'rol_auditor';
GRANT SELECT ON medicita_ips.invoices TO 'rol_auditor';
GRANT SELECT ON medicita_ips.invoice_items TO 'rol_auditor';
GRANT SELECT ON medicita_ips.payments TO 'rol_auditor';
GRANT SELECT ON medicita_ips.monthly_production_summary TO 'rol_auditor';

-- --- ROL 5: rol_admin_bd ---
-- Puede: todo sobre medicita_ips y nada fuera de ella
GRANT ALL PRIVILEGES ON medicita_ips.* TO 'rol_admin_bd';

-- ============================================================================
-- 4. CREACIÓN DE USUARIOS DE PRUEBA Y ACTIVACIÓN DE ROLES POR DEFECTO
-- ============================================================================
CREATE USER 'usr_recepcion'@'localhost' IDENTIFIED BY 'Practica_2026*';
CREATE USER 'usr_medico'@'localhost' IDENTIFIED BY 'Practica_2026*';
CREATE USER 'usr_facturacion'@'localhost' IDENTIFIED BY 'Practica_2026*';
CREATE USER 'usr_auditor'@'localhost' IDENTIFIED BY 'Practica_2026*';
CREATE USER 'usr_admin_bd'@'localhost' IDENTIFIED BY 'Practica_2026*';

GRANT 'rol_recepcion' TO 'usr_recepcion'@'localhost';
GRANT 'rol_medico' TO 'usr_medico'@'localhost';
GRANT 'rol_facturacion' TO 'usr_facturacion'@'localhost';
GRANT 'rol_auditor' TO 'usr_auditor'@'localhost';
GRANT 'rol_admin_bd' TO 'usr_admin_bd'@'localhost';

SET DEFAULT ROLE 'rol_recepcion' TO 'usr_recepcion'@'localhost';
SET DEFAULT ROLE 'rol_medico' TO 'usr_medico'@'localhost';
SET DEFAULT ROLE 'rol_facturacion' TO 'usr_facturacion'@'localhost';
SET DEFAULT ROLE 'rol_auditor' TO 'usr_auditor'@'localhost';
SET DEFAULT ROLE 'rol_admin_bd' TO 'usr_admin_bd'@'localhost';

-- ============================================================================
-- 5. EVIDENCIA DE PERMISOS (SHOW GRANTS CON USING)
-- ============================================================================
SHOW GRANTS FOR 'usr_recepcion'@'localhost' USING 'rol_recepcion';
SHOW GRANTS FOR 'usr_medico'@'localhost' USING 'rol_medico';
SHOW GRANTS FOR 'usr_facturacion'@'localhost' USING 'rol_facturacion';
SHOW GRANTS FOR 'usr_auditor'@'localhost' USING 'rol_auditor';
SHOW GRANTS FOR 'usr_admin_bd'@'localhost' USING 'rol_admin_bd';

-- ============================================================================
-- 6. PRUEBAS POR CONEXIÓN (EJECUTAR CONECTADO CON CADA USUARIO)
-- ============================================================================

-- [Conexión: usr_recepcion]
-- Permitida:
-- SELECT id, scheduled_start, status FROM medicita_ips.appointments LIMIT 5;
-- Denegada (ver datos clínicos):
-- ⚠️ ESPERADO: ERROR 1142 (42000): SELECT command denied to user 'usr_recepcion'@'localhost' for table 'attention_diagnoses'
-- SELECT * FROM medicita_ips.attention_diagnoses;
-- Denegada (modificar cita directamente):
-- ⚠️ ESPERADO: ERROR 1142 (42000): UPDATE command denied to user 'usr_recepcion'@'localhost' for table 'appointments'
-- UPDATE medicita_ips.appointments SET status = 'CANCELADA' WHERE id = 21;

-- [Conexión: usr_medico]
-- Permitida:
-- SELECT id, attention_date FROM medicita_ips.attentions LIMIT 5;
-- Denegada (ver facturación):
-- ⚠️ ESPERADO: ERROR 1142 (42000): SELECT command denied to user 'usr_medico'@'localhost' for table 'invoices'
-- SELECT * FROM medicita_ips.invoices;
-- Denegada (borrar datos clínicos):
-- ⚠️ ESPERADO: ERROR 1142 (42000): DELETE command denied to user 'usr_medico'@'localhost' for table 'vital_signs'
-- DELETE FROM medicita_ips.vital_signs WHERE id = 1;

-- [Conexión: usr_facturacion]
-- Permitida:
-- SELECT id, total_amount, status FROM medicita_ips.invoices LIMIT 5;
-- Denegada (ver diagnósticos clínicos):
-- ⚠️ ESPERADO: ERROR 1142 (42000): SELECT command denied to user 'usr_facturacion'@'localhost' for table 'attention_diagnoses'
-- SELECT * FROM medicita_ips.attention_diagnoses;
-- Denegada (cambiar estado de factura directamente sin SP):
-- ⚠️ ESPERADO: ERROR 1142 (42000): UPDATE command denied to user 'usr_facturacion'@'localhost' for table 'invoices'
-- UPDATE medicita_ips.invoices SET status = 'ANULADA' WHERE id = 1;

-- [Conexión: usr_auditor]
-- Permitida (columnas no sensibles de pacientes):
-- SELECT id, first_name, last_name, city FROM medicita_ips.patients LIMIT 5;
-- Denegada (leer documento o correo del paciente):
-- ⚠️ ESPERADO: ERROR 1143 (42000): SELECT command denied to user 'usr_auditor'@'localhost' for column 'document_number' in table 'patients'
-- SELECT id, document_number, email FROM medicita_ips.patients LIMIT 5;
-- Denegada (ejecutar procedimiento):
-- ⚠️ ESPERADO: ERROR 1370 (42000): execute command denied to user 'usr_auditor'@'localhost' for routine 'medicita_ips.sp_anular_factura'
-- CALL medicita_ips.sp_anular_factura(1, '2026-11-30', 'Prueba');

-- [Conexión: usr_admin_bd]
-- Permitida:
-- SELECT COUNT(*) AS