# MediCita IPS — Sistema de Base de Datos en MySQL 8

## 1. Descripción del proyecto

**MediCita IPS** es una institución prestadora de servicios de salud con cuatro sedes en el área metropolitana de Bucaramanga (**Cabecera** en Bucaramanga, **Cañaveral** en Floridablanca, **Girón Centro** en Girón y **Piedecuesta** en Piedecuesta). Presta servicios de consulta externa de medicina general y especialidades, procedimientos menores, toma de muestras de laboratorio y facturación a pacientes particulares y aseguradoras (EPS y medicina prepagada).

Este proyecto reemplaza la operación manual basada en hojas de cálculo y documentos de Word por una base de datos relacional normalizada (`medicita_ips`, compuesta por **41 tablas** organizadas en 6 módulos), diseñada para resolver de raíz tres problemas críticos detectados en la operación:

1. **Cruce de citas:** evitar que dos pacientes sean agendados al mismo tiempo con el mismo médico o en el mismo consultorio.

2. **Seguridad clínica:** impedir la formulación de medicamentos cuyo principio activo cause alergia al paciente y rechazar signos vitales fisiológicamente imposibles.

3. **Integridad financiera:** garantizar la trazabilidad de tarifas históricas por plan, copagos, cartera por aseguradora y la prohibición de borrado físico de facturas (exigencia DIAN y auditoría).

> **Fecha de corte histórica de referencia:** `2026-11-30`. Los datos de prueba simulan la operación de la IPS entre septiembre y diciembre de 2026.

## 2. Cómo ejecutarlo (orden de los scripts)

### Requisitos previos

* **MySQL 8.0+** (local o contenedor).

* Cliente SQL como **DBeaver** o **MySQL Workbench**.

* Conexión con usuario administrador (`root`) para la creación de la base, rutinas, eventos y roles.

### Estructura del repositorio

```
ProyectoMySQL_MediCita_ApellidoNombre/
├── README.md
├── capturas/                    # Evidencias de ejecución (sección 9)
├── diagramas/
│   ├── 00_diagrama_er.jpg       # Diagrama Entidad-Relación hecho a mano
│   └── 00_diagrama_logico.png   # Diagrama lógico por ingeniería inversa
└── sql/
    ├── 01_ddl.sql               # Estructura de 41 tablas, PK, FK, CHECK, UNIQUE
    ├── 02_dml.sql               # Poblado estratégico, UPDATE, DELETE y 4 errores comentados
    ├── 03_dql.sql               # 30 consultas (1 tabla, JOIN, agregación y subconsultas)
    ├── 04_funciones.sql         # 5 funciones (UDF) y sus pruebas
    ├── 05_procedimientos.sql    # 5 procedimientos almacenados (con transacciones y cursor)
    ├── 06_triggers.sql          # 5 triggers de validación, auditoría y reglas clínicas
    ├── 07_eventos.sql           # 5 eventos programados con pruebas al corte y apagado
    └── 08_dcl.sql               # sp_anular_factura, 5 roles, usuarios, pruebas y limpieza

```

### Orden estricto de ejecución

Ejecuta cada archivo completo como script (`Alt + X` en DBeaver o el ícono de rayo en Workbench) en este orden exacto:

1. `sql/01_ddl.sql` — Elimina (si existe) y crea la base `medicita_ips` con sus 41 tablas.

2. `sql/02_dml.sql` — Inserta los datos semilla estratégicos y ejecuta los `UPDATE`/`DELETE` de mantenimiento.

3. `sql/03_dql.sql` — Ejecuta las 30 consultas de negocio.

4. `sql/04_funciones.sql` — Crea y prueba las 5 funciones (`F-1` a `F-5`).

5. `sql/05_procedimientos.sql` — Crea y prueba los 5 procedimientos (`P-1` a `P-5`).

6. `sql/06_triggers.sql` — Crea y prueba los 5 triggers (`T-1` a `T-5`).

7. `sql/07_eventos.sql` — Enciende el `event_scheduler`, ejecuta los 5 eventos (`E-1` a `E-5`), espera 4 segundos, verifica resultados y los desactiva.

8. `sql/08_dcl.sql` — Crea `sp_anular_factura`, los 5 roles, los 5 usuarios de prueba, muestra los `SHOW GRANTS` y ejecuta la limpieza final.

> **Nota sobre pruebas de error:** Todas las sentencias diseñadas para fallar van comentadas con `-- ⚠️ ESPERADO: ERROR <código> ...` para garantizar que los scripts sean 100 % reproducibles de principio a fin. Para verificar cada rechazo, selecciona únicamente la sentencia sin el `--` y ejecútala individualmente.

