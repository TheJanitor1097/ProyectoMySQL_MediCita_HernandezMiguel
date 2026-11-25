	USE medicita_ips;

-- BLOQUE 1: CONSULTAS DE UNA TABLA (1 - 8)

-- Consulta 1: Pacientes nacidos antes de 1960, del mayor al menor.
SELECT
    document_number AS documento,
    CONCAT(first_name, ' ', last_name) AS nombre_completo,
    birth_date AS fecha_nacimiento
FROM patients
WHERE birth_date < '1960-01-01'
ORDER BY birth_date ASC;

-- Consulta 2: Médicos activos con su registro médico y correo, ordenados por apellido.
SELECT
    medical_license AS registro_medico,
    CONCAT(first_name, ' ', last_name) AS medico,
    institutional_email AS correo
FROM doctors
WHERE status = 'ACTIVO'
ORDER BY last_name ASC, first_name ASC;

-- Consulta 3: Citas con inicio entre el 1 y el 7 de diciembre de 2026.
SELECT
    id AS cita_id,
    patient_id,
    doctor_id,
    scheduled_start AS inicio,
    scheduled_end AS fin,
    status AS estado
FROM appointments
WHERE scheduled_start >= '2026-12-01 00:00:00'
  AND scheduled_start < '2026-12-08 00:00:00'
ORDER BY scheduled_start ASC;

-- Consulta 4: Exámenes de laboratorio cuya unidad es mg/dL, con su rango de referencia.
SELECT
    name AS examen,
    unit AS unidad,
    min_reference AS minimo,
    max_reference AS maximo
FROM lab_tests
WHERE unit = 'mg/dL'
ORDER BY name ASC;

-- Consulta 5: Cantidad de citas por estado, de la más frecuente a la menos frecuente.
SELECT
    status AS estado,
    COUNT(*) AS total_citas
FROM appointments
GROUP BY status
ORDER BY total_citas DESC;

-- Consulta 6: Facturas emitidas en noviembre de 2026 con total mayor a 150.000, de mayor a menor.
SELECT
    id AS factura_id,
    issue_date AS fecha_emision,
    total_amount AS total,
    status AS estado
FROM invoices
WHERE issue_date >= '2026-11-01'
  AND issue_date <= '2026-11-30'
  AND total_amount > 150000.00
ORDER BY total_amount DESC;

-- Consulta 7: Pacientes sin correo registrado.
SELECT
    id AS paciente_id,
    document_number AS documento,
    CONCAT(first_name, ' ', last_name) AS paciente
FROM patients
WHERE email IS NULL
ORDER BY last_name ASC;

-- Consulta 8: Los 5 servicios con la tarifa vigente al corte (2026-11-30) más alta para plan PARTICULAR.
SELECT
    cups_service_id AS servicio_id,
    price AS tarifa,
    valid_from AS vigente_desde,
    valid_to AS vigente_hasta
FROM service_tariffs
WHERE plan_id = 10
  AND valid_from <= '2026-11-30'
  AND (valid_to IS NULL OR valid_to >= '2026-11-30')
ORDER BY price DESC
LIMIT 5;

-- BLOQUE 2: CONSULTAS CON JOINS (9 - 15)

-- Consulta 9: Agenda del martes 1 de diciembre de 2026 en orden de hora.
SELECT
    TIME(a.scheduled_start) AS hora,
    CONCAT(p.first_name, ' ', p.last_name) AS paciente,
    CONCAT(d.first_name, ' ', d.last_name) AS medico,
    s.name AS especialidad,
    o.office_number AS consultorio,
    b.name AS sede
FROM appointments AS a
JOIN patients AS p ON p.id = a.patient_id
JOIN doctors AS d ON d.id = a.doctor_id
JOIN specialties AS s ON s.id = a.specialty_id
JOIN offices AS o ON o.id = a.office_id
JOIN branches AS b ON b.id = o.branch_id
WHERE a.scheduled_start >= '2026-12-01 00:00:00'
  AND a.scheduled_start < '2026-12-02 00:00:00'
ORDER BY a.scheduled_start ASC;

-- Consulta 10: Cada paciente con su afiliación vigente al corte.
SELECT
    CONCAT(p.first_name, ' ', p.last_name) AS paciente,
    i.name AS aseguradora,
    pl.name AS plan,
    pa.start_date AS fecha_inicio,
    pa.end_date AS fecha_fin
