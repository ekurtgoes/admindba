# AUDITORÍA Y CUMPLIMIENTO — BASES DE DATOS

> **Documento de Auditoría y Compliance**  
> **Última actualización:** 2026-06-29

---

## ÍNDICE

1. [Marco de Auditoría](#1-marco-de-auditoría)
2. [Logs y Trazabilidad](#2-logs-y-trazabilidad)
3. [Recertificación de Accesos](#3-recertificación-de-accesos)
4. [Auditorías Programadas](#4-auditorías-programadas)
5. [Compliance y Regulaciones](#5-compliance-y-regulaciones)
6. [Gestión de Incidentes de Seguridad](#6-gestión-de-incidentes-de-seguridad)
7. [Reportes de Compliance](#7-reportes-de-compliance)
8. [Retención de Evidencias](#8-retención-de-evidencias)

---

## 1. MARCO DE AUDITORÍA

### 1.1 Objetivos de Auditoría

1. **Verificar cumplimiento** de políticas de acceso a bases de datos
2. **Detectar accesos no autorizados** o actividades sospechosas
3. **Validar segregación de funciones** (SoD) entre ambientes
4. **Asegurar trazabilidad** completa de operaciones críticas
5. **Garantizar protección** de datos sensibles (PII, PHI)
6. **Demostrar compliance** con regulaciones aplicables (GDPR, HIPAA, SOC 2)

### 1.2 Principios de Auditoría

#### Completitud
- **Todos los accesos** deben estar registrados (sin excepción)
- **Todas las operaciones** en Producción deben ser auditables
- **Todos los cambios** de privilegios deben quedar documentados

#### Integridad
- Logs de auditoría **no pueden ser modificados** por usuarios regulares
- Almacenamiento **inmutable** con retención definida
- **Segregación** entre quien genera logs y quien los audita

#### Confidencialidad
- Logs pueden contener datos sensibles → **cifrado obligatorio**
- Acceso a logs de auditoría **restringido** a Security y DBA Lead
- Exportación de logs para análisis requiere **aprobación**

### 1.3 Alcance de Auditoría

| Categoría | Qué se Audita | Frecuencia |
|-----------|---------------|------------|
| **Accesos** | Creación, modificación, revocación de usuarios | Continua |
| **Autenticación** | Intentos de login (exitosos y fallidos) | Continua |
| **Privilegios** | Cambios en roles y permisos (GRANT/REVOKE) | Continua |
| **Operaciones DDL** | CREATE, ALTER, DROP de objetos | Continua (PRD), Muestreo (DEV/QA) |
| **Operaciones DML críticas** | DELETE masivo, UPDATE sin WHERE | Continua (PRD) |
| **Configuración** | Cambios en parámetros de instancia | Continua |
| **Exportación de datos** | Queries que retornan > 10k filas | Continua (PRD) |
| **Actividad administrativa** | Backups, restores, failovers | Continua |

---

## 2. LOGS Y TRAZABILIDAD

### 2.1 Tipos de Logs

#### 2.1.1 Cloud Audit Logs (GCP)

**Admin Activity Logs**
- Cambios de configuración de instancias CloudSQL
- Creación/eliminación de instancias
- Modificación de reglas de firewall
- Gestión de backups automáticos

```bash
# Consultar Admin Activity Logs
gcloud logging read "resource.type=cloudsql_database AND \
  logName=projects/PROJECT_ID/logs/cloudaudit.googleapis.com%2Factivity" \
  --limit 50 --format json
```

**Data Access Logs**
- Conexiones a bases de datos
- Queries ejecutadas (si está habilitado)
- Acceso a datos sensibles

```bash
# Habilitar Data Access Logs en Producción
gcloud logging sinks create cloudsql-data-access \
  storage.googleapis.com/BUCKET_LOGS \
  --log-filter='resource.type="cloudsql_database" AND protoPayload.serviceName="cloudsql.googleapis.com"'
```

#### 2.1.2 Query Logs (PostgreSQL)

**Configuración recomendada para Producción:**
```sql
-- Habilitar logging de queries en PostgreSQL
ALTER SYSTEM SET log_statement = 'ddl';  -- Solo DDL (CREATE, ALTER, DROP)
ALTER SYSTEM SET log_duration = ON;       -- Duración de queries
ALTER SYSTEM SET log_min_duration_statement = 5000;  -- Queries > 5 segundos

-- Para auditoría completa (impacto en performance)
ALTER SYSTEM SET log_statement = 'mod';  -- DDL + DML (INSERT, UPDATE, DELETE)

-- Recargar configuración
SELECT pg_reload_conf();
```

**Verificar logs:**
```bash
# Via Cloud Logging
gcloud logging read "resource.type=cloudsql_database AND \
  textPayload=~\"LOG:  statement\"" \
  --limit 100
```

#### 2.1.3 Audit Logs (SQL Server)

```sql
-- Crear Server Audit (nivel instancia)
CREATE SERVER AUDIT DBAudit
TO FILE (FILEPATH = 'gs://BUCKET/audit/', MAXSIZE = 10 MB);

-- Habilitar audit
ALTER SERVER AUDIT DBAudit WITH (STATE = ON);

-- Crear Database Audit Specification
CREATE DATABASE AUDIT SPECIFICATION AuditDDL
FOR SERVER AUDIT DBAudit
    ADD (SCHEMA_OBJECT_CHANGE_GROUP),
    ADD (DATABASE_OBJECT_CHANGE_GROUP),
    ADD (SELECT, INSERT, UPDATE, DELETE ON DATABASE::sistema_prd BY public);

ALTER DATABASE AUDIT SPECIFICATION AuditDDL WITH (STATE = ON);
```

#### 2.1.4 Query Logs (MySQL)

```sql
-- Habilitar General Query Log (solo para troubleshooting, NO permanente)
SET GLOBAL general_log = 'ON';
SET GLOBAL general_log_file = '/var/log/mysql/general.log';

-- Habilitar Slow Query Log (recomendado en PRD)
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 5;  -- Queries > 5 segundos
SET GLOBAL log_slow_admin_statements = 'ON';
```

### 2.2 Configuración de Auditoría por Ambiente

| Configuración | DEV | QA | PRD |
|---------------|-----|-----|-----|
| **Cloud Audit Logs (Admin)** | ✅ Habilitado | ✅ Habilitado | ✅ Habilitado |
| **Cloud Audit Logs (Data Access)** | ❌ Opcional | ⚠️ Recomendado | ✅ **Obligatorio** |
| **Query Logs (DDL)** | ⚠️ Opcional | ✅ Habilitado | ✅ **Obligatorio** |
| **Query Logs (DML)** | ❌ No | ❌ No | ⚠️ Solo críticas |
| **Slow Query Log** | ✅ Habilitado | ✅ Habilitado | ✅ Habilitado |
| **Retención en Cloud Logging** | 7 días | 30 días | 365 días |
| **Export a Cloud Storage** | ❌ No | ⚠️ Opcional | ✅ 7 años |
| **Alertas en tiempo real** | ❌ No | ⚠️ Críticas | ✅ **Completas** |

### 2.3 Eventos Críticos que Generan Alertas

#### Alertas de Seguridad (Inmediatas)

| Evento | Severidad | Destinatarios | Acción |
|--------|-----------|---------------|--------|
| **DROP DATABASE** | CRITICAL | DBA Lead + CISO + PagerDuty | Investigar inmediatamente |
| **DROP TABLE en PRD** | CRITICAL | DBA + CISO | Validar si es autorizado |
| **GRANT/REVOKE fuera de horario** | WARNING | DBA Lead | Revisar en 1 hora |
| **Intento de acceso denegado (> 5 en 10 min)** | WARNING | Security | Posible brute-force |
| **Acceso desde IP no autorizada** | CRITICAL | Security + DBA | Bloquear y investigar |
| **Exportación masiva (> 50k filas)** | WARNING | DBA + Product Owner | Validar autorización |
| **ALTER USER (cambio password no programado)** | WARNING | Security | Verificar legitimidad |
| **DELETE sin WHERE (tabla completa)** | CRITICAL | DBA + Product Owner | Validar y posible restore |
| **Conexión de usuario vencido** | WARNING | DBA | Revisar proceso de expiración |
| **SUPERUSER otorgado fuera de proceso JIT** | CRITICAL | CISO + DBA Lead | Investigación obligatoria |

#### Query de Ejemplo — Detectar Eventos Sospechosos (PostgreSQL)

```sql
-- Detectar GRANT/REVOKE no autorizados
SELECT 
    usename,
    application_name,
    client_addr,
    query,
    query_start,
    state
FROM pg_stat_activity
WHERE query ILIKE '%GRANT%' 
   OR query ILIKE '%REVOKE%'
ORDER BY query_start DESC;

-- Detectar DROP TABLE
SELECT 
    usename,
    query,
    query_start
FROM pg_stat_statements
WHERE query ILIKE '%DROP TABLE%'
ORDER BY query_start DESC;
```

---

## 3. RECERTIFICACIÓN DE ACCESOS

### 3.1 Proceso de Recertificación Trimestral

**Objetivo:** Validar que todos los accesos activos siguen siendo necesarios

#### Cronograma
- **Frecuencia:** Cada 90 días
- **Inicio:** Primer día hábil del trimestre
- **Deadline:** 15 días naturales para completar
- **Responsable:** Product Owner de cada sistema

#### Proceso

```
Día 1: DBA genera reporte de usuarios activos por BD
       ↓
Día 1-3: Envío de reporte a Product Owners
         - Lista de usuarios
         - Privilegios otorgados
         - Última fecha de uso
         - Fecha de última recertificación
       ↓
Día 3-15: Product Owner revisa y certifica:
          [ ] Confirmar acceso necesario
          [ ] Revocar acceso (ya no necesario)
          [ ] Modificar privilegios (reducir si es posible)
       ↓
Día 15: Deadline de respuesta
        - Accesos no confirmados → Suspendidos automáticamente
        - Notificación a usuarios suspendidos
       ↓
Día 16-20: Implementación de cambios por DBA
           - Revocaciones aprobadas
           - Modificaciones de privilegios
       ↓
Día 20: Reporte de cierre a CISO
        - % de recertificación completada
        - Accesos revocados
        - Accesos suspendidos por falta de respuesta
```

#### Template de Reporte de Recertificación

```yaml
# RECERTIFICACIÓN TRIMESTRAL Q2-2026
# Sistema: Avanzo / Telemedicina
# Product Owner: [Nombre]
# Periodo: Abril - Junio 2026

Usuarios Activos:
┌────────────────┬──────────┬─────────────┬──────────────┬─────────────┐
│ Usuario        │ Rol      │ Privilegios │ Último uso   │ Certificar  │
├────────────────┼──────────┼─────────────┼──────────────┼─────────────┤
│ dev_jperez     │ Dev      │ ReadWrite   │ 2026-06-28   │ [✓] Confirmar [ ] Revocar [ ] Modificar │
│ svc_avanzo_app │ App SA   │ ReadWrite   │ 2026-06-29   │ [✓] Confirmar [ ] Revocar [ ] Modificar │
│ bi_analytics   │ BI       │ ReadOnly    │ 2026-05-15   │ [ ] Confirmar [✓] Revocar (inactivo) │
│ ext_consultor  │ Externo  │ ReadOnly    │ 2026-04-10   │ [ ] Confirmar [✓] Revocar (proyecto terminado) │
└────────────────┴──────────┴─────────────┴──────────────┴─────────────┘

Acciones:
- Confirmar: 2 usuarios (dev_jperez, svc_avanzo_app)
- Revocar: 2 usuarios (bi_analytics por inactividad, ext_consultor por fin de proyecto)

Firma Product Owner: ___________________
Fecha: _____________________
```

### 3.2 Recertificación Anual de Service Accounts

**Más estricta que usuarios personales:**

- **Frecuencia:** Anual (o cada 6 meses para PRD crítico)
- **Validaciones adicionales:**
  - [ ] Service Account sigue siendo utilizado por aplicación activa
  - [ ] Credenciales rotadas en los últimos 90 días
  - [ ] Privilegios aún son mínimos necesarios
  - [ ] Aplicación no ha cambiado de propósito
  - [ ] Logs no muestran actividad sospechosa

---

## 4. AUDITORÍAS PROGRAMADAS

### 4.1 Auditoría Mensual de Usuarios

**Responsable:** DBA Lead  
**Frecuencia:** Primer lunes de cada mes

#### Checklist
- [ ] Ejecutar scripts de inventario de usuarios en todas las instancias
- [ ] Comparar con inventario documentado (ADMIN_DB_ORGANIZACION.md)
- [ ] Identificar usuarios no documentados (shadow accounts)
- [ ] Identificar usuarios inactivos (> 60 días sin login)
- [ ] Verificar que usuarios vencidos fueron eliminados
- [ ] Validar que privilegios coinciden con aprobaciones
- [ ] Generar reporte de discrepancias

#### Script de Auditoría — PostgreSQL

```sql
-- Reporte completo de usuarios activos
SELECT 
    u.usename AS usuario,
    CASE 
        WHEN u.usesuper THEN 'SUPERUSER'
        ELSE 'REGULAR'
    END AS tipo,
    u.valuntil AS expiracion,
    CASE 
        WHEN u.valuntil < NOW() THEN 'VENCIDO'
        WHEN u.valuntil IS NULL THEN 'PERMANENTE'
        ELSE 'ACTIVO'
    END AS estado,
    (
        SELECT MAX(backend_start)
        FROM pg_stat_activity
        WHERE usename = u.usename
    ) AS ultimo_acceso,
    array_agg(DISTINCT d.datname) FILTER (WHERE d.datname IS NOT NULL) AS databases
FROM pg_user u
LEFT JOIN pg_database d ON has_database_privilege(u.usename, d.datname, 'CONNECT')
WHERE u.usename NOT LIKE 'pg_%'
  AND u.usename NOT IN ('postgres', 'cloudsqladmin', 'cloudsqlreplica')
GROUP BY u.usename, u.usesuper, u.valuntil
ORDER BY u.usename;

-- Detectar usuarios SUPERUSER (solo DBAs deberían tenerlo)
SELECT usename, valuntil
FROM pg_user
WHERE usesuper = TRUE
  AND usename NOT IN ('postgres', 'cloudsqladmin')
ORDER BY usename;

-- Detectar usuarios sin uso reciente (> 60 días)
SELECT 
    u.usename,
    MAX(s.backend_start) AS ultimo_acceso,
    NOW() - MAX(s.backend_start) AS dias_inactivo
FROM pg_user u
LEFT JOIN pg_stat_activity s ON u.usename = s.usename
WHERE u.usename NOT LIKE 'pg_%'
GROUP BY u.usename
HAVING MAX(s.backend_start) < NOW() - INTERVAL '60 days'
    OR MAX(s.backend_start) IS NULL;
```

### 4.2 Auditoría Trimestral de Privilegios

**Responsable:** Security Lead + DBA Lead  
**Frecuencia:** Último viernes de cada trimestre

#### Objetivos
- Validar principio de **mínimo privilegio** (PoLP)
- Detectar **over-provisioning** de privilegios
- Verificar **separación de funciones** (SoD)

#### Checklist
- [ ] Revisar usuarios con privilegios de escritura en PRD
  - ¿Todos son Service Accounts de aplicaciones?
  - ¿Algún usuario personal tiene escritura en PRD?
- [ ] Revisar usuarios con privilegios DDL (CREATE/ALTER/DROP)
  - ¿Solo DBAs los tienen?
  - ¿Hay desarrolladores con DDL en QA/PRD?
- [ ] Validar que no hay usuarios compartidos (múltiples personas usando misma cuenta)
- [ ] Verificar rotación de contraseñas (Service Accounts < 90 días)
- [ ] Revisar privilegios GRANT OPTION (capacidad de otorgar privilegios)
  - ¿Solo DBAs lo tienen?

#### Script de Auditoría — Privilegios Excesivos (PostgreSQL)

```sql
-- Usuarios con privilegios de escritura en PRD
SELECT 
    grantee,
    table_schema,
    table_name,
    string_agg(privilege_type, ', ') AS privilegios
FROM information_schema.role_table_grants
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
  AND privilege_type IN ('INSERT', 'UPDATE', 'DELETE')
  AND grantee NOT LIKE 'svc_%'  -- Filtrar Service Accounts esperados
GROUP BY grantee, table_schema, table_name
ORDER BY grantee;

-- Usuarios con capacidad de otorgar privilegios (GRANT OPTION)
SELECT 
    grantee,
    table_schema,
    table_name,
    privilege_type
FROM information_schema.role_table_grants
WHERE is_grantable = 'YES'
  AND grantee NOT IN ('postgres', 'cloudsqladmin')
ORDER BY grantee;
```

### 4.3 Auditoría Anual de Compliance

**Responsable:** CISO + Auditor externo (si aplica)  
**Frecuencia:** Anual (o según requerimiento de certificación)

#### Objetivos
- Demostrar cumplimiento con **SOC 2 Type II**
- Validar controles de **GDPR** (protección de datos)
- Verificar cumplimiento de **HIPAA** (si aplica datos de salud)
- Preparar evidencia para **certificación ISO 27001**

#### Documentación Requerida
1. **Política de acceso a BD** (este documento) — vigente y aprobada
2. **Inventario completo de usuarios** — todas las instancias
3. **Log de solicitudes de acceso** — aprobadas y rechazadas
4. **Reportes de recertificaciones** — últimos 4 trimestres
5. **Incidentes de seguridad** — relacionados con BD, con resolución
6. **Reportes de auditoría mensual/trimestral** — último año
7. **Evidencia de capacitación** — personal entrenado en políticas
8. **Configuración de auditoría** — logs habilitados en PRD
9. **Plan de DR (Disaster Recovery)** — y drill de restauración
10. **Matriz de accesos actualizada** — roles vs privilegios

---

## 5. COMPLIANCE Y REGULACIONES

### 5.1 GDPR (General Data Protection Regulation)

#### Requisitos Clave
- **Derecho al olvido:** Capacidad de eliminar datos personales
- **Portabilidad:** Exportar datos de usuario en formato legible
- **Minimización de datos:** Solo recolectar lo necesario
- **Cifrado:** Datos personales cifrados en reposo y tránsito
- **Auditoría:** Logs de acceso a datos personales

#### Implementación

**Identificar Datos Personales (PII):**
```sql
-- Ejemplo: Marcar columnas PII en metadata
CREATE TABLE data_catalog (
    table_name VARCHAR(100),
    column_name VARCHAR(100),
    is_pii BOOLEAN,
    pii_category VARCHAR(50), -- email, phone, address, name, ssn, etc.
    retention_policy VARCHAR(100)
);

-- Insertar metadatos
INSERT INTO data_catalog VALUES
('users', 'email', TRUE, 'email', '5 years after last activity'),
('users', 'phone', TRUE, 'phone', '5 years after last activity'),
('users', 'first_name', TRUE, 'name', '5 years after last activity');
```

**Procedimiento de "Derecho al Olvido":**
```sql
-- Script de eliminación de datos personales (GDPR)
-- Requiere ticket de solicitud del usuario + aprobación Legal

DO $$
DECLARE
    v_user_id INTEGER := 12345;  -- ID del usuario que solicita eliminación
BEGIN
    -- 1. Anonimizar (preferido sobre DELETE para mantener integridad)
    UPDATE users SET
        email = 'deleted_' || v_user_id || '@gdpr-deleted.local',
        phone = NULL,
        first_name = 'Deleted',
        last_name = 'User',
        address = NULL,
        date_of_birth = NULL
    WHERE id = v_user_id;

    -- 2. Eliminar datos relacionados sensibles
    DELETE FROM user_preferences WHERE user_id = v_user_id;
    DELETE FROM user_consents WHERE user_id = v_user_id;

    -- 3. Log de auditoría (GDPR compliance)
    INSERT INTO gdpr_deletion_log (user_id, deleted_at, ticket_reference)
    VALUES (v_user_id, NOW(), 'GDPR-REQ-12345');

    RAISE NOTICE 'Datos personales de usuario % anonimizados según GDPR', v_user_id;
END $$;
```

**Auditoría de Acceso a PII:**
```sql
-- Habilitar logging de acceso a columnas PII (PostgreSQL)
-- Requiere extensión pgaudit
CREATE EXTENSION IF NOT EXISTS pgaudit;

-- Configurar auditoría de PII
ALTER SYSTEM SET pgaudit.log = 'read,write';
ALTER SYSTEM SET pgaudit.log_catalog = off;
ALTER SYSTEM SET pgaudit.log_parameter = on;

SELECT pg_reload_conf();
```

### 5.2 HIPAA (Health Insurance Portability and Accountability Act)

**Aplica si la base de datos contiene PHI (Protected Health Information)**

#### Requisitos Técnicos
- [x] **Cifrado en reposo** — CMEK en Cloud KMS
- [x] **Cifrado en tránsito** — TLS 1.3 obligatorio
- [x] **Control de acceso** — Autenticación + Autorización + Auditoría
- [x] **Auditoría completa** — Logs de acceso a PHI (retención 6 años)
- [x] **Backup cifrado** — Con procedimiento de restore testeado
- [x] **Integridad de datos** — Protección contra modificación no autorizada

#### Datos Clasificados como PHI
- Nombre + cualquier identificador médico (ID paciente, número de historia clínica)
- Diagnósticos, tratamientos, recetas médicas
- Resultados de laboratorio
- Información de seguros médicos
- Fechas de citas médicas con proveedor identificado

#### Script de Anonimización para Ambientes No-Prod

```sql
-- Anonimizar PHI en copias de QA/DEV
UPDATE pacientes SET
    nombre = 'Paciente ' || id,
    apellido = 'Prueba ' || id,
    ssn = 'XXX-XX-' || LPAD((1000 + id)::TEXT, 4, '0'),
    fecha_nacimiento = fecha_nacimiento + (random() * INTERVAL '730 days') - INTERVAL '365 days',
    direccion = 'Dirección Anonimizada ' || (id % 100),
    telefono = '+1-555-' || LPAD((id % 10000)::TEXT, 4, '0'),
    email = 'paciente' || id || '@hipaa-test.local';

UPDATE historias_clinicas SET
    diagnostico = 'Diagnóstico anonimizado ' || id,
    notas_medicas = 'Notas anonimizadas para ambiente de prueba',
    nombre_medico = 'Dr. Prueba ' || (id % 50);

-- Eliminar datos altamente sensibles
UPDATE laboratorios SET
    resultado_detallado = NULL,
    interpretacion = 'Resultado anonimizado';
```

### 5.3 SOC 2 Type II

#### Controles de Seguridad Auditables

| Control | Evidencia Requerida | Frecuencia |
|---------|---------------------|------------|
| **CC6.1 — Logical Access** | Inventario de usuarios + Recertificaciones | Trimestral |
| **CC6.2 — Authentication** | MFA habilitado para todos los usuarios | Continua |
| **CC6.3 — Authorization** | Matriz de privilegios vs roles aprobados | Trimestral |
| **CC6.6 — Logging and Monitoring** | Cloud Audit Logs + Query Logs habilitados | Continua |
| **CC6.7 — Restrict Access** | Solo acceso via Cloud SQL Proxy/VPN | Continua |
| **CC7.2 — Change Management** | Tickets de cambio en PRD con aprobación | Por cambio |

#### Evidencias para Auditoría SOC 2

```bash
# 1. Exportar logs de auditoría (último trimestre)
gcloud logging read "resource.type=cloudsql_database" \
  --format=json \
  --freshness=90d > audit-logs-q2-2026.json

# 2. Exportar inventario de usuarios
# (ejecutar scripts de sección 4.1 y guardar resultado)

# 3. Exportar solicitudes de acceso aprobadas (desde ITSM)
# JIRA Query: project = "DB-ACCESS" AND status = "Approved" AND created >= "2026-04-01"

# 4. Exportar recertificaciones completadas
# (reportes de sección 3.1)

# 5. Exportar incidentes de seguridad
# (de sistema de gestión de incidentes)
```

---

## 6. GESTIÓN DE INCIDENTES DE SEGURIDAD

### 6.1 Clasificación de Incidentes

| Severidad | Descripción | Tiempo de Respuesta | Notificación |
|-----------|-------------|---------------------|--------------|
| **P0 — Crítico** | Brecha de datos confirmada, acceso no autorizado activo | 15 minutos | CISO + CTO + Legal + PagerDuty |
| **P1 — Alto** | Intento de acceso no autorizado, actividad sospechosa confirmada | 1 hora | CISO + DBA Lead |
| **P2 — Medio** | Violación de política detectada, acceso no justificado | 4 horas | Security Team |
| **P3 — Bajo** | Anomalía detectada, requiere investigación | 1 día | DBA Team |

### 6.2 Proceso de Respuesta a Incidentes

```
1. DETECCIÓN
   - Alerta automática o reporte manual
   - Clasificación inicial de severidad
   ↓
2. CONTENCIÓN
   - P0/P1: Revocar acceso inmediatamente
   - Aislar sistema afectado si es necesario
   - Preservar evidencia (logs)
   ↓
3. ANÁLISIS
   - Determinar alcance del incidente
   - Identificar datos/sistemas comprometidos
   - Revisar logs de auditoría
   ↓
4. ERRADICACIÓN
   - Eliminar causa raíz
   - Cambiar credenciales comprometidas
   - Aplicar parches de seguridad
   ↓
5. RECUPERACIÓN
   - Restaurar desde backup si hay corrupción
   - Verificar integridad de datos
   - Restablecer servicio normal
   ↓
6. POST-MORTEM
   - Documentar cronología completa
   - Identificar mejoras de proceso
   - Actualizar políticas/controles
   - Capacitación si aplica
```

### 6.3 Template de Reporte de Incidente

```yaml
# REPORTE DE INCIDENTE DE SEGURIDAD — BASE DE DATOS

Ticket ID: INC-12345
Fecha/Hora detección: 2026-06-29 14:35:00 UTC
Severidad: [P0 / P1 / P2 / P3]
Estado: [Activo / Contenido / Resuelto / Cerrado]

## RESUMEN
[Descripción breve del incidente en 2-3 líneas]

## CRONOLOGÍA
- 14:35 — Alerta generada: [descripción alerta]
- 14:37 — DBA Lead notificado
- 14:40 — Acceso revocado
- 14:50 — Análisis de logs iniciado
- 15:20 — Causa raíz identificada
- 16:00 — Remediación completada
- 16:30 — Servicio restaurado

## ALCANCE DEL INCIDENTE
Instancia afectada: g-us-east1-avanzo-db01
Base de datos: avanzo_prd
Usuario involucrado: [nombre_usuario]
Privilegios del usuario: [ReadWrite / Admin / etc.]

## IMPACTO
- Datos accedidos: [SÍ/NO — Si sí, cuáles]
- Datos modificados: [SÍ/NO — Si sí, cuáles]
- Datos eliminados: [SÍ/NO — Si sí, cuáles]
- Downtime: [X minutos / No aplica]
- Usuarios afectados: [Número o N/A]

## CAUSA RAÍZ
[Descripción detallada de cómo ocurrió el incidente]

## ACCIONES TOMADAS
1. [Acción inmediata de contención]
2. [Acción de análisis]
3. [Acción de erradicación]
4. [Acción de recuperación]

## EVIDENCIA
- Logs exportados: gs://bucket/incident-logs/INC-12345/
- Capturas de pantalla: [adjuntas]
- Queries ejecutadas: [ver anexo]

## MEJORAS IMPLEMENTADAS
1. [Cambio de proceso/política]
2. [Control técnico adicional]
3. [Capacitación/awareness]

## NOTIFICACIONES REALIZADAS
- CISO: [Fecha/Hora]
- Legal: [Si aplica — brecha de datos reportable]
- Usuarios afectados: [Si aplica — GDPR/HIPAA]
- Auditor externo: [Si aplica — SOC 2]

## CIERRE
Fecha de resolución: 2026-06-29 16:30
Responsable: [Nombre DBA Lead]
Aprobación CISO: [Nombre + Fecha]

---
Post-Mortem Meeting: [Fecha programada]
Participantes: DBA Lead, Security, DevOps, Product Owner
```

---

## 7. REPORTES DE COMPLIANCE

### 7.1 Reporte Mensual al CISO

**Destinatarios:** CISO, CTO, DBA Lead  
**Frecuencia:** Primer viernes de cada mes

```yaml
# REPORTE MENSUAL — ADMINISTRACIÓN DE BASES DE DATOS
# Mes: Junio 2026

## RESUMEN EJECUTIVO
- Total de instancias activas: 12 (DEV: 4, QA: 3, PRD: 5)
- Total de usuarios activos: 87
- Solicitudes de acceso procesadas: 23 (aprobadas: 21, rechazadas: 2)
- Accesos revocados: 8 (offboarding: 3, inactividad: 5)
- Incidentes de seguridad: 1 (P3 — resuelto)
- Tiempo promedio de aprobación: 1.8 días (SLA: 2 días)

## SOLICITUDES DE ACCESO
| Tipo | DEV | QA | PRD | Total |
|------|-----|----|-----|-------|
| Lectura | 8 | 5 | 3 | 16 |
| Escritura | 4 | 2 | 1 | 7 |
| Rechazadas | 1 | 1 | 0 | 2 |

Motivos de rechazo:
- Falta de justificación de negocio (1)
- Privilegios excesivos solicitados (1)

## USUARIOS ACTIVOS
| Categoría | DEV | QA | PRD |
|-----------|-----|----|-----|
| DBA | 3 | 3 | 3 |
| DevOps | 8 | 6 | 0 (solo SA) |
| Desarrolladores | 25 | 12 | 0 |
| Service Accounts | 10 | 8 | 15 |
| BI/Analytics | 4 | 2 | 5 |
| Proveedores | 2 | 1 | 0 |

## REVOCACIONES
- Empleados desvinculados: 3 (tiempo promedio: 2.5 horas)
- Cuentas inactivas > 60 días: 5
- Proyectos finalizados: 0

## AUDITORÍA
- Usuarios vencidos eliminados: 2
- Usuarios sin documentar (shadow accounts): 0 ✓
- Usuarios con privilegios excesivos: 1 (corregido)

## INCIDENTES DE SEGURIDAD
INC-12345 (P3) — Usuario externo intentó acceder fuera de horario aprobado
- Detección: Alerta automática
- Resolución: 45 minutos
- Acción: Acceso suspendido, re-capacitación obligatoria

## COMPLIANCE
- Recertificación Q2: 95% completada (pendiente 1 Product Owner)
- Auditoría mensual: Completada ✓
- Rotación de credenciales: 100% (Service Accounts < 90 días)

## MÉTRICAS DE PERFORMANCE
- Disponibilidad PRD: 99.95% (SLA: 99.9%) ✓
- Backups exitosos: 100%
- Tiempo promedio respuesta DBA: 3.2 horas (SLA: 4 horas) ✓

## ACCIONES PENDIENTES
1. Completar recertificación Q2 — Product Owner pendiente
2. Actualizar inventario de usuarios (nueva instancia QA)
3. Implementar alerta de exportación masiva en instancia QA-03

## TENDENCIAS Y RECOMENDACIONES
- ↗️ Aumento de solicitudes PRD (+15% vs mes anterior)
  Recomendación: Revisar necesidad de nuevos roles específicos

- ↘️ Reducción de rechazos (-30% vs mes anterior)
  Recomendación: Capacitación sobre políticas está funcionando

---
Preparado por: [Nombre DBA Lead]
Fecha: 2026-07-05
```

### 7.2 Reporte Trimestral de Compliance

**Más detallado, para auditoría SOC 2 / ISO 27001**

```yaml
# REPORTE TRIMESTRAL DE COMPLIANCE — Q2 2026

## MÉTRICAS DE CUMPLIMIENTO
| Control | Objetivo | Actual | Estado |
|---------|----------|--------|--------|
| Recertificación completada | 100% | 98% | ⚠️ Casi completo |
| Usuarios con MFA | 100% | 100% | ✅ Cumple |
| Rotación credenciales SA | 100% < 90d | 100% | ✅ Cumple |
| Accesos revocados < 4h (offboarding) | 100% | 100% | ✅ Cumple |
| Auditoría mensual ejecutada | 100% | 100% | ✅ Cumple |
| Incidentes P0/P1 resueltos en SLA | 100% | N/A | N/A (0 incidentes) |

## EVIDENCIAS GENERADAS
1. Inventario de usuarios (mensual) — 3 reportes
2. Recertificaciones — 1 ciclo completo
3. Logs de auditoría — Exportados a GCS (retención 7 años)
4. Solicitudes de acceso — 68 tickets procesados
5. Incidentes — 3 reportes (todos P3, resueltos)

## CAMBIOS EN POLÍTICAS
- Ninguno este trimestre

## CAPACITACIONES REALIZADAS
- Onboarding de 5 nuevos desarrolladores
- Sesión de awareness sobre PII para equipo BI (2026-05-20)

## PLAN DE ACCIÓN — Q3 2026
1. Automatizar proceso de recertificación (reducir carga manual)
2. Implementar dashboard de compliance en tiempo real
3. Drill de Disaster Recovery (trimestral obligatorio)
```

---

## 8. RETENCIÓN DE EVIDENCIAS

### 8.1 Política de Retención

| Tipo de Evidencia | Retención Mínima | Ubicación | Responsable |
|-------------------|------------------|-----------|-------------|
| **Cloud Audit Logs (Admin)** | 365 días (Logging) + 7 años (GCS) | Cloud Logging + GCS | DBA |
| **Cloud Audit Logs (Data Access)** | 365 días (Logging) + 7 años (GCS) | Cloud Logging + GCS | DBA |
| **Query Logs** | 90 días (Logging) + 1 año (GCS) | Cloud Logging + GCS | DBA |
| **Solicitudes de acceso** | Permanente | JIRA/ServiceNow | ITSM Admin |
| **Recertificaciones** | 7 años | Google Drive (cifrado) | CISO |
| **Inventarios de usuarios** | 3 años | Repositorio Git privado | DBA |
| **Reportes de incidentes** | 7 años | Sistema de tickets + Drive | Security |
| **Backups de BD** | 30 días (operacional) + Mensual 7 años (compliance) | Cloud Storage | DBA |
| **Configuraciones de instancias** | Histórico completo (IaC) | Repositorio Git | DevOps |

### 8.2 Exportación de Logs para Compliance

```bash
# Script de exportación trimestral de logs (automatizar via cron)
#!/bin/bash

QUARTER="Q2-2026"
START_DATE="2026-04-01"
END_DATE="2026-06-30"
PROJECT_ID="proyecto-prd"
BUCKET="gs://compliance-logs-archive"

# Exportar Admin Activity Logs
gcloud logging read "resource.type=cloudsql_database AND \
  logName=projects/$PROJECT_ID/logs/cloudaudit.googleapis.com%2Factivity AND \
  timestamp >= \"$START_DATE\" AND timestamp <= \"$END_DATE\"" \
  --format=json > admin-activity-$QUARTER.json

# Subir a Cloud Storage (inmutable)
gsutil -h "x-goog-meta-quarter:$QUARTER" \
       -h "x-goog-meta-retention:7years" \
       cp admin-activity-$QUARTER.json $BUCKET/admin-activity/

# Configurar Object Versioning y Retention Policy (7 años)
gsutil versioning set on $BUCKET
gsutil retention set 7y $BUCKET

echo "Logs exportados y archivados para compliance — $QUARTER"
```

---

## ANEXOS

### Anexo A: Scripts de Auditoría

**Ubicación:** `Administraciondb/scripts/auditoria/`

- `audit_users_postgres.sql` — Inventario de usuarios PostgreSQL
- `audit_users_mysql.sql` — Inventario de usuarios MySQL
- `audit_users_sqlserver.sql` — Inventario de usuarios SQL Server
- `detect_overprivileged.sql` — Detectar privilegios excesivos
- `inactive_users.sql` — Usuarios sin actividad > 60 días
- `export_logs.sh` — Script de exportación de logs

### Anexo B: Contactos de Auditoría

- **CISO:** ciso@dominio.org
- **DBA Lead:** dba-lead@dominio.org
- **Auditor Externo (SOC 2):** [Firma auditora]
- **Legal (GDPR/HIPAA):** legal@dominio.org

### Anexo C: Documentación Relacionada

- [Política de Administración de Accesos](./README.md)
- [Matriz de Accesos](./04_Matriz_Accesos.md)
- [Procedimientos de Solicitud](./05_Procedimientos_Solicitud.md)
- [Organización y Mantenimiento de BD](../ADMIN_DB_ORGANIZACION.md)

---

**Última revisión:** 2026-06-29  
**Próxima revisión:** 2026-12-29 (semestral)  
**Aprobado por:** CISO + DBA Lead

**NOTA:** Este documento es confidencial y de uso exclusivo para auditorías internas y externas autorizadas.
