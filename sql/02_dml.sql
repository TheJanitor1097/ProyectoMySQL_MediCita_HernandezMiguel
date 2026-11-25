USE medicita_ips;

-- MÓDULO 1: INFRAESTRUCTURA Y CATÁLOGOS BASE

INSERT INTO branches (name, municipality, address) VALUES
('Cabecera', 'Bucaramanga', 'Cra 33 # 48-20'),
('Cañaveral', 'Floridablanca', 'Calle 30 # 25-15'),
('Girón Centro', 'Girón', 'Cra 26 # 31-10'),
('Piedecuesta', 'Piedecuesta', 'Calle 9 # 6-45');

INSERT INTO offices (branch_id, office_number, floor) VALUES
(1, '101', 1), (1, '102', 1), (1, '201', 2),
(2, '101', 1), (2, '102', 1), (2, '201', 2),
(3, '101', 1), (3, '102', 1),
(4, '101', 1), (4, '302', 3); -- El consultorio 10 nunca tendrá citas (Anti-join)

INSERT INTO document_types (code, name) VALUES
('CC', 'Cédula de Ciudadanía'),
('TI', 'Tarjeta de Identidad'),
('CE', 'Cédula de Extranjería'),
('PA', 'Pasaporte'),
('PPT', 'Permiso por Protección Temporal'),
('RC', 'Registro Civil'),
('CD', 'Carné Diplomático'),
('SC', 'Salvoconducto'),
('PEP', 'Permiso Especial de Permanencia'),
('DE', 'Documento Extranjero');

INSERT INTO specialties (name) VALUES
('Medicina General'),
('Medicina Interna'),
('Cardiología'),
('Pediatría'),
('Dermatología'),
('Ginecología'),
('Psicología'),
('Ortopedia'),
('Oftalmología'),
('Nutrición');

INSERT INTO appointment_types (name, duration_minutes) VALUES
('Primera Vez Medicina General', 20),
('Control Medicina General', 20),
('Primera Vez Especialidad', 30),
('Control Especialidad', 20),
('Procedimiento Menor', 40),
('Toma de Muestras', 20),
('Valoración Cardiológica', 40),
('Consulta Pediátrica', 30),
('Sesión Psicología', 40),
('Control Prenatal', 30);

INSERT INTO cancellation_reasons (name) VALUES
('Enfermedad del paciente'),
('Viaje'),
('Olvido'),
('Cambio de EPS'),
('Solicitud del médico'),
('Calamidad doméstica'),
('Dificultad de transporte'),
('Reprogramación laboral'),
('Falla en autorización'),
('Mejora de síntomas');

INSERT INTO cie10_codes (code, description) VALUES
('I10', 'Hipertensión esencial'),
('E11', 'Diabetes mellitus tipo 2'),
('J06', 'Infección respiratoria aguda'),
('K29', 'Gastritis'),
('M54', 'Dorsalgia'),
('F41', 'Ansiedad'),
('N39', 'Infección urinaria'),
('J45', 'Asma'),
('E66', 'Obesidad'),
('L20', 'Dermatitis atópica');

INSERT INTO cups_services (cups_code, name, category) VALUES
('890201', 'Consulta de primera vez por medicina general', 'CONSULTA'),
('890202', 'Consulta de primera vez por medicina especializada', 'CONSULTA'),
('890301', 'Consulta de control por medicina general', 'CONSULTA'),
('895100', 'Electrocardiograma de ritmo o de superficie', 'PROCEDIMIENTO'),
('903883', 'Glucometría capilar', 'PROCEDIMIENTO'),
('862201', 'Curación de herida superficial', 'PROCEDIMIENTO'),
('903841', 'Glucosa en suero', 'LABORATORIO'),
('903818', 'Colesterol total', 'LABORATORIO'),
('903868', 'Triglicéridos', 'LABORATORIO'),
('903895', 'Creatinina en suero', 'LABORATORIO'),
('902210', 'Hemograma completo', 'LABORATORIO'),
('903426', 'Hemoglobina glicosilada HbA1c', 'LABORATORIO'),
('904902', 'TSH ultrasensible', 'LABORATORIO'),
('903801', 'Ácido úrico en suero', 'LABORATORIO'),
('903815', 'Colesterol HDL', 'LABORATORIO'),
('903816', 'Colesterol LDL', 'LABORATORIO');

INSERT INTO active_ingredients (name) VALUES
('Penicilina'),
('Ibuprofeno'),
('Acetaminofén'),
('Losartán'),
('Metformina'),
('Omeprazol'),
('Loratadina'),
('Salbutamol'),
('Amoxicilina'),
('Atorvastatina');

INSERT INTO medications (active_ingredient_id, commercial_name, presentation) VALUES
(1, 'Penicilina G Benzatínica', 'Ampolla 1.2M UI'),
(2, 'Advil Max', 'Cápsula blanda 400mg'),
(3, 'Dolex Forte', 'Tableta 500mg'),
(4, 'Cozaar', 'Tableta 50mg'),
(5, 'Glucophage', 'Tableta 850mg'),
(6, 'Losec', 'Cápsula 20mg'),
(7, 'Clarityne', 'Tableta 10mg'),
(8, 'Ventolin', 'Inhalador 100mcg'),
(9, 'Amoxal', 'Cápsula 500mg'),
(10, 'Lipitor', 'Tableta 20mg');