FROM patients AS p
JOIN patient_affiliations AS pa ON pa.patient_id = p.id
JOIN plans AS pl ON pl.id = pa.plan_id
JOIN insurers AS i ON i.id = pl.insurer_id
WHERE pa.status = 'ACTIVA'
  AND pa.start_date <= '2026-11-30'
  AND (pa.end_date IS NULL OR pa.end_date >= '2026-11-30')
ORDER BY p.last_name ASC, p.first_name ASC;

-- Consulta 11: Cada médico con sus especialidades y sedes donde atiende.
SELECT
    CONCAT(d.first_name, ' ', d.last_name) AS medico,
    s.name AS especialidad,
    b.name AS sede
FROM doctors AS d
JOIN doctor_specialties AS ds ON ds.doctor_id = d.id
JOIN specialties AS s ON s.id = ds.specialty_id
JOIN doctor_branches AS db ON db.doctor_id = d.id
JOIN branches AS b ON b.id = db.branch_id
ORDER BY d.last_name ASC, s.name ASC, b.name ASC;

-- Consulta 12: Diagnósticos principales de las atenciones de noviembre de 2026.
SELECT
    att.attention_date AS fecha,
    CONCAT(p.first_name, ' ', p.last_name) AS paciente,
    CONCAT(d.first_name, ' ', d.last_name) AS medico,
    c.code AS codigo_cie10,
    c.description AS nombre_cie10
FROM attentions AS att
JOIN appointments AS a ON a.id = att.appointment_id
JOIN patients AS p ON p.id = a.patient_id
JOIN doctors AS d ON d.id = a.doctor_id
JOIN attention_diagnoses AS ad ON ad.attention_id = att.id
JOIN cie10_codes AS c ON c.id = ad.cie10_id
WHERE ad.is_primary = 1
  AND att.attention_date >= '2026-11-01 00:00:00'
  AND att.attention_date < '2026-12-01 00:00:00'
ORDER BY att.attention_date ASC;

-- Consulta 13: Fórmulas emitidas con detalle de medicamento y principio activo.
SELECT
    pr.issued_at AS fecha,
    CONCAT(p.first_name, ' ', p.last_name) AS paciente,
    CONCAT(d.first_name, ' ', d.last_name) AS medico,
    m.commercial_name AS medicamento,
    ai.name AS principio_activo,
    pi.dosage AS dosis,
    pi.frequency AS frecuencia,
    pi.duration_days AS dias
FROM prescriptions AS pr
JOIN prescription_items AS pi ON pi.prescription_id = pr.id
JOIN medications AS m ON m.id = pi.medication_id
JOIN active_ingredients AS ai ON ai.id = m.active_ingredient_id
JOIN attentions AS att ON att.id = pr.attention_id
JOIN appointments AS a ON a.id = att.appointment_id
JOIN patients AS p ON p.id = a.patient_id
JOIN doctors AS d ON d.id = a.doctor_id
ORDER BY pr.issued_at ASC, m.commercial_name ASC;

-- Consulta 14: Resultados de laboratorio fuera de rango de referencia
SELECT
    CONCAT(p.first_name, ' ', p.last_name) AS paciente,
    lt.name AS examen,
    loi.result_value AS valor,
    lt.unit AS unidad,
    lt.min_reference AS minimo,
    lt.max_reference AS maximo
FROM lab_order_items AS loi
JOIN lab_tests AS lt ON lt.id = loi.lab_test_id
JOIN lab_orders AS lo ON lo.id = loi.lab_order_id
JOIN attentions AS att ON att.id = lo.attention_id
JOIN appointments AS a ON a.id = att.appointment_id
JOIN patients AS p ON p.id = a.patient_id
WHERE loi.result_value IS NOT NULL
  AND (loi.result_value < lt.min_reference OR loi.result_value > lt.max_reference)
ORDER BY p.last_name ASC, lt.name ASC;

-- Consulta 15: Citas canceladas con su motivo, quién las canceló y cuándo según el historial.
SELECT
    a.id AS cita_id,
    CONCAT(p.first_name, ' ', p.last_name) AS paciente,
    cr.name AS motivo,
    su.full_name AS cancelado_por,
    ash.changed_at AS fecha_cancelacion
FROM appointments AS a
JOIN patients AS p ON p.id = a.patient_id
JOIN cancellation_reasons AS cr ON cr.id = a.cancellation_reason_id
JOIN appointment_status_history AS ash ON ash.appointment_id = a.id
JOIN system_users AS su ON su.id = ash.changed_by
WHERE a.status = 'CANCELADA'
  AND ash.new_status = 'CANCELADA'
