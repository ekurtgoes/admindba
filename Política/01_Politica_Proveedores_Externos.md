# POLÍTICA DE ACCESO A BASES DE DATOS — PROVEEDORES EXTERNOS

> **Documento consolidado:** consultar [01_Politica_Gestion_Accesos_Bases_Datos.md](01_Politica_Gestion_Accesos_Bases_Datos.md). Este documento se conserva como referencia histórica y no debe utilizarse como política independiente.

> **Aplicable a:** Contratistas, proveedores de servicios, consultores externos  
> **Nivel de Restricción:** ALTA  
> **Última actualización:** 2026-06-29

---

## 1. PRINCIPIOS GENERALES

### 1.1 Acceso Mínimo y Temporal
- Los proveedores externos deben tener acceso **SOLO** cuando sea estrictamente necesario
- El acceso debe ser **temporal** con fecha de expiración explícita
- Se aplica el principio de **Mínimo Privilegio** de forma estricta

### 1.2 Segregación Total de Producción
- **Prohibido:** Acceso directo a bases de datos de Producción salvo excepciones críticas aprobadas por CISO
- **Preferencia:** Trabajar sobre copias anonimizadas de datos en ambiente DEV/QA

---

## 2. REQUISITOS PREVIOS AL ACCESO

### 2.1 Documentación Obligatoria
Antes de otorgar cualquier acceso, el proveedor debe firmar:

| Documento | Descripción | Responsable |
|-----------|-------------|-------------|
| **NDA (Non-Disclosure Agreement)** | Acuerdo de confidencialidad | Legal |
| **Contrato de Servicios** | Con cláusulas de seguridad y protección de datos | Legal / Compras |
| **Anexo de Seguridad** | Específico para manejo de datos sensibles | CISO |
| **Política de Uso Aceptable** | Compromiso de cumplimiento de políticas internas | RRHH / Security |

### 2.2 Verificación de Identidad
- Verificación de identidad con documento oficial
- Creación de cuenta corporativa temporal (no usar emails personales)
- Autenticación de doble factor (2FA/MFA) **obligatoria**

---

## 3. TIPOS DE ACCESO PERMITIDOS

### 3.1 Solo Lectura (Read-Only) — Ambiente DEV/QA
**Uso típico:** Análisis de datos, troubleshooting, consultoría

| Privilegio | Permitido | Ambiente |
|-----------|-----------|----------|
| SELECT | ✅ Sí | DEV, QA |
| INSERT/UPDATE/DELETE | ❌ No | Ninguno |
| CREATE/ALTER/DROP | ❌ No | Ninguno |
| GRANT/REVOKE | ❌ No | Ninguno |

**Implementación:**
```sql
-- PostgreSQL
CREATE USER proveedor_consultoria WITH PASSWORD 'xxx';
GRANT CONNECT ON DATABASE sistema_dev TO proveedor_consultoria;
GRANT USAGE ON SCHEMA public TO proveedor_consultoria;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO proveedor_consultoria;

-- Expiración automática después de 30 días
ALTER USER proveedor_consultoria VALID UNTIL '2026-07-29';
```

### 3.2 Lectura/Escritura — Solo DEV (Excepcional)
**Uso típico:** Desarrollo de integraciones, migraciones de datos

| Privilegio | Permitido | Ambiente | Aprobación |
|-----------|-----------|----------|-----------|
| SELECT, INSERT, UPDATE | ✅ Sí | DEV únicamente | Product Owner |
| DELETE | ⚠️ Condicional | DEV únicamente | DBA + Product Owner |
| CREATE/ALTER/DROP | ❌ No | Ninguno | N/A |

**Restricciones adicionales:**
- Acceso limitado a tablas/esquemas específicos (NO wildcard `*`)
- Prohibido acceso a tablas de configuración del sistema
- Monitoreo activo de todas las operaciones

### 3.3 Acceso a Producción (Excepcional y Crítico)
**Solo bajo circunstancias excepcionales:**
- Incidente crítico (P0/P1) que requiera soporte del proveedor
- Aprobación **obligatoria** por: CISO + CTO + Product Owner
- Acceso **JIT (Just-In-Time)** por máximo 4 horas