INSERT INTO lab_tests (cups_service_id, name, unit, min_reference, max_reference) VALUES
(7, 'Glucosa en ayunas', 'mg/dL', 70.00, 100.00),
(8, 'Colesterol total', 'mg/dL', 0.00, 200.00),
(9, 'Triglicéridos', 'mg/dL', 0.00, 150.00),
(10, 'Creatinina sérica', 'mg/dL', 0.60, 1.20),
(11, 'Hemoglobina', 'g/dL', 12.00, 16.50),
(12, 'HbA1c', '%', 4.00, 5.60),
(13, 'TSH', 'mUI/L', 0.40, 4.00),
(14, 'Ácido úrico', 'mg/dL', 3.40, 7.00),
(15, 'Colesterol HDL', 'mg/dL', 40.00, 60.00),
(16, 'Colesterol LDL', 'mg/dL', 0.00, 100.00);

-- MÓDULO 2: MÉDICOS, DISPONIBILIDAD Y USUARIOS DEL SISTEMA
INSERT INTO system_users (username, full_name, role_name) VALUES
('hrueda', 'Hernán Rueda', 'COORDINADOR_AGENDA'),
('lprada', 'Liliana Prada', 'FACTURACION'),
('mortiz', 'Marcela Ortiz', 'DIRECTORA_MEDICA'),
('recep_cab', 'Laura Gómez', 'RECEPCION'),
('recep_can', 'Carlos Méndez', 'RECEPCION'),
('recep_gir', 'Sofía Castro', 'RECEPCION'),
('recep_pie', 'Andrés Silva', 'RECEPCION'),
('fact_aux1', 'Diana Rojas', 'FACTURACION'),
('auditor1', 'Jorge Vargas', 'AUDITOR'),
('sistema', 'Proceso Automático', 'SISTEMA');

INSERT INTO doctors (medical_license, first_name, last_name, institutional_email, status) VALUES
('RM-1001', 'Patricia', 'Salazar', 'p.salazar@medicita.com', 'ACTIVO'), -- 2 esp, 2 sedes
('RM-1002', 'Ricardo', 'Pabón', 'r.pabon@medicita.com', 'ACTIVO'),       -- 2 esp, 2 sedes (A estos 2 les pagan el doble, no?)
('RM-1003', 'Elena', 'Martínez', 'e.martinez@medicita.com', 'ACTIVO'),
('RM-1004', 'Javier', 'Ríos', 'j.rios@medicita.com', 'ACTIVO'),
('RM-1005', 'Mónica', 'Duarte', 'm.duarte@medicita.com', 'ACTIVO'),
('RM-1006', 'Fernando', 'Cárdenas', 'f.cardenas@medicita.com', 'ACTIVO'),
('RM-1007', 'Claudia', 'Pineda', 'c.pineda@medicita.com', 'ACTIVO'),
('RM-1008', 'Diego', 'Navarro', 'd.navarro@medicita.com', 'ACTIVO'),
('RM-1009', 'Lucía', 'Quintero', 'l.quintero@medicita.com', 'ACTIVO'),   -- Sin citas en diciembre
('RM-1010', 'Héctor', 'Suárez', 'h.suarez@medicita.com', 'INACTIVO');

INSERT INTO doctor_specialties (doctor_id, specialty_id) VALUES
(1, 2), (1, 3), -- Dra. Salazar: Medicina Interna y Cardiología
(2, 4), (2, 5), -- Dr. Pabón: Pediatría y Dermatología
(3, 1),
(4, 1),
(5, 6),
(6, 7),
(7, 8),
(8, 2),
(9, 1),
(10, 9);

INSERT INTO doctor_branches (doctor_id, branch_id) VALUES
(1, 1), (1, 2), -- Dra. Salazar: Cabecera y Cañaveral
(2, 1), (2, 3), -- Dr. Pabón: Cabecera y Girón Centro
(3, 1),
(4, 2),
(5, 2),
(6, 3),
(7, 4),
(8, 4),
(9, 1),
(10, 3);

-- Horarios semanales (1=Lunes, 2=Martes, 3=Miércoles, 4=Jueves, 5=Viernes) muy obvio, no?
INSERT INTO doctor_schedules (doctor_id, office_id, day_of_week, start_time, end_time) VALUES
(1, 1, 1, '07:00:00', '12:00:00'), -- Dra. Salazar Lunes Cabecera 101
(1, 4, 2, '08:00:00', '13:00:00'), -- Dra. Salazar Martes Cañaveral 101
(2, 2, 2, '08:00:00', '12:00:00'), -- Dr. Pabón Martes Cabecera 102
(2, 7, 3, '14:00:00', '18:00:00'), -- Dr. Pabón Miércoles Girón 101
(3, 3, 2, '07:00:00', '12:00:00'), -- Dra. Martínez Martes Cabecera 201
(4, 5, 2, '08:00:00', '12:00:00'), -- Dr. Ríos Martes Cañaveral 102
(5, 6, 3, '08:00:00', '12:00:00'), -- Dra. Duarte Miércoles Cañaveral 201
(6, 8, 4, '08:00:00', '12:00:00'), -- Dr. Cárdenas Jueves Girón 102
(7, 9, 5, '08:00:00', '12:00:00'), -- Dra. Pineda Viernes Piedecuesta 101
(8, 9, 1, '14:00:00', '18:00:00'), -- Dr. Navarro Lunes Piedecuesta 101
(9, 1, 5, '14:00:00', '18:00:00'), -- Dra. Quintero Viernes Cabecera 101
(3, 3, 4, '08:00:00', '12:00:00'); -- Dra. Martínez Jueves Cabecera 201