ORDER BY ash.changed_at ASC;

-- BLOQUE 3: AGREGACIÓN Y LEFT JOIN (16 - 20)

-- Consulta 16: Atenciones por especialidad y por mes, solo combinaciones con 3 o más atenciones.
SELECT
    s.name AS especialidad,
    DATE_FORMAT(att.attention_date, '%Y-%m') AS mes,
    COUNT(att.id) AS total_atenciones
FROM attentions AS att
JOIN appointments AS a ON a.id = att.appointment_id
JOIN specialties AS s ON s.id = a.specialty_id
GROUP BY s.id, s.name, DATE_FORMAT(att.attention_date, '%Y-%m')
HAVING COUNT(att.id) >= 3
ORDER BY mes ASC, total_atenciones DESC;

-- Consulta 17: Médicos activos sin ninguna cita en diciembre de 2026.
SELECT
    d.id AS medico_id,
    d.medical_license AS registro_medico,
    CONCAT(d.first_name, ' ', d.last_name) AS medico
FROM doctors AS d
LEFT JOIN appointments AS a
    ON a.doctor_id = d.id
   AND a.scheduled_start >= '2026-12-01 00:00:00'
   AND a.scheduled_start < '2027-01-01 00:00:00'
WHERE d.status = 'ACTIVO'
  AND a.id IS NULL
ORDER BY d.last_name ASC;

-- Consulta 18: Porcentaje de inasistencia por sede antes del corte (2026-11-30), de peor a mejor.
SELECT
    b.name AS sede,
    COUNT(a.id) AS total_citas,
    SUM(CASE WHEN a.status = 'NO_ASISTIO' THEN 1 ELSE 0 END) AS inasistencias,
    ROUND(
        SUM(CASE WHEN a.status = 'NO_ASISTIO' THEN 1 ELSE 0 END) * 100.0 / COUNT(a.id),
        2
    ) AS porcentaje_inasistencia
FROM branches AS b
JOIN offices AS o ON o.branch_id = b.id
JOIN appointments AS a ON a.office_id = o.id
WHERE a.scheduled_start <= '2026-11-30 23:59:59'
GROUP BY b.id, b.name
ORDER BY porcentaje_inasistencia DESC, b.name ASC;

-- Consulta 19: Por aseguradora, total facturado (sin anuladas), total abonado y saldo sin duplicar montos.
SELECT
    ins.name AS aseguradora,
    ROUND(IFNULL(SUM(inv.total_amount), 0), 2) AS total_facturado,
    ROUND(IFNULL(SUM(pay.total_pagado), 0), 2) AS total_abonado,
    ROUND(IFNULL(SUM(inv.total_amount), 0) - IFNULL(SUM(pay.total_pagado), 0), 2) AS saldo
FROM insurers AS ins
JOIN plans AS pl ON pl.insurer_id = ins.id
LEFT JOIN invoices AS inv
    ON inv.plan_id = pl.id
   AND inv.status <> 'ANULADA'
LEFT JOIN (
    SELECT invoice_id, SUM(amount) AS total_pagado
    FROM payments
    GROUP BY invoice_id
) AS pay ON pay.invoice_id = inv.id
GROUP BY ins.id, ins.name
ORDER BY saldo DESC, ins.name ASC;

-- Consulta 20: Promedio de satisfacción por médico y número de encuestas (solo 2 o más), de mejor a peor.
SELECT
    CONCAT(d.first_name, ' ', d.last_name) AS medico,
    COUNT(ss.id) AS total_encuestas,
    ROUND(AVG(ss.rating), 2) AS promedio_satisfaccion
FROM doctors AS d
JOIN appointments AS a ON a.doctor_id = d.id
JOIN satisfaction_surveys AS ss ON ss.appointment_id = a.id
GROUP BY d.id, d.first_name, d.last_name
HAVING COUNT(ss.id) >= 2
ORDER BY promedio_satisfaccion DESC, total_encuestas DESC;

-- BLOQUE 4: SUBCONSULTAS, CORRELACIONADAS Y VENTANA (21 - 30)

-- Consulta 21: Pacientes cuyo número de citas supera el promedio de citas por paciente.
SELECT
    p.id AS paciente_id,
    CONCAT(p.first_name, ' ', p.last_name) AS paciente,
    COUNT(a.id) AS total_citas