**Condiciones:**
1. Sesión supervisada por DBA interno (screen sharing obligatorio)
2. Grabación de sesión completa
3. Auditoría en tiempo real
4. Revocación automática al finalizar el incidente

---

## 4. MÉTODO DE CONEXIÓN

### 4.1 Conexión Segura Obligatoria
- **Prohibido:** Conexión directa con IP pública
- **Obligatorio:** Cloud SQL Auth Proxy + VPN corporativa o IAP Tunnel

```bash
# Ejemplo de conexión vía Cloud SQL Auth Proxy
./cloud-sql-proxy \
  --private-ip \
  --address 0.0.0.0 \
  --port 5432 \
  PROJECT:REGION:INSTANCE_NAME
```

### 4.2 Autenticación
- **Preferencia:** Autenticación IAM de GCP (si aplica)
- **Alternativa:** Usuario/contraseña almacenada en Secret Manager
- **Obligatorio:** Rotación de credenciales cada 30 días para proveedores
- **MFA:** Autenticación de doble factor en la cuenta de GCP

### 4.3 IP Whitelisting
- Solo IPs corporativas del proveedor (oficinas, no IPs residenciales)
- Registradas y aprobadas en firewall de GCP
- Revisión mensual de IPs autorizadas

---

## 5. AUDITORÍA Y MONITOREO

### 5.1 Registro Obligatorio de Actividad
Todas las acciones del proveedor deben ser registradas:

| Evento | Registro | Alerta |
|--------|----------|--------|
| Inicio de sesión | ✅ Cloud Audit Logs | ✅ Notificación a DBA |
| Query SELECT | ✅ Query Logs | ❌ No |
| Query INSERT/UPDATE/DELETE | ✅ Query Logs | ✅ Alerta inmediata |
| Intento de DROP/ALTER | ✅ Audit Logs | ✅ Alerta crítica + Bloqueo |
| Exportación masiva de datos | ✅ Logs | ✅ Alerta crítica |

### 5.2 Revisión de Actividad
- **Diaria:** Durante el periodo de acceso activo
- **Semanal:** Informe de actividad al Product Owner
- **Al término:** Informe completo de todas las acciones realizadas

---

## 6. DATOS SENSIBLES Y ANONIMIZACIÓN

### 6.1 Prohibición de Datos Personales en Ambientes No Productivos
- **DEV/QA:** Deben contener datos **anonimizados** o **sintéticos**
- **Prohibido:** Copiar datos reales de Producción sin anonimizar

### 6.2 Anonimización Obligatoria
Para cualquier copia de datos a ambientes de trabajo:

| Campo Sensible | Técnica de Anonimización |
|----------------|-------------------------|
| Nombre completo | Reemplazo con nombres ficticios |
| Email | `usuario_xxx@ejemplo.com` |
| Teléfono | Enmascaramiento: `+506-XXXX-1234` |
| Identificación (cédula, SSN) | Hash irreversible o valor ficticio |
| Dirección | Dirección genérica por región |
| Datos médicos (HIPAA) | Eliminación o hash criptográfico |

**Script de referencia:** `scripts/anonimizacion_datos.sql`

---

## 7. VIGENCIA Y RENOVACIÓN

### 7.1 Periodo Máximo de Acceso
- **Inicial:** 30 días (prorrogable)
- **Renovación:** Requiere nueva solicitud y aprobación
- **Máximo acumulado:** 6 meses (después requiere re-evaluación completa)

### 7.2 Expiración Automática
```sql
-- Implementar en PostgreSQL
ALTER USER proveedor_xxx VALID UNTIL '2026-07-29 23:59:59';

-- Implementar en MySQL
CREATE USER 'proveedor_xxx'@'%' 
  IDENTIFIED BY 'xxx' 
  PASSWORD EXPIRE INTERVAL 30 DAY;
```