INSERT INTO doctor_leaves (doctor_id, leave_type, start_date, end_date) VALUES
(1, 'CAPACITACION', '2026-12-08', '2026-12-10'),
(2, 'VACACIONES', '2026-12-14', '2026-12-20'),
(3, 'INCAPACIDAD', '2026-10-05', '2026-10-07'),
(4, 'VACACIONES', '2026-09-10', '2026-09-15'),
(5, 'CAPACITACION', '2026-11-02', '2026-11-03'),
(6, 'INCAPACIDAD', '2026-12-03', '2026-12-05'),
(7, 'VACACIONES', '2026-10-20', '2026-10-25'),
(8, 'CAPACITACION', '2026-09-22', '2026-09-23'),
(9, 'VACACIONES', '2026-12-01', '2026-12-15'),
(10, 'INCAPACIDAD', '2026-09-01', '2026-09-10');

-- MÓDULO 3: PACIENTES Y ASEGURAMIENTO

INSERT INTO patients (document_type_id, document_number, first_name, last_name, birth_date, gender, address, city, email) VALUES
(1, '1098765432', 'Carlos', 'Gutiérrez', '1955-03-14', 'M', 'Cra 27 # 45-10', 'Bucaramanga', 'cgutierrez@mail.com'), -- < 1960
(1, '63456789', 'María', 'Peña', '1958-08-22', 'F', 'Calle 36 # 20-15', 'Floridablanca', NULL),                        -- < 1960 y sin email
(1, '1095123456', 'Andrés', 'Rojas', '1985-11-05', 'M', 'Cra 15 # 12-30', 'Girón', 'arojas@mail.com'),
(2, '1095123456', 'Mateo', 'Rojas', '2014-06-18', 'M', 'Cra 15 # 12-30', 'Girón', NULL),                              -- Mismo número, distinto tipo (TI)
(1, '37890123', 'Lucía', 'Fernández', '1972-01-30', 'F', 'Calle 10 # 5-22', 'Piedecuesta', 'lfernandez@mail.com'),
(1, '91234567', 'Jorge', 'Castillo', '1952-12-01', 'M', 'Cra 35 # 52-18', 'Bucaramanga', 'jcastillo@mail.com'),       -- < 1960
(1, '1098222333', 'Valentina', 'Sánchez', '1996-04-12', 'F', 'Calle 200 # 18-40', 'Floridablanca', 'vsanchez@mail.com'),
(3, '456789', 'Luis', 'Morales', '1980-09-09', 'M', 'Cra 22 # 33-11', 'Bucaramanga', 'lmorales@mail.com'),
(1, '63555666', 'Ana', 'Vargas', '1965-07-19', 'F', 'Calle 45 # 28-09', 'Bucaramanga', NULL),                         -- Sin email
(1, '1098444555', 'Sebastián', 'Díaz', '1990-02-25', 'M', 'Cra 10 # 8-14', 'Piedecuesta', 'sdiaz@mail.com'),          -- Particular (sin afiliación)
(1, '37777888', 'Marta', 'Jiménez', '1959-10-10', 'F', 'Calle 31 # 24-50', 'Floridablanca', 'mjimenez@mail.com'),     -- < 1960
(5, '88990011', 'Gabriel', 'Torres', '1988-05-03', 'M', 'Cra 25 # 30-12', 'Girón', 'gtorres@mail.com');

INSERT INTO patient_phones (patient_id, phone_number, is_primary) VALUES
(1, '3101112233', 1), (1, '6076341122', NULL),
(2, '3112223344', 1),
(3, '3123334455', 1), (3, '3009998877', NULL),
(4, '3123334455', 1),
(5, '3134445566', 1),
(6, '3145556677', 1),
(7, '3156667788', 1),
(8, '3167778899', 1),
(9, '3178889900', 1),
(10, '3189990011', 1),
(11, '3190001122', 1),
(12, '3201112233', 1);

INSERT INTO emergency_contacts (patient_id, full_name, relationship, phone_number) VALUES
(1, 'Elena Gutiérrez', 'Hija', '3109876543'),
(2, 'Pedro Peña', 'Esposo', '3118765432'),
(3, 'Carmen Díaz', 'Madre', '3127654321'),
(4, 'Andrés Rojas', 'Padre', '3123334455'),
(5, 'Raúl Fernández', 'Hermano', '3136543210'),
(6, 'Clara Castillo', 'Esposa', '3145432109'),
(7, 'Miguel Sánchez', 'Padre', '3154321098'),
(8, 'Rosa Morales', 'Esposa', '3163210987'),
(9, 'Juan Vargas', 'Hijo', '3172109876'),
(10, 'Laura Díaz', 'Hermana', '3181098765');

INSERT INTO patient_allergies (patient_id, active_ingredient_id, recorded_date) VALUES
(1, 1, '2026-09-01'), -- Carlos alérgico a Penicilina
(2, 2, '2026-09-02'), -- María alérgica a Ibuprofeno (Dios te salve Maria)
(3, 9, '2026-09-05'),
(5, 1, '2026-09-10'),
(6, 2, '2026-09-12'),
(7, 7, '2026-09-15'),
(8, 1, '2026-09-18'),
(9, 6, '2026-09-20'),
(11, 2, '2026-09-25'),
(12, 9, '2026-09-28');

