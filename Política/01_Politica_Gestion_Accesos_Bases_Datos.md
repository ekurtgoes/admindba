# POLÍTICA DE GESTIÓN DE ACCESOS A BASES DE DATOS Y PLATAFORMAS ANALÍTICAS

> **Documento maestro que consolida:** 01 Política de Proveedores Externos, 02 Política de Personal Interno, 03 Política por Ambiente y 04 Matriz de Accesos  
> **Aplicable a:** Usuarios internos, aplicaciones, cuentas de servicio, proveedores externos, auditores y administradores  
> **Responsables:** DBA Lead, CISO/Security, DevOps Lead, Data Owners y Product Owners  
> **Última actualización:** 2026-09-04  
> **Estado:** Vigente; sustituye operativamente a los documentos 01, 02, 03 y 04

-----

## ÍNDICE

1. [Objetivo y alcance](#1-objetivo-y-alcance)
2. [Principios de gestión de accesos](#2-principios-de-gestión-de-accesos)
3. [Tipos de identidades y responsabilidades](#3-tipos-de-identidades-y-responsabilidades)
4. [Segregación por ambiente](#4-segregación-por-ambiente)
5. [Matriz de permisos](#5-matriz-de-permisos)
6. [Grupos de consumo BigQuery](#6-grupos-de-consumo-bigquery)
7. [Controles técnicos y buenas prácticas](#7-controles-técnicos-y-buenas-prácticas)
8. [Solicitud, aprobación y ciclo de vida](#8-solicitud-aprobación-y-ciclo-de-vida)
9. [Auditoría, monitoreo y recertificación](#9-auditoría-monitoreo-y-recertificación)
10. [Excepciones e incumplimientos](#10-excepciones-e-incumplimientos)
11. [Responsabilidades](#11-responsabilidades)

---

## 1. OBJETIVO Y ALCANCE

Esta política establece cómo se solicitan, aprueban, implementan, monitorean y revocan los accesos a bases de datos, Cloud SQL, BigQuery y demás plataformas de datos institucionales.

Aplica a:

- Personal interno: DBA, DevOps, desarrolladores, QA, BI, analistas, seguridad y auditores.
- Aplicaciones y procesos automatizados mediante cuentas de servicio.
- Proveedores externos, consultores, soporte de fabricantes y auditores contratados.
- Ambientes DEV, QA/UAT y PRODUCCIÓN.
- Acceso a datos, metadatos, estructuras, consultas, cargas, exportaciones y administración.

Esta política define el control de acceso. Los procedimientos operativos, formularios y scripts de implementación deben mantenerse alineados con ella.

---

## 2. PRINCIPIOS DE GESTIÓN DE ACCESOS

### 2.1 Mínimo privilegio

Cada identidad recibe únicamente los permisos necesarios para una función, objeto, operación y periodo determinados. El acceso a una base de datos no implica acceso a todos sus esquemas, tablas, columnas o datasets.

### 2.2 Necesidad de conocer

El acceso a datos se concede según la responsabilidad del solicitante y la clasificación del dato. Los datos sensibles, personales, médicos o regulados requieren controles reforzados y acceso limitado.

### 2.3 Separación de funciones

La persona que solicita un acceso no debe aprobarlo ni implementarlo. La administración de permisos debe estar separada del desarrollo, la operación y el consumo de datos.

### 2.4 Identidad individual y trazable

- Se deben utilizar cuentas corporativas individuales para personas.
- Se prohíben cuentas compartidas, credenciales embebidas y usuarios personales para operar servicios institucionales.
- Las aplicaciones deben utilizar cuentas de servicio independientes por sistema, ambiente y función.
- MFA es obligatorio para accesos humanos a GCP y ambientes administrativos.

### 2.5 Temporalidad y revocación

Los accesos temporales deben tener fecha de expiración automática. Todo acceso debe revocarse por cambio de función, finalización de contrato, baja laboral, cierre del proyecto o incumplimiento.

### 2.6 Trazabilidad

Toda solicitud, aprobación, modificación, consulta administrativa, exportación y cambio de privilegios debe poder asociarse con una identidad, ticket, sistema, ambiente y fecha.

### 2.7 Prohibición de secretos en código

Las contraseñas, llaves y tokens deben almacenarse en Secret Manager o una bóveda aprobada. No deben almacenarse en código fuente, repositorios, imágenes, archivos de configuración ni tickets.

---

## 3. TIPOS DE IDENTIDADES Y RESPONSABILIDADES

### 3.1 Usuarios internos

Incluye DBA, DevOps, desarrolladores, QA, BI/Analytics, Data Engineers, Security y auditores internos.

| Perfil | Uso principal | Regla de acceso |
|--------|---------------|-----------------|
| **DBA** | Administración, seguridad, respaldo, recuperación y rendimiento | Administración permanente en DEV/QA; acceso JIT y auditado en PRD |
| **DevOps** | Infraestructura, CI/CD y troubleshooting | Lectura en PRD; cambios mediante pipelines aprobados |
| **Desarrollador** | Desarrollo, pruebas y migraciones | Lectura/escritura en DEV; lectura o sandbox en QA; sin acceso directo a PRD por defecto |
| **QA** | Pruebas funcionales e integración | Escritura limitada a datos y esquemas de testing |
| **BI/Analytics** | Consultas, modelos y reportes | Solo lectura sobre vistas, tablas o datasets autorizados |
| **Data Engineer** | Ingesta, transformación y operación de pipelines | Escritura controlada en capas y ambientes asignados; cambios versionados |
| **Security/Auditor** | Revisión de logs, metadatos y controles | Solo lectura; acceso a datos sensibles únicamente si está justificado |

Nomenclatura recomendada para identidades humanas: `rol_iniciales`, por ejemplo `dba_eleo`, `dev_jperez` o `bi_agarcia`.

### 3.2 Aplicaciones y cuentas de servicio

Las aplicaciones no deben conectarse usando cuentas personales. Cada aplicación debe tener una cuenta de servicio separada por ambiente y función:

```text
sa-[sistema]-[ambiente]-[funcion]

Ejemplos:
sa-avanzo-prd-app
sa-avanzo-prd-migration
sa-analitica-prd-pipeline
```

Reglas obligatorias:

- Una cuenta de servicio de runtime no debe tener permisos de administración ni DDL.
- Las cuentas de migración deben ser diferentes de las cuentas de runtime.
- Los permisos deben limitarse a los datasets, esquemas y operaciones requeridos.
- Las credenciales deben rotarse automáticamente, preferiblemente mediante IAM y Workload Identity.
- Las aplicaciones deben usar consultas parametrizadas, límites de tiempo, reintentos controlados y paginación.
- Las cargas y migraciones deben ejecutarse por CI/CD versionado, con revisión y rollback.

### 3.3 Proveedores externos

Los proveedores, consultores, soporte de fabricantes y auditores externos deben cumplir controles adicionales:

- Contrato vigente, NDA, anexo de seguridad y sponsor interno identificado.
- Cuenta corporativa temporal; nunca correo personal o cuenta compartida.
- MFA obligatorio.
- Acceso inicial máximo de 30 días, con renovación justificada.
- Acceso preferente a DEV/QA con datos sintéticos o anonimizados.
- Prohibido el acceso directo a PRD por defecto.
- Acceso excepcional a PRD solo por incidente crítico, con aprobación de CISO, CTO, Product Owner y sponsor, sesión supervisada y expiración máxima de 4 horas.
- Conexión por VPN, IAP Tunnel, Cloud SQL Auth Proxy o mecanismo institucional aprobado; no se permite conexión directa mediante IP pública.
- El acceso se revoca al terminar el contrato, proyecto, autorización o necesidad de negocio.

| Tipo de proveedor | DEV | QA | PRD |
|-------------------|-----|-----|-----|
| Consultor técnico | Read-only temporal; ReadWrite solo si se aprueba | Read-only temporal | Prohibido por defecto |
| Desarrollador externo | ReadWrite temporal con NDA | Read-only temporal | Prohibido |
| Soporte de fabricante | Solo caso excepcional | Solo caso excepcional | Solo P0 crítico y supervisado |
| Auditor externo | Read-only para compliance | Read-only para compliance | Read-only de logs y evidencia autorizada |

---

## 4. SEGREGACIÓN POR AMBIENTE

Los ambientes deben estar aislados lógica y técnicamente. No se deben compartir instancias, credenciales ni redes entre DEV, QA y PRD cuando la arquitectura permita su separación.

| Control | DEV | QA/UAT | PRODUCCIÓN |
|---------|-----|--------|------------|
| **Datos** | Sintéticos o anonimizados | Anonimizados o subconjuntos aprobados | Datos reales, con clasificación y controles reforzados |
| **Acceso DBA** | Administración completa | Administración documentada | JIT, ticket y auditoría en tiempo real |
| **DevOps personal** | ReadWrite según función | Read-only | Read-only sin PII |
| **CI/CD** | Despliegue controlado | Despliegue mediante pipeline | Despliegue mediante pipeline aprobado |
| **Desarrolladores** | ReadWrite y DDL de desarrollo | Read-only y sandbox | Sin acceso directo por defecto |
| **Proveedores** | Temporal y restringido | Temporal y restringido | Prohibido salvo excepción crítica |
| **Auditoría** | Básica | Completa | Completa y con retención definida por compliance |
| **Cambio de esquema** | Coordinado | Versionado y revisado | Ventana aprobada, peer review y rollback |

Está prohibido copiar datos de PRD a DEV o QA sin anonimización, enmascaramiento o autorización documentada.

---

## 5. MATRIZ DE PERMISOS

### 5.1 Matriz resumida por rol y ambiente

| Rol | DEV | QA/UAT | PRD |
|-----|-----|--------|-----|
| **DBA** | Full admin | Full admin documentado | JIT admin, máximo 4 horas |
| **DevOps personal** | ReadWrite | Read-only | Read-only, sin PII |
| **DevOps CI/CD** | Deploy | Deploy por pipeline | Deploy por pipeline aprobado |
| **Desarrollador** | ReadWrite + CREATE | Read-only + sandbox | Sin acceso; excepción P0/P1 |
| **QA** | ReadWrite de test | ReadWrite de test | Sin acceso |
| **BI/Analytics** | Read-only | Read-only | Read-only sobre vistas autorizadas |
| **Data Engineer** | Operación de pipelines | Operación controlada | Pipelines aprobados y auditados |
| **Proveedor** | Temporal | Temporal | Prohibido por defecto |
| **Auditor/Security** | Read-only | Read-only | Logs, metadatos y evidencia autorizada |

### 5.2 Operaciones

| Operación | DBA | DevOps manual | CI/CD | Desarrollador | Proveedor |
|-----------|-----|---------------|--------|--------------|-----------|
| SELECT | Según ambiente | Sí, según ambiente | Sí | DEV/QA | DEV/QA temporal |
| INSERT/UPDATE | Según ambiente y ticket | No en PRD | Sí, por pipeline | DEV; QA sandbox | Solo DEV aprobado |
| DELETE/TRUNCATE | Ticket y aprobación en PRD | No | Solo caso aprobado | DEV controlado | No |
| CREATE/ALTER/DROP | Según ambiente | No manual | Migración versionada | DEV | No |
| GRANT/REVOKE | Solo DBA | No | No | No | No |
| Backup/Restore | Procedimiento aprobado | No, salvo DEV con DBA | No | No | No |

El acceso a PII, PHI o datos regulados debe restringirse además por vistas, columnas, filas, enmascaramiento o controles equivalentes.

---

## 6. GRUPOS DE CONSUMO BIGQUERY

### 6.1 Principio

Los grupos de acceso a datos y los grupos de consumo de recursos son controles relacionados, pero distintos:

- IAM determina qué usuario o grupo puede consultar un dataset, tabla, vista o proyecto.
- El control de consumo determina cuánto puede procesar o utilizar una carga de trabajo.
- Pertenecer a un grupo IAM no aplica por sí solo `maximum_bytes_billed` a todas las consultas.

### 6.2 Clasificación institucional

Todo usuario, aplicación o proceso que consulte BigQuery debe pertenecer a una clasificación de consumo aprobada y utilizar el proyecto de ejecución institucional correspondiente.

| Grupo | Perfil | Límite de slots de referencia | `maximum_bytes_billed` por consulta |
|-------|--------|-------------------------------:|-------------------------------------|
| **Grupo01** | Usuarios analíticos | 200 slots | Valor definido en el registro de cuotas |
| **Grupo02** | Aplicaciones | 1,000 slots | Valor definido por aplicación y caso de uso |
| **Grupo03** | Ingenieros de datos | 500 slots | Valor definido por pipeline y ventana de ejecución |

Los límites de bytes procesados deben establecerse en bytes y aprobarse por el propietario de BigQuery. Como referencia, un límite de 200 GiB equivale a `214748364800` bytes.

### 6.3 Implementación y garantía del límite

`maximum_bytes_billed` es un límite por consulta: BigQuery rechaza la consulta si la estimación supera el valor configurado. No es un límite de slots ni una cuota diaria.

Para que el control sea obligatorio:

- Las aplicaciones y pipelines deben enviar `maximum_bytes_billed` en cada job.
- Las herramientas corporativas deben establecer el valor por defecto y evitar que el usuario lo elimine o eleve sin autorización.
- Si los usuarios consultan directamente desde la consola u otras herramientas, se deben complementar los límites por consulta con cuotas, alertas, monitoreo y control del proyecto de ejecución.
- Para separar cargas por grupo, se recomienda asignar cada grupo a un proyecto de ejecución y Reservation compatible con la arquitectura aprobada.
- Si se requiere cumplimiento estricto por identidad, las consultas deben pasar por una aplicación o servicio intermediario que valide grupo, datasets y límite antes de crear el job.
- Los jobs deben usar etiquetas como `grupo_consumo`, `sistema`, `ambiente`, `owner` y `centro_costo`.

El propietario de la plataforma debe registrar por cada grupo: proyecto de ejecución, Reservation o cuota aplicable, límite de bytes, responsables, datasets autorizados, alertas y fecha de revisión.

---

## 7. CONTROLES TÉCNICOS Y BUENAS PRÁCTICAS

### 7.1 Autenticación y conectividad

- Preferir IAM, IAM Database Authentication y Workload Identity cuando el servicio lo soporte.
- Usar MFA para toda identidad humana.
- Deshabilitar IP pública para bases de datos cuando sea técnicamente posible.
- Usar VPC privada, VPN, IAP Tunnel, Cloud SQL Auth Proxy y TLS.
- No autorizar redes o IPs residenciales sin evaluación y aprobación.
- No compartir contraseñas por correo, chat o tickets.

### 7.2 Bases de datos transaccionales

- Usar roles por función y permisos sobre esquemas u objetos específicos.
- No conceder `SUPERUSER`, `db_owner` o privilegios equivalentes en PRD de forma permanente.
- Aplicar JIT para elevaciones administrativas.
- Separar cuentas de runtime, migración, operación y administración.
- Usar transacciones, rollback y peer review para cambios de datos.
- Evitar comodines de permisos cuando se puede especificar el objeto.

### 7.3 BigQuery y plataformas analíticas

- Preferir vistas autorizadas y datasets curados para consumidores.
- Aplicar control de acceso por dataset, tabla, columna y fila cuando corresponda.
- Usar particionado y clustering para reducir datos procesados.
- Evitar `SELECT *` en consultas productivas.
- Consultar primero con dry run o estimación de bytes.
- Mantener Bronze, Silver y Gold conforme a la política de Gobierno, Modelado y Documentación de Datos.
- Restringir escritura y modificación de capas analíticas a cuentas de servicio autorizadas.
- Controlar exportaciones masivas y accesos a datos sensibles.

### 7.4 Datos no productivos

DEV y QA deben utilizar datos sintéticos, anonimizados o enmascarados. La anonimización debe validarse antes de conceder acceso y debe conservar trazabilidad de la fuente, método y fecha.

---

## 8. SOLICITUD, APROBACIÓN Y CICLO DE VIDA

### 8.1 Información mínima de la solicitud

Toda solicitud debe incluir:

- Identidad, equipo, rol y sponsor.
- Sistema, proyecto, instancia, base de datos, dataset, esquema o tabla.
- Ambiente y periodo solicitado.
- Operaciones requeridas y justificación de negocio.
- Clasificación de datos involucrados.
- Método de conexión y origen de la conexión.
- Para BigQuery: grupo de consumo, proyecto de ejecución, límite de bytes y datasets autorizados.
- Ticket, aprobadores y fecha de expiración cuando aplique.

### 8.2 Aprobaciones

| Caso | Aprobaciones mínimas |
|------|----------------------|
| DEV | DBA o DevOps Lead; Product Owner cuando afecte datos del negocio |
| QA/UAT | DBA o DevOps Lead + Product Owner |
| PRD lectura | Product Owner + DBA Lead + Security cuando haya datos sensibles |
| PRD escritura o DDL | Product Owner + DBA Lead + Security/CISO + change management |
| Proveedor externo | Sponsor + Product Owner + Legal + CISO/Security |
| Elevación DBA JIT | Ticket + aprobador según operación; CISO para cambios críticos |
| Cambio de cuota o grupo BigQuery | Propietario de plataforma + Data Owner cuando afecte datasets |

### 8.3 Implementación

El DBA o administrador autorizado debe validar la aprobación, crear la identidad o grupo, asignar el mínimo privilegio, configurar expiración, registrar el acceso en inventario y comunicar instrucciones por canal seguro.

### 8.4 Revocación

- Baja laboral o terminación de contrato: inmediata.
- Cambio de equipo o función: máximo 24 horas.
- Fin de proyecto: máximo 48 horas.
- Acceso temporal: revocación automática al expirar.
- Incidente o uso indebido: revocación inmediata por Security o DBA autorizado.

---

## 9. AUDITORÍA, MONITOREO Y RECERTIFICACIÓN

### 9.1 Registros obligatorios

Deben conservarse los registros de autenticación, accesos a datos, cambios de privilegios, consultas administrativas, exportaciones, jobs BigQuery, consumo de bytes, consumo de slots y errores por exceso de límite.

### 9.2 Alertas mínimas

- Cambios de IAM, GRANT o REVOKE.
- Acceso a PRD fuera de horario o desde origen no autorizado.
- DROP, ALTER o DELETE masivo en PRD.
- Exportación masiva de datos.
- Creación o modificación de cuentas de servicio.
- Consulta BigQuery rechazada por `maximum_bytes_billed`.
- Incrementos anómalos de bytes procesados o slots consumidos.
- Intentos repetidos de autenticación fallida.

### 9.3 Recertificación

Los Data Owners y Product Owners deben recertificar los accesos como mínimo trimestralmente. La revisión debe confirmar pertenencia al equipo, necesidad vigente, privilegios, datasets autorizados, grupo de consumo y uso real. Los accesos sin justificación deben revocarse.

### 9.4 Retención

La retención de logs, tickets, evidencias y registros de consumo debe cumplir la clasificación de datos, requisitos legales y la política institucional de auditoría. Producción requiere retención reforzada y exportación a almacenamiento protegido cuando aplique.

---

## 10. EXCEPCIONES E INCUMPLIMIENTOS

Toda excepción debe ser temporal, documentada y aprobada por el responsable del riesgo. Debe indicar justificación, alcance, controles compensatorios, fecha de inicio, fecha de vencimiento y responsable.

Son incumplimientos críticos:

- Acceso no autorizado a PRD.
- Compartir credenciales o usar cuentas personales/compartidas.
- Exportar datos sin autorización.
- Deshabilitar auditoría.
- Modificar datos o estructura en PRD sin aprobación.
- Eludir los controles de consumo de BigQuery o ejecutar cargas sin etiquetado.

Las medidas pueden incluir revocación inmediata, investigación de seguridad, re-capacitación, acciones disciplinarias, notificación contractual y acciones legales según corresponda.

---

## 11. RESPONSABILIDADES

| Rol | Responsabilidades |
|-----|------------------|
| **DBA Lead** | Implementar permisos, mantener inventario, aplicar JIT, revisar auditoría y revocar accesos |
| **CISO/Security** | Definir controles de seguridad, aprobar excepciones críticas y atender incidentes |
| **Product Owner/Data Owner** | Justificar necesidad, aprobar acceso y recertificarlo |
| **DevOps Lead** | Administrar conectividad, CI/CD, cuentas de servicio y secretos |
| **Propietario de BigQuery** | Administrar grupos de consumo, cuotas, Reservations, límites y monitoreo |
| **Managers** | Notificar cambios de rol, bajas y necesidades de acceso |
| **Usuarios y proveedores** | Usar el acceso autorizado, proteger credenciales y reportar incidentes |
| **Auditoría** | Revisar evidencia, cumplimiento, segregación y efectividad de controles |

---