### 7.3 Revocación Inmediata
El acceso se revoca **inmediatamente** en estos casos:
- Finalización del contrato de servicios
- Detección de uso indebido o violación de políticas
- Solicitud del Product Owner o CISO
- Fin del proyecto para el cual se otorgó acceso

---

## 8. PROCESO DE SOLICITUD

### 8.1 Flujo de Aprobación

```
1. Proveedor/Sponsor solicita acceso → Ticket en sistema ITSM
   ↓
2. Product Owner aprueba necesidad de negocio
   ↓
3. CISO/Security revisa riesgos y aprueba controles
   ↓
4. Legal verifica firma de NDA y contratos
   ↓
5. DBA implementa acceso con restricciones técnicas
   ↓
6. Notificación al proveedor con instrucciones de conexión
```

### 8.2 Información Requerida en Solicitud
- Nombre completo del proveedor
- Empresa/Organización
- Email corporativo (no personal)
- Justificación de negocio detallada
- Bases de datos y tablas específicas requeridas
- Tipo de privilegios necesarios
- Periodo de acceso requerido (fecha inicio - fecha fin)
- Aprobación del sponsor interno

**Formulario:** `formularios/solicitud_acceso_proveedor.md`

---

## 9. CAPACITACIÓN Y ONBOARDING

### 9.1 Obligatorio Antes del Acceso
- Sesión de inducción sobre políticas de seguridad (30 min)
- Entrega de guía de buenas prácticas
- Confirmación de lectura y comprensión de esta política

### 9.2 Materiales Entregados
- Guía de conexión segura
- Política de uso aceptable
- Contactos de emergencia (DBA, Security)
- Procedimiento de reporte de incidentes

---

## 10. PENALIZACIONES Y CONSECUENCIAS

### 10.1 Violaciones Graves
- Intento de acceso no autorizado a datos
- Exportación no autorizada de información
- Compartir credenciales con terceros
- Acceso desde ubicaciones no autorizadas

**Consecuencias:**
1. Revocación inmediata de todos los accesos
2. Reporte al sponsor interno y management del proveedor
3. Posible terminación del contrato
4. Acciones legales según gravedad

### 10.2 Violaciones Menores
- No usar MFA
- Conexión desde IP no autorizada
- No reportar incidentes de seguridad

**Consecuencias:**
1. Advertencia formal
2. Suspensión temporal de acceso
3. Re-capacitación obligatoria

---

## 11. CHECKLIST DE IMPLEMENTACIÓN

### Para el DBA
- [ ] Verificar firma de NDA y contratos
- [ ] Crear usuario con nomenclatura: `ext_[empresa]_[nombre]`
- [ ] Configurar expiración automática (30 días)
- [ ] Limitar privilegios al mínimo necesario
- [ ] Configurar auditoría específica para el usuario
- [ ] Agregar IP autorizada al firewall (si aplica)
- [ ] Documentar en inventario de usuarios externos
- [ ] Enviar instrucciones de conexión vía canal seguro
- [ ] Configurar alerta de monitoreo activo

### Para el Proveedor
- [ ] Firmar NDA y documentos de seguridad
- [ ] Configurar MFA en cuenta de GCP
- [ ] Leer y confirmar política de uso aceptable
- [ ] Asistir a sesión de inducción
- [ ] Probar conexión en presencia del DBA
- [ ] Reportar cualquier incidente de seguridad inmediatamente

---

## 12. CONTACTOS Y SOPORTE

| Rol | Contacto | Propósito |
|-----|----------|-----------|
| **DBA Principal** | dba@dominio.org | Solicitudes técnicas, troubleshooting |
| **CISO / Security** | security@dominio.org | Incidentes de seguridad, aprobaciones críticas |
| **Product Owner** | [específico por proyecto] | Aprobación de negocio |

**Canal Slack:** #external-access-support (solo para sponsors internos)

---

**NOTA LEGAL:** Esta política es parte integral del contrato de servicios. El incumplimiento puede resultar en terminación del contrato y acciones legales según aplique.