INSERT INTO insurers (nit, name, insurer_type) VALUES
('800130907-4', 'EPS Sura', 'EPS'),
('800251440-6', 'EPS Sanitas', 'EPS'),
('900156264-2', 'Nueva EPS', 'EPS'),
('890903790-5', 'Salud Total EPS', 'EPS'),
('800112806-2', 'Coosalud EPS', 'EPS'),
('860066942-7', 'Colsanitas Prepagada', 'PREPAGADA'),
('800088702-2', 'Medplus Prepagada', 'PREPAGADA'),
('890200756-7', 'Coomeva Medicina Prepagada', 'PREPAGADA'),
('800140949-6', 'Compensar EPS', 'EPS'),
('900000000-0', 'Particular MediCita', 'PARTICULAR');

INSERT INTO plans (insurer_id, name, plan_type, copay_percentage) VALUES
(1, 'Sura Contributivo', 'CONTRIBUTIVO', 15.00),
(2, 'Sanitas Contributivo', 'CONTRIBUTIVO', 15.00),
(3, 'Nueva EPS Subsidiado', 'SUBSIDIADO', 5.00),
(4, 'Salud Total Contributivo', 'CONTRIBUTIVO', 15.00),
(5, 'Coosalud Subsidiado', 'SUBSIDIADO', 0.00),
(6, 'Colsanitas Integral', 'PREPAGADA', 10.00),
(7, 'Medplus Oro', 'PREPAGADA', 10.00),
(8, 'Coomeva Plata', 'PREPAGADA', 12.00),
(9, 'Compensar Contributivo', 'CONTRIBUTIVO', 15.00),
(10, 'Plan Particular', 'PARTICULAR', 100.00);

INSERT INTO patient_affiliations (patient_id, plan_id, start_date, end_date, status) VALUES
(1, 3, '2026-01-01', '2026-08-31', 'INACTIVA'), -- Historial: vencida
(1, 1, '2026-09-01', '2027-08-31', 'ACTIVA'),   -- Vigente
(2, 6, '2026-01-01', '2026-12-31', 'ACTIVA'),
(3, 2, '2026-01-01', '2026-12-31', 'ACTIVA'),
(4, 2, '2026-01-01', '2026-12-31', 'ACTIVA'),
(5, 3, '2026-01-01', '2026-11-15', 'ACTIVA'),   -- Vencida al corte (para el prox evento :p)
(6, 6, '2026-01-01', '2026-12-31', 'ACTIVA'),
(7, 7, '2026-01-01', '2026-12-31', 'ACTIVA'),
(8, 4, '2026-01-01', '2026-12-31', 'ACTIVA'),
(9, 5, '2026-01-01', '2026-12-31', 'ACTIVA'),
-- Paciente 10 sin afiliación (se atiende como PARTICULAR :D)
(11, 1, '2026-01-01', '2026-12-31', 'ACTIVA'),
(12, 8, '2026-01-01', '2026-12-31', 'ACTIVA');

-- MÓDULO 4: AGENDAMIENTO Y EXPERIENCIA DEL PACIENTE

INSERT INTO appointments (patient_id, doctor_id, specialty_id, office_id, appointment_type_id, scheduled_start, scheduled_end, status, cancellation_reason_id, created_by, updated_by) VALUES
-- 14 Citas ATENDIDAS (Septiembre, Octubre y Noviembre 2026)
(1, 1, 2, 1, 3, '2026-09-14 08:00:00', '2026-09-14 08:30:00', 'ATENDIDA', NULL, 4, 4),
(2, 1, 3, 4, 7, '2026-09-15 09:00:00', '2026-09-15 09:40:00', 'ATENDIDA', NULL, 5, 5),
(3, 3, 1, 3, 1, '2026-10-06 08:00:00', '2026-10-06 08:20:00', 'ATENDIDA', NULL, 4, 4),
(4, 2, 4, 2, 8, '2026-10-13 09:00:00', '2026-10-13 09:30:00', 'ATENDIDA', NULL, 4, 4),
(5, 5, 6, 6, 3, '2026-10-14 08:30:00', '2026-10-14 09:00:00', 'ATENDIDA', NULL, 5, 5),
(6, 1, 2, 1, 3, '2026-10-19 09:00:00', '2026-10-19 09:30:00', 'ATENDIDA', NULL, 4, 4),
(1, 1, 2, 1, 4, '2026-11-02 08:00:00', '2026-11-02 08:20:00', 'ATENDIDA', NULL, 4, 4),
(6, 1, 3, 4, 7, '2026-11-03 10:00:00', '2026-11-03 10:40:00', 'ATENDIDA', NULL, 5, 5),
(7, 4, 1, 5, 1, '2026-11-03 08:30:00', '2026-11-03 08:50:00', 'ATENDIDA', NULL, 5, 5),
(8, 2, 5, 7, 3, '2026-11-04 14:30:00', '2026-11-04 15:00:00', 'ATENDIDA', NULL, 6, 6),
(9, 6, 7, 8, 9, '2026-11-05 09:00:00', '2026-11-05 09:40:00', 'ATENDIDA', NULL, 6, 6),
(10, 7, 8, 9, 3, '2026-11-06 08:00:00', '2026-11-06 08:30:00', 'ATENDIDA', NULL, 7, 7),
(11, 1, 2, 1, 3, '2026-11-09 09:00:00', '2026-11-09 09:30:00', 'ATENDIDA', NULL, 4, 4),
(12, 8, 2, 9, 3, '2026-11-16 14:30:00', '2026-11-16 15:00:00', 'ATENDIDA', NULL, 7, 7),
(2, 3, 1, 3, 2, '2026-11-10 08:00:00', '2026-11-10 08:20:00', 'CANCELADA', 1, 4, 1),
(5, 4, 1, 5, 2, '2026-11-17 09:00:00', '2026-11-17 09:20:00', 'CANCELADA', 2, 5, 1),
(3, 3, 1, 3, 2, '2026-11-12 08:30:00', '2026-11-12 08:50:00', 'NO_ASISTIO', NULL, 4, 10),
(3, 3, 1, 3, 2, '2026-11-19 08:30:00', '2026-11-19 08:50:00', 'NO_ASISTIO', NULL, 4, 10),
(8, 6, 7, 8, 9, '2026-11-19 10:00:00', '2026-11-19 10:40:00', 'NO_ASISTIO', NULL, 6, 10),
(7, 3, 1, 3, 2, '2026-11-26 09:00:00', '2026-11-26 09:20:00', 'PROGRAMADA', NULL, 4, 4),
(1, 1, 3, 4, 7, '2026-12-01 08:30:00', '2026-12-01 09:10:00', 'CONFIRMADA', NULL, 5, 5),
(4, 2, 4, 2, 8, '2026-12-01 09:00:00', '2026-12-01 09:30:00', 'PROGRAMADA', NULL, 4, 4),
(11, 3, 1, 3, 2, '2026-12-01 10:00:00', '2026-12-01 10:20:00', 'CONFIRMADA', NULL, 4, 4),
(12, 6, 7, 8, 9, '2026-12-03 09:00:00', '2026-12-03 09:40:00', 'PROGRAMADA', NULL, 6, 6);

