# MATRIZ DE ACCESOS A BASES DE DATOS

> **Documento consolidado:** consultar [01_Politica_Gestion_Accesos_Bases_Datos.md](01_Politica_Gestion_Accesos_Bases_Datos.md). Este documento se conserva como referencia histórica y no debe utilizarse como política independiente.

> **Documento de Referencia Rápida**  
> **Última actualización:** 2026-06-29

---

## ÍNDICE

1. [Matriz por Rol y Ambiente](#1-matriz-por-rol-y-ambiente)
2. [Matriz por Operación](#2-matriz-por-operación)
3. [Privilegios de Bases de Datos por Motor](#3-privilegios-de-bases-de-datos-por-motor)
4. [Roles IAM de GCP](#4-roles-iam-de-gcp)
5. [Templates de Creación de Usuarios](#5-templates-de-creación-de-usuarios)

---

## 1. MATRIZ POR ROL Y AMBIENTE

### Leyenda
- ✅ **Permitido** — Sin restricciones adicionales
- ⚠️ **Condicional** — Requiere aprobación o circunstancias específicas
- ❌ **Prohibido** — No permitido bajo ninguna circunstancia
- 🔒 **JIT** — Just-In-Time, acceso temporal con aprobación

### 1.1 Personal Interno

| Rol | DEV | QA | PRD |
|-----|-----|-----|-----|
| **DBA** | ✅ Full Admin | ✅ Full Admin (documentado) | 🔒 JIT Admin (4h max, con ticket) |
| **DevOps (Personal)** | ✅ ReadWrite | ✅ ReadOnly | ✅ ReadOnly (sin PII) |
| **DevOps (CI/CD SA)** | ✅ Full Deploy | ✅ Deploy via pipeline | ✅ Deploy via pipeline aprobado |
| **Desarrolladores** | ✅ ReadWrite + CREATE | ✅ ReadOnly + Sandbox INSERT | ❌ Sin acceso (excepto P0/P1) |
| **QA Team** | ✅ ReadWrite (test data) | ✅ ReadWrite (test data) | ❌ Sin acceso |
| **BI/Analytics** | ✅ ReadOnly | ✅ ReadOnly | ✅ ReadOnly (vistas sin PII) |
| **Security/Auditor** | ✅ ReadOnly | ✅ ReadOnly | ✅ ReadOnly (logs + metadata) |

### 1.2 Proveedores Externos

| Tipo de Proveedor | DEV | QA | PRD |
|-------------------|-----|-----|-----|
| **Consultor técnico** | ⚠️ ReadOnly (temporal 30d) | ⚠️ ReadOnly (temporal 30d) | ❌ Prohibido |
| **Desarrollador externo** | ⚠️ ReadWrite (temporal, NDA) | ⚠️ ReadOnly (temporal, NDA) | ❌ Prohibido |
| **Soporte de vendor** | ❌ Excepcional P0 | ❌ Excepcional P0 | ⚠️ P0 crítico (CISO+CTO, supervisado) |
| **Auditor externo** | ✅ ReadOnly (compliance) | ✅ ReadOnly (compliance) | ✅ ReadOnly (compliance, logs) |

---

## 2. MATRIZ POR OPERACIÓN

### 2.1 Operaciones de Lectura

| Operación | DBA | DevOps | Dev | Proveedor | Ambiente |
|-----------|-----|--------|-----|-----------|----------|
| **SELECT (no PII)** | ✅ Todos | ✅ Todos | ✅ DEV, QA | ⚠️ DEV, QA | Todos |
| **SELECT (PII/sensible)** | ✅ PRD JIT | ❌ PRD | ❌ | ❌ | Solo PRD con control |
| **SELECT (logs/metadata)** | ✅ Todos | ✅ Todos | ✅ DEV, QA | ⚠️ Auditor | Todos |
| **EXPLAIN PLAN** | ✅ Todos | ✅ DEV, QA | ✅ DEV, QA | ❌ | DEV, QA |

### 2.2 Operaciones de Escritura (DML)

| Operación | DBA | DevOps (Manual) | DevOps (CI/CD) | Dev | Ambiente |
|-----------|-----|-----------------|----------------|-----|----------|
| **INSERT** | ✅ Todos | ❌ PRD | ✅ PRD pipeline | ✅ DEV, ⚠️ QA sandbox | Según ambiente |
| **UPDATE** | ✅ Todos | ❌ QA, PRD | ✅ PRD pipeline | ✅ DEV | Según ambiente |
| **DELETE** | 🔒 PRD ticket | ❌ QA, PRD | ⚠️ Específico | ✅ DEV | DEV sin restricción |
| **TRUNCATE** | 🔒 Aprobación | ❌ | ❌ | ✅ DEV | Solo DEV |
| **MERGE/UPSERT** | ✅ Todos | ❌ PRD | ✅ PRD pipeline | ✅ DEV | Según ambiente |

### 2.3 Operaciones de Estructura (DDL)

| Operación | DBA | DevOps (CI/CD) | Dev | Ambiente | Restricción |
|-----------|-----|----------------|-----|----------|-------------|
| **CREATE TABLE** | ✅ Todos | ✅ Migrations | ✅ DEV | DEV libre, QA/PRD migration | Versionado obligatorio |
| **ALTER TABLE (ADD COLUMN)** | ✅ Todos | ✅ Migrations | ⚠️ DEV coordinado | Todos | PRD requiere peer review |
| **ALTER TABLE (DROP COLUMN)** | 🔒 Peer review | ⚠️ Migration aprobada | ❌ | QA, PRD | Validar sin uso activo |
| **CREATE INDEX** | ✅ Todos | ✅ Migrations | ✅ DEV | Todos | PRD usar CONCURRENTLY |
| **DROP INDEX** | ✅ Ticket | ✅ Migration | ✅ DEV propios | Todos | Validar impacto performance |
| **DROP TABLE** | 🔒 Peer review + backup | ⚠️ Aprobación CISO | ❌ | Solo con aprobación | PRD requiere backup previo |
| **RENAME TABLE/COLUMN** | ✅ Ventana cambio | ✅ Migration | ⚠️ DEV | Todos | Coordinar con devs |
| **CREATE/DROP DATABASE** | 🔒 CISO aprobación | ❌ | ❌ | Solo DBA | Procedimiento especial |

### 2.4 Operaciones de Control (DCL)

| Operación | DBA | DevOps | Dev | Restricción |
|-----------|-----|--------|-----|-------------|
| **GRANT** | ✅ Proceso aprobación | ❌ | ❌ | Documentar en inventario |
| **REVOKE** | ✅ Inmediato si security | ❌ | ❌ | Notificar a afectado |
| **CREATE USER** | ✅ Proceso aprobación | ❌ | ❌ | Nomenclatura estándar |
| **DROP USER** | ✅ Offboarding | ❌ | ❌ | Verificar sin sesiones activas |
| **ALTER USER (password)** | ✅ | ❌ | ❌ | Rotación 90 días |

### 2.5 Operaciones Administrativas

| Operación | DBA | DevOps | Restricción |
|-----------|-----|--------|-------------|
| **Backup manual** | ✅ | ⚠️ DEV | PRD automático, manual solo emergencia |
| **Restore** | ✅ Proceso DR | ❌ | Ticket + aprobación en PRD |
| **VACUUM/ANALYZE** | ✅ | ❌ | Ventana de mantenimiento en PRD |
| **Reindex** | ✅ | ❌ | Fuera de horas pico en PRD |
| **Modificar configuración** | ✅ Ticket | ❌ | Change management en PRD |
| **Habilitar/Deshabilitar auditoría** | 🔒 CISO | ❌ | Prohibido deshabilitar en PRD |

---

## 3. PRIVILEGIOS DE BASES DE DATOS POR MOTOR

### 3.1 PostgreSQL — Roles Estándar

#### Template: Usuario Solo Lectura
```sql
-- Aplicable: BI, Analytics, Desarrolladores en QA/PRD
CREATE USER usr_nombre WITH PASSWORD 'xxx';
GRANT CONNECT ON DATABASE db_nombre TO usr_nombre;
GRANT USAGE ON SCHEMA public TO usr_nombre;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO usr_nombre;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO usr_nombre;

-- Para tablas futuras
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
  GRANT SELECT ON TABLES TO usr_nombre;
```

#### Template: Usuario Lectura/Escritura (Aplicación)
```sql
-- Aplicable: Service Accounts de aplicaciones
CREATE USER svc_app WITH PASSWORD 'xxx';
GRANT CONNECT ON DATABASE db_nombre TO svc_app;
GRANT USAGE ON SCHEMA public TO svc_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO svc_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO svc_app;

-- Para tablas futuras
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO svc_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
  GRANT USAGE, SELECT ON SEQUENCES TO svc_app;
```

#### Template: DBA (Dev/QA)
```sql
-- Full admin en DEV/QA
CREATE USER dba_eleo WITH PASSWORD 'xxx' SUPERUSER;
GRANT ALL PRIVILEGES ON DATABASE db_nombre TO dba_eleo;
```

#### Template: DBA (PRD) — Sin SUPERUSER permanente
```sql
-- Crear sin SUPERUSER, elevar con JIT cuando se necesite
CREATE USER dba_eleo WITH PASSWORD 'xxx';
GRANT CONNECT ON DATABASE db_nombre TO dba_eleo;
GRANT USAGE ON SCHEMA public TO dba_eleo;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO dba_eleo;

-- Cuando se necesite SUPERUSER (JIT):
ALTER USER dba_eleo WITH SUPERUSER; -- Ticket INC-12345
-- ... realizar operaciones ...
-- Revocar después:
ALTER USER dba_eleo WITH NOSUPERUSER;
```

#### Template: Desarrollador (DEV)
```sql
CREATE USER dev_nombre WITH PASSWORD 'xxx';
GRANT CONNECT ON DATABASE db_nombre TO dev_nombre;
GRANT USAGE, CREATE ON SCHEMA public TO dev_nombre;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO dev_nombre;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO dev_nombre;

-- Permitir crear tablas temporales en su propio esquema
CREATE SCHEMA IF NOT EXISTS temp_dev_nombre AUTHORIZATION dev_nombre;
```

### 3.2 MySQL — Roles Estándar

#### Solo Lectura
```sql
CREATE USER 'usr_nombre'@'%' IDENTIFIED BY 'xxx';
GRANT SELECT ON db_nombre.* TO 'usr_nombre'@'%';
FLUSH PRIVILEGES;
```

#### Lectura/Escritura (Aplicación)
```sql
CREATE USER 'svc_app'@'%' IDENTIFIED BY 'xxx';
GRANT SELECT, INSERT, UPDATE, DELETE ON db_nombre.* TO 'svc_app'@'%';
FLUSH PRIVILEGES;
```

#### DBA (Full Admin)
```sql
CREATE USER 'dba_eleo'@'%' IDENTIFIED BY 'xxx';
GRANT ALL PRIVILEGES ON db_nombre.* TO 'dba_eleo'@'%' WITH GRANT OPTION;
GRANT SUPER ON *.* TO 'dba_eleo'@'%'; -- Solo en DEV/QA
FLUSH PRIVILEGES;
```

#### Desarrollador (DEV)
```sql
CREATE USER 'dev_nombre'@'%' IDENTIFIED BY 'xxx';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, DROP, INDEX 
  ON db_nombre.* TO 'dev_nombre'@'%';
FLUSH PRIVILEGES;
```

### 3.3 SQL Server — Roles Estándar

#### Solo Lectura
```sql
CREATE USER usr_nombre WITH PASSWORD = 'xxx';
ALTER ROLE db_datareader ADD MEMBER usr_nombre;
```

#### Lectura/Escritura (Aplicación)
```sql
CREATE USER svc_app WITH PASSWORD = 'xxx';
ALTER ROLE db_datareader ADD MEMBER svc_app;
ALTER ROLE db_datawriter ADD MEMBER svc_app;
```

#### DBA (Full Admin)
```sql
CREATE USER dba_eleo WITH PASSWORD = 'xxx';
ALTER ROLE db_owner ADD MEMBER dba_eleo;
-- En instancia (solo DEV/QA):
ALTER SERVER ROLE sysadmin ADD MEMBER dba_eleo;
```

#### Desarrollador (DEV)
```sql
CREATE USER dev_nombre WITH PASSWORD = 'xxx';
ALTER ROLE db_datareader ADD MEMBER dev_nombre;
ALTER ROLE db_datawriter ADD MEMBER dev_nombre;
ALTER ROLE db_ddladmin ADD MEMBER dev_nombre; -- Solo DEV
```

---

## 4. ROLES IAM DE GCP

### 4.1 Roles Predefinidos de Cloud SQL

| Rol IAM | Descripción | Uso Típico |
|---------|-------------|------------|
| `roles/cloudsql.admin` | Control total sobre instancias CloudSQL | DBA (con JIT en PRD) |
| `roles/cloudsql.editor` | Modificar configuración, no gestionar usuarios IAM | DevOps Lead |
| `roles/cloudsql.client` | Conectarse a instancias vía Cloud SQL Proxy | Todos los usuarios + Service Accounts |
| `roles/cloudsql.viewer` | Solo lectura de metadatos (no datos de BD) | Auditoría, Monitoreo |
| `roles/cloudsql.instanceUser` | Permiso para autenticación IAM en la BD | Usuarios con auth IAM |

### 4.2 Matriz IAM por Rol

| Rol de Usuario | Proyecto DEV | Proyecto QA | Proyecto PRD |
|----------------|--------------|-------------|--------------|
| **DBA** | `cloudsql.admin` | `cloudsql.admin` | `cloudsql.admin` (JIT) |
| **DevOps** | `cloudsql.editor`<br>`cloudsql.client` | `cloudsql.client` | `cloudsql.client` (solo) |
| **Desarrollador** | `cloudsql.client` | `cloudsql.client` | ❌ Sin rol |
| **Service Account (App)** | `cloudsql.client` | `cloudsql.client` | `cloudsql.client` |
| **Service Account (CI/CD)** | `cloudsql.client` | `cloudsql.client` | `cloudsql.client` |
| **BI/Analytics** | `cloudsql.client` | `cloudsql.client` | `cloudsql.client` |

### 4.3 Comandos de Gestión IAM

#### Otorgar rol a usuario
```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="user:usuario@dominio.org" \
  --role="roles/cloudsql.client"
```

#### Otorgar rol a Service Account
```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:sa-app@PROJECT.iam.gserviceaccount.com" \
  --role="roles/cloudsql.client"
```

#### Revocar rol
```bash
gcloud projects remove-iam-policy-binding PROJECT_ID \
  --member="user:usuario@dominio.org" \
  --role="roles/cloudsql.client"
```

#### Listar roles de un usuario
```bash
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:user:usuario@dominio.org" \
  --format="table(bindings.role)"
```

---

## 5. TEMPLATES DE CREACIÓN DE USUARIOS

### 5.1 Template Completo — PostgreSQL

```sql
-- ============================================
-- TEMPLATE: Crear Usuario en PostgreSQL
-- Ambiente: [DEV / QA / PRD]
-- Rol: [DBA / DevOps / Dev / BI / Proveedor]
-- ============================================

DO $$
DECLARE
    v_username TEXT := 'CAMBIAR_NOMBRE_USUARIO';      -- Ej: dev_jperez
    v_password TEXT := 'CAMBIAR_PASSWORD_SEGURA';     -- Almacenar en Secret Manager
    v_db_name TEXT := 'CAMBIAR_NOMBRE_DB';            -- Ej: sistema_dev
    v_role_type TEXT := 'CAMBIAR_ROL';                -- readonly | readwrite | dba | developer
    v_expiration TEXT := NULL;                        -- Ej: '2026-12-31' para temporal, NULL para permanente
BEGIN
    -- 1. Crear usuario
    EXECUTE format('CREATE USER %I WITH PASSWORD %L', v_username, v_password);
    RAISE NOTICE 'Usuario % creado', v_username;

    -- 2. Configurar expiración si es temporal
    IF v_expiration IS NOT NULL THEN
        EXECUTE format('ALTER USER %I VALID UNTIL %L', v_username, v_expiration);
        RAISE NOTICE 'Expiración configurada: %', v_expiration;
    END IF;

    -- 3. Otorgar privilegios según rol
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO %I', v_db_name, v_username);
    EXECUTE format('GRANT USAGE ON SCHEMA public TO %I', v_username);

    CASE v_role_type
        WHEN 'readonly' THEN
            EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA public TO %I', v_username);
            EXECUTE format('GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO %I', v_username);
            EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO %I', v_username);
            RAISE NOTICE 'Privilegios: READ-ONLY';

        WHEN 'readwrite' THEN
            EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO %I', v_username);
            EXECUTE format('GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO %I', v_username);
            EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO %I', v_username);
            EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO %I', v_username);
            RAISE NOTICE 'Privilegios: READ-WRITE';

        WHEN 'developer' THEN
            EXECUTE format('GRANT USAGE, CREATE ON SCHEMA public TO %I', v_username);
            EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO %I', v_username);
            EXECUTE format('GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO %I', v_username);
            EXECUTE format('CREATE SCHEMA IF NOT EXISTS temp_%s AUTHORIZATION %I', v_username, v_username);
            RAISE NOTICE 'Privilegios: DEVELOPER (con esquema temporal)';

        WHEN 'dba' THEN
            EXECUTE format('ALTER USER %I WITH SUPERUSER', v_username);
            EXECUTE format('GRANT ALL PRIVILEGES ON DATABASE %I TO %I', v_db_name, v_username);
            RAISE NOTICE 'Privilegios: DBA (SUPERUSER)';

        ELSE
            RAISE EXCEPTION 'Rol no válido: %. Usar: readonly, readwrite, developer, dba', v_role_type;
    END CASE;

    RAISE NOTICE '✓ Usuario % creado exitosamente con rol %', v_username, v_role_type;
END $$;

-- 4. Documentar en inventario (manual)
-- Agregar entrada en: ../ADMIN_DB_ORGANIZACION.md sección 3
```

### 5.2 Template Completo — MySQL

```sql
-- ============================================
-- TEMPLATE: Crear Usuario en MySQL
-- Ambiente: [DEV / QA / PRD]
-- Rol: [readonly / readwrite / dba / developer]
-- ============================================

SET @username = 'CAMBIAR_NOMBRE_USUARIO';           -- Ej: 'dev_jperez'
SET @password = 'CAMBIAR_PASSWORD_SEGURA';          -- Almacenar en Secret Manager
SET @db_name = 'CAMBIAR_NOMBRE_DB';                 -- Ej: 'sistema_dev'
SET @role_type = 'CAMBIAR_ROL';                     -- readonly | readwrite | dba | developer
SET @host = '%';                                    -- '%' para cualquier IP, o IP específica

-- 1. Crear usuario
SET @sql = CONCAT('CREATE USER ''', @username, '''@''', @host, ''' IDENTIFIED BY ''', @password, '''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SELECT CONCAT('Usuario ', @username, ' creado') AS Status;

-- 2. Otorgar privilegios según rol

-- READ-ONLY
SET @sql = IF(@role_type = 'readonly',
    CONCAT('GRANT SELECT ON ', @db_name, '.* TO ''', @username, '''@''', @host, ''''),
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- READ-WRITE
SET @sql = IF(@role_type = 'readwrite',
    CONCAT('GRANT SELECT, INSERT, UPDATE, DELETE ON ', @db_name, '.* TO ''', @username, '''@''', @host, ''''),
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- DEVELOPER (DEV only)
SET @sql = IF(@role_type = 'developer',
    CONCAT('GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, DROP, INDEX ON ', @db_name, '.* TO ''', @username, '''@''', @host, ''''),
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- DBA
SET @sql = IF(@role_type = 'dba',
    CONCAT('GRANT ALL PRIVILEGES ON ', @db_name, '.* TO ''', @username, '''@''', @host, ''' WITH GRANT OPTION'),
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 3. Aplicar cambios
FLUSH PRIVILEGES;

SELECT CONCAT('✓ Usuario ', @username, ' configurado con rol ', @role_type) AS Result;

-- 4. Verificar
SELECT User, Host FROM mysql.user WHERE User = @username;
SHOW GRANTS FOR CONCAT(@username, '@', @host);
```

### 5.3 Template Completo — SQL Server

```sql
-- ============================================
-- TEMPLATE: Crear Usuario en SQL Server
-- Ambiente: [DEV / QA / PRD]
-- Rol: [readonly / readwrite / dba / developer]
-- ============================================

DECLARE @username NVARCHAR(128) = 'CAMBIAR_NOMBRE_USUARIO';    -- Ej: dev_jperez
DECLARE @password NVARCHAR(128) = 'CAMBIAR_PASSWORD_SEGURA';   -- Almacenar en Secret Manager
DECLARE @db_name NVARCHAR(128) = 'CAMBIAR_NOMBRE_DB';          -- Ej: sistema_dev
DECLARE @role_type NVARCHAR(20) = 'CAMBIAR_ROL';               -- readonly | readwrite | dba | developer

-- 1. Crear login a nivel de instancia (si no existe)
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @username)
BEGIN
    DECLARE @sql_login NVARCHAR(MAX) = 'CREATE LOGIN [' + @username + '] WITH PASSWORD = ''' + @password + '''';
    EXEC sp_executesql @sql_login;
    PRINT 'Login ' + @username + ' creado';
END

-- 2. Cambiar a la base de datos objetivo
DECLARE @sql_use NVARCHAR(MAX) = 'USE [' + @db_name + ']';
EXEC sp_executesql @sql_use;

-- 3. Crear usuario en la base de datos
DECLARE @sql_user NVARCHAR(MAX) = 'CREATE USER [' + @username + '] FOR LOGIN [' + @username + ']';
EXEC sp_executesql @sql_user;
PRINT 'Usuario ' + @username + ' creado en BD ' + @db_name;

-- 4. Asignar roles según tipo
IF @role_type = 'readonly'
BEGIN
    EXEC sp_executesql N'ALTER ROLE db_datareader ADD MEMBER [@username]', N'@username NVARCHAR(128)', @username;
    PRINT 'Rol asignado: db_datareader';
END

IF @role_type = 'readwrite'
BEGIN
    EXEC sp_executesql N'ALTER ROLE db_datareader ADD MEMBER [@username]', N'@username NVARCHAR(128)', @username;
    EXEC sp_executesql N'ALTER ROLE db_datawriter ADD MEMBER [@username]', N'@username NVARCHAR(128)', @username;
    PRINT 'Roles asignados: db_datareader, db_datawriter';
END

IF @role_type = 'developer'
BEGIN
    EXEC sp_executesql N'ALTER ROLE db_datareader ADD MEMBER [@username]', N'@username NVARCHAR(128)', @username;
    EXEC sp_executesql N'ALTER ROLE db_datawriter ADD MEMBER [@username]', N'@username NVARCHAR(128)', @username;
    EXEC sp_executesql N'ALTER ROLE db_ddladmin ADD MEMBER [@username]', N'@username NVARCHAR(128)', @username;  -- Solo DEV
    PRINT 'Roles asignados: db_datareader, db_datawriter, db_ddladmin';
END

IF @role_type = 'dba'
BEGIN
    EXEC sp_executesql N'ALTER ROLE db_owner ADD MEMBER [@username]', N'@username NVARCHAR(128)', @username;
    PRINT 'Rol asignado: db_owner';
END

-- 5. Verificar
SELECT 
    dp.name AS UserName,
    dp.type_desc AS UserType,
    r.name AS RoleName
FROM sys.database_principals dp
LEFT JOIN sys.database_role_members drm ON dp.principal_id = drm.member_principal_id
LEFT JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
WHERE dp.name = @username;
```

---

## 6. PROCEDIMIENTOS DE REVOCACIÓN

### 6.1 Revocación Completa — PostgreSQL
```sql
DO $$
DECLARE
    v_username TEXT := 'USUARIO_A_REVOCAR';
    v_db_name TEXT := 'NOMBRE_DB';
BEGIN
    -- 1. Terminar sesiones activas
    PERFORM pg_terminate_backend(pid) 
    FROM pg_stat_activity 
    WHERE usename = v_username AND pid <> pg_backend_pid();
    RAISE NOTICE 'Sesiones activas terminadas';

    -- 2. Revocar privilegios
    EXECUTE format('REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM %I', v_username);
    EXECUTE format('REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM %I', v_username);
    EXECUTE format('REVOKE USAGE ON SCHEMA public FROM %I', v_username);
    EXECUTE format('REVOKE CONNECT ON DATABASE %I FROM %I', v_db_name, v_username);
    RAISE NOTICE 'Privilegios revocados';

    -- 3. Eliminar usuario
    EXECUTE format('DROP USER IF EXISTS %I', v_username);
    RAISE NOTICE '✓ Usuario % eliminado completamente', v_username;
END $$;
```

### 6.2 Revocación Completa — MySQL
```sql
SET @username = 'USUARIO_A_REVOCAR';
SET @host = '%';

-- 1. Terminar sesiones activas
SELECT CONCAT('KILL ', id, ';') AS kill_query
FROM information_schema.processlist
WHERE user = @username;
-- Ejecutar manualmente los KILL generados

-- 2. Revocar privilegios y eliminar
SET @sql = CONCAT('DROP USER ''', @username, '''@''', @host, '''');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
FLUSH PRIVILEGES;

SELECT CONCAT('✓ Usuario ', @username, ' eliminado') AS Status;
```

### 6.3 Revocación Completa — SQL Server
```sql
DECLARE @username NVARCHAR(128) = 'USUARIO_A_REVOCAR';
DECLARE @db_name NVARCHAR(128) = 'NOMBRE_DB';

-- 1. Terminar sesiones activas
DECLARE @kill VARCHAR(MAX) = '';
SELECT @kill = @kill + 'KILL ' + CAST(session_id AS VARCHAR(5)) + '; '
FROM sys.dm_exec_sessions
WHERE login_name = @username;
IF @kill != '' EXEC(@kill);

-- 2. Eliminar usuario de la base de datos
DECLARE @sql_user NVARCHAR(MAX) = 'USE [' + @db_name + ']; DROP USER [' + @username + ']';
EXEC sp_executesql @sql_user;

-- 3. Eliminar login de la instancia
DECLARE @sql_login NVARCHAR(MAX) = 'DROP LOGIN [' + @username + ']';
EXEC sp_executesql @sql_login;

PRINT '✓ Usuario ' + @username + ' eliminado completamente';
```

---

## 7. AUDITORÍA DE MATRIZ DE ACCESOS

### 7.1 Verificación de Cumplimiento

#### Checklist Mensual
- [ ] Todos los usuarios activos están documentados en inventario
- [ ] No hay usuarios con privilegios superiores a los aprobados
- [ ] Usuarios temporales vencidos han sido eliminados
- [ ] Service Accounts tienen rotación de credenciales vigente
- [ ] Roles IAM de GCP coinciden con roles de BD

#### Query de Auditoría — PostgreSQL
```sql
-- Listar todos los usuarios y sus privilegios
SELECT 
    u.usename AS usuario,
    CASE 
        WHEN u.usesuper THEN 'SUPERUSER'
        ELSE 'REGULAR'
    END AS tipo,
    u.valuntil AS expiracion,
    array_agg(DISTINCT d.datname) AS databases_acceso
FROM pg_user u
LEFT JOIN pg_database d ON has_database_privilege(u.usename, d.datname, 'CONNECT')
WHERE u.usename NOT LIKE 'pg_%' 
  AND u.usename NOT IN ('postgres', 'cloudsqladmin')
GROUP BY u.usename, u.usesuper, u.valuntil
ORDER BY u.usename;

-- Verificar usuarios vencidos
SELECT usename, valuntil 
FROM pg_user 
WHERE valuntil < NOW() 
  AND usename NOT LIKE 'pg_%';
```

---

**Última revisión:** 2026-06-29  
**Próxima revisión:** 2026-09-29 (trimestral)

**NOTA:** Esta matriz debe actualizarse cada vez que se creen, modifiquen o revoquen accesos.