FROM patients AS p
JOIN appointments AS a ON a.patient_id = p.id
GROUP BY p.id, p.first_name, p.last_name
HAVING COUNT(a.id) > (
    SELECT AVG(citas_por_paciente)
    FROM (
        SELECT COUNT(*) AS citas_por_paciente
        FROM appointments
        GROUP BY patient_id
    ) AS conteo
)
ORDER BY total_citas DESC, p.last_name ASC;

-- Consulta 22: Médicos que han atendido al paciente con más atenciones de la IPS.
SELECT DISTINCT
    d.id AS medico_id,
    CONCAT(d.first_name, ' ', d.last_name) AS medico,
    CONCAT(p.first_name, ' ', p.last_name) AS paciente_mas_atendido
FROM doctors AS d
JOIN appointments AS a ON a.doctor_id = d.id
JOIN attentions AS att ON att.appointment_id = a.id
JOIN patients AS p ON p.id = a.patient_id
WHERE a.patient_id IN (
    SELECT a2.patient_id
    FROM appointments AS a2
    JOIN attentions AS att2 ON att2.appointment_id = a2.id
    GROUP BY a2.patient_id
    HAVING COUNT(att2.id) = (
        SELECT MAX(total_att)
        FROM (
            SELECT COUNT(att3.id) AS total_att
            FROM appointments AS a3
            JOIN attentions AS att3 ON att3.appointment_id = a3.id
            GROUP BY a3.patient_id
        ) AS resumen_att
    )
)  -- Queria ordenarlo por last_name pero hubo un error en el select y genuinamente me dio paja arreglarlo.
ORDER BY medico ASC;

-- Consulta 23: Consultorios que nunca han tenido una cita.
SELECT
    o.id AS consultorio_id,
    b.name AS sede,
    o.office_number AS consultorio,
    o.floor AS piso
FROM offices AS o
JOIN branches AS b ON b.id = o.branch_id
WHERE NOT EXISTS (
    SELECT 1
    FROM appointments AS a
    WHERE a.office_id = o.id
)
ORDER BY b.name ASC, o.office_number ASC;

-- Consulta 24: Pacientes con alguna alergia registrada que sí tienen fórmulas emitidas.
SELECT
    p.id AS paciente_id,
    CONCAT(p.first_name, ' ', p.last_name) AS paciente
FROM patients AS p
WHERE EXISTS (
    SELECT 1
    FROM patient_allergies AS pa
    WHERE pa.patient_id = p.id
)
AND EXISTS (
    SELECT 1
    FROM appointments AS a
    JOIN attentions AS att ON att.appointment_id = a.id
    JOIN prescriptions AS pr ON pr.attention_id = att.id
    WHERE a.patient_id = p.id
)
ORDER BY p.last_name ASC;

-- Consulta 25: Por cada especialidad, el médico con más atenciones.
WITH ranking_especialidad AS (
    SELECT
        s.name AS especialidad,
        CONCAT(d.first_name, ' ', d.last_name) AS medico,
        COUNT(att.id) AS total_atenciones,
        RANK() OVER (
            PARTITION BY s.id
            ORDER BY COUNT(att.id) DESC
        ) AS posicion
    FROM attentions AS att
    JOIN appointments AS a ON a.id = att.appointment_id
    JOIN specialties AS s ON s.id = a.specialty_id
    JOIN doctors AS d ON d.id = a.doctor_id
    GROUP BY s.id, s.name, d.id, d.first_name, d.last_name
)
SELECT
    especialidad,
    medico,
    total_atenciones
FROM ranking_especialidad
WHERE posicion = 1
ORDER BY especialidad ASC, medico ASC;

-- Consulta 26: Facturas cuyo total supera el promedio de las facturas de su misma aseguradora.=
SELECT
    inv.id AS factura_id,
    ins.name AS aseguradora,
    inv.issue_date AS fecha_emision,
    inv.total_amount AS total_factura
FROM invoices AS inv
JOIN plans AS pl ON pl.id = inv.plan_id
JOIN insurers AS ins ON ins.id = pl.insurer_id
WHERE inv.status <> 'ANULADA'
  AND inv.total_amount > (
      SELECT AVG(inv2.total_amount)
      FROM invoices AS inv2
      JOIN plans AS pl2 ON pl2.id = inv2.plan_id
      WHERE pl2.insurer_id = ins.id
        AND inv2.status <> 'ANULADA'
  )
ORDER BY ins.name ASC, inv.total_amount DESC;