INSERT INTO appointment_status_history (appointment_id, previous_status, new_status, changed_at, changed_by) VALUES
(1, NULL, 'PROGRAMADA', '2026-09-10 10:00:00', 4),
(1, 'PROGRAMADA', 'ATENDIDA', '2026-09-14 08:35:00', 4),
(2, NULL, 'PROGRAMADA', '2026-09-11 11:00:00', 5),
(2, 'PROGRAMADA', 'ATENDIDA', '2026-09-15 09:45:00', 5),
(7, NULL, 'PROGRAMADA', '2026-10-28 09:00:00', 4),
(7, 'PROGRAMADA', 'ATENDIDA', '2026-11-02 08:25:00', 4),
(15, NULL, 'PROGRAMADA', '2026-11-05 14:00:00', 4),
(15, 'PROGRAMADA', 'CANCELADA', '2026-11-09 16:20:00', 1),
(16, NULL, 'PROGRAMADA', '2026-11-12 10:00:00', 5),
(16, 'PROGRAMADA', 'CANCELADA', '2026-11-16 11:15:00', 1),
(17, 'PROGRAMADA', 'NO_ASISTIO', '2026-11-12 23:55:00', 10),
(18, 'PROGRAMADA', 'NO_ASISTIO', '2026-11-19 23:55:00', 10);

INSERT INTO appointment_reminders (appointment_id, channel, scheduled_for, status) VALUES
(1, 'WHATSAPP', '2026-09-13 08:00:00', 'ENVIADO'),
(2, 'SMS', '2026-09-14 09:00:00', 'ENVIADO'),
(3, 'CORREO', '2026-10-05 08:00:00', 'ENVIADO'),
(4, 'WHATSAPP', '2026-10-12 09:00:00', 'ENVIADO'),
(5, 'SMS', '2026-10-13 08:30:00', 'FALLIDO'),
(6, 'WHATSAPP', '2026-10-18 09:00:00', 'ENVIADO'),
(7, 'WHATSAPP', '2026-11-01 08:00:00', 'ENVIADO'),
(8, 'CORREO', '2026-11-02 10:00:00', 'ENVIADO'),
(9, 'SMS', '2026-11-02 08:30:00', 'ENVIADO'),
(10, 'WHATSAPP', '2026-11-03 14:30:00', 'FALLIDO');
-- Nota: Citas 21, 22 y 23 (1 de dic) quedan sin recordatorio para probar el Evento E-2

INSERT INTO satisfaction_surveys (appointment_id, rating, comments, submitted_at) VALUES
(1, 5, 'Excelente atención de la doctora Salazar.', '2026-09-14 10:00:00'),
(2, 5, 'Muy clara con las indicaciones.', '2026-09-15 11:00:00'),
(3, 4, 'Buena atención, algo de espera.', '2026-10-06 10:00:00'),
(4, 5, 'Muy amable con el niño.', '2026-10-13 11:00:00'),
(5, 4, 'Todo bien.', '2026-10-14 11:00:00'),
(6, 5, 'Excelente especialista.', '2026-10-19 12:00:00'),
(7, 4, 'Control rápido y efectivo.', '2026-11-02 10:00:00'),
(8, 5, 'Muy profesional.', '2026-11-03 12:00:00'),
(9, 3, 'Demora en recepción.', '2026-11-03 11:00:00'),
(10, 4, 'Buena consulta dermatológica.', '2026-11-04 17:00:00');

-- MÓDULO 5: ATENCIÓN CLÍNICA

