# POLÍTICA DE ACCESO POR AMBIENTE

> **Documento consolidado:** consultar [01_Politica_Gestion_Accesos_Bases_Datos.md](01_Politica_Gestion_Accesos_Bases_Datos.md). Este documento se conserva como referencia histórica y no debe utilizarse como política independiente.

> **Aplicable a:** Todos los usuarios (internos y externos)  
> **Segregación:** DEV | QA | PRODUCCIÓN  
> **Última actualización:** 2026-06-29

---

## ÍNDICE

1. [Principios de Segregación de Ambientes](#1-principios-de-segregación-de-ambientes)
2. [Desarrollo (DEV)](#31-desarrollo-dev)
3. [Quality Assurance (QA)](#32-quality-assurance-qa)
4. [Producción (PRD)](#33-producción-prd)
5. [Matriz Comparativa de Ambientes](#4-matriz-comparativa-de-ambientes)
6. [Promoción de Cambios Entre Ambientes](#5-promoción-de-cambios-entre-ambientes)

---

## 1. PRINCIPIOS DE SEGREGACIÓN DE AMBIENTES

### 1.1 Objetivo
Garantizar que cada ambiente tenga controles de seguridad proporcionales a:
- El riesgo de los datos contenidos
- El impacto potencial de errores o mal uso
- Los requisitos de compliance y auditoría

### 1.2 Aislamiento de Ambientes
- **Redes separadas:** Cada ambiente en su propia VPC o subnet
- **Instancias separadas:** No compartir instancias CloudSQL entre ambientes
- **Credenciales únicas:** Cada ambiente con sus propios usuarios y contraseñas
- **Datos aislados:** DEV/QA con datos sintéticos o anonimizados

### 1.3 Flujo de Datos
```
┌─────────────┐
│ PRODUCCIÓN  │  ← Solo lectura para backups
│  (Real data)│  
└──────┬──────┘
       │
       ↓ Anonimización + Sanitización
┌──────┴──────┐
│     QA      │  
│ (Data anon.)│
└──────┬──────┘
       │
       ↓ Subset o sintético
┌──────┴──────┐
│     DEV     │
│(Synthetic)  │
└─────────────┘
```

**Prohibido:** Copiar datos directamente de PRD a DEV/QA sin anonimizar

---

## 3.1 DESARROLLO (DEV)

### 3.1.1 Propósito
- Desarrollo activo de nuevas funcionalidades
- Pruebas unitarias e integración
- Experimentación y prototipos
- Entrenamiento y onboarding de nuevos desarrolladores

### 3.1.2 Características del Ambiente

| Aspecto | Configuración |
|---------|--------------|
| **Proyecto GCP** | `proyecto-dev` (separado de PRD) |
| **Red** | VPC privada `vpc-dev` |
| **Datos** | Sintéticos o anonimizados |
| **Disponibilidad** | No crítica (SLA: 95%) |
| **Respaldos** | Snapshots ocasionales (retención: 3 días) |
| **High Availability** | No requerida |
| **Auditoría** | Básica (logs de 7 días) |

### 3.1.3 Accesos Permitidos

#### DBA
```
Privilegios: SUPERUSER / db_owner (control total)
Restricciones: Documentar cambios mayores
```

#### DevOps
```
Privilegios: readWrite en todos los esquemas
Restricciones: No DROP DATABASE (solo tablas temporales)
```

#### Desarrolladores
```
Privilegios: readWrite + CREATE TABLE
Restricciones: Coordinación en cambios de esquema compartidos
```

#### Proveedores Externos
```
Privilegios: SELECT (read-only) o readWrite según contrato
Restricciones: MFA obligatorio, acceso temporal
```

### 3.1.4 Configuración de Seguridad

#### Autenticación
- Usuario/contraseña almacenado en Secret Manager
- MFA obligatorio para conexiones externas
- Cloud SQL Auth Proxy recomendado

#### Red y Conectividad
```yaml
Acceso IP pública: NO (disabled)
Acceso vía Cloud SQL Proxy: SÍ
Acceso vía VPN corporativa: SÍ
Acceso vía IAP Tunnel: SÍ
IPs autorizadas: Solo rangos corporativos
```

#### Auditoría y Logs
```yaml
Cloud Audit Logs: Habilitado (Admin activity)
Query Logs: Opcional (para troubleshooting)
Retención: 7 días
Alertas: Solo para DROP DATABASE
```

### 3.1.5 Operaciones Permitidas

| Operación | DBA | DevOps | Dev | Proveedor Externo |
|-----------|-----|--------|-----|-------------------|
| SELECT | ✅ | ✅ | ✅ | ✅ |
| INSERT/UPDATE | ✅ | ✅ | ✅ | ⚠️ Según contrato |
| DELETE | ✅ | ✅ | ✅ | ❌ |
| CREATE TABLE/INDEX | ✅ | ⚠️ Temporal | ✅ | ❌ |
| ALTER TABLE | ✅ | ⚠️ Coordinado | ⚠️ Coordinado | ❌ |
| DROP TABLE | ✅ | ⚠️ Solo temporal | ⚠️ Solo propias | ❌ |
| DROP DATABASE | ✅ | ❌ | ❌ | ❌ |
| GRANT/REVOKE | ✅ | ❌ | ❌ | ❌ |
| Backup/Restore | ✅ | ❌ | ❌ | ❌ |

### 3.1.6 Datos en DEV

#### Fuentes de Datos Permitidas
1. **Datos sintéticos:** Generados por scripts o herramientas (faker, mockaroo)
2. **Datos anonimizados:** Copia de QA con PII removida/enmascarada
3. **Datasets públicos:** Para prototipos y demos

#### Prohibido
- Copiar datos de Producción directamente
- Datos reales de clientes/pacientes
- Información personal identificable (PII) sin anonimizar

#### Script de Generación de Datos Sintéticos
```sql
-- Ejemplo: Generar usuarios de prueba
INSERT INTO users (username, email, first_name, last_name, created_at)
SELECT 
    'user_' || generate_series,
    'user_' || generate_series || '@ejemplo-dev.com',
    'Usuario',
    'Prueba ' || generate_series,
    NOW() - (random() * INTERVAL '365 days')
FROM generate_series(1, 1000);
```

### 3.1.7 Mantenimiento y Limpieza
- **Frecuencia:** Semanal o según necesidad
- **Reset completo:** Permitido sin aprobación
- **Snapshot antes de reset:** Recomendado

```bash
# Reset de base de datos DEV (script seguro)
#!/bin/bash
# Crear snapshot antes de reset
gcloud sql backups create --instance=dev-instance --project=proyecto-dev

# Ejecutar script de reset
psql -h localhost -U dba_admin -d sistema_dev -f scripts/reset_dev_database.sql
```

---

## 3.2 QUALITY ASSURANCE (QA)

### 3.2.1 Propósito
- Testing de integración y sistema
- Validación de migraciones de base de datos
- Staging para releases a Producción
- User Acceptance Testing (UAT)

### 3.2.2 Características del Ambiente

| Aspecto | Configuración |
|---------|--------------|
| **Proyecto GCP** | `proyecto-qa` (separado de DEV y PRD) |
| **Red** | VPC privada `vpc-qa` |
| **Datos** | Anonimizados de PRD o subconjunto sintético |
| **Disponibilidad** | Media (SLA: 98%) |
| **Respaldos** | Diarios (retención: 7 días) |
| **High Availability** | Recomendada (réplica en standby) |
| **Auditoría** | Completa (logs de 30 días) |

### 3.2.3 Accesos Permitidos

#### DBA
```
Privilegios: SUPERUSER / db_owner
Restricciones: Cambios deben ser documentados en tickets
```

#### DevOps
```
Privilegios: SELECT (todas las tablas) + Despliegue vía CI/CD
Restricciones: No acceso manual de escritura (solo via pipeline)
```

#### Desarrolladores
```
Privilegios: SELECT (read-only) + INSERT en tablas de testing
Restricciones: No UPDATE/DELETE en datos compartidos
```

#### QA Team
```
Privilegios: SELECT + INSERT/UPDATE en esquemas de testing
Restricciones: Limitado a datos de prueba, no datos de referencia
```

#### Proveedores Externos
```
Privilegios: SELECT (read-only)
Restricciones: Solo con NDA firmado, acceso temporal
```

### 3.2.4 Configuración de Seguridad

#### Autenticación
- Preferencia: IAM de GCP para usuarios internos
- Usuario/contraseña para Service Accounts en Secret Manager
- MFA obligatorio para todos

#### Red y Conectividad
```yaml
Acceso IP pública: NO (disabled)
Acceso vía Cloud SQL Proxy: SÍ
Acceso vía VPN corporativa: SÍ
Acceso vía IAP Tunnel: SÍ (preferido)
IPs autorizadas: Rangos corporativos + CI/CD runners
```

#### Auditoría y Logs
```yaml
Cloud Audit Logs: Habilitado (Admin + Data access)
Query Logs: Habilitado (queries de escritura)
Retención: 30 días
Alertas: DROP/ALTER de tablas principales, DELETE masivo
```

### 3.2.5 Operaciones Permitidas

| Operación | DBA | DevOps (Manual) | DevOps (CI/CD) | Dev | QA Team | Proveedor |
|-----------|-----|-----------------|----------------|-----|---------|-----------|
| SELECT | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| INSERT | ✅ | ❌ | ✅ (via deploy) | ⚠️ Sandbox | ✅ Test data | ❌ |
| UPDATE | ✅ | ❌ | ✅ (via deploy) | ❌ | ⚠️ Test data | ❌ |
| DELETE | ✅ | ❌ | ⚠️ Específico | ❌ | ❌ | ❌ |
| CREATE TABLE | ✅ | ❌ | ✅ (migrations) | ❌ | ❌ | ❌ |
| ALTER TABLE | ✅ | ❌ | ✅ (migrations) | ❌ | ❌ | ❌ |
| DROP TABLE | ✅ | ❌ | ⚠️ Con aprobación | ❌ | ❌ | ❌ |
| GRANT/REVOKE | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Backup/Restore | ✅ | ⚠️ Con DBA | ❌ | ❌ | ❌ | ❌ |

### 3.2.6 Datos en QA

#### Fuentes de Datos
1. **Anonimización de PRD:** Copia periódica (mensual) con PII enmascarada
2. **Datos sintéticos:** Para escenarios de testing específicos
3. **Subset de PRD:** Solo datos no sensibles o públicos

#### Proceso de Anonimización
```sql
-- Script de anonimización desde backup de PRD
-- Ejecutar DESPUÉS de restaurar backup en QA

BEGIN;

-- Anonimizar información personal
UPDATE usuarios SET
    nombre = 'Usuario ' || id,
    apellido = 'Prueba ' || id,
    email = 'usuario' || id || '@ejemplo-qa.com',
    telefono = '+506-' || LPAD((1000 + id)::TEXT, 4, '0') || '-0000',
    identificacion = 'ID-QA-' || LPAD(id::TEXT, 8, '0');

-- Anonimizar datos médicos (si aplica HIPAA)
UPDATE pacientes SET
    ssn = 'XXX-XX-' || RIGHT(ssn, 4),
    fecha_nacimiento = fecha_nacimiento + (random() * INTERVAL '365 days'),
    direccion = 'Dirección de Prueba ' || id;

-- Eliminar datos altamente sensibles
UPDATE tarjetas_pago SET
    numero_tarjeta = NULL,
    cvv = NULL,
    token_pago = 'TOKEN_ANONIMIZADO_' || id;

-- Validar resultado
SELECT COUNT(*) AS usuarios_anonimizados FROM usuarios WHERE email LIKE '%@ejemplo-qa.com';

COMMIT;
```

#### Frecuencia de Refresh
- **Recomendado:** Mensual o antes de releases mayores
- **Proceso:** Backup de PRD → Restore en QA → Anonimización → Validación

### 3.2.7 Testing y Validaciones

#### Antes de Promover a Producción
- [ ] Migraciones ejecutadas exitosamente en QA
- [ ] Tests de integración passed
- [ ] Performance testing completado
- [ ] Validación de anonimización (no hay PII real)
- [ ] Rollback plan testeado

#### Ambientes de Testing Adicionales
```
QA (stable) → Para UAT y demos
QA (integration) → Para testing de CI/CD continuo
```

---

## 3.3 PRODUCCIÓN (PRD)

### 3.3.1 Propósito
- Ambiente productivo con datos reales
- Operación de servicios críticos del negocio
- Datos de clientes/pacientes/usuarios reales
- Sujeto a compliance (GDPR, HIPAA, SOC2)

### 3.3.2 Características del Ambiente

| Aspecto | Configuración |
|---------|--------------|
| **Proyecto GCP** | `proyecto-prd` (aislado, sin compartir con DEV/QA) |
| **Red** | VPC privada `vpc-prd` con reglas estrictas de firewall |
| **Datos** | **DATOS REALES** — alta sensibilidad |
| **Disponibilidad** | Crítica (SLA: 99.9%) |
| **Respaldos** | Automáticos diarios + export semanal (retención: 30-90 días) |
| **High Availability** | **Obligatoria** (réplica síncrona en otra zona) |
| **Auditoría** | **Completa** (Admin + Data access logs, retención: 365 días) |
| **Cifrado** | Datos en reposo (CMEK) + en tránsito (TLS 1.3) |

### 3.3.3 Accesos Permitidos

#### DBA
```
Privilegios: SUPERUSER / db_owner (via JIT)
Restricciones: 
  - Acceso JIT (Just-In-Time) solo cuando se necesita
  - Aprobación via ticket para operaciones de escritura
  - Sesión auditada en tiempo real
  - Expiración automática después de 4 horas
```

#### DevOps (Personal)
```
Privilegios: SELECT (read-only, sin acceso a PII)
Restricciones:
  - Solo para troubleshooting
  - Vistas limitadas (sin columnas sensibles)
  - Via VPN + MFA + Cloud SQL Proxy
```

#### DevOps (Service Account para CI/CD)
```
Privilegios: readWrite para despliegues automatizados
Restricciones:
  - Solo via pipeline aprobado
  - Migraciones requieren peer review + aprobación DBA
  - Rollback automático en caso de error
```

#### Desarrolladores
```
Privilegios: NINGUNO (sin acceso directo por defecto)
Excepciones:
  - Incidentes críticos P0/P1 con aprobación CISO
  - Sesión temporal (max 4 horas) supervisada por DBA
  - Solo SELECT en tablas específicas del incidente
```

#### Proveedores Externos
```
Privilegios: NINGUNO (prohibido por defecto)
Excepciones críticas:
  - Incidente P0 que requiera soporte del proveedor
  - Aprobación: CISO + CTO + Legal
  - Sesión grabada y supervisada
  - Screen sharing obligatorio con DBA
```

### 3.3.4 Configuración de Seguridad

#### Autenticación
```yaml
Método preferido: IAM de GCP (sin contraseñas)
Método alternativo: Usuario/contraseña en Secret Manager con rotación automática (90 días)
MFA: OBLIGATORIO para todos los accesos humanos
Tokens de sesión: Expiración en 4 horas
```

#### Red y Conectividad
```yaml
IP pública: DESHABILITADA
Acceso solo vía:
  - Cloud SQL Auth Proxy v2 con IP privada
  - VPN corporativa (solo rangos aprobados)
  - IAP Tunnel (preferido para accesos humanos)
Authorized Networks: VACÍO (no IPs públicas permitidas)
SSL/TLS: OBLIGATORIO (TLS 1.3 mínimo)
```

#### Cifrado
```yaml
En reposo: Customer-Managed Encryption Keys (CMEK) en Cloud KMS
En tránsito: TLS 1.3
Backups: Cifrados con la misma CMEK
Conexiones: Require SSL (enforce)
```

#### Auditoría y Logs
```yaml
Cloud Audit Logs:
  - Admin Activity: Habilitado
  - Data Access: Habilitado (READ + WRITE)
Query Logs:
  - Habilitado para todos los usuarios
  - Filtro: Queries > 5 segundos
Retención:
  - Cloud Logging: 365 días
  - Export a Cloud Storage: 7 años (compliance)
Alertas en tiempo real:
  - DROP TABLE/DATABASE
  - ALTER TABLE en horario no laboral
  - DELETE masivo (> 1000 filas)
  - Intentos de acceso fallidos (> 3 en 10 min)
  - Exportación de datos (> 10k filas)
  - Creación/modificación de usuarios (GRANT/REVOKE)
```

### 3.3.5 Operaciones Permitidas

| Operación | DBA (JIT) | DevOps (Personal) | DevOps (CI/CD SA) | Dev | Proveedor |
|-----------|-----------|-------------------|-------------------|-----|-----------|
| SELECT (no PII) | ✅ | ✅ | ✅ | ⚠️ Incidente | ❌ |
| SELECT (PII) | ✅ | ❌ | ❌ | ❌ | ❌ |
| INSERT | ✅ Con ticket | ❌ | ✅ Via deploy | ❌ | ❌ |
| UPDATE | ✅ Con ticket | ❌ | ✅ Via deploy | ❌ | ❌ |
| DELETE | ✅ Con aprobación | ❌ | ⚠️ Específico | ❌ | ❌ |
| CREATE TABLE | ✅ Ventana cambio | ❌ | ✅ Migrations | ❌ | ❌ |
| ALTER TABLE | ✅ Ventana cambio | ❌ | ✅ Migrations | ❌ | ❌ |
| DROP TABLE | ✅ Peer review | ❌ | ⚠️ Con aprobación | ❌ | ❌ |
| DROP DATABASE | ✅ CISO + CTO | ❌ | ❌ | ❌ | ❌ |
| GRANT/REVOKE | ✅ Proceso aprobación | ❌ | ❌ | ❌ | ❌ |
| Backup/Restore | ✅ DR procedure | ❌ | ❌ | ❌ | ❌ |

### 3.3.6 Acceso Just-In-Time (JIT) para DBAs

#### Proceso de Elevación de Privilegios
```
1. DBA abre ticket justificando necesidad
   ↓
2. Aprobación automática para troubleshooting (read-only)
   Aprobación de DBA Lead para escritura
   Aprobación de CISO para cambios estructurales
   ↓
3. Sistema PAM otorga privilegios temporales (4 horas)
   ↓
4. DBA ejecuta operaciones con auditoría en tiempo real
   ↓
5. Expiración automática o revocación manual
   ↓
6. Log completo de acciones archivado para compliance
```

#### Implementación JIT con Cloud IAM
```bash
# Otorgar acceso temporal vía Cloud IAM Conditions
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="user:dba@dominio.org" \
  --role="roles/cloudsql.admin" \
  --condition="expression=request.time < timestamp('2026-06-29T22:00:00Z'),
               title=Temporary DBA access for INC-12345,
               description=Emergency access expires at 22:00"
```

### 3.3.7 Change Management en Producción

#### Ventanas de Cambio (Change Windows)
| Tipo de Cambio | Ventana Permitida | Aprobación Requerida | Rollback Plan |
|----------------|-------------------|---------------------|---------------|
| **Migraciones de esquema** | Martes/Jueves 22:00-02:00 | DBA Lead + Product Owner | Obligatorio |
| **Cambios de configuración** | Cualquier día 22:00-02:00 | DBA Lead | Recomendado |
| **Parches de seguridad** | Inmediato si crítico | CISO | Opcional |
| **Actualizaciones de motor** | Sábado 02:00-06:00 | CISO + CTO | Obligatorio |

#### Proceso de Change Management
```
1. Crear Change Request en ITSM (JIRA/ServiceNow)
   - Descripción del cambio
   - Justificación de negocio
   - Impacto y riesgo
   - Rollback plan
   - Validación en QA
   ↓
2. Peer Review (al menos 1 DBA senior)
   ↓
3. Aprobación según tabla arriba
   ↓
4. Scheduling en ventana de cambio
   ↓
5. Ejecución con monitoreo en vivo
   ↓
6. Validación post-cambio
   ↓
7. Cierre de ticket con documentación
```

#### Migraciones en Producción — Checklist
- [ ] Migración testeada exitosamente en QA (ambiente idéntico)
- [ ] Peer review por al menos 1 DBA senior
- [ ] Rollback script probado en QA
- [ ] Backup completo tomado < 1 hora antes
- [ ] Equipo de DevOps notificado (por si afecta deployments)
- [ ] Ventana de cambio aprobada y comunicada
- [ ] Monitoreo activo durante la migración
- [ ] Plan de comunicación a usuarios (si hay downtime)

**Script de migración seguro:**
```sql
-- V100__add_critical_index.sql
-- Ticket: CHANGE-12345
-- Ventana: 2026-06-30 22:00 - 23:00
-- Rollback: DROP INDEX idx_users_email;

BEGIN;

-- Verificación pre-cambio
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_users_email') THEN
        RAISE EXCEPTION 'Index already exists, migration already applied';
    END IF;
END $$;

-- Crear índice concurrente (no bloquea escrituras)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_email ON users(email);

-- Verificación post-cambio
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_users_email') THEN
        RAISE EXCEPTION 'Index creation failed';
    END IF;
    RAISE NOTICE 'Migration successful, index created';
END $$;

COMMIT;
```

### 3.3.8 Disaster Recovery

#### Objetivos de Recuperación
```yaml
RPO (Recovery Point Objective): 1 hora (máximo de datos perdidos)
RTO (Recovery Time Objective): 4 horas (máximo de downtime)
```

#### Respaldos en Producción
| Tipo | Frecuencia | Retención | Ubicación | Cifrado |
|------|------------|-----------|-----------|---------|
| **Snapshot automático** | Diario 02:00 | 30 días | Región principal | CMEK |
| **Export a GCS** | Semanal (Domingo 03:00) | 90 días | Multi-región | CMEK |
| **Réplica continua** | Tiempo real | N/A | Región secundaria | CMEK |
| **Archive (compliance)** | Mensual | 7 años | Cloud Storage Archive | CMEK |

#### Drill de Recuperación
- **Frecuencia:** Trimestral
- **Objetivo:** Validar que RTO/RPO son alcanzables
- **Proceso:**
  1. Crear instancia de prueba
  2. Restaurar último backup
  3. Validar integridad de datos
  4. Medir tiempo de restauración
  5. Documentar resultados y ajustar procedimientos

### 3.3.9 Monitoreo y Alertas

#### Métricas Críticas (SLI/SLO)
| Métrica | SLO | Alerta WARNING | Alerta CRITICAL |
|---------|-----|----------------|-----------------|
| Disponibilidad | 99.9% | 99.5% | < 99.5% |
| CPU utilization | < 70% | > 80% | > 95% |
| Disk utilization | < 80% | > 85% | > 90% |
| Memory utilization | < 80% | > 85% | > 95% |
| Conexiones activas | < 80% max | > 85% max | > 95% max |
| Query latency p95 | < 100ms | > 150ms | > 500ms |
| Replica lag | < 10s | > 30s | > 60s |

#### Alertas de Seguridad (Tiempo Real)
- Intento de DROP TABLE/DATABASE → Slack + PagerDuty + Email CISO
- Acceso desde IP no autorizada → Bloqueo automático + alerta
- Intentos fallidos de autenticación (> 5 en 10 min) → Alerta Security
- Exportación masiva de datos (> 50k filas) → Alerta DBA + Product Owner
- Cambio de permisos (GRANT/REVOKE) → Log + notificación DBA Lead

### 3.3.10 Compliance y Retención de Datos

#### Regulaciones Aplicables
- **GDPR:** Datos de usuarios en UE — derecho al olvido, portabilidad
- **HIPAA:** Datos médicos (si aplica) — auditoría completa, cifrado
- **SOC 2 Type II:** Controles de acceso, auditoría, disponibilidad
- **Ley local de protección de datos:** Según país de operación

#### Retención de Logs para Compliance
```yaml
Cloud Audit Logs (Admin Activity): 365 días en Cloud Logging → 7 años en GCS
Cloud Audit Logs (Data Access): 365 días en Cloud Logging → 7 años en GCS
Query Logs: 90 días en Cloud Logging → 1 año en GCS
Backups de base de datos: 90 días → Archive mensual por 7 años
Change Requests: Permanente en ITSM
```

#### Reportes de Compliance
- **Mensual:** Informe de accesos y cambios a Product Owners
- **Trimestral:** Auditoría de usuarios y recertificación de accesos
- **Anual:** Auditoría completa para certificaciones (SOC 2, ISO 27001)

---

## 4. MATRIZ COMPARATIVA DE AMBIENTES

| Característica | DEV | QA | PRODUCCIÓN |
|----------------|-----|-----|------------|
| **Propósito** | Desarrollo, experimentación | Testing, staging | Operación real |
| **Datos** | Sintéticos / Anonimizados | Anonimizados de PRD | **Datos REALES** |
| **Sensibilidad** | Baja | Media | **ALTA** |
| **Acceso DBA** | Completo permanente | Completo documentado | **JIT con aprobación** |
| **Acceso DevOps (personal)** | Read/Write | Read-only | **Read-only (sin PII)** |
| **Acceso DevOps (CI/CD)** | Completo | Via pipeline | **Via pipeline aprobado** |
| **Acceso Desarrolladores** | Read/Write | Read-only + sandbox | **NINGUNO (excepciones críticas)** |
| **Acceso Proveedores** | Read (temporal) | Read (temporal) | **PROHIBIDO (excepciones P0)** |
| **Disponibilidad SLA** | 95% | 98% | **99.9%** |
| **High Availability** | No | Recomendada | **Obligatoria** |
| **Backups retención** | 3 días | 7 días | **30-90 días + archive 7 años** |
| **Auditoría logs** | 7 días | 30 días | **365 días + export 7 años** |
| **MFA** | Obligatorio externo | Obligatorio todos | **Obligatorio todos** |
| **Cifrado en reposo** | Opcional | Recomendado | **CMEK obligatorio** |
| **Cifrado en tránsito** | TLS 1.2+ | TLS 1.2+ | **TLS 1.3** |
| **IP pública** | Deshabilitada | Deshabilitada | **Deshabilitada** |
| **Change Management** | No requerido | Ticket recomendado | **Obligatorio con aprobación** |
| **Ventana de cambios** | Anytime | Recomendado off-hours | **Solo en ventanas aprobadas** |
| **Peer Review** | Recomendado | Recomendado | **Obligatorio** |
| **Rollback plan** | Opcional | Recomendado | **Obligatorio** |

---

## 5. PROMOCIÓN DE CAMBIOS ENTRE AMBIENTES

### 5.1 Flujo de Promoción

```
┌─────────────┐
│  DEV        │  Desarrollo y pruebas unitarias
│             │  ↓ Deploy automático en cada commit
└──────┬──────┘
       │
       ↓ Pull Request + Code Review
┌──────┴──────┐
│  QA         │  Testing de integración y UAT
│             │  ↓ Deploy automático al merge a main
└──────┬──────┘
       │
       ↓ Aprobación manual + Checklist
┌──────┴──────┐
│ PRODUCCIÓN  │  Release planificado en ventana de cambio
└─────────────┘
```

### 5.2 Checklist de Promoción DEV → QA

- [ ] Tests unitarios passed (coverage > 80%)
- [ ] Code review aprobado por al menos 1 dev senior
- [ ] Migraciones de BD incluidas y versionadas
- [ ] Documentación actualizada
- [ ] No hay secretos/credenciales en código

**Automatización:** Deploy automático vía CI/CD al hacer merge a branch `main`

### 5.3 Checklist de Promoción QA → PRODUCCIÓN

#### Pre-Requisitos Técnicos
- [ ] Tests de integración passed en QA
- [ ] Performance testing completado (sin degradación)
- [ ] Security scan passed (sin vulnerabilidades críticas)
- [ ] Migraciones de BD ejecutadas exitosamente en QA
- [ ] Rollback plan documentado y probado
- [ ] Monitoring dashboards actualizados

#### Aprobaciones Requeridas
- [ ] Product Owner aprueba funcionalidad
- [ ] DBA Lead aprueba migraciones de BD (si las hay)
- [ ] Security aprueba cambios que afectan seguridad/compliance
- [ ] DevOps Lead confirma infraestructura lista

#### Change Management
- [ ] Change Request creado en ITSM
- [ ] Ventana de cambio asignada y comunicada
- [ ] Stakeholders notificados (si hay impacto)
- [ ] Plan de comunicación a usuarios (si hay downtime)
- [ ] Equipo on-call identificado y alertado

#### Ejecución
- [ ] Backup de PRD tomado < 1 hora antes del cambio
- [ ] Deployment ejecutado en ventana aprobada
- [ ] Smoke tests post-deployment passed
- [ ] Monitoreo activo por 2 horas post-deployment
- [ ] Rollback ejecutado si hay problemas críticos

#### Post-Deployment
- [ ] Validación de funcionalidad en PRD
- [ ] Métricas de performance dentro de SLO
- [ ] No hay errores críticos en logs
- [ ] Change Request cerrado con documentación

### 5.4 Proceso de Rollback

#### Triggers de Rollback
- Error crítico que afecta funcionalidad core
- Degradación de performance > 50%
- Brecha de seguridad detectada
- Pérdida de datos o corrupción

#### Procedimiento de Rollback
```
1. STOP — Detener deployment si está en progreso
   ↓
2. ASSESS — Evaluar impacto (¿es rollbackable o requiere fix-forward?)
   ↓
3. DECIDE — DBA Lead + DevOps Lead deciden rollback vs fix
   ↓
4. EXECUTE — Rollback de código + rollback de migrations de BD
   ↓
5. VERIFY — Validar que sistema volvió a estado previo estable
   ↓
6. COMMUNICATE — Notificar a stakeholders
   ↓
7. POST-MORTEM — Documentar causa raíz y prevención
```

#### Rollback de Migraciones
```sql
-- Cada migración debe tener su rollback
-- V100__add_index.sql → Rollback: V100__rollback.sql

-- V100__rollback.sql
BEGIN;

DROP INDEX IF EXISTS idx_users_email;

-- Verificación
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_users_email') THEN
        RAISE EXCEPTION 'Rollback failed, index still exists';
    END IF;
    RAISE NOTICE 'Rollback successful';
END $$;

COMMIT;
```

### 5.5 Tiempos Objetivo de Promoción

| Promoción | Tiempo Objetivo | Bloqueadores Comunes |
|-----------|----------------|---------------------|
| **DEV → QA** | Automático al merge | Tests fallando, conflicts |
| **QA → PRD** | 2-5 días hábiles | Aprobaciones pendientes, bugs en QA |
| **Hotfix → PRD** | < 4 horas | Solo para P0/P1, proceso acelerado |

---

## 6. CONTACTOS Y ESCALACIÓN

### 6.1 Matriz de Escalación

| Severidad | Tiempo de Respuesta | Contacto | Horario |
|-----------|---------------------|----------|---------|
| **P0 (Critical)** | 15 minutos | On-Call DBA + DevOps via PagerDuty | 24/7 |
| **P1 (High)** | 1 hora | DBA Lead + DevOps Lead | Horario laboral |
| **P2 (Medium)** | 4 horas | DBA Team | Horario laboral |
| **P3 (Low)** | 1 día hábil | Ticket en ITSM | Horario laboral |

### 6.2 Contactos Clave
- **On-Call DBA:** pagerduty-dba@dominio.org
- **DBA Lead:** dba-lead@dominio.org
- **CISO:** ciso@dominio.org
- **DevOps Lead:** devops-lead@dominio.org

### 6.3 Canales de Comunicación
- **Incidentes:** #incidents (Slack)
- **Change Requests:** JIRA/ServiceNow
- **Consultas generales:** #db-support (Slack)

---

**NOTA:** Esta política es complementaria a las políticas por tipo de usuario. En caso de conflicto, prevalece la restricción más estricta.