-- Consulta 27: Producción por sede en noviembre de 2026 y su participación porcentual sobre el total de la IPS.
SELECT
    b.name AS sede,
    ROUND(SUM(inv.total_amount), 2) AS total_facturado,
    ROUND(SUM(inv.total_amount) * 100.0 / total_ips.gran_total, 2) AS participacion_porcentual
FROM invoices AS inv
JOIN attentions AS att ON att.id = inv.attention_id
JOIN appointments AS a ON a.id = att.appointment_id
JOIN offices AS o ON o.id = a.office_id
JOIN branches AS b ON b.id = o.branch_id
CROSS JOIN (
    SELECT SUM(total_amount) AS gran_total
    FROM invoices
    WHERE status <> 'ANULADA'
      AND issue_date >= '2026-11-01'
      AND issue_date <= '2026-11-30'
) AS total_ips
WHERE inv.status <> 'ANULADA'
  AND inv.issue_date >= '2026-11-01'
  AND inv.issue_date <= '2026-11-30'
GROUP BY b.id, b.name, total_ips.gran_total
ORDER BY total_facturado DESC;

-- Consulta 28: Última cita de cada paciente hasta el corte (2026-11-30) y días transcurridos hasta el corte.
SELECT
    p.id AS paciente_id,
    CONCAT(p.first_name, ' ', p.last_name) AS paciente,
    ult.ultima_cita,
    DATEDIFF('2026-11-30', DATE(ult.ultima_cita)) AS dias_desde_ultima_cita
FROM patients AS p
JOIN (
    SELECT
        patient_id,
        MAX(scheduled_start) AS ultima_cita
    FROM appointments
    WHERE scheduled_start <= '2026-11-30 23:59:59'
    GROUP BY patient_id
) AS ult ON ult.patient_id = p.id
ORDER BY dias_desde_ultima_cita DESC, p.last_name ASC;

-- Consulta 29: Pacientes con diagnóstico de hipertensión (I10) cuya última presión sistólica es 140 o más.
SELECT
    p.id AS paciente_id,
    CONCAT(p.first_name, ' ', p.last_name) AS paciente,
    att.attention_date AS fecha_ultima_toma,
    vs.systolic_bp AS sistolica,
    vs.diastolic_bp AS diastolica
FROM patients AS p
JOIN appointments AS a ON a.patient_id = p.id
JOIN attentions AS att ON att.appointment_id = a.id
JOIN vital_signs AS vs ON vs.attention_id = att.id
WHERE vs.systolic_bp >= 140
  AND att.attention_date = (
      SELECT MAX(att2.attention_date)
      FROM appointments AS a2
      JOIN attentions AS att2 ON att2.appointment_id = a2.id
      JOIN vital_signs AS vs2 ON vs2.attention_id = att2.id
      WHERE a2.patient_id = p.id
  )
  AND EXISTS (
      SELECT 1
      FROM appointments AS a3
      JOIN attentions AS att3 ON att3.appointment_id = a3.id
      JOIN attention_diagnoses AS ad3 ON ad3.attention_id = att3.id
      JOIN cie10_codes AS c3 ON c3.id = ad3.cie10_id
      WHERE a3.patient_id = p.id
        AND c3.code = 'I10'
  )
ORDER BY vs.systolic_bp DESC;

-- Consulta 30: Los 3 diagnósticos más frecuentes de cada sede con su posición (desempate por menor CIE-10).
WITH conteo_diagnosticos AS (
    SELECT
        b.name AS sede,
        c.code AS codigo_cie10,
        c.description AS diagnostico,
        COUNT(ad.id) AS frecuencia,
        ROW_NUMBER() OVER (
            PARTITION BY b.id
            ORDER BY COUNT(ad.id) DESC, c.code ASC
        ) AS posicion
    FROM branches AS b
    JOIN offices AS o ON o.branch_id = b.id
    JOIN appointments AS a ON a.office_id = o.id
    JOIN attentions AS att ON att.appointment_id = a.id
    JOIN attention_diagnoses AS ad ON ad.attention_id = att.id
    JOIN cie10_codes AS c ON c.id = ad.cie10_id
    GROUP BY b.id, b.name, c.id, c.code, c.description
)
SELECT
    sede,
    posicion,
    codigo_cie10,
    diagnostico,
    frecuencia
FROM conteo_diagnosticos
WHERE posicion <= 3
ORDER BY sede ASC, posicion ASC;