INSERT INTO attentions (appointment_id, attention_date, clinical_notes) VALUES
(1, '2026-09-14 08:05:00', 'Control inicial de hipertensión arterial.'),
(2, '2026-09-15 09:05:00', 'Valoración cardiológica por palpitaciones.'),
(3, '2026-10-06 08:05:00', 'Cuadro gripal de 3 días de evolución.'),
(4, '2026-10-13 09:05:00', 'Control pediátrico y manejo de asma leve.'),
(5, '2026-10-14 08:35:00', 'Control ginecológico anual.'),
(6, '2026-10-19 09:05:00', 'Seguimiento de hipertensión y diabetes tipo 2.'),
(7, '2026-11-02 08:05:00', 'Control de presión arterial, persiste elevada.'),
(8, '2026-11-03 10:05:00', 'Electrocardiograma y ajuste de antihipertensivo.'),
(9, '2026-11-03 08:35:00', 'Dolor lumbar mecánico.'),
(10, '2026-11-04 14:35:00', 'Lesiones pruriginosas en antebrazos.'),
(11, '2026-11-05 09:05:00', 'Sesión de manejo de ansiedad laboral.'),
(12, '2026-11-06 08:05:00', 'Valoración de dorsalgia crónica.'),
(13, '2026-11-09 09:05:00', 'Control de tensión arterial y perfil lipídico.'),
(14, '2026-11-16 14:35:00', 'Control metabólico y gastritis.');

INSERT INTO vital_signs (attention_id, systolic_bp, diastolic_bp, heart_rate, temperature_c, weight_kg, height_cm) VALUES
(1, 145, 92, 78, 36.5, 82.00, 172.00),
(2, 130, 82, 84, 36.6, 68.50, 160.00),
(3, 118, 76, 72, 37.8, 75.00, 175.00),
(4, 102, 65, 92, 36.7, 38.00, 142.00),
(5, 115, 74, 70, 36.4, 62.00, 163.00),
(6, 150, 95, 80, 36.5, 88.00, 170.00), 
(7, 152, 94, 76, 36.6, 81.50, 172.00), 
(8, 142, 88, 74, 36.5, 87.50, 170.00), 
(9, 112, 70, 68, 36.5, 58.00, 165.00),
(10, 122, 78, 75, 36.6, 79.00, 178.00),
(11, 120, 80, 88, 36.5, 64.00, 161.00),
(12, 124, 80, 72, 36.6, 76.00, 174.00),
(13, 136, 84, 74, 36.5, 70.00, 158.00), 
(14, 126, 82, 76, 36.7, 84.00, 176.00);

INSERT INTO attention_diagnoses (attention_id, cie10_id, is_primary) VALUES
(1, 1, 1),            -- I10
(2, 1, 1), (2, 6, 0), -- I10 + F41
(3, 3, 1),            -- J06
(4, 8, 1),            -- J45
(5, 7, 1),            -- N39
(6, 1, 1), (6, 2, 0), -- I10 + E11
(7, 1, 1),            -- I10
(8, 1, 1),            -- I10
(9, 5, 1),            -- M54
(10, 10, 1),          -- L20
(11, 6, 1),           -- F41
(12, 5, 1),           -- M54
(13, 1, 1), (13, 9, 0), -- I10 + E66
(14, 4, 1);           -- K29

INSERT INTO attention_procedures (attention_id, cups_service_id, quantity) VALUES
(1, 2, 1),
(2, 2, 1), (2, 4, 1), -- Consulta esp + Electrocardiograma
(3, 1, 1),
(4, 2, 1),
(5, 2, 1),
(6, 2, 1), (6, 5, 1), -- Consulta esp + Glucometría
(7, 2, 1),
(8, 2, 1), (8, 4, 1),
(9, 1, 1), (9, 6, 1), -- Consulta gen + Curación
(10, 2, 1),
(11, 2, 1),
(12, 2, 1),
(13, 2, 1), (13, 5, 1),
(14, 2, 1);

INSERT INTO prescriptions (attention_id, issued_at) VALUES
(1, '2026-09-14 08:25:00'),
(2, '2026-09-15 09:30:00'),
(3, '2026-10-06 08:18:00'),
(4, '2026-10-13 09:25:00'),
(6, '2026-10-19 09:25:00'),
(7, '2026-11-02 08:18:00'),
(8, '2026-11-03 10:30:00'),
(10, '2026-11-04 14:55:00'),
(13, '2026-11-09 09:25:00'),
(14, '2026-11-16 14:55:00');

-- Fórmulas seguras (sin chocar con alergias registradas)
INSERT INTO prescription_items (prescription_id, medication_id, dosage, frequency, duration_days) VALUES
(1, 4, '50 mg', 'Cada 12 horas', 30),  -- Paciente 1: Losartán (alérgico a Penicilina)
(2, 3, '500 mg', 'Cada 8 horas', 5),   -- Paciente 2: Dolex (alérgico a Ibuprofeno)
(3, 3, '500 mg', 'Cada 8 horas', 5),   -- Paciente 3: Dolex
(4, 8, '2 inhalaciones', 'Cada 6 horas', 15),
(5, 4, '50 mg', 'Cada 12 horas', 30),
(5, 5, '850 mg', 'Cada 12 horas', 30),
(6, 4, '100 mg', 'Cada 24 horas', 30),
(6, 10, '20 mg', 'Cada 24 horas', 30),
(7, 4, '50 mg', 'Cada 12 horas', 30),
(8, 7, '10 mg', 'Cada 24 horas', 10),
(9, 4, '50 mg', 'Cada 24 horas', 30),
(10, 6, '20 mg', 'Antes del desayuno', 14);

INSERT INTO lab_orders (attention_id, ordered_at) VALUES
(1, '2026-09-14 08:25:00'),
(2, '2026-09-15 09:30:00'),
(5, '2026-10-14 08:55:00'),
(6, '2026-10-19 09:25:00'),
(7, '2026-11-02 08:18:00'),
(8, '2026-11-03 10:30:00'),
(10, '2026-11-04 14:55:00'),
(12, '2026-11-06 08:25:00'),
(13, '2026-11-09 09:25:00'),
(14, '2026-11-16 14:55:00');