## 3. Tabla de reglas corroboradas

Auditoría del análisis preliminar contra las entrevistas a la **Dra. Marcela Ortiz** (Directora médica, E1), **Hernán Rueda** (Coordinador de agendamiento, E2) y **Liliana Prada** (Jefa de facturación y cartera, E3):

| Regla | ¿Se confirma? | Evidencia (quién lo dijo) | Corrección / Detalle | 
| ----- | ----- | ----- | ----- | 
| **RP-01**: Paciente identificado por tipo y número de documento; no se repite dentro del mismo tipo. | **Sí** | Hernán Rueda (E2) | Se implementa con `UNIQUE (document_type_id, document_number)` en `patients`. | 
| **RP-02**: Cada paciente tiene un único número de teléfono. | **No** | Hernán Rueda (E2) | Un paciente puede tener **varios teléfonos**, y exactamente **uno** marcado como principal (`patient_phones`). | 
| **RP-03**: Cada médico pertenece a una sola especialidad. | **No** | Dra. Marcela Ortiz (E1) | Un médico puede tener **varias especialidades** (ej. Dra. Salazar: Medicina Interna y Cardiología). Relación N:M (`doctor_specialties`). | 
| **RP-04**: Un médico puede atender en varias sedes. | **Sí** | Dra. Marcela Ortiz (E1) | Un médico rota por varias sedes, de forma independiente a su especialidad (`doctor_branches`). | 
| **RP-05**: La duración de una cita depende del tipo de cita. | **Sí** | Hernán Rueda (E2) | `appointment_types.duration_minutes` define 20, 30 o 40 minutos. | 
| **RP-06**: Un médico no puede tener dos citas que se crucen en el tiempo. | **Sí** | Hernán Rueda (E2) | Aplica tanto para el **médico** como para el **consultorio**. | 
| **RP-07**: No se puede agendar fuera del horario del médico ni durante sus novedades. | **Sí** | Dra. Marcela Ortiz (E1) | Validado contra `doctor_schedules` y `doctor_leaves` (vacaciones, incapacidades, capacitaciones). | 
| **RP-08**: Una cita se puede cancelar sin indicar el motivo. | **No** | Hernán Rueda (E2) | **Toda cancelación exige un motivo** del catálogo `cancellation_reasons`. | 
| **RP-09**: Cada cambio de estado de una cita queda en un historial. | **Sí** | Hernán Rueda (E2) | Se registra estado anterior, nuevo, fecha/hora y responsable en `appointment_status_history`. | 
| **RP-10**: Un paciente puede tener varias afiliaciones vigentes al mismo tiempo. | **No** | Hernán Rueda (E2) | Se guarda el historial, pero **solo puede haber una afiliación vigente**; si no tiene ninguna, se atiende como `PARTICULAR`. | 
| **RP-11**: Una atención registra uno o varios diagnósticos, y uno de ellos es el principal. | **Sí** | Dra. Marcela Ortiz (E1) | Relación N:M en `attention_diagnoses` con códigos CIE-10 y bandera `is_primary`. | 
| **RP-12**: No se formula un medicamento cuyo principio activo cause alergia al paciente. | **Sí** | Dra. Marcela Ortiz (E1) | Las alergias se registran contra `active_ingredients` (principio activo), no contra la marca comercial. | 
| **RP-13**: El precio de un servicio es el mismo para todos los pacientes. | **No** | Liliana Prada (E3) | El precio depende del **plan** (`plans`) y tiene fechas de vigencia (`service_tariffs`: `valid_from`, `valid_to`). | 
| **RP-14**: Si hay un error en una factura, se borra y se vuelve a hacer. | **No** | Liliana Prada (E3) | **Las facturas nunca se borran** (DIAN y auditoría); se anulan pasando a estado `ANULADA` con fecha y motivo. | 
| **RP-15**: Una factura queda `PAGADA` cuando sus abonos completan el total. | **Sí** | Liliana Prada (E3) | Estados: `PENDIENTE`, `PARCIAL`, `PAGADA`, `VENCIDA` (> 30 días sin saldar) y `ANULADA`. | 

### Reglas adicionales identificadas en las entrevistas

* **RP-16 (Signos vitales):** Rechazar valores fisiológicamente imposibles (sistólica 60–260, diastólica 30–160 y menor que la sistólica, temperatura 30–45 °C, frecuencia cardíaca 20–250). *(Dra. Ortiz, E1)*

