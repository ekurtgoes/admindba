# POLÍTICA DE ACCESO A BASES DE DATOS — PERSONAL INTERNO

> **Documento consolidado:** consultar [01_Politica_Gestion_Accesos_Bases_Datos.md](01_Politica_Gestion_Accesos_Bases_Datos.md). Este documento se conserva como referencia histórica y no debe utilizarse como política independiente.

> **Aplicable a:** DBA, DevOps, Desarrolladores  
> **Nivel de Restricción:** MEDIA-ALTA (según rol)  
> **Última actualización:** 2026-06-29

---

## ÍNDICE

1. [Principios Generales](#1-principios-generales)
2. [DBA - Administradores de Bases de Datos](#21-dba---administradores-de-bases-de-datos)
3. [DevOps - Equipo de Despliegue](#22-devops---equipo-de-despliegue)
4. [Desarrolladores](#23-desarrolladores)
5. [Proceso de Solicitud y Aprobación](#3-proceso-de-solicitud-y-aprobación)
6. [Auditoría y Cumplimiento](#4-auditoría-y-cumplimiento)

---

## 1. PRINCIPIOS GENERALES

### 1.1 Separación de Funciones (SoD)
- Los roles deben estar claramente separados
- Una misma persona no debe tener control total sobre todo el ciclo de vida de los datos en Producción
- Los accesos deben ser específicos al rol y responsabilidades

### 1.2 Autenticación Corporativa
- **Obligatorio:** Uso de identidad corporativa (Google Cloud Identity)
- **Prohibido:** Cuentas personales o compartidas
- **MFA:** Autenticación de doble factor obligatoria para todos

### 1.3 Nomenclatura de Usuarios Internos

| Tipo de Usuario | Patrón | Ejemplo |
|-----------------|--------|---------|
| DBA | `dba_[iniciales]` | `dba_eleo` |
| DevOps | `devops_[iniciales]` | `devops_jperez` |
| Desarrollador | `dev_[iniciales]` | `dev_mrodriguez` |
| BI/Analytics | `bi_[iniciales]` | `bi_agarcia` |

---

## 2.1 DBA - ADMINISTRADORES DE BASES DE DATOS

### 2.1.1 Responsabilidades
- Administración completa de instancias CloudSQL
- Creación y gestión de usuarios
- Gestión de respaldos y recuperación
- Monitoreo y optimización de rendimiento
- Implementación de políticas de seguridad
- Auditoría de accesos y privilegios

### 2.1.2 Privilegios por Ambiente

#### DEV — Acceso Completo
```
Rol IAM: roles/cloudsql.admin
Privilegios BD: SUPERUSER / db_owner (todos los privilegios)
```

| Operación | Permitido | Restricción |
|-----------|-----------|-------------|
| SELECT/INSERT/UPDATE/DELETE | ✅ Sí | Ninguna |
| CREATE/ALTER/DROP | ✅ Sí | Ninguna |
| GRANT/REVOKE | ✅ Sí | Ninguna |
| Backup/Restore | ✅ Sí | Ninguna |
| Cambios de configuración | ✅ Sí | Documentar cambios |

**PostgreSQL — Ejemplo DEV:**
```sql
-- Crear DBA con privilegios completos
CREATE USER dba_eleo WITH PASSWORD 'xxx' SUPERUSER;
GRANT ALL PRIVILEGES ON DATABASE sistema_dev TO dba_eleo;
```

#### QA — Acceso Administrativo con Registro
```
Rol IAM: roles/cloudsql.admin
Privilegios BD: SUPERUSER / db_owner
Restricción: Cambios deben ser documentados
```

| Operación | Permitido | Restricción |
|-----------|-----------|-------------|
| SELECT/INSERT/UPDATE/DELETE | ✅ Sí | Registrar en change log |
| CREATE/ALTER/DROP | ✅ Sí | Requiere ticket de cambio |
| GRANT/REVOKE | ✅ Sí | Documentar en inventario |
| Backup/Restore | ✅ Sí | Ninguna |
| Cambios de configuración | ✅ Sí | Ticket + aprobación lead |

#### PRODUCCIÓN — Acceso JIT (Just-In-Time)
```
Rol IAM: roles/cloudsql.admin (activado solo cuando se necesita)
Privilegios BD: Elevación temporal con aprobación
Método: Privileged Access Management (PAM) o sistema de tickets
```

| Operación | Permitido | Restricción |
|-----------|-----------|-------------|
| SELECT (troubleshooting) | ✅ Sí | Con justificación en ticket |
| INSERT/UPDATE/DELETE | ⚠️ Excepcional | Solo en incidentes críticos P0/P1 |
| CREATE/ALTER/DROP | ⚠️ Excepcional | Ventana de cambio aprobada + peer review |
| GRANT/REVOKE | ✅ Sí | Según proceso de solicitud aprobado |
| Backup/Restore | ✅ Sí | Procedimiento de disaster recovery |
| Cambios de configuración | ⚠️ Excepcional | Change management + rollback plan |

**Acceso JIT en Producción:**
```bash
# Solicitar acceso temporal (4 horas) vía PAM
gcloud alpha access-context-manager perimeters create temp-dba-access \
  --title="DBA Emergency Access - Ticket INC-12345" \
  --resources=projects/PROJECT_ID \
  --access-levels=HIGH_TRUST_LEVEL \
  --restricted-services=sqladmin.googleapis.com

# El acceso expira automáticamente después de 4 horas
```

### 2.1.3 Mejores Prácticas para DBAs

#### En Producción
- **Siempre** tener un ticket de cambio aprobado antes de ejecutar cambios
- **Nunca** ejecutar scripts ad-hoc sin revisión previa
- **Usar** transacciones y rollback plan para cambios de datos
- **Documentar** cada cambio en el change log
- **Notificar** al equipo de DevOps antes de cambios de configuración

#### Script Seguro en Producción
```sql
-- Siempre usar transacciones para cambios en PRD
BEGIN;

-- Hacer el cambio
UPDATE tabla_critica SET campo = 'nuevo_valor' WHERE condicion = 'xxx';

-- Verificar resultado antes de commit
SELECT COUNT(*) FROM tabla_critica WHERE campo = 'nuevo_valor';

-- Si todo está correcto: COMMIT; si no: ROLLBACK;
COMMIT;
```

### 2.1.4 Auditoría de Acciones DBA
- **Cloud Audit Logs:** Habilitado para todas las operaciones administrativas
- **Query Logs:** Habilitado en Producción con retención de 90 días
- **Revisión:** Auditoría trimestral de acciones de DBAs por CISO

---

## 2.2 DEVOPS - EQUIPO DE DESPLIEGUE

### 2.2.1 Responsabilidades
- Despliegue de aplicaciones y servicios
- Gestión de CI/CD pipelines
- Configuración de conexiones de aplicaciones a BD
- Gestión de Service Accounts para aplicaciones
- Monitoreo de infraestructura y aplicaciones

### 2.2.2 Privilegios por Ambiente

#### DEV — Lectura/Escritura Amplia
```
Rol IAM: roles/cloudsql.client + roles/cloudsql.editor (instancia)
Privilegios BD: readWrite en esquemas de aplicación
```

| Operación | Permitido | Restricción |
|-----------|-----------|-------------|
| SELECT/INSERT/UPDATE | ✅ Sí | Solo en esquemas de aplicación |
| DELETE | ✅ Sí | Solo en esquemas de aplicación |
| CREATE TABLE | ⚠️ Condicional | Solo para tablas temporales de testing |
| ALTER/DROP | ❌ No | Requiere coordinación con DBA |
| GRANT/REVOKE | ❌ No | Solo DBA puede gestionar usuarios |

**PostgreSQL — Ejemplo DEV:**
```sql
CREATE USER devops_jperez WITH PASSWORD 'xxx';
GRANT CONNECT ON DATABASE sistema_dev TO devops_jperez;
GRANT USAGE ON SCHEMA public TO devops_jperez;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO devops_jperez;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO devops_jperez;
```

#### QA — Lectura/Escritura Controlada
```
Rol IAM: roles/cloudsql.client
Privilegios BD: readWrite limitado + SELECT en tablas de sistema
```

| Operación | Permitido | Restricción |
|-----------|-----------|-------------|
| SELECT | ✅ Sí | Todas las tablas (troubleshooting) |
| INSERT/UPDATE | ✅ Sí | Solo vía despliegue automatizado |
| DELETE | ⚠️ Condicional | Solo con aprobación de QA lead |
| CREATE/ALTER/DROP | ❌ No | Coordinación con DBA |
| Despliegue de migraciones | ✅ Sí | Vía CI/CD con revisión automática |

**MySQL — Ejemplo QA:**
```sql
CREATE USER 'devops_jperez'@'%' IDENTIFIED BY 'xxx';
GRANT SELECT, INSERT, UPDATE ON sistema_qa.* TO 'devops_jperez'@'%';
GRANT SELECT ON mysql.* TO 'devops_jperez'@'%'; -- Solo lectura de metadatos
```

#### PRODUCCIÓN — Solo Lectura + Despliegue Automatizado
```
Rol IAM: roles/cloudsql.client (sin privilegios administrativos)
Privilegios BD: READ-ONLY para troubleshooting
Despliegue: Via Service Account en CI/CD
```

| Operación | Permitido | Restricción |
|-----------|-----------|-------------|
| SELECT (troubleshooting) | ✅ Sí | Sin acceso a datos sensibles (PII) |
| INSERT/UPDATE/DELETE | ❌ No | **Solo vía Service Account en CI/CD** |
| CREATE/ALTER/DROP | ❌ No | **Solo vía migraciones en CI/CD** |
| Despliegue manual | ❌ No | Todo debe ser via pipeline automatizado |

**Acceso de DevOps en Producción:**
```sql
-- Usuario personal DevOps: SOLO LECTURA
CREATE USER devops_jperez WITH PASSWORD 'xxx';
GRANT CONNECT ON DATABASE sistema_prd TO devops_jperez;
GRANT USAGE ON SCHEMA public TO devops_jperez;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO devops_jperez;

-- Service Account para CI/CD: LECTURA/ESCRITURA controlada
CREATE USER svc_cicd_deploy WITH PASSWORD 'xxx';
GRANT CONNECT ON DATABASE sistema_prd TO svc_cicd_deploy;
GRANT USAGE ON SCHEMA public TO svc_cicd_deploy;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO svc_cicd_deploy;
```

### 2.2.3 Gestión de Service Accounts

#### Nomenclatura
```
sa-[sistema]-[ambiente]-[funcion]
```
Ejemplos:
- `sa-avanzo-prd-app` — Service Account para la aplicación Avanzo en Producción
- `sa-avanzo-prd-migration` — Service Account para ejecutar migraciones

#### Privilegios de Service Accounts
```sql
-- Service Account para aplicación (runtime)
CREATE USER svc_avanzo_app WITH PASSWORD 'xxx';
GRANT CONNECT ON DATABASE avanzo_prd TO svc_avanzo_app;
GRANT USAGE ON SCHEMA public TO svc_avanzo_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO svc_avanzo_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO svc_avanzo_app;

-- Service Account para migraciones (CI/CD)
CREATE USER svc_avanzo_migration WITH PASSWORD 'xxx';
GRANT CONNECT ON DATABASE avanzo_prd TO svc_avanzo_migration;
GRANT USAGE ON SCHEMA public TO svc_avanzo_migration;
GRANT ALL PRIVILEGES ON SCHEMA public TO svc_avanzo_migration; -- Necesario para migrations
```

#### Rotación de Credenciales
- **Frecuencia:** Cada 90 días (automatizado vía Secret Manager)
- **Proceso:** Rotación sin downtime usando credenciales duales
- **Almacenamiento:** Google Secret Manager (nunca en código o variables de entorno en texto plano)

### 2.2.4 CI/CD y Migraciones de Base de Datos

#### Pipeline de Despliegue — QA y Producción
```yaml
# Ejemplo de pipeline con aprobaciones
stages:
  - test
  - migrate-qa
  - deploy-qa
  - approve-prod  # ⬅️ Aprobación manual obligatoria
  - migrate-prod
  - deploy-prod

migrate-prod:
  stage: migrate-prod
  script:
    - ./run-migrations.sh --env=prod
  only:
    - main
  when: manual  # Requiere aprobación explícita
  needs:
    - approve-prod
```

#### Validaciones Automáticas Pre-Deploy
- [ ] Migraciones tienen rollback definido
- [ ] No hay DROP TABLE/DATABASE en scripts de migración a PRD
- [ ] Peer review de al menos 1 DBA en migrations a PRD
- [ ] Tests de integración pasan en QA
- [ ] Dry-run de migración ejecutado exitosamente en QA

---

## 2.3 DESARROLLADORES

### 2.3.1 Responsabilidades
- Desarrollo de aplicaciones y features
- Escritura de queries y optimización
- Creación de scripts de migración (revisados por DBA)
- Testing de funcionalidades
- Reporte de issues de rendimiento o errores

### 2.3.2 Privilegios por Ambiente

#### DEV — Lectura/Escritura Completa
```
Rol IAM: roles/cloudsql.client
Privilegios BD: readWrite en esquemas de desarrollo
```

| Operación | Permitido | Restricción |
|-----------|-----------|-------------|
| SELECT/INSERT/UPDATE/DELETE | ✅ Sí | En esquemas de desarrollo |
| CREATE TABLE/INDEX | ✅ Sí | Para prototipos y testing |
| ALTER TABLE | ⚠️ Condicional | Coordinar con equipo si afecta otros devs |
| DROP TABLE | ⚠️ Condicional | Solo tablas propias o temporales |
| GRANT/REVOKE | ❌ No | Solo DBA |

**PostgreSQL — Ejemplo DEV:**
```sql
CREATE USER dev_mrodriguez WITH PASSWORD 'xxx';
GRANT CONNECT ON DATABASE sistema_dev TO dev_mrodriguez;
GRANT USAGE, CREATE ON SCHEMA public TO dev_mrodriguez;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO dev_mrodriguez;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO dev_mrodriguez;

-- Permitir creación de tablas temporales
ALTER USER dev_mrodriguez SET search_path TO public, temp_mrodriguez;
```

#### QA — Solo Lectura + Escritura Limitada
```
Rol IAM: roles/cloudsql.client
Privilegios BD: SELECT (general) + INSERT limitado (para testing)
```

| Operación | Permitido | Restricción |
|-----------|-----------|-------------|
| SELECT | ✅ Sí | Todas las tablas (para debugging) |
| INSERT | ⚠️ Condicional | Solo en tablas de testing/sandbox |
| UPDATE/DELETE | ❌ No | Puede corromper tests automatizados |
| CREATE/ALTER/DROP | ❌ No | Solo via migraciones aprobadas |

**SQL Server — Ejemplo QA:**
```sql
CREATE USER dev_mrodriguez WITH PASSWORD = 'xxx';
ALTER ROLE db_datareader ADD MEMBER dev_mrodriguez; -- Lectura completa
GRANT INSERT ON SCHEMA::sandbox TO dev_mrodriguez; -- Escritura solo en sandbox
```

#### PRODUCCIÓN — SIN ACCESO DIRECTO
```
Rol IAM: NINGUNO (sin acceso por defecto)
Privilegios BD: NINGUNO
Excepción: Solo con aprobación de CISO para troubleshooting crítico
```

| Operación | Permitido | Restricción |
|-----------|-----------|-------------|
| Acceso directo | ❌ No | **PROHIBIDO** |
| SELECT (troubleshooting) | ⚠️ Excepcional | Solo con aprobación CISO + sesión supervisada |
| INSERT/UPDATE/DELETE | ❌ No | **NUNCA** |
| Análisis de logs | ✅ Sí | Via Cloud Logging (sin conexión directa a BD) |

### 2.3.3 Acceso Excepcional a Producción

**Solo en caso de incidente crítico P0/P1:**

1. **Solicitud:** Ticket de incidente con justificación
2. **Aprobación:** CISO + Product Owner + DBA Lead
3. **Implementación:** DBA crea usuario temporal con:
   - Expiración automática en 4 horas
   - Solo SELECT en tablas específicas
   - Auditoría en tiempo real
4. **Supervisión:** Sesión grabada y monitoreada por DBA
5. **Revocación:** Automática al expirar o al cerrar incidente

```sql
-- Usuario temporal para troubleshooting en PRD
CREATE USER dev_mrodriguez_temp WITH PASSWORD 'xxx';
GRANT CONNECT ON DATABASE sistema_prd TO dev_mrodriguez_temp;
GRANT USAGE ON SCHEMA public TO dev_mrodriguez_temp;
GRANT SELECT ON tabla_especifica TO dev_mrodriguez_temp; -- Solo tabla del incidente

-- Expiración automática
ALTER USER dev_mrodriguez_temp VALID UNTIL '2026-06-29 18:00:00';
```

### 2.3.4 Desarrollo de Migraciones

#### Requisitos para Scripts de Migración
- [ ] Usar herramienta de migración estándar (Flyway, Liquibase, Alembic, etc.)
- [ ] Incluir script de rollback
- [ ] Versionado secuencial (V001, V002, etc.)
- [ ] Testeado en DEV y QA antes de PRD
- [ ] Peer review por al menos 1 desarrollador senior
- [ ] Revisión por DBA para migraciones a PRD

#### Ejemplo de Migración Segura
```sql
-- V042__add_user_preferences.sql
-- Autor: dev_mrodriguez
-- Fecha: 2026-06-29
-- Ticket: JIRA-1234

BEGIN;

-- Crear tabla con valores por defecto seguros
CREATE TABLE user_preferences (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    preference_key VARCHAR(100) NOT NULL,
    preference_value TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índice para performance
CREATE INDEX idx_user_prefs_user_id ON user_preferences(user_id);

-- Verificación
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_preferences') THEN
        RAISE EXCEPTION 'Migration failed: table not created';
    END IF;
END $$;

COMMIT;

-- Rollback: DROP TABLE user_preferences CASCADE;
```

### 2.3.5 Mejores Prácticas para Desarrolladores

#### Uso de Datos en DEV/QA
- **Nunca** copiar datos de Producción directamente a DEV
- **Usar** datos sintéticos o anonimizados
- **Script de anonimización:** `scripts/anonimizar_datos.sql`

#### Queries Seguras
```python
# ❌ INCORRECTO — Vulnerable a SQL Injection
query = f"SELECT * FROM users WHERE username = '{username}'"

# ✅ CORRECTO — Usar parametrización
query = "SELECT * FROM users WHERE username = %s"
cursor.execute(query, (username,))
```

#### Conexión Segura
```python
# ✅ Usar Cloud SQL Auth Proxy en desarrollo local
import pg8000
import sqlalchemy

# Conexión via Unix socket (Cloud SQL Proxy)
db = sqlalchemy.create_engine(
    sqlalchemy.engine.url.URL.create(
        drivername="postgresql+pg8000",
        username="dev_mrodriguez",
        password=os.environ["DB_PASSWORD"],  # Desde variable de entorno
        database="sistema_dev",
        query={"unix_sock": "/cloudsql/PROJECT:REGION:INSTANCE/.s.PGSQL.5432"}
    )
)
```

---

## 3. PROCESO DE SOLICITUD Y APROBACIÓN

### 3.1 Solicitud de Nuevo Acceso

#### Formulario de Solicitud
- **Nombre completo:** 
- **Email corporativo:** 
- **Rol:** DBA / DevOps / Desarrollador
- **Base de datos:** Nombre de la instancia y base de datos
- **Ambiente:** DEV / QA / PRD
- **Privilegios solicitados:** SELECT / INSERT / UPDATE / DELETE / CREATE / ALTER / DROP
- **Justificación de negocio:** 
- **Periodo de acceso:** Permanente / Temporal (fecha fin)
- **Aprobador (Product Owner):** 

#### Flujo de Aprobación

| Ambiente | Aprobadores Requeridos | SLA |
|----------|----------------------|-----|
| **DEV** | DevOps Lead o DBA | 1 día hábil |
| **QA** | DevOps Lead + Product Owner | 2 días hábiles |
| **PRD** | Product Owner + CISO + DBA Lead | 5 días hábiles |

### 3.2 Modificación de Privilegios Existentes
- Mismo proceso que solicitud nueva
- Justificar cambio de privilegios
- Re-aprobación según ambiente

### 3.3 Revocación de Acceso

#### Revocación Programada
- Cuentas temporales: automática al expirar
- Cambio de rol: dentro de 24 horas de notificación
- Fin de proyecto: dentro de 48 horas

#### Revocación Inmediata
- Terminación de empleo: **inmediata** (parte de offboarding)
- Violación de política: **inmediata**
- Solicitud de Security: **inmediata**

```sql
-- Revocación completa de usuario
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM dev_usuario;
REVOKE USAGE ON SCHEMA public FROM dev_usuario;
REVOKE CONNECT ON DATABASE sistema FROM dev_usuario;
DROP USER dev_usuario;
```

---

## 4. AUDITORÍA Y CUMPLIMIENTO

### 4.1 Auditoría de Accesos

#### Recertificación Trimestral
- Cada 90 días, el Product Owner revisa y confirma accesos
- Lista de usuarios activos enviada por DBA
- Confirmación de necesidad continua de privilegios
- Revocación de accesos no confirmados

#### Checklist de Recertificación
- [ ] Revisar lista completa de usuarios por ambiente
- [ ] Verificar que usuarios aún están en el equipo/proyecto
- [ ] Confirmar que privilegios siguen siendo necesarios
- [ ] Identificar cuentas inactivas (> 60 días sin login)
- [ ] Documentar aprobación o revocación

### 4.2 Monitoreo de Actividad

#### Alertas Automáticas
| Evento | Severidad | Destinatario |
|--------|-----------|--------------|
| Inicio de sesión en PRD fuera de horario laboral | INFO | DBA |
| Ejecución de DROP TABLE/DATABASE en PRD | CRITICAL | DBA + CISO |
| Intento de acceso denegado (fallo autenticación) | WARNING | Security |
| Exportación masiva de datos (> 10k filas) | WARNING | DBA + Product Owner |
| Cambio de privilegios (GRANT/REVOKE) | INFO | DBA Lead |

#### Revisión de Logs
- **Semanal:** Revisión de alertas críticas
- **Mensual:** Análisis de patrones de acceso inusuales
- **Trimestral:** Auditoría completa de compliance

### 4.3 Métricas de Compliance

| Métrica | Meta | Frecuencia |
|---------|------|------------|
| Tiempo de revocación post-offboarding | < 4 horas | Por caso |
| Porcentaje de usuarios con MFA activo | 100% | Mensual |
| Recertificaciones completadas a tiempo | 100% | Trimestral |
| Accesos sin uso > 60 días | < 5% | Mensual |
| Violaciones de política detectadas | 0 | Mensual |

---

## 5. CAPACITACIÓN Y ONBOARDING

### 5.1 Onboarding Obligatorio

#### Para Todos los Roles
- Sesión de inducción sobre políticas de seguridad de BD
- Entrega de guía de buenas prácticas
- Configuración de MFA
- Firma de política de uso aceptable

#### Específico por Rol

**DBA:**
- Capacitación en procedimientos de emergency access
- Uso de herramientas de auditoría
- Proceso de change management

**DevOps:**
- Gestión segura de Service Accounts
- Uso de Cloud SQL Auth Proxy
- Integración de Secret Manager en CI/CD

**Desarrolladores:**
- Prevención de SQL Injection
- Uso de datos anonimizados
- Proceso de creación de migraciones

### 5.2 Capacitación Continua
- **Trimestral:** Security awareness con casos de uso de BD
- **Anual:** Actualización de políticas y procedimientos
- **Ad-hoc:** Capacitación específica tras incidentes

---

## 6. PENALIZACIONES Y CONSECUENCIAS

### 6.1 Violaciones Críticas
- Acceso no autorizado a Producción
- Exportación no autorizada de datos
- Compartir credenciales
- Deshabilitar auditoría intencionalmente
- Modificación de datos en PRD sin aprobación

**Consecuencias:**
1. Revocación inmediata de todos los accesos a BD
2. Reporte a RRHH y management
3. Proceso disciplinario según políticas de empresa
4. Posible terminación de empleo

### 6.2 Violaciones Menores
- No usar MFA
- Acceso desde IP no corporativa sin VPN
- No documentar cambios en QA
- No seguir nomenclatura estándar

**Consecuencias:**
1. Advertencia formal
2. Capacitación obligatoria
3. Suspensión temporal de acceso (segunda infracción)

---

## 7. CONTACTOS Y RECURSOS

### 7.1 Contactos Clave
| Rol | Email | Slack |
|-----|-------|-------|
| **DBA Lead** | dba-lead@dominio.org | @dba-lead |
| **CISO** | ciso@dominio.org | @security-team |
| **DevOps Lead** | devops-lead@dominio.org | @devops-lead |

### 7.2 Canales de Comunicación
- **General:** #db-team
- **Incidentes:** #db-incidents
- **Solicitudes:** #db-access-requests

### 7.3 Documentación de Referencia
- [Scripts de administración](../accesodbs/)
- [Guía de Cloud SQL Auth Proxy](../ConexionIAP-bds.txt)
- [Procedimientos de emergencia](../ADMIN_DB_ORGANIZACION.md#10-procedimientos-de-emergencia)

---

**NOTA:** Esta política es de cumplimiento obligatorio para todo el personal interno. El incumplimiento puede resultar en acciones disciplinarias según políticas de RRHH.