INSERT INTO lab_order_items (lab_order_id, lab_test_id, result_value, result_date) VALUES
(1, 1, 95.00, '2026-09-16 10:00:00'),  -- Normal (70-100)
(1, 2, 235.00, '2026-09-16 10:00:00'), -- FUERA DE RANGO (> 200)
(2, 3, 180.00, '2026-09-17 11:00:00'), -- FUERA DE RANGO (> 150)
(3, 5, 13.50, '2026-10-16 09:00:00'),  -- Normal
(4, 1, 142.00, '2026-10-21 10:00:00'), -- FUERA DE RANGO (> 100)
(4, 6, 7.20, '2026-10-21 10:00:00'),   -- FUERA DE RANGO (> 5.60)
(5, 4, 1.45, '2026-11-04 10:00:00'),   -- FUERA DE RANGO (> 1.20)
(6, 2, 190.00, '2026-11-05 11:00:00'), -- Normal
(7, 5, 14.20, '2026-11-06 09:00:00'),  -- Normal
(8, 8, 6.10, '2026-11-08 10:00:00'),   -- Normal
(9, 10, 130.00, '2026-11-11 10:00:00'),-- FUERA DE RANGO (> 100)
(10, 1, 88.00, '2026-11-18 10:00:00'); -- Normal

-- MÓDULO 6: TARIFAS, FACTURACIÓN, ABONOS Y REPORTES

INSERT INTO service_tariffs (cups_service_id, plan_id, price, valid_from, valid_to) VALUES
-- Tarifas con dos vigencias (antigua y actual) para el mismo servicio y plan
(2, 1, 95000.00, '2026-01-01', '2026-09-30'),
(2, 1, 110000.00, '2026-10-01', NULL),
(2, 6, 130000.00, '2026-01-01', '2026-09-30'),
(2, 6, 150000.00, '2026-10-01', NULL),
-- Tarifas vigentes para otros planes
(1, 2, 55000.00, '2026-01-01', NULL),
(2, 2, 110000.00, '2026-01-01', NULL),
(2, 3, 85000.00, '2026-01-01', NULL),
(2, 4, 115000.00, '2026-01-01', NULL),
(2, 5, 80000.00, '2026-01-01', NULL),
(1, 7, 75000.00, '2026-01-01', NULL),
(2, 8, 140000.00, '2026-01-01', NULL),
(4, 6, 85000.00, '2026-01-01', NULL),
(5, 1, 25000.00, '2026-01-01', NULL),
(5, 6, 30000.00, '2026-01-01', NULL),
(6, 7, 45000.00, '2026-01-01', NULL),
-- 6 Servicios con tarifa vigente para plan PARTICULAR (id 10) -> Consulta 8
(1, 10, 90000.00, '2026-01-01', NULL),
(2, 10, 180000.00, '2026-01-01', NULL),
(4, 10, 120000.00, '2026-01-01', NULL),
(5, 10, 35000.00, '2026-01-01', NULL),
(6, 10, 65000.00, '2026-01-01', NULL),
(11, 10, 50000.00, '2026-01-01', NULL);

-- 12 Facturas (Atenciones 13 y 14 quedan pendientes de facturar para probar P-4)
INSERT INTO invoices (attention_id, patient_id, plan_id, issue_date, total_amount, patient_copay, insurer_amount, status, cancellation_date, cancellation_reason) VALUES
(1, 1, 1, '2026-09-14', 95000.00, 14250.00, 80750.00, 'PAGADA', NULL, NULL),
(2, 2, 6, '2026-09-15', 215000.00, 21500.00, 193500.00, 'PENDIENTE', NULL, NULL), -- > 30 días sin pagar (Evento E-4)
(3, 3, 2, '2026-10-06', 55000.00, 8250.00, 46750.00, 'PAGADA', NULL, NULL),
(4, 4, 2, '2026-10-13', 110000.00, 16500.00, 93500.00, 'PARCIAL', NULL, NULL),   -- > 30 días parcial (Evento E-4)
(5, 5, 3, '2026-10-14', 85000.00, 4250.00, 80750.00, 'ANULADA', '2026-10-15', 'Error en plan facturado'),
(6, 6, 6, '2026-10-19', 180000.00, 18000.00, 162000.00, 'PAGADA', NULL, NULL),
(7, 1, 1, '2026-11-02', 110000.00, 16500.00, 93500.00, 'PAGADA', NULL, NULL),
(8, 6, 6, '2026-11-03', 235000.00, 23500.00, 211500.00, 'PARCIAL', NULL, NULL),   -- Nov > 150.000
(9, 7, 7, '2026-11-03', 120000.00, 12000.00, 108000.00, 'PAGADA', NULL, NULL),
(10, 8, 4, '2026-11-04', 115000.00, 17250.00, 97750.00, 'PENDIENTE', NULL, NULL),
(11, 9, 5, '2026-11-05', 80000.00, 0.00, 80000.00, 'PAGADA', NULL, NULL),
(12, 10, 10, '2026-11-06', 180000.00, 180000.00, 0.00, 'PAGADA', NULL, NULL);     -- Nov > 150.000 (Particular)