* **RP-17 (Laboratorio y alertas):** Cada examen tiene unidad y rango de referencia (mínimo y máximo) para identificar resultados fuera de rango. *(Dra. Ortiz, E1)*

* **RP-18 (Contactos de emergencia):** Cada paciente puede tener uno o más contactos de emergencia (`emergency_contacts`). *(Hernán Rueda, E2)*

* **RP-19 (Recordatorios y encuestas):** Envío de recordatorio el día anterior (`SMS`, `CORREO`, `WHATSAPP`); encuesta de satisfacción de 1 a 5 solo para citas `ATENDIDA` y una sola vez por cita. *(Hernán Rueda, E2)*

* **RP-20 (Inmutabilidad histórica de factura):** Cada renglón en `invoice_items` copia el `unit_price` vigente del día de la atención para que cambios futuros en `service_tariffs` no alteren facturas ya emitidas. *(Liliana Prada, E3)*

## 4. Justificación de la normalización (1FN–4FN)

1. **Primera Forma Normal (1FN — Atomicidad):**

   * *Problema detectado:* En la entrevista 2 se indica que los pacientes tienen varios teléfonos y varios contactos de emergencia. Guardar múltiples números separados por comas en una columna `phones` dentro de `patients` violaría la 1FN.

   * *Solución:* Se extrajeron los atributos multivaluados a tablas independientes (`patient_phones` y `emergency_contacts`), garantizando valores atómicos por celda. Para permitir varios teléfonos secundarios y **un solo teléfono principal** por estructura, `is_primary` acepta `1` (principal) o `NULL` (secundario) bajo un `UNIQUE (patient_id, is_primary)`.

2. **Segunda Forma Normal (2FN — Dependencia funcional completa):**

   * *Problema detectado:* En el detalle de facturación (`invoice_items`), si se almacenara el nombre del servicio CUPS junto a `(invoice_id, cups_service_id)`, el nombre del servicio dependería solo de `cups_service_id` (dependencia parcial) y no de la factura.

   * *Solución:* Los datos propios del servicio residen únicamente en `cups_services`, mientras que `invoice_items` conserva solo la referencia `cups_service_id`, la `quantity` y la copia histórica del `unit_price` y `subtotal` propios de esa factura.

3. **Tercera Forma Normal (3FN — Eliminación de dependencias transitivas):**

   * *Problema detectado:* Si `patient_affiliations` guardara `plan_id`, `insurer_id` e `insurer_name`, existiría una dependencia transitiva (`affiliation_id -> plan_id -> insurer_id -> insurer_name`), generando anomalías de actualización si una aseguradora cambia de nombre o NIT.

   * *Solución:* Se descompuso la jerarquía en `patient_affiliations` → `plans` → `insurers`, eliminando redundancias transitivas.

4. **Cuarta Forma Normal (4FN — Dependencias multivaluadas independientes):**

   * *Problema detectado:* Un médico puede tener varias especialidades y rotar por varias sedes, pero ambos hechos son independientes entre sí (ej. el Dr. Pabón es pediatra y dermatólogo y atiende ambas especialidades en Cabecera y Girón). Almacenarlos en una sola tabla `(doctor_id, specialty_id, branch_id)` violaría la 4FN porque obligaría a registrar el producto cartesiano de especialidades × sedes, generando redundancia y anomalías al agregar una nueva sede o especialidad.

   * *Solución:* Se descompuso en dos tablas independientes: `doctor_specialties (doctor_id, specialty_id)` y `doctor_branches (doctor_id, branch_id)`.

## 5. Los dos diagramas

### 5.1 Diagrama Entidad-Relación (hecho a mano)

### 5.2 Diagrama lógico (ingeniería inversa)

> **Coherencia entre diagramas y DDL:** Ambos modelos representan exactamente las **41 tablas** distribuidas en 6 módulos (Infraestructura/Catálogos, Médicos/Usuarios, Pacientes/Aseguramiento, Agendamiento, Atención Clínica y Facturación/Reportes), con todas las relaciones N:M resueltas y las llaves foráneas declaradas explícitamente en `01_ddl.sql`.

## 6. Reglas que no protege la estructura y dónde se resolvieron

Las restricciones de tabla (`CHECK`, `UNIQUE`, `FOREIGN KEY`) solo validan una fila aislada o unicidad simple. Las reglas que requieren comparar múltiples filas, rangos temporales o cruzar varias tablas se resolvieron en la capa de programación de la base de datos:

