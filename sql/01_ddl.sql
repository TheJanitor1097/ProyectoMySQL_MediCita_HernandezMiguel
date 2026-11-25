DROP DATABASE IF EXISTS medicita_ips;
CREATE DATABASE medicita_ips;
USE medicita_ips;

-- MÓDULO 1: INFRAESTRUCTURA Y CATÁLOGOS BASE

CREATE TABLE IF NOT EXISTS branches (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    municipality VARCHAR(100) NOT NULL,
    address VARCHAR(200) NOT NULL
);

CREATE TABLE IF NOT EXISTS offices (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    branch_id BIGINT NOT NULL,
    office_number VARCHAR(20) NOT NULL,
    floor INT NOT NULL DEFAULT 1,
    UNIQUE (branch_id, office_number),	
    FOREIGN KEY (branch_id) REFERENCES branches(id)
);

CREATE TABLE IF NOT EXISTS document_types (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(10) NOT NULL UNIQUE,
    name VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS specialties (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS appointment_types (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,  
    name VARCHAR(80) NOT NULL UNIQUE,
    duration_minutes INT NOT NULL CHECK (duration_minutes IN (20, 30, 40))
);

CREATE TABLE IF NOT EXISTS cancellation_reasons (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS cie10_codes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(10) NOT NULL UNIQUE,
    description VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS cups_services (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    cups_code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    category ENUM('CONSULTA', 'PROCEDIMIENTO', 'LABORATORIO') NOT NULL
);

CREATE TABLE IF NOT EXISTS active_ingredients (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(120) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS medications (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    active_ingredient_id BIGINT NOT NULL,
    commercial_name VARCHAR(150) NOT NULL,
    presentation VARCHAR(100) NOT NULL,
    UNIQUE (commercial_name, presentation),
    FOREIGN KEY (active_ingredient_id) REFERENCES active_ingredients(id)
);

CREATE TABLE IF NOT EXISTS lab_tests (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    cups_service_id BIGINT NOT NULL UNIQUE,
    name VARCHAR(120) NOT NULL,
    unit VARCHAR(30) NOT NULL,
    min_reference DECIMAL(10,2) NOT NULL,
    max_reference DECIMAL(10,2) NOT NULL,
    CHECK (max_reference >= min_reference),
    FOREIGN KEY (cups_service_id) REFERENCES cups_services(id)
);

-- MÓDULO 2: MÉDICOS, DISPONIBILIDAD Y USUARIOS DEL SISTEMA

CREATE TABLE IF NOT EXISTS system_users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(60) NOT NULL UNIQUE,
    full_name VARCHAR(120) NOT NULL,
    role_name VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS doctors (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    medical_license VARCHAR(40) NOT NULL UNIQUE,
    first_name VARCHAR(80) NOT NULL,
    last_name VARCHAR(80) NOT NULL,
    institutional_email VARCHAR(120) NOT NULL UNIQUE,
    status ENUM('ACTIVO', 'INACTIVO') NOT NULL DEFAULT 'ACTIVO'
);

CREATE TABLE IF NOT EXISTS doctor_specialties (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    doctor_id BIGINT NOT NULL,
    specialty_id BIGINT NOT NULL,
    UNIQUE (doctor_id, specialty_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(id),
    FOREIGN KEY (specialty_id) REFERENCES specialties(id)
);

CREATE TABLE IF NOT EXISTS doctor_branches (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    doctor_id BIGINT NOT NULL,
    branch_id BIGINT NOT NULL,
    UNIQUE (doctor_id, branch_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(id),
    FOREIGN KEY (branch_id) REFERENCES branches(id)
); 

CREATE TABLE IF NOT EXISTS doctor_schedules (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    doctor_id BIGINT NOT NULL,
    office_id BIGINT NOT NULL,
    day_of_week TINYINT NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    CHECK (end_time > start_time),
    FOREIGN KEY (doctor_id) REFERENCES doctors(id),
    FOREIGN KEY (office_id) REFERENCES offices(id)
);

CREATE TABLE IF NOT EXISTS doctor_leaves (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    doctor_id BIGINT NOT NULL,
    leave_type ENUM('VACACIONES', 'INCAPACIDAD', 'CAPACITACION') NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    CHECK (end_date >= start_date),
    FOREIGN KEY (doctor_id) REFERENCES doctors(id)
);

-- MÓDULO 3: PACIENTES Y ASEGURAMIENTO

CREATE TABLE IF NOT EXISTS patients (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    document_type_id BIGINT NOT NULL,
    document_number VARCHAR(30) NOT NULL,
    first_name VARCHAR(80) NOT NULL,
    last_name VARCHAR(80) NOT NULL,
    birth_date DATE NOT NULL,
    gender ENUM('M', 'F', 'OTRO') NOT NULL,
    address VARCHAR(200) NOT NULL,
    city VARCHAR(80) NOT NULL,
    email VARCHAR(120) NULL,
    UNIQUE (document_type_id, document_number),
    FOREIGN KEY (document_type_id) REFERENCES document_types(id)
);

	CREATE TABLE IF NOT EXISTS patient_phones (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    patient_id BIGINT NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    is_primary TINYINT(1) NULL CHECK (is_primary = 1),
    UNIQUE (patient_id, is_primary),
    UNIQUE (patient_id, phone_number),
    FOREIGN KEY (patient_id) REFERENCES patients(id)
);

CREATE TABLE IF NOT EXISTS emergency_contacts (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    patient_id BIGINT NOT NULL,
    full_name VARCHAR(120) NOT NULL,
    relationship VARCHAR(50) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    FOREIGN KEY (patient_id) REFERENCES patients(id)
);

CREATE TABLE IF NOT EXISTS patient_allergies (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    patient_id BIGINT NOT NULL,
    active_ingredient_id BIGINT NOT NULL,
    recorded_date DATE NOT NULL,
    UNIQUE (patient_id, active_ingredient_id),
    FOREIGN KEY (patient_id) REFERENCES patients(id),
    FOREIGN KEY (active_ingredient_id) REFERENCES active_ingredients(id)
);

CREATE TABLE IF NOT EXISTS insurers (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    nit VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(120) NOT NULL UNIQUE,
    insurer_type ENUM('EPS', 'PREPAGADA', 'PARTICULAR') NOT NULL
);

CREATE TABLE IF NOT EXISTS plans (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    insurer_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL,
    plan_type ENUM('CONTRIBUTIVO', 'SUBSIDIADO', 'PREPAGADA', 'PARTICULAR') NOT NULL,
    copay_percentage DECIMAL(5,2) NOT NULL CHECK (copay_percentage BETWEEN 0 AND 100),
    UNIQUE (insurer_id, name),
    FOREIGN KEY (insurer_id) REFERENCES insurers(id)
);

CREATE TABLE IF NOT EXISTS patient_affiliations (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    patient_id BIGINT NOT NULL,
    plan_id BIGINT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    status ENUM('ACTIVA', 'INACTIVA') NOT NULL DEFAULT 'ACTIVA',
    CHECK (end_date IS NULL OR end_date >= start_date),
    FOREIGN KEY (patient_id) REFERENCES patients(id),
    FOREIGN KEY (plan_id) REFERENCES plans(id)
);

-- MÓDULO 4: AGENDAMIENTO Y EXPERIENCIA DEL PACIENTE

CREATE TABLE IF NOT EXISTS appointments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    patient_id BIGINT NOT NULL,
    doctor_id BIGINT NOT NULL,
    specialty_id BIGINT NOT NULL,
    office_id BIGINT NOT NULL,
    appointment_type_id BIGINT NOT NULL,
    scheduled_start DATETIME NOT NULL,
    scheduled_end DATETIME NOT NULL,
    status ENUM('PROGRAMADA', 'CONFIRMADA', 'ATENDIDA', 'CANCELADA', 'NO_ASISTIO') NOT NULL DEFAULT 'PROGRAMADA',
    cancellation_reason_id BIGINT NULL,
    created_by BIGINT NOT NULL,
    updated_by BIGINT NOT NULL,
    CHECK (scheduled_end > scheduled_start),
    CHECK (status <> 'CANCELADA' OR cancellation_reason_id IS NOT NULL),
    FOREIGN KEY (patient_id) REFERENCES patients(id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(id),
    FOREIGN KEY (specialty_id) REFERENCES specialties(id),
    FOREIGN KEY (office_id) REFERENCES offices(id),
    FOREIGN KEY (appointment_type_id) REFERENCES appointment_types(id),
    FOREIGN KEY (cancellation_reason_id) REFERENCES cancellation_reasons(id),
    FOREIGN KEY (created_by) REFERENCES system_users(id),
    FOREIGN KEY (updated_by) REFERENCES system_users(id)
);

CREATE TABLE IF NOT EXISTS appointment_status_history (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    appointment_id BIGINT NOT NULL,
    previous_status ENUM('PROGRAMADA', 'CONFIRMADA', 'ATENDIDA', 'CANCELADA', 'NO_ASISTIO') NULL,
    new_status ENUM('PROGRAMADA', 'CONFIRMADA', 'ATENDIDA', 'CANCELADA', 'NO_ASISTIO') NOT NULL,
    changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_by BIGINT NOT NULL,
    FOREIGN KEY (appointment_id) REFERENCES appointments(id),
    FOREIGN KEY (changed_by) REFERENCES system_users(id)
);

CREATE TABLE IF NOT EXISTS appointment_reminders (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    appointment_id BIGINT NOT NULL,
    channel ENUM('SMS', 'CORREO', 'WHATSAPP') NOT NULL,
    scheduled_for DATETIME NOT NULL,
    status ENUM('PENDIENTE', 'ENVIADO', 'FALLIDO') NOT NULL DEFAULT 'PENDIENTE',
    FOREIGN KEY (appointment_id) REFERENCES appointments(id)
);

CREATE TABLE IF NOT EXISTS satisfaction_surveys (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    appointment_id BIGINT NOT NULL UNIQUE,
    rating TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comments VARCHAR(500) NULL,
    submitted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (appointment_id) REFERENCES appointments(id)
);

-- MÓDULO 5: ATENCIÓN CLÍNICA

CREATE TABLE IF NOT EXISTS attentions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    appointment_id BIGINT NOT NULL UNIQUE,
    attention_date DATETIME NOT NULL,
    clinical_notes TEXT NOT NULL,
    FOREIGN KEY (appointment_id) REFERENCES appointments(id)
);

CREATE TABLE IF NOT EXISTS vital_signs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    attention_id BIGINT NOT NULL UNIQUE,
    systolic_bp INT NOT NULL CHECK (systolic_bp BETWEEN 60 AND 260),
    diastolic_bp INT NOT NULL CHECK (diastolic_bp BETWEEN 30 AND 160),
    heart_rate INT NOT NULL CHECK (heart_rate BETWEEN 20 AND 250),
    temperature_c DECIMAL(4,1) NOT NULL CHECK (temperature_c BETWEEN 30.0 AND 45.0),
    weight_kg DECIMAL(5,2) NOT NULL CHECK (weight_kg > 0),
    height_cm DECIMAL(5,2) NOT NULL CHECK (height_cm > 0),
    CHECK (diastolic_bp < systolic_bp),
    FOREIGN KEY (attention_id) REFERENCES attentions(id)
);

CREATE TABLE IF NOT EXISTS attention_diagnoses (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    attention_id BIGINT NOT NULL,
    cie10_id BIGINT NOT NULL,
    is_primary TINYINT(1) NOT NULL DEFAULT 0,
    UNIQUE (attention_id, cie10_id),
    FOREIGN KEY (attention_id) REFERENCES attentions(id),
    FOREIGN KEY (cie10_id) REFERENCES cie10_codes(id)
);

CREATE TABLE IF NOT EXISTS attention_procedures (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    attention_id BIGINT NOT NULL,
    cups_service_id BIGINT NOT NULL,
    quantity INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
    FOREIGN KEY (attention_id) REFERENCES attentions(id),
    FOREIGN KEY (cups_service_id) REFERENCES cups_services(id)
);

CREATE TABLE IF NOT EXISTS prescriptions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    attention_id BIGINT NOT NULL UNIQUE,
    issued_at DATETIME NOT NULL,
    FOREIGN KEY (attention_id) REFERENCES attentions(id)
);

CREATE TABLE IF NOT EXISTS prescription_items (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    prescription_id BIGINT NOT NULL,
    medication_id BIGINT NOT NULL,
    dosage VARCHAR(80) NOT NULL,
    frequency VARCHAR(80) NOT NULL,
    duration_days INT NOT NULL CHECK (duration_days > 0),
    UNIQUE (prescription_id, medication_id),
    FOREIGN KEY (prescription_id) REFERENCES prescriptions(id),
    FOREIGN KEY (medication_id) REFERENCES medications(id)
);

CREATE TABLE IF NOT EXISTS lab_orders (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    attention_id BIGINT NOT NULL UNIQUE,
    ordered_at DATETIME NOT NULL,
    FOREIGN KEY (attention_id) REFERENCES attentions(id)
);

CREATE TABLE IF NOT EXISTS lab_order_items (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    lab_order_id BIGINT NOT NULL,
    lab_test_id BIGINT NOT NULL,
    result_value DECIMAL(10,2) NULL,
    result_date DATETIME NULL,
    UNIQUE (lab_order_id, lab_test_id),
    FOREIGN KEY (lab_order_id) REFERENCES lab_orders(id),
    FOREIGN KEY (lab_test_id) REFERENCES lab_tests(id)
);

-- MÓDULO 6: TARIFAS, FACTURACIÓN, ABONOS Y REPORTES

CREATE TABLE IF NOT EXISTS service_tariffs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    cups_service_id BIGINT NOT NULL,
    plan_id BIGINT NOT NULL,
    price DECIMAL(12,2) NOT NULL CHECK (price >= 0),
    valid_from DATE NOT NULL,
    valid_to DATE NULL,
    CHECK (valid_to IS NULL OR valid_to > valid_from),
    FOREIGN KEY (cups_service_id) REFERENCES cups_services(id),
    FOREIGN KEY (plan_id) REFERENCES plans(id)
);

CREATE TABLE IF NOT EXISTS invoices (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    attention_id BIGINT NOT NULL UNIQUE,
    patient_id BIGINT NOT NULL,
    plan_id BIGINT NOT NULL,
    issue_date DATE NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL CHECK (total_amount >= 0),
    patient_copay DECIMAL(12,2) NOT NULL CHECK (patient_copay >= 0),
    insurer_amount DECIMAL(12,2) NOT NULL CHECK (insurer_amount >= 0),
    status ENUM('PENDIENTE', 'PARCIAL', 'PAGADA', 'VENCIDA', 'ANULADA') NOT NULL DEFAULT 'PENDIENTE',
    cancellation_date DATE NULL,
    cancellation_reason VARCHAR(255) NULL,
    FOREIGN KEY (attention_id) REFERENCES attentions(id),
    FOREIGN KEY (patient_id) REFERENCES patients(id),
    FOREIGN KEY (plan_id) REFERENCES plans(id)
);

CREATE TABLE IF NOT EXISTS invoice_items (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    invoice_id BIGINT NOT NULL,
    cups_service_id BIGINT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(12,2) NOT NULL CHECK (unit_price >= 0),
    subtotal DECIMAL(12,2) NOT NULL CHECK (subtotal >= 0),
    FOREIGN KEY (invoice_id) REFERENCES invoices(id),
    FOREIGN KEY (cups_service_id) REFERENCES cups_services(id)
);

CREATE TABLE IF NOT EXISTS payments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    invoice_id BIGINT NOT NULL,
    amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    payment_method ENUM('EFECTIVO', 'TARJETA', 'TRANSFERENCIA', 'PSE') NOT NULL,
    paid_at DATETIME NOT NULL,
    FOREIGN KEY (invoice_id) REFERENCES invoices(id)
);

CREATE TABLE IF NOT EXISTS monthly_production_summary (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    year_month_code VARCHAR(7) NOT NULL,
    doctor_id BIGINT NOT NULL,
    total_attentions INT NOT NULL DEFAULT 0,
    total_billed DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    generated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (year_month_code, doctor_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(id)
);