INSERT INTO invoice_items (invoice_id, cups_service_id, quantity, unit_price, subtotal) VALUES
(1, 2, 1, 95000.00, 95000.00),
(2, 2, 1, 130000.00, 130000.00), (2, 4, 1, 85000.00, 85000.00),
(3, 1, 1, 55000.00, 55000.00),
(4, 2, 1, 110000.00, 110000.00),
(5, 2, 1, 85000.00, 85000.00),
(6, 2, 1, 150000.00, 150000.00), (6, 5, 1, 30000.00, 30000.00),
(7, 2, 1, 110000.00, 110000.00),
(8, 2, 1, 150000.00, 150000.00), (8, 4, 1, 85000.00, 85000.00),
(9, 1, 1, 75000.00, 75000.00), (9, 6, 1, 45000.00, 45000.00),
(10, 2, 1, 115000.00, 115000.00),
(11, 2, 1, 80000.00, 80000.00),
(12, 2, 1, 180000.00, 180000.00);

INSERT INTO payments (invoice_id, amount, payment_method, paid_at) VALUES
(1, 14250.00, 'EFECTIVO', '2026-09-14 08:40:00'),
(1, 80750.00, 'TRANSFERENCIA', '2026-09-30 15:00:00'),
(3, 55000.00, 'PSE', '2026-10-06 08:30:00'),
(4, 16500.00, 'TARJETA', '2026-10-13 09:40:00'), -- Parcial
(6, 180000.00, 'TRANSFERENCIA', '2026-10-25 14:00:00'),
(7, 16500.00, 'EFECTIVO', '2026-11-02 08:30:00'),
(7, 93500.00, 'TRANSFERENCIA', '2026-11-15 16:00:00'),
(8, 23500.00, 'TARJETA', '2026-11-03 10:50:00'), -- Parcial
(9, 120000.00, 'PSE', '2026-11-03 09:00:00'),
(11, 80000.00, 'TRANSFERENCIA', '2026-11-10 11:00:00'),
(12, 180000.00, 'PSE', '2026-11-06 08:40:00');

INSERT INTO monthly_production_summary (year_month_code, doctor_id, total_attentions, total_billed) VALUES
('2026-09', 1, 2, 310000.00),
('2026-09', 2, 0, 0.00),
('2026-09', 3, 0, 0.00),
('2026-09', 4, 0, 0.00),
('2026-09', 5, 0, 0.00),
('2026-10', 1, 1, 180000.00),
('2026-10', 2, 1, 110000.00),
('2026-10', 3, 1, 55000.00),
('2026-10', 4, 0, 0.00),
('2026-10', 5, 1, 0.00);


-- OPERACIONES DE MANTENIMIENTO: 

-- UPDATE 1: Actualizar dirección de un paciente
SELECT id, first_name, address FROM patients WHERE id = 3;
UPDATE patients SET address = 'Cra 16 # 14-22' WHERE id = 3;

-- UPDATE 2: Marcar un recordatorio fallido como enviado tras reintento
SELECT id, appointment_id, status FROM appointment_reminders WHERE id = 5;
UPDATE appointment_reminders SET status = 'ENVIADO' WHERE id = 5;

-- UPDATE 3: Ajustar comentario de encuesta de satisfacción
SELECT id, appointment_id, comments FROM satisfaction_surveys WHERE id = 5;
UPDATE satisfaction_surveys SET comments = 'Todo bien, excelente puntualidad.' WHERE id = 5;

-- DELETE 1 y 2: Insertar y eliminar dos registros de prueba (contacto de emergencia y teléfono secundario)
INSERT INTO emergency_contacts (patient_id, full_name, relationship, phone_number)
VALUES (10, 'Contacto Temporal', 'Amigo', '3000000000');
SELECT id, full_name FROM emergency_contacts WHERE full_name = 'Contacto Temporal';
DELETE FROM emergency_contacts WHERE full_name = 'Contacto Temporal';

INSERT INTO patient_phones (patient_id, phone_number, is_primary)
VALUES (10, '3001111111', NULL);
SELECT id, phone_number FROM patient_phones WHERE phone_number = '3001111111';
DELETE FROM patient_phones WHERE phone_number = '3001111111';

-- 4 ERRORES PROVOCADOS 

-- 1. Error UNIQUE (documento repetido dentro del mismo tipo)
-- Este error mandara este resultado: ERROR 1062 (23000): Duplicate entry '1-1098765432' for key 'patients.document_type_id'
-- INSERT INTO patients (document_type_id, document_number, first_name, last_name, birth_date, gender, address, city)
-- VALUES (1, '1098765432', 'Duplicado', 'Test', '1990-01-01', 'M', 'Calle 1', 'Bucaramanga'); 

-- 2. Error FK (sede inexistente al crear consultorio)
-- Este error mandara este resultado: ERROR 1452 (23000): Cannot add or update a child row: a foreign key constraint fails
-- INSERT INTO offices (branch_id, office_number, floor) VALUES (999, '999', 9);

-- 3. Error CHECK (signo vital imposible: temperatura de 5 grados)
-- Este error mandara este resultado: ERROR 3819 (HY000): Check constraint 'vital_signs_chk_4' is violated.
-- INSERT INTO vital_signs (attention_id, systolic_bp, diastolic_bp, heart_rate, temperature_c, weight_kg, height_cm)
-- VALUES (14, 120, 80, 70, 5.0, 70.00, 170.00);

-- 4. Error ENUM (estado de cita inexistente)
-- Este error mandara este resultado: ERROR 1265 (01000): Data truncated for column 'status' at row 1
-- UPDATE appointments SET status = 'REAGENDADA' WHERE id = 21;