| Regla de negocio | ¿Por qué no basta el DDL? | Objeto donde se resolvió | 
| ----- | ----- | ----- | 
| Disponibilidad del médico (dentro de horario, sin novedades y sin cruce de citas). | Requiere consultar intervalos en `doctor_schedules`, `doctor_leaves` y `appointments`. | `fn_medico_disponible` (`04_funciones.sql`) y `sp_agendar_cita` (`05_procedimientos.sql`). | 
| Validar que el médico tenga la especialidad, atienda en la sede del consultorio y el consultorio esté libre. | Cruza `doctor_specialties`, `doctor_branches`, `offices` y traslapes en `appointments`. | `sp_agendar_cita` (`05_procedimientos.sql`). | 
| Solo cancelar citas `PROGRAMADA` o `CONFIRMADA` con motivo válido del catálogo. | Evalúa el estado actual previo al cambio y la existencia del motivo. | `sp_cancelar_cita` (`05_procedimientos.sql`). | 
| Facturación atómica con tarifa vigente del día de la atención y cálculo de copago (o 100 % particular). | Consulta vigencia de afiliación y tarifas históricas, inserta múltiples filas en transacción. | `fn_tarifa_vigente` (`04_funciones.sql`) y `sp_facturar_atencion` (`05_procedimientos.sql`). | 
| Prohibir el borrado físico de facturas. | El DDL permite `DELETE` si no hay filas hijas que lo impidan. | `trg_invoices_before_delete` (`T-2`, `06_triggers.sql`). | 
| Registrar automáticamente el historial ante cada cambio de estado de cita. | Requiere comparar `OLD.status` vs `NEW.status` e insertar en otra tabla. | `trg_appointments_after_update` (`T-3`, `06_triggers.sql`). | 
| Actualizar estado de factura a `PARCIAL` o `PAGADA` al registrar un abono. | Requiere sumar todos los abonos de `payments` y actualizar `invoices`. | `trg_payments_after_insert` (`T-4`, `06_triggers.sql`). | 
| Impedir formular un medicamento cuyo principio activo cause alergia al paciente. | Cruza `prescription_items` → `medications` → `patient_allergies` del paciente dueño de la fórmula. | `trg_prescription_items_before_insert` (`T-5`, `06_triggers.sql`). | 
| Marcar inasistencias, generar recordatorios, inactivar afiliaciones vencidas, vencer facturas > 30 días y generar resumen mensual. | Dependen del paso del tiempo y procesamiento por lotes sobre múltiples filas. | Eventos `E-1` a `E-5` (`07_eventos.sql`). | 
| Anular factura solo si existe, no está anulada, tiene motivo y no tiene abonos. | Requiere validar estado previo y conteo en `payments`. | `sp_anular_factura` (`08_dcl.sql`). | 

## 7. Características de cada función

En MySQL 8 (con *binary logging* activo), cada función debe declarar explícitamente su determinismo y acceso a datos para evitar el **Error 1418**:

| Función | Características declaradas | Justificación técnica | 
| ----- | ----- | ----- | 
| **`fn_edad`** | `DETERMINISTIC`, `NO SQL` | Solo calcula la diferencia en años entre dos fechas recibidas por parámetro. No lee tablas y para las mismas fechas siempre retorna el mismo entero. | 
| **`fn_imc`** | `DETERMINISTIC`, `NO SQL` | Realiza un cálculo aritmético puro ($peso / talla^2$). No accede a la base de datos y su salida depende únicamente de sus argumentos. | 
| **`fn_tarifa_vigente`** | `NOT DETERMINISTIC`, `READS SQL DATA` | Consulta la tabla `service_tariffs`. Aunque se llame con los mismos parámetros, si se registra o actualiza una tarifa en la tabla, el resultado puede cambiar. | 
| **`fn_saldo_factura`** | `NOT DETERMINISTIC`, `READS SQL DATA` | Lee `invoices` y suma los registros de `payments`. El saldo varía cada vez que entra un nuevo abono o se anula la factura. | 
| **`fn_medico_disponible`** | `NOT DETERMINISTIC`, `READS SQL DATA` | Consulta `doctor_schedules`, `doctor_leaves` y `appointments`. La disponibilidad de un mismo horario cambia si se agenda o cancela una cita o se registra una novedad. | 

## 8. Roles y permisos (DCL)

Se aplicó el **principio de mínimo privilegio** mediante roles de MySQL 8 activados por defecto (`SET DEFAULT ROLE`), encapsulando las operaciones sensibles mediante procedimientos almacenados (`SQL SECURITY DEFINER`) para evitar modificaciones directas sobre tablas críticas:

