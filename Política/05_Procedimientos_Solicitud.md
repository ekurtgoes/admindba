# PROCEDIMIENTOS DE SOLICITUD DE ACCESO A BASES DE DATOS

> **Documento Operativo**  
> **Última actualización:** 2026-06-29

---

## ÍNDICE

1. [Proceso General de Solicitud](#1-proceso-general-de-solicitud)
2. [Formularios de Solicitud](#2-formularios-de-solicitud)
3. [Flujos de Aprobación](#3-flujos-de-aprobación)
4. [Tiempos de Respuesta (SLA)](#4-tiempos-de-respuesta-sla)
5. [Implementación Técnica](#5-implementación-técnica)
6. [Notificaciones y Seguimiento](#6-notificaciones-y-seguimiento)
7. [Casos Especiales](#7-casos-especiales)

---

## 1. PROCESO GENERAL DE SOLICITUD

### 1.1 Diagrama de Flujo

```
┌─────────────────────────────────────────────┐
│ 1. SOLICITANTE                              │
│    - Completa formulario                    │
│    - Justifica necesidad de negocio         │
└──────────────┬──────────────────────────────┘
               ↓
┌──────────────┴──────────────────────────────┐
│ 2. VALIDACIÓN INICIAL (DBA)                 │
│    - Verifica formato correcto              │
│    - Valida nomenclatura                    │
│    - Confirma que DB/ambiente existen       │
└──────────────┬──────────────────────────────┘
               ↓
┌──────────────┴──────────────────────────────┐
│ 3. APROBACIÓN DE NEGOCIO                    │
│    - Product Owner (obligatorio)            │
│    - Manager del solicitante (opcional)     │
└──────────────┬──────────────────────────────┘
               ↓
┌──────────────┴──────────────────────────────┐
│ 4. APROBACIÓN DE SEGURIDAD                  │
│    - DEV/QA: Automático si Product Owner OK │
│    - PRD: CISO/Security Lead (obligatorio)  │
└──────────────┬──────────────────────────────┘
               ↓
┌──────────────┴──────────────────────────────┐
│ 5. IMPLEMENTACIÓN TÉCNICA (DBA)             │
│    - Crear usuario según template           │
│    - Configurar IAM en GCP                  │
│    - Documentar en inventario               │
└──────────────┬──────────────────────────────┘
               ↓
┌──────────────┴──────────────────────────────┐
│ 6. ENTREGA Y ONBOARDING                     │
│    - Enviar credenciales vía canal seguro   │
│    - Instrucciones de conexión              │
│    - Guía de buenas prácticas               │
└─────────────────────────────────────────────┘
```

### 1.2 Principios del Proceso

1. **Transparencia:** Todo acceso debe tener justificación documentada
2. **Trazabilidad:** Cada solicitud genera un ticket rastreable
3. **Separación de funciones:** Quien solicita no aprueba
4. **Mínimo privilegio:** Otorgar solo lo estrictamente necesario
5. **Tiempo limitado:** Accesos temporales con expiración automática

---

## 2. FORMULARIOS DE SOLICITUD

### 2.1 Solicitud de Acceso — Personal Interno

**Ubicación:** JIRA / ServiceNow / Sistema ITSM  
**Tipo de ticket:** Access Request — Database  
**Template:** `DB-ACCESS-INTERNAL`

#### Información Requerida

```yaml
# DATOS DEL SOLICITANTE
Nombre completo: _______________________
Email corporativo: _____________________
Rol/Equipo: ____________________________
Manager directo: _______________________

# ACCESO SOLICITADO
Proyecto GCP: __________________________
Instancia CloudSQL: ____________________
Nombre de base de datos: _______________
Ambiente: [ ] DEV  [ ] QA  [ ] PRODUCCIÓN

# PRIVILEGIOS
Tipo de acceso solicitado:
  [ ] Solo lectura (SELECT)
  [ ] Lectura/Escritura (SELECT, INSERT, UPDATE)
  [ ] Lectura/Escritura/Eliminación (incluye DELETE)
  [ ] Administrador (DDL - CREATE, ALTER, DROP)
  [ ] DBA (control total)

Tablas/Esquemas específicos (si no es todas):
  _____________________________________________

# JUSTIFICACIÓN
Motivo de negocio (detallado):
  _____________________________________________
  _____________________________________________

Tareas específicas que realizará:
  _____________________________________________

Periodo de acceso:
  [ ] Permanente (mientras esté en el rol/proyecto)
  [ ] Temporal — Fecha inicio: _____ Fecha fin: _____

# APROBADORES
Product Owner / Dueño de la BD: _______________
Security Lead (solo PRD): ___________________

# INFORMACIÓN ADICIONAL
¿Ha leído la Política de Acceso a BD?: [ ] Sí [ ] No
¿Requiere capacitación de conexión?: [ ] Sí [ ] No
```

**Enviar a:** db-access-requests@dominio.org  
**CC:** Product Owner del sistema

---

### 2.2 Solicitud de Acceso — Proveedores Externos

**Template:** `DB-ACCESS-EXTERNAL`

#### Pre-Requisitos Obligatorios
- [ ] NDA firmado y vigente
- [ ] Contrato de servicios con anexo de seguridad
- [ ] Sponsor interno identificado
- [ ] Verificación de identidad completada

#### Información Requerida

```yaml
# DATOS DEL PROVEEDOR
Nombre completo: _______________________
Email corporativo (NO personal): ________
Empresa/Organización: __________________
Tipo de proveedor:
  [ ] Consultor técnico
  [ ] Desarrollador externo
  [ ] Soporte de vendor
  [ ] Auditor externo

# SPONSOR INTERNO
Nombre del sponsor: ____________________
Relación con el proyecto: ______________
Aprobación del sponsor: [ ] Aprobado [ ] Pendiente

# ACCESO SOLICITADO
Proyecto GCP: __________________________
Instancia CloudSQL: ____________________
Nombre de base de datos: _______________
Ambiente: 
  [ ] DEV (permitido con restricciones)
  [ ] QA (permitido con restricciones)
  [ ] PRODUCCIÓN (solo excepciones críticas)

# PRIVILEGIOS (Limitados)
Tipo de acceso solicitado:
  [ ] Solo lectura (único permitido por defecto)
  [ ] Lectura/Escritura en DEV (requiere NDA + aprobación CISO)

Periodo de acceso (MÁXIMO 30 días inicial):
  Fecha inicio: _____
  Fecha fin: _____

# JUSTIFICACIÓN
Motivo de necesidad del acceso:
  _____________________________________________

Entregables del proyecto:
  _____________________________________________

¿Por qué se necesita acceso a datos reales?:
  _____________________________________________

Alternativas consideradas (ej. datos sintéticos):
  _____________________________________________

# SEGURIDAD
IP(s) desde donde se conectará: ____________
¿Usará VPN corporativa?: [ ] Sí [ ] No
MFA configurado: [ ] Sí [ ] No [ ] Requiere setup

# APROBACIONES (Todas obligatorias)
Product Owner: _________________________
CISO / Security Lead: __________________
Legal (NDA verificado): ________________
Sponsor interno: _______________________

# DOCUMENTACIÓN ADJUNTA
[ ] NDA firmado (PDF)
[ ] Anexo de seguridad del contrato
[ ] Identificación oficial (copia)
[ ] Carta de autorización de la empresa proveedora
```

**Enviar a:** external-access@dominio.org  
**CC:** security@dominio.org, sponsor interno

---

### 2.3 Solicitud de Modificación de Privilegios

**Template:** `DB-ACCESS-MODIFY`

```yaml
# IDENTIFICACIÓN
Usuario existente: _____________________
Instancia/BD actual: ___________________
Ambiente: [ ] DEV  [ ] QA  [ ] PRD

# CAMBIO SOLICITADO
Privilegios actuales: __________________
Nuevos privilegios solicitados: ________

Motivo del cambio:
  [ ] Cambio de rol/responsabilidades
  [ ] Proyecto temporal finalizado
  [ ] Necesidad adicional por nuevo proyecto
  [ ] Corrección de over-provisioning

Justificación detallada:
  _____________________________________________

# APROBACIÓN
Product Owner: _________________________
Security (si es PRD): __________________

# VALIDACIÓN DBA
Verificar que privilegios actuales coinciden: [ ]
Validar que cambio es necesario: [ ]
```

---

### 2.4 Solicitud de Revocación de Acceso

**Template:** `DB-ACCESS-REVOKE`

```yaml
# IDENTIFICACIÓN
Usuario a revocar: _____________________
Instancia(s) afectada(s): ______________
Ambiente(s): [ ] DEV  [ ] QA  [ ] PRD  [ ] TODOS

# MOTIVO DE REVOCACIÓN
  [ ] Finalización de contrato/empleo
  [ ] Cambio de rol (ya no requiere acceso)
  [ ] Proyecto finalizado
  [ ] Violación de política de seguridad
  [ ] Cuenta inactiva (> 60 días sin uso)
  [ ] Solicitud del usuario
  [ ] Otro: _____________________________

# URGENCIA
  [ ] Normal (proceso estándar: 24-48h)
  [ ] Urgente (offboarding: 4 horas)
  [ ] CRÍTICO (incidente de seguridad: INMEDIATO)

# SOLICITANTE
Nombre: ________________________________
Rol: ___________________________________
Autorización: __________________________

# VALIDACIÓN DBA
Verificar sesiones activas antes de revocar: [ ]
Documentar en inventario: [ ]
Notificar al usuario (si aplica): [ ]
```

---

## 3. FLUJOS DE APROBACIÓN

### 3.1 Matriz de Aprobadores por Tipo de Solicitud

| Tipo de Solicitud | Ambiente | Aprobadores Requeridos | Orden |
|-------------------|----------|----------------------|-------|
| **Personal Interno — Lectura** | DEV | Product Owner | 1 nivel |
| **Personal Interno — Lectura** | QA | Product Owner | 1 nivel |
| **Personal Interno — Lectura** | PRD | Product Owner → Security Lead | 2 niveles |
| **Personal Interno — Escritura** | DEV | Product Owner | 1 nivel |
| **Personal Interno — Escritura** | QA | Product Owner → DevOps Lead | 2 niveles |
| **Personal Interno — Escritura** | PRD | Product Owner → CISO → DBA Lead | 3 niveles |
| **Personal Interno — DBA** | DEV/QA | DBA Lead | 1 nivel |
| **Personal Interno — DBA** | PRD | DBA Lead → CISO | 2 niveles |
| **Proveedor Externo — Lectura** | DEV/QA | Sponsor → Product Owner → Security → Legal | 4 niveles |
| **Proveedor Externo — Escritura** | DEV | Sponsor → Product Owner → CISO | 3 niveles |
| **Proveedor Externo — Cualquier** | PRD | Sponsor → Product Owner → CISO → CTO → Legal | 5 niveles |
| **Modificación privilegios** | Cualquiera | Mismos aprobadores que solicitud original | N/A |
| **Revocación normal** | Cualquiera | Manager o Product Owner | 1 nivel |
| **Revocación por security** | Cualquiera | CISO (automática) | 0 niveles |

### 3.2 Delegación de Aprobaciones

#### Aprobaciones Delegables
- **Product Owner:** Puede delegar a Tech Lead o Product Manager
- **DevOps Lead:** Puede delegar a DevOps Senior
- **DBA Lead:** Puede delegar a DBA Senior (solo DEV/QA)

#### Aprobaciones NO Delegables
- **CISO / Security Lead:** No delegable
- **CTO:** No delegable
- **Legal:** No delegable

#### Proceso de Delegación
```yaml
1. Aprobador original registra delegado en sistema ITSM
2. Delegación válida por máximo 30 días
3. Re-aprobación del aprobador original al retornar
4. Notificación automática de delegación activa
```

---

## 4. TIEMPOS DE RESPUESTA (SLA)

### 4.1 SLA por Tipo y Ambiente

| Tipo de Solicitud | Ambiente | Tiempo Máximo | Métrica |
|-------------------|----------|---------------|---------|
| **Lectura — Personal interno** | DEV | 1 día hábil | 95% cumplimiento |
| **Lectura — Personal interno** | QA | 2 días hábiles | 95% cumplimiento |
| **Lectura — Personal interno** | PRD | 5 días hábiles | 90% cumplimiento |
| **Escritura — Personal interno** | DEV | 1 día hábil | 95% cumplimiento |
| **Escritura — Personal interno** | QA | 3 días hábiles | 90% cumplimiento |
| **Escritura — Personal interno** | PRD | 7 días hábiles | 85% cumplimiento |
| **Proveedor externo** | DEV/QA | 5-7 días hábiles | 85% cumplimiento |
| **Proveedor externo** | PRD | 10-15 días hábiles | 80% cumplimiento |
| **Modificación** | Cualquiera | Igual que solicitud original | N/A |
| **Revocación normal** | Cualquiera | 24 horas | 100% cumplimiento |
| **Revocación offboarding** | Cualquiera | 4 horas | 100% cumplimiento |
| **Revocación por incidente** | Cualquiera | INMEDIATO (< 30 min) | 100% cumplimiento |

### 4.2 Excepciones de SLA

#### Fast-Track (Acelerado)
Aplica para:
- Incidentes de producción (P0/P1) que requieran acceso urgente
- Nuevos empleados con fecha de inicio inminente
- Auditorías programadas con fecha límite

**Proceso:**
1. Marcar ticket como "URGENT — Fast-Track"
2. Justificación de urgencia obligatoria
3. Aprobación de VP/C-level requerida
4. SLA reducido a: 4 horas (PRD lectura), 8 horas (PRD escritura)

---

## 5. IMPLEMENTACIÓN TÉCNICA

### 5.1 Checklist de Implementación para DBA

#### Antes de Crear el Usuario
- [ ] Ticket aprobado por todos los aprobadores requeridos
- [ ] Validar que usuario no existe ya en el sistema
- [ ] Validar nomenclatura según estándar (ej: `dev_jperez`, `svc_app`)
- [ ] Generar contraseña segura (min 16 caracteres, almacenar en Secret Manager)
- [ ] Verificar que BD/esquema objetivo existe

#### Durante la Creación
- [ ] Ejecutar template de creación correspondiente al rol
- [ ] Configurar expiración si es acceso temporal
- [ ] Limitar privilegios al mínimo necesario (PoLP)
- [ ] Configurar auditoría específica si es PRD
- [ ] Asignar roles IAM en GCP si corresponde

#### Después de Crear el Usuario
- [ ] Documentar en inventario de usuarios (ADMIN_DB_ORGANIZACION.md)
- [ ] Almacenar credenciales en Secret Manager
- [ ] Generar instrucciones de conexión personalizadas
- [ ] Programar recordatorio de revisión (30/60/90 días según tipo)

### 5.2 Plantilla de Instrucciones de Conexión

**Enviar al usuario vía canal seguro (email corporativo cifrado o Slack privado)**

```markdown
# Instrucciones de Conexión — Base de Datos

**Usuario:** {NOMBRE_USUARIO}
**Base de Datos:** {NOMBRE_DB}
**Ambiente:** {DEV/QA/PRD}
**Vigencia:** {FECHA_EXPIRACION o "Permanente mientras esté en el proyecto"}

---

## Credenciales

**IMPORTANTE:** Estas credenciales son personales e intransferibles.

- **Usuario:** `{USUARIO}`
- **Contraseña:** Se encuentra en Google Secret Manager:
  ```
  gcloud secrets versions access latest --secret="{SECRET_NAME}"
  ```

**Rotación de contraseña:** Cada 90 días (automática para Service Accounts)

---

## Método de Conexión (Cloud SQL Auth Proxy)

### 1. Instalar Cloud SQL Auth Proxy
```bash
# Linux/Mac
curl -o cloud-sql-proxy \
  https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.8.1/cloud-sql-proxy.linux.amd64
chmod +x cloud-sql-proxy

# Windows
curl -o cloud-sql-proxy.exe \
  https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.8.1/cloud-sql-proxy.x64.exe
```

### 2. Autenticarse en GCP
```bash
gcloud auth login
gcloud config set project {PROJECT_ID}
```

### 3. Ejecutar el Proxy
```bash
# PostgreSQL
./cloud-sql-proxy --private-ip --address 0.0.0.0 --port 5432 \
  {PROJECT_ID}:{REGION}:{INSTANCE_NAME}

# MySQL
./cloud-sql-proxy --private-ip --address 0.0.0.0 --port 3306 \
  {PROJECT_ID}:{REGION}:{INSTANCE_NAME}

# SQL Server
./cloud-sql-proxy --private-ip --address 0.0.0.0 --port 1433 \
  {PROJECT_ID}:{REGION}:{INSTANCE_NAME}
```

### 4. Conectarse con tu cliente favorito

**Parámetros de conexión:**
- Host: `localhost`
- Puerto: `{5432|3306|1433}`
- Usuario: `{USUARIO}`
- Contraseña: (obtener de Secret Manager)
- Base de datos: `{NOMBRE_DB}`

---

## Restricciones y Responsabilidades

✅ **Puedes:**
{LISTA_PERSONALIZADA_SEGUN_ROL}

❌ **NO puedes:**
{LISTA_PERSONALIZADA_SEGUN_ROL}

📋 **Recuerda:**
- Usar MFA en tu cuenta de GCP (obligatorio)
- No compartir credenciales con nadie
- Reportar cualquier incidente de seguridad a security@dominio.org
- Cerrar sesiones al terminar de trabajar

---

## Soporte

- **Problemas de conexión:** #db-support (Slack)
- **Solicitudes de cambio de privilegios:** db-access-requests@dominio.org
- **Incidentes de seguridad:** security@dominio.org

**Documentación:** {LINK_A_POLITICAS}

---

*Este acceso está sujeto a la Política de Administración de Accesos a Bases de Datos. El incumplimiento puede resultar en revocación inmediata.*
```

---

## 6. NOTIFICACIONES Y SEGUIMIENTO

### 6.1 Notificaciones Automáticas

| Evento | Destinatarios | Canal | Template |
|--------|--------------|-------|----------|
| **Solicitud creada** | Solicitante, Aprobadores | Email | `NOTIF_REQ_CREATED` |
| **Aprobación pendiente** | Aprobador actual | Email + Slack | `NOTIF_APPROVAL_PENDING` |
| **Solicitud aprobada** | Solicitante, DBA | Email | `NOTIF_REQ_APPROVED` |
| **Solicitud rechazada** | Solicitante, Manager | Email | `NOTIF_REQ_REJECTED` |
| **Acceso creado** | Solicitante | Email cifrado | `NOTIF_ACCESS_GRANTED` |
| **Acceso próximo a expirar** | Usuario, Manager | Email (7 días antes) | `NOTIF_ACCESS_EXPIRING` |
| **Acceso expirado** | Usuario, Manager, DBA | Email | `NOTIF_ACCESS_EXPIRED` |
| **Acceso revocado** | Usuario, Manager | Email | `NOTIF_ACCESS_REVOKED` |

### 6.2 Recordatorios de Recertificación

```yaml
Frecuencia: Trimestral (cada 90 días)
Destinatario: Product Owner de cada sistema
Contenido:
  - Lista de usuarios activos en sus BD
  - Privilegios otorgados
  - Última fecha de uso
  - Fecha de última revisión

Acción requerida: Confirmar o revocar cada acceso
Deadline: 15 días naturales
Escalación: DBA Lead + CISO si no se completa a tiempo
```

---

## 7. CASOS ESPECIALES

### 7.1 Acceso de Emergencia (Break-Glass)

**Escenario:** Incidente crítico (P0) en Producción, requiere acceso inmediato

#### Proceso Acelerado
```
1. Incidente P0 declarado en sistema de alertas
   ↓
2. On-Call DBA otorga acceso temporal (max 4 horas)
   ↓
3. Notificación inmediata a CISO + DBA Lead
   ↓
4. Sesión auditada en tiempo real
   ↓
5. Revocación automática al expirar
   ↓
6. Post-mortem obligatorio dentro de 48 horas
```

#### Documentación Posterior (Obligatoria)
- Ticket de incidente vinculado
- Justificación de acceso emergencia
- Log de acciones realizadas
- Aprobación retroactiva de CISO (dentro de 24h)

### 7.2 Acceso para Auditoría de Compliance

**Aprobadores:** CISO + Legal  
**Privilegios:** Solo lectura + acceso a logs/metadatos  
**Duración:** Según plan de auditoría (típicamente 2-4 semanas)

#### Requisitos Específicos
- [ ] Plan de auditoría recibido con alcance definido
- [ ] Auditor identificado (interno o externo certificado)
- [ ] NDA firmado (si es auditor externo)
- [ ] Ambiente aislado para análisis (preferido)
- [ ] Sesiones grabadas

### 7.3 Service Accounts para Aplicaciones

**Proceso diferenciado:**

```yaml
Solicitante: DevOps o Tech Lead de la aplicación
Aprobadores:
  - Product Owner
  - Security Lead (siempre, incluso en DEV)

Implementación:
  1. Crear Service Account en GCP IAM
     Nomenclatura: sa-{sistema}-{ambiente}-{funcion}
  2. Asignar rol IAM: roles/cloudsql.client
  3. Crear usuario en BD vinculado al SA
  4. Almacenar credenciales en Secret Manager
  5. Configurar rotación automática (90 días)
  6. Integrar en CI/CD o aplicación

Auditoría adicional:
  - Revisión trimestral de uso
  - Validar que aplicación sigue activa
  - Confirmar que privilegios son mínimos necesarios
```

### 7.4 Acceso de Lectura para BI/Analytics

**Consideraciones especiales:**

```yaml
Datos sensibles:
  - Crear VISTAS que excluyan columnas PII
  - Ejemplo: users_analytics (sin email, teléfono, dirección)

Performance:
  - Limitar queries a réplicas de lectura (no instancia principal)
  - Configurar query timeout (ej. 5 minutos max)

Monitoreo:
  - Alertas de queries lentas que impacten performance
  - Dashboard de uso de recursos por usuario BI
```

---

## 8. MÉTRICAS Y REPORTING

### 8.1 Métricas de Proceso

| Métrica | Objetivo | Frecuencia de Reporte |
|---------|----------|---------------------|
| **Tiempo promedio de aprobación** | < SLA definido | Mensual |
| **% de solicitudes rechazadas** | < 10% | Mensual |
| **% de solicitudes aprobadas dentro de SLA** | > 90% | Mensual |
| **Tiempo promedio de implementación (DBA)** | < 4 horas | Mensual |
| **Número de accesos revocados por inactividad** | Tendencia | Trimestral |
| **% de recertificaciones completadas a tiempo** | 100% | Trimestral |

### 8.2 Reporte Mensual a Management

**Destinatarios:** CISO, CTO, DBA Lead  
**Contenido:**
- Total de solicitudes recibidas (por tipo y ambiente)
- Solicitudes aprobadas vs rechazadas
- Tiempo promedio de procesamiento
- Accesos revocados (motivo de revocación)
- Violaciones de política detectadas
- Tendencias y recomendaciones

---

## 9. MEJORA CONTINUA

### 9.1 Revisión del Proceso

**Frecuencia:** Semestral  
**Participantes:** DBA Lead, Security Lead, Product Owners, DevOps Lead

**Agenda:**
- Revisar métricas de eficiencia del proceso
- Identificar cuellos de botella
- Evaluar feedback de usuarios
- Proponer mejoras al flujo
- Actualizar templates y formularios

### 9.2 Automatizaciones Recomendadas

**Prioridad ALTA:**
- Integración ITSM → GCP IAM (auto-aprovisionamiento)
- Revocación automática de accesos expirados
- Alertas de recertificación a Product Owners

**Prioridad MEDIA:**
- Validación automática de nomenclatura en formularios
- Dashboard de accesos activos en tiempo real
- Chatbot para consultas frecuentes de acceso

**Prioridad BAJA:**
- Auto-aprobación para renovaciones sin cambio
- Integración con sistema de onboarding/offboarding de RRHH

---

## ANEXOS

### Anexo A: Links a Formularios
- **Solicitud Interna:** {JIRA_TEMPLATE_LINK}
- **Solicitud Externa:** {SERVICEDESK_TEMPLATE_LINK}
- **Modificación:** {CHANGE_REQUEST_LINK}
- **Revocación:** {REVOCATION_FORM_LINK}

### Anexo B: Contactos Clave
- **DBA Team:** dba@dominio.org — Slack: #db-team
- **Security:** security@dominio.org — Slack: #security
- **ITSM Support:** servicedesk@dominio.org

### Anexo C: Documentación Relacionada
- [Política de Administración de Accesos](./README.md)
- [Matriz de Accesos](./04_Matriz_Accesos.md)
- [Auditoría y Cumplimiento](./06_Auditoria_Cumplimiento.md)

---

**Última revisión:** 2026-06-29  
**Próxima revisión:** 2026-12-29 (semestral)