| Rol / Usuario de prueba | Permisos concedidos (`GRANT`) | Restricciones clave (qué NO puede hacer) | 
| ----- | ----- | ----- | 
| **`rol_recepcion`** (`usr_recepcion`) | `SELECT` en pacientes, teléfonos, contactos, afiliaciones, médicos, agenda y catálogos. `EXECUTE` en `sp_registrar_paciente`, `sp_agendar_cita` y `sp_cancelar_cita`. | No puede ver ni modificar datos clínicos ni facturación (`ERROR 1142`). No tiene `UPDATE`/`INSERT` directo sobre `appointments`. | 
| **`rol_medico`** (`usr_medico`) | `SELECT` en pacientes, alergias, agenda y catálogos clínicos. `SELECT, INSERT, UPDATE` en atenciones, signos vitales, diagnósticos, procedimientos, fórmulas y laboratorio. | No puede ver ni tocar facturación (`ERROR 1142`). No tiene `DELETE` sobre ningún registro clínico. | 
| **`rol_facturacion`** (`usr_facturacion`) | `SELECT` en atenciones, procedimientos, tarifas, aseguradoras, planes, facturas e ítems. `SELECT, INSERT` en `payments`. `EXECUTE` en `sp_facturar_atencion` y `sp_anular_factura`. | No puede ver diagnósticos, fórmulas ni laboratorio (`ERROR 1142`). No tiene `UPDATE` ni `DELETE` sobre `invoices` (los estados los controlan `T-4`, `E-4` y `sp_anular_factura`). | 
| **`rol_auditor`** (`usr_auditor`) | `SELECT` en tablas operativas, clínicas y financieras. En `patients`, permiso **por columnas** únicamente sobre `(id, first_name, last_name, birth_date, gender, city)`. | No puede leer `document_number`, `address` ni `email` (`ERROR 1143`), ni consultar `patient_phones`/`emergency_contacts`. No puede modificar datos ni ejecutar rutinas (`ERROR 1370`). | 
| **`rol_admin_bd`** (`usr_admin_bd`) | `ALL PRIVILEGES ON medicita_ips.*`. | No tiene acceso a ningún otro esquema del servidor como `mysql` (`ERROR 1044`). | 

## 9. Capturas de funcionamiento

> *(Reemplaza las rutas siguientes por las capturas reales guardadas en tu carpeta `capturas/` antes de hacer el commit final).*

### 9.1 Tres consultas DQL

* **Consulta 11 (Combinaciones 4FN médico–especialidad–sede):**
  

* **Consulta 19 (Cartera por aseguradora sin duplicar montos):**
  

* **Consulta 30 (Top 3 diagnósticos por sede con función de ventana):**
  

### 9.2 Un procedimiento almacenado

* **Procedimiento `sp_facturar_atencion` (P-4) o `sp_reporte_produccion` (P-5):**
  

### 9.3 Un trigger

* **Trigger `trg_prescription_items_before_insert` (T-5 — bloqueo por alergia con `ERROR 1644`) o `trg_payments_after_insert` (T-4):**
  

### 9.4 Un evento programado

* **Eventos `E-1` a `E-5` verificados en `information_schema.EVENTS` (`se_ejecuto = 1`, `DISABLED`):**
  

## 10. Conclusiones

1. **Auditoría antes del código:** Validar las 15 reglas preliminares contra las entrevistas evitó errores graves de arquitectura desde el día 1 (como modelar un solo teléfono por paciente, una sola especialidad por médico o permitir el borrado físico de facturas).

2. **Defensa en profundidad:** Combinar integridad estructural en el DDL (`UNIQUE`, `CHECK`, `FOREIGN KEY`), lógica transaccional en procedimientos (`EXIT HANDLER` + `ROLLBACK`/`RESIGNAL`), automatización reactiva y temporal (triggers y eventos) y privilegio mínimo en el DCL garantiza que las reglas del negocio se cumplan sin depender de la aplicación externa.

3. **Resolución de los incidentes de MediCita IPS:** El diseño elimina los cruces de agenda (`fn_medico_disponible` y `sp_agendar_cita`), protege la vida del paciente frente a alergias medicamentosas (`T-5`) y asegura la trazabilidad contable con precios históricos inmutables, cálculo exacto de cartera y control estricto de estados de factura (`P-4`, `T-2`, `T-4`, `E-4` y `sp_anular_factura`).