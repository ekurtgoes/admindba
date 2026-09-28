# ONBOARDING — EQUIPO DE BASES DE DATOS (GCP)

> **Aplicable a:** Ingeniero BD Junior, Ingeniero BD Proficient, Ingeniero BD Senior, Líder Técnico Bases de Datos
> **Plataforma:** Google Cloud Platform — Cloud SQL (MySQL/PostgreSQL/SQL Server), AlloyDB, Cloud Spanner, Firestore/Firebase, MongoDB Atlas, BigQuery (Data Warehouse medallón Bronze/Silver/Gold × dev/qa/prd), Cloud Healthcare API (FHIR/HL7v2/DICOM)
> **Documentos base:** [01 Gestión de Accesos](./01_Politica_Gestion_Accesos_Bases_Datos.md) · [07 Gobierno y Modelado](./07_Politica_Gobierno_Modelado_Documentacion.md) · [08 Aprovisionamiento GCP](./08_Politica_Aprovisionamiento_Plataformas_Datos_GCP.md) · [09 Continuidad y DR](./09_Politica_Continuidad_Mantenimiento_DR.md) · [12 Batch y Streaming](./12_Politica_Ingenieria_Datos_Batch_Streaming.md) · [13 Datos de Salud/FHIR](./13_Politica_Datos_Salud_FHIR.md) · [14 Estructura del Equipo](./14_Estructura_Equipo_RACI_Guardias.md) · [15 Línea Base del Inventario](./15_Linea_Base_Inventario_CloudSQL.md) · [GUIA_RAPIDA](./GUIA_RAPIDA.md)
> **Asignación nominal vigente:** [11_Onboarding_por_Perfil.md](./11_Onboarding_por_Perfil.md)
> **Última actualización:** 2026-09-17
> **Dueño del documento:** DBA Lead / Líder Técnico Bases de Datos
>
> **Escala real de la plataforma:** **216 instancias Cloud SQL** en 129 proyectos (113 PostgreSQL, 55 MySQL, 48 SQL Server, 16 réplicas de lectura), nueve proyectos de Data Warehouse medallón y sistemas de salud bajo FHIR. Toda referencia a "25+ instancias" en versiones anteriores de este documento o en [perfiles.txt](./perfiles.txt) queda corregida por la cifra verificada en [15](./15_Linea_Base_Inventario_CloudSQL.md). La consecuencia práctica es que **ninguna responsabilidad operativa de este documento es viable de forma manual**: automatizar es parte del rol, no una mejora opcional.

---

## ÍNDICE

1. [Objetivo](#1-objetivo)
2. [Ruta común de onboarding (todos los perfiles)](#2-ruta-común-de-onboarding-todos-los-perfiles)
3. [Onboarding — Ingeniero Base de Datos Junior](#3-onboarding--ingeniero-base-de-datos-junior)
4. [Onboarding — Ingeniero Base de Datos Proficient](#4-onboarding--ingeniero-base-de-datos-proficient)
5. [Onboarding — Ingeniero Base de Datos Senior](#5-onboarding--ingeniero-base-de-datos-senior)
6. [Onboarding — Líder Técnico Bases de Datos](#6-onboarding--líder-técnico-bases-de-datos)
7. [Buenas prácticas GCP por motor (referencia transversal)](#7-buenas-prácticas-gcp-por-motor-referencia-transversal)
8. [Plan 30-60-90 días (resumen ejecutivo)](#8-plan-30-60-90-días-resumen-ejecutivo)
9. [Checklist de cierre de onboarding (sign-off)](#9-checklist-de-cierre-de-onboarding-sign-off)

---

## 1. OBJETIVO

Estandarizar el proceso de incorporación técnica y normativa de todo nuevo integrante del equipo de bases de datos, asegurando que — antes de operar plataformas productivas en GCP — conozca las políticas vigentes, obtenga los accesos mínimos necesarios (PoLP) y desarrolle las competencias técnicas esperadas para su nivel (Junior, Proficient, Senior, Líder Técnico), según las responsabilidades descritas en [perfiles.txt](./perfiles.txt).

Este documento no reemplaza las políticas oficiales; es una guía operativa de incorporación que remite a ellas.

---

## 2. RUTA COMÚN DE ONBOARDING (TODOS LOS PERFILES)

Independientemente del nivel, todo ingreso al equipo de bases de datos sigue esta secuencia antes de recibir accesos a QA o PRD:

### 2.1 Día 1 — Identidad y cuentas

- [ ] Alta en el directorio corporativo (correo, MFA obligatorio) — ver [01_Politica_Gestion_Accesos §2.4](./01_Politica_Gestion_Accesos_Bases_Datos.md#24-identidad-individual-y-trazable).
- [ ] Cuenta individual `rol_iniciales` — nunca cuentas compartidas. La convención vigente es `{rol}_{inicial del nombre}{primeras 4 letras del apellido paterno}` (ej. `dba_porte`, `lead_kleon`). Ver [14 §3](./14_Estructura_Equipo_RACI_Guardias.md#3-convención-de-identidades-del-equipo) para la regla de desempate cuando dos personas comparten apellido.
- [ ] Acceso a `gcloud` CLI + `gcloud auth login` configurado con MFA.
- [ ] Alta en el gestor de tickets (`DB-ACCESS-INTERNAL`) y canal Slack `#db-security-compliance`.
- [ ] Entrega de equipo con VPN corporativa configurada (requisito para conectividad privada a Cloud SQL/Spanner/AlloyDB).

### 2.2 Semana 1 — Lectura obligatoria de políticas (orden sugerido)

| Orden | Documento | Enfoque |
|---|---|---|
| 1 | [README.md](./README.md) | Visión general, principios (PoLP, SoD, JIT) |
| 2 | [GUIA_RAPIDA.md](./GUIA_RAPIDA.md) | Qué puedo/no puedo hacer por rol y ambiente |
| 3 | [01_Politica_Gestion_Accesos_Bases_Datos.md](./01_Politica_Gestion_Accesos_Bases_Datos.md) | Roles, matriz de permisos, ciclo de vida del acceso |
| 4 | [08_Politica_Aprovisionamiento_Plataformas_Datos_GCP.md](./08_Politica_Aprovisionamiento_Plataformas_Datos_GCP.md) | Estándares GCP, nomenclatura, IaC |
| 5 | [09_Politica_Continuidad_Mantenimiento_DR.md](./09_Politica_Continuidad_Mantenimiento_DR.md) | Backups, HA/DR, mantenimiento |
| 6 | [07_Politica_Gobierno_Modelado_Documentacion.md](./07_Politica_Gobierno_Modelado_Documentacion.md) | Diccionario de datos, clasificación, linaje |
| 7 | [05_Procedimientos_Solicitud.md](./05_Procedimientos_Solicitud.md) y [06_Auditoria_Cumplimiento.md](./06_Auditoria_Cumplimiento.md) | Cómo pedir accesos y cómo se audita |
| 8 | [14_Estructura_Equipo_RACI_Guardias.md](./14_Estructura_Equipo_RACI_Guardias.md) | Quién hace qué, guardias, escalamiento y segregación de funciones |
| 9 | [15_Linea_Base_Inventario_CloudSQL.md](./15_Linea_Base_Inventario_CloudSQL.md) | Qué hay realmente en la plataforma y cuáles son los hallazgos abiertos |
| 10 | [12_Politica_Ingenieria_Datos_Batch_Streaming.md](./12_Politica_Ingenieria_Datos_Batch_Streaming.md) | Separación batch / tiempo real, CDC y contratos de datos |
| 11 | [13_Politica_Datos_Salud_FHIR.md](./13_Politica_Datos_Salud_FHIR.md) | PHI, FHIR, desidentificación y break-the-glass |

- [ ] Firma de acuse de lectura de las políticas (evidencia para auditoría, ver [06_Auditoria_Cumplimiento](./06_Auditoria_Cumplimiento.md)).
- [ ] Asignación de mentor/buddy (Proficient o Senior) durante las primeras 4 semanas, según el organigrama de [14 §2.2](./14_Estructura_Equipo_RACI_Guardias.md#22-organigrama-funcional).

> Los documentos 12 y 13 son de **lectura obligatoria para todos los perfiles**, no solo para quienes trabajen en pipelines o en sistemas clínicos: definen prohibiciones que aplican a cualquier persona con acceso a la plataforma. El documento 13 es además condición previa para cualquier acceso a proyectos con PHI.

### 2.3 Semana 1-2 — Accesos iniciales (siempre DEV primero)

Según [01_Politica_Gestion_Accesos §4](./01_Politica_Gestion_Accesos_Bases_Datos.md#4-segregación-por-ambiente), todo nuevo integrante inicia en **DEV** con datos sintéticos/anonimizados. El acceso a QA y PRD se otorga de forma incremental según el nivel (ver secciones 3-6).

- [ ] Ticket `DB-ACCESS-INTERNAL` para acceso DEV.
- [ ] Conexión validada vía Cloud SQL Auth Proxy / IAP Tunnel (nunca IP pública).
- [ ] Alta en el inventario de accesos (trazabilidad, ver [08 §7.2](./08_Politica_Aprovisionamiento_Plataformas_Datos_GCP.md#72-inventario)).

### 2.4 Herramientas estándar del equipo

- [ ] `gcloud` SDK, `cloud-sql-proxy`, cliente del motor correspondiente (`psql`, `mysql`, `sqlcmd`, `mongosh`, consola Firestore, `bq`).
- [ ] Acceso de solo lectura al repositorio de IaC (Terraform) del equipo.
- [ ] Acceso al inventario de instancias/datasets (Cloud SQL, Spanner, BigQuery, Firestore, MongoDB Atlas).
- [ ] Acceso al dashboard de monitoreo (Cloud Monitoring / Looker / panel institucional).

---

## 3. ONBOARDING — INGENIERO BASE DE DATOS JUNIOR

### 3.1 Responsabilidades (según perfiles.txt)

1. Salud del dato: reporte diario de backups y latencia del parque completo (**216 instancias**, no 25).
2. Soporte de queries: depuración de errores sintácticos y ejecución de scripts autorizados.
3. Monitoreo de capacidad: alertas al 80% de ocupación en Cloud SQL.
4. Gestión de usuarios: creación/revocación bajo estándares de seguridad.
5. Documentación de esquemas: diccionario de datos de aplicaciones core.
6. Refuerzo operativo: respaldo del Ingeniero Senior en tareas operativas.

> **Consecuencia del tamaño real del parque:** el reporte diario de salud debe producirse mediante una **extracción automatizada** (`gcloud`/API + script), no por revisión manual instancia por instancia. Construir esa automatización es la primera tarea sustantiva del perfil Junior, no un objetivo de largo plazo.

### 3.2 Accesos a solicitar (mapeo a la matriz de permisos)

| Ambiente | Nivel de acceso | Referencia |
|---|---|---|
| DEV | ReadWrite + CREATE (sandbox) | [01 §5.1](./01_Politica_Gestion_Accesos_Bases_Datos.md#51-matriz-resumida-por-rol-y-ambiente) |
| QA | Read-only inicial; escritura solo bajo supervisión | Rol "DBA" en formación — tratar como Desarrollador hasta certificación interna |
| PRD | **Sin acceso directo** — solo observación acompañada por Senior/Lead durante troubleshooting | [01 §3.1](./01_Politica_Gestion_Accesos_Bases_Datos.md#31-usuarios-internos) |
| PRD con PHI | **Sin acceso bajo ninguna modalidad**, incluido break-the-glass | [13 §5](./13_Politica_Datos_Salud_FHIR.md#5-modelo-de-acceso-a-datos-de-salud) |
| Pipelines | Lectura de logs y métricas; sin permiso de despliegue ni de reprocesamiento | [12 §7](./12_Politica_Ingenieria_Datos_Batch_Streaming.md#7-separación-de-recursos-nomenclatura-y-etiquetado) |

> El acceso administrativo pleno en PRD (JIT) se otorga solo cuando el Junior sea promovido o certificado por el Lead — no aplica por defecto en esta etapa.
> Durante los primeros 90 días el Junior participa en las guardias **en modo observador**, sin ser punto de contacto primario de incidentes P0/P1 ([14 §7](./14_Estructura_Equipo_RACI_Guardias.md#7-guardias-severidades-y-escalamiento)).

### 3.3 Plan de competencias (primeros 90 días)

**Semanas 1-2 — Fundamentos**
- [ ] Diferencia entre backup automático, PITR y export lógico ([09 §3](./09_Politica_Continuidad_Mantenimiento_DR.md#3-política-de-respaldos-por-motor)).
- [ ] Uso de Cloud SQL Auth Proxy y `gcloud sql` para conexión segura.
- [ ] Lectura de métricas básicas en Cloud Monitoring: CPU, storage, conexiones, latencia.
- [ ] Práctica de SQL: `EXPLAIN`/`EXPLAIN ANALYZE`, índices básicos, joins, transacciones.

**Semanas 3-6 — Operación asistida**
- [ ] Ejecutar el reporte diario de salud (backups exitosos, latencia, alertas) con checklist provisto por el Lead.
- [ ] Configurar alertas de capacidad al 80% en Cloud Monitoring (umbral, canal de notificación).
- [ ] Crear/revocar usuarios de BD en DEV siguiendo la nomenclatura `rol_iniciales` y el procedimiento de [05_Procedimientos_Solicitud](./05_Procedimientos_Solicitud.md).
- [ ] Actualizar el diccionario de datos de al menos una aplicación core (plantilla en [07_Politica_Gobierno_Modelado_Documentacion](./07_Politica_Gobierno_Modelado_Documentacion.md)).

**Semanas 3-6 — Automatización del inventario**
- [ ] Construir la extracción automatizada del inventario de las 216 instancias: motor y versión, estado, `availabilityType` (ZONAL/REGIONAL), backups habilitados, PITR, IP pública, TLS, ventana de mantenimiento, canal de actualización y uso de disco.
- [ ] Publicar el resultado como fuente del reporte diario y de los indicadores de [15 §10](./15_Linea_Base_Inventario_CloudSQL.md#10-indicadores-de-seguimiento).

**Semanas 7-12 — Autonomía supervisada**
- [ ] Resolver 3-5 tickets de soporte de queries con revisión de un Proficient/Senior.
- [ ] Participar como observador en una prueba de restauración ([09 §5](./09_Politica_Continuidad_Mantenimiento_DR.md#5-pruebas-de-restauración)).
- [ ] Shadowing de una elevación JIT en PRD ejecutada por el Senior/Lead.
- [ ] Distinguir en el monitoreo un pipeline **batch** de uno de **tiempo real** y saber qué alerta corresponde a cada uno ([12 §10](./12_Politica_Ingenieria_Datos_Batch_Streaming.md#10-sla-slo-y-observabilidad-por-modo)); en particular, reconocer un **slot de replicación de PostgreSQL creciendo sin consumir** como incidente P0.
- [ ] Identificar qué proyectos contienen PHI y por qué no debe acceder a ellos ([13 §1.2](./13_Politica_Datos_Salud_FHIR.md#12-definición-de-phi)).

### 3.4 Motores mínimos a dominar
Cloud SQL (MySQL, PostgreSQL) — nivel operativo básico; PostgreSQL con prioridad, por ser el motor de 113 de las 216 instancias. Introducción a BigQuery (solo lectura/consultas) recomendable desde el primer mes. Nociones de SQL Server suficientes para leer métricas y escalar incidentes, dado que sostiene 48 instancias.

---

## 4. ONBOARDING — INGENIERO BASE DE DATOS PROFICIENT

### 4.1 Responsabilidades (según perfiles.txt)

1. Optimización de rendimiento: tuning de índices y consultas en QA/PRD.
2. Migraciones de ambiente: DEV → QA → PRD de forma segura.
3. Alta disponibilidad: configuración y pruebas de failover en Cloud SQL.
4. Estandarización de motores: garantizar las versiones "Golden Path" vigentes — **PostgreSQL 18.x, MySQL 8.4 LTS, SQL Server 2022 Standard** ([15 §3.2](./15_Linea_Base_Inventario_CloudSQL.md#32-golden-path-institucional)).
5. Seguridad de datos: cifrado en reposo/tránsito (TLS) en todas las conexiones.
6. Automatización operativa: scripts de limpieza de logs y mantenimiento preventivo.
7. Operación de pipelines: separación efectiva de batch y tiempo real, y protección de la base origen en CDC ([12](./12_Politica_Ingenieria_Datos_Batch_Streaming.md)).

> La referencia a "PostgreSQL 16.x" de [perfiles.txt](./perfiles.txt) quedó desactualizada: el parque real está mayoritariamente en PostgreSQL 18 (58 instancias) y 17 (27). El Golden Path se define desde el inventario, no al revés, y se revisa semestralmente.

### 4.2 Accesos a solicitar

| Ambiente | Nivel de acceso | Referencia |
|---|---|---|
| DEV | Full ReadWrite + DDL | [01 §5.1](./01_Politica_Gestion_Accesos_Bases_Datos.md#51-matriz-resumida-por-rol-y-ambiente) |
| QA | Administración documentada, ejecución de migraciones vía CI/CD | [01 §4](./01_Politica_Gestion_Accesos_Bases_Datos.md#4-segregación-por-ambiente) |
| PRD | Acceso JIT (lectura habitual; escritura/DDL con ticket y aprobación DBA Lead) | [01 §8.2](./01_Politica_Gestion_Accesos_Bases_Datos.md#82-aprobaciones) |
| Pipelines | Despliegue en DEV/QA; en PRD, despliegue vía CI/CD y reprocesamiento con aprobación | [12 §11](./12_Politica_Ingenieria_Datos_Batch_Streaming.md#11-reprocesamiento-backfill-y-recuperación) |
| PRD con PHI | Acceso a datos seudonimizados (N2); acceso identificable (N1) solo break-the-glass, con formación previa | [13 §5](./13_Politica_Datos_Salud_FHIR.md#5-modelo-de-acceso-a-datos-de-salud) |
| BigQuery | Grupo de consumo asignado según dominio; `maximum_bytes_billed` obligatorio | [01 §6](./01_Politica_Gestion_Accesos_Bases_Datos.md#6-grupos-de-consumo-bigquery) |

### 4.3 Plan de competencias (primeros 90 días)

**Semanas 1-3**
- [ ] Certificar dominio de `EXPLAIN ANALYZE`, planes de ejecución y estadísticas del optimizador en PostgreSQL/MySQL/SQL Server.
- [ ] Configurar y probar HA regional en Cloud SQL (failover controlado) en un ambiente no productivo — ver [09 §8.1](./09_Politica_Continuidad_Mantenimiento_DR.md#81-alta-disponibilidad) y [08 §5.1](./08_Politica_Aprovisionamiento_Plataformas_Datos_GCP.md#51-cloud-sql).
- [ ] Revisar y documentar la versión "Golden Path" vigente por motor (con el Lead).

**Semanas 4-8**
- [ ] Ejecutar una migración de esquema DEV→QA con pipeline versionado (Flyway/Liquibase o equivalente), incluyendo rollback documentado.
- [ ] Habilitar/validar TLS en todas las cadenas de conexión de al menos un sistema.
- [ ] Automatizar limpieza de logs/mantenimiento preventivo (`VACUUM`/`ANALYZE`, slow query log) según [09 §6](./09_Politica_Continuidad_Mantenimiento_DR.md#6-mantenimientos-e-índices).

**Semanas 4-8 — Ingeniería de datos**
- [ ] Clasificar los pipelines de su dominio según la taxonomía de [12 §3](./12_Politica_Ingenieria_Datos_Batch_Streaming.md#3-taxonomía-de-cargas-de-datos) y verificar que ningún flujo batch comparta cuenta de servicio ni tabla de escritura con un flujo de tiempo real.
- [ ] Configurar los controles de protección de la base origen en CDC ([12 §9](./12_Politica_Ingenieria_Datos_Batch_Streaming.md#9-protección-de-la-base-de-datos-fuente-cdc)): alertas sobre slots de replicación, retención de binlog, limpieza de CDC y oplog.
- [ ] Validar que las ventanas de carga batch no se solapen con las ventanas de mantenimiento del motor ([15 §4.3](./15_Linea_Base_Inventario_CloudSQL.md#43-estándar-a-aplicar)).

**Semanas 9-12**
- [ ] Liderar una prueba de restauración documentada (evidencia según [09 §5.2](./09_Politica_Continuidad_Mantenimiento_DR.md#52-evidencia-obligatoria)).
- [ ] Participar en al menos una revisión de peer review de cambio en PRD.
- [ ] Iniciar exposición a un segundo motor (AlloyDB, Spanner, Firestore o MongoDB Atlas) mediante laboratorio guiado, priorizando el dominio donde el equipo tenga punto único de conocimiento ([11 §8](./11_Onboarding_por_Perfil.md#8-cobertura-de-competencias-del-equipo)).
- [ ] Definir o revisar un contrato de datos entre capas del medallón ([12 §8](./12_Politica_Ingenieria_Datos_Batch_Streaming.md#8-contratos-de-datos-y-evolución-de-esquema)).

### 4.4 Motores mínimos a dominar
Cloud SQL (los tres motores) a nivel avanzado — incluido **SQL Server**, que representa 48 instancias y suele ser la brecha más común; introducción práctica a AlloyDB; BigQuery a nivel de modelado medallón (particionado, clustering, costos). Un Proficient debe poder sostener su dominio en guardia sin escalar al Senior para tareas rutinarias.

---

## 5. ONBOARDING — INGENIERO BASE DE DATOS SENIOR

### 5.1 Responsabilidades (según perfiles.txt)

1. Arquitectura de datos: modelos distribuidos (Spanner/BigQuery) para escalabilidad global.
2. Plan de recuperación (DRP): simulacros semestrales de restauración.
3. Migraciones on-prem → cloud: proyectos complejos hacia servicios administrados GCP.
4. Auditoría de datos: revisión de logs para detectar accesos no autorizados a PII.
5. Estrategia de parcheo: ventanas de mantenimiento para versiones menores.
6. FinOps en datos: ciclo de vida de datos (archiving) para reducir costos en BigQuery/SQL.

### 5.2 Accesos a solicitar

| Ambiente | Nivel de acceso | Referencia |
|---|---|---|
| DEV/QA | Administración completa | [01 §5.1](./01_Politica_Gestion_Accesos_Bases_Datos.md#51-matriz-resumida-por-rol-y-ambiente) |
| PRD | Administración JIT (máx. 4h, auditoría en tiempo real); coordinador de elevaciones críticas | [01 §3.1](./01_Politica_Gestion_Accesos_Bases_Datos.md#31-usuarios-internos), [GUIA_RAPIDA](./GUIA_RAPIDA.md#-soy-dba) |
| BigQuery | Alta en grupo de consumo "Grupo03 – Ingenieros de datos" | [01 §6.2](./01_Politica_Gestion_Accesos_Bases_Datos.md#62-clasificación-institucional) |

### 5.3 Plan de competencias (primeros 90 días)

**Semanas 1-4**
- [ ] Diseñar (o revisar) un modelo de datos distribuido en Spanner: llaves primarias sin hotspots, índices secundarios respaldados por consultas reales ([08 §5.3](./08_Politica_Aprovisionamiento_Plataformas_Datos_GCP.md#53-cloud-spanner)).
- [ ] Revisar clasificación de datos y logs de Data Access en al menos un sistema con PII ([07](./07_Politica_Gobierno_Modelado_Documentacion.md), [06_Auditoria_Cumplimiento](./06_Auditoria_Cumplimiento.md)).
- [ ] Definir criticidad/RPO/RTO de un sistema no documentado aún, junto al Product Owner ([09 §2](./09_Politica_Continuidad_Mantenimiento_DR.md#2-criticidad-rpo-y-rto)).

**Semanas 5-8**
- [ ] Liderar o co-liderar un simulacro de DR (real o tabletop) siguiendo [09 §9](./09_Politica_Continuidad_Mantenimiento_DR.md#9-disaster-recovery).
- [ ] Definir ventana de parcheo/mantenimiento institucional para un motor crítico.
- [ ] Implementar una política de ciclo de vida (lifecycle) en BigQuery o Cloud Storage para reducir costo de almacenamiento (Nearline/Coldline/Archive, expiración de tablas).

**Semanas 5-8 — Continuidad a escala**
- [ ] Definir la **región secundaria de DR**: el 80 % del parque está concentrado en `us-east1` y no existe hoy una estrategia regional documentada ([15 §8](./15_Linea_Base_Inventario_CloudSQL.md#8-distribución-regional-y-residencia-de-datos)).
- [ ] Establecer el estándar de ventanas y canal de actualización, y remediar las instancias de PRD que hoy están en canal `canary` ([15 §4](./15_Linea_Base_Inventario_CloudSQL.md#4-ventanas-de-mantenimiento-y-canal-de-actualización)).
- [ ] Verificar que las réplicas de lectura no se confundan con alta disponibilidad: una réplica no hace failover automático ni garantiza RTO ([15 §7.2](./15_Linea_Base_Inventario_CloudSQL.md#72-brecha-frente-a-la-política)).

**Semanas 9-12**
- [ ] Diseñar el plan de una migración on-prem → GCP (evaluación de motor según [08 §4](./08_Politica_Aprovisionamiento_Plataformas_Datos_GCP.md#4-criterios-de-selección-de-motor)).
- [ ] Revisión de auditoría trimestral de accesos a datos sensibles, incluyendo los Data Access Logs de los proyectos con PHI ([13 §10](./13_Politica_Datos_Salud_FHIR.md#10-auditoría-y-cumplimiento)).
- [ ] Mentoría formal de al menos un Junior/Proficient (registrar en plan de desarrollo del equipo).
- [ ] Documentar los runbooks de su dominio y transferirlos a un respaldo nombrado ([14 §9](./14_Estructura_Equipo_RACI_Guardias.md#9-continuidad-del-equipo-bus-factor)).

### 5.4 Motores mínimos a dominar
Cloud SQL, AlloyDB, Cloud Spanner y BigQuery a nivel arquitectura; nociones sólidas de Firestore/Firebase y MongoDB Atlas para decisiones de selección de motor; comprensión del modelo de datos FHIR y de los controles de Cloud Healthcare API suficiente para aprobar diseños ([13 §8](./13_Politica_Datos_Salud_FHIR.md#8-modelado-e-interoperabilidad)).

---

## 6. ONBOARDING — LÍDER TÉCNICO BASES DE DATOS

### 6.1 Responsabilidades (según perfiles.txt)

1. Gobernanza de datos: marco normativo de manejo, retención y borrado.
2. Pipeline de datos automatizado: estándar Build-Once-Promote-Everywhere (Flyway/Liquibase).
3. Mentoría y formación: convertir ingenieros de soporte en DBAs especialistas.
4. Estrategia de persistencia: elección de motor SQL vs NoSQL junto a desarrollo.
5. Seguridad de datos avanzada: enmascaramiento y Row-Level Security (RLS).
6. Relación con partners: evaluación y certificación de herramientas de terceros.

### 6.2 Accesos a solicitar

| Ambiente | Nivel de acceso | Referencia |
|---|---|---|
| DEV/QA/PRD | Administración plena + aprobador de solicitudes de nivel crítico | [01 §8.2](./01_Politica_Gestion_Accesos_Bases_Datos.md#82-aprobaciones) |
| IAM/GCP | Co-propietario de políticas IAM y Secret Manager del dominio de datos | [08 §6.2](./08_Politica_Aprovisionamiento_Plataformas_Datos_GCP.md#62-identidad-y-acceso) |
| Gobierno | Dueño del proceso de aprobación de cambios de modelo (menor/mayor/crítico) | [07_Politica_Gobierno_Modelado_Documentacion](./07_Politica_Gobierno_Modelado_Documentacion.md) |

### 6.3 Plan de competencias (primeros 90 días)

**Semanas 1-4**
- [ ] Auditar el estado actual de las políticas vs. la implementación real (gap analysis usando [CHECKLIST_IMPLEMENTACION.md](./CHECKLIST_IMPLEMENTACION.md) y el backlog de [15 §9](./15_Linea_Base_Inventario_CloudSQL.md#9-backlog-priorizado-de-remediación)).
- [ ] Formalizar la estructura del equipo, las identidades y la matriz RACI ([14](./14_Estructura_Equipo_RACI_Guardias.md)), y verificar que ningún dominio crítico quede con una sola persona capaz de atenderlo.
- [ ] Validar que el proceso de solicitud/aprobación de accesos esté activo end-to-end ([05_Procedimientos_Solicitud](./05_Procedimientos_Solicitud.md)).
- [ ] Revisar cobertura de IaC (Terraform) para instancias productivas existentes ([08 §2](./08_Politica_Aprovisionamiento_Plataformas_Datos_GCP.md#2-principios-de-aprovisionamiento)).

**Semanas 5-8**
- [ ] Definir/actualizar el estándar de migraciones automatizadas (Build-Once-Promote-Everywhere) con Flyway/Liquibase para al menos un sistema piloto.
- [ ] Implementar o revisar enmascaramiento/RLS en un sistema con datos sensibles (vistas autorizadas, policy tags en BigQuery, RLS en PostgreSQL).
- [ ] Diseñar plan de formación para Junior→Proficient→Senior (rutas de este mismo documento como base).

**Semanas 5-8 — Cumplimiento regulatorio**
- [ ] Formalizar con Legal y CISO el alcance de [13 Datos de Salud/FHIR](./13_Politica_Datos_Salud_FHIR.md): base legal del tratamiento, política de retención y procedimiento break-the-glass con su revisión posterior.
- [ ] Confirmar qué proyectos contienen PHI y aplicarles las etiquetas `phi`, `phi_level`, `clinical_owner`, `legal_basis` y `retention_policy`.

**Semanas 9-12**
- [ ] Evaluar y certificar al menos una herramienta de terceros (observabilidad, gestión de BD) contra criterios de seguridad institucionales.
- [ ] Presentar a CISO/CTO el estado de cumplimiento (auditoría) y el roadmap de gobernanza de datos, usando los indicadores de [15 §10](./15_Linea_Base_Inventario_CloudSQL.md#10-indicadores-de-seguimiento) con su línea base y su tendencia.
- [ ] Establecer cadencia de revisión semestral de las políticas (según [README §Vigencia](./README.md#vigencia-y-actualizaciones)).
- [ ] Ejecutar la primera recertificación trimestral de accesos ([01 §9](./01_Politica_Gestion_Accesos_Bases_Datos.md#9-auditoría-monitoreo-y-recertificación)).

### 6.4 Alcance transversal
Debe mantener visión de arquitectura sobre todos los motores (Cloud SQL, AlloyDB, Spanner, Firestore/Firebase, MongoDB Atlas, BigQuery, Cloud Healthcare API) y ser el aprobador final de excepciones de política.

### 6.5 Límites del rol
El Líder Técnico **no integra la rotación de guardias operativas**: si lo hace, la función de gobernanza se degrada y las aprobaciones se convierten en cuello de botella. Tampoco puede aprobar su propia elevación de privilegios en PRD; esa aprobación corresponde al DBA Senior o al CISO ([14 §6](./14_Estructura_Equipo_RACI_Guardias.md#6-segregación-de-funciones-sod)). Para sostener la operación con un parque de 216 instancias debe delegar explícitamente en el DBA Senior las aprobaciones de cambios menores y las elevaciones JIT rutinarias.

---

## 7. BUENAS PRÁCTICAS GCP POR MOTOR (REFERENCIA TRANSVERSAL)

Resumen operativo alineado a las recomendaciones de Google Cloud y a las políticas 08/09. Usar como checklist de estudio según el motor asignado.

| Motor | Buenas prácticas clave a interiorizar |
|---|---|
| **Cloud SQL** | Private IP + Cloud SQL Auth Proxy/IAM DB Auth; HA regional en PRD crítico; PITR habilitado; slow query log activo; parámetros ajustados a carga real; ventana de mantenimiento definida |
| **AlloyDB** | Private Service Connect; clúster regional para cargas críticas; PITR + backups automáticos; prueba de compatibilidad PostgreSQL antes de migrar; cuentas separadas por aplicación |
| **Cloud Spanner** | Diseño de llave primaria sin hotspots; índices solo si están respaldados por consultas reales; evaluar impacto de DDL online; separar IAM de instancia/base/lectura |
| **Firestore/Firebase** | Definir modo Native vs Datastore antes de crear (no reversible); Security Rules probadas antes de PRD; índices compuestos versionados; exportaciones programadas a GCS |
| **MongoDB Atlas** | Conectividad privada (PSC/VPC Peering); usuarios por app/persona (no compartidos); Cloud Backups + PITR en PRD; revisión periódica de índices y queries lentas |
| **BigQuery** | Separar datasets raw/curated/semantic/sandbox; particionado obligatorio en tablas grandes; `maximum_bytes_billed` en cada job; vistas autorizadas y policy tags para PII; dry run antes de ejecutar consultas costosas; respetar la separación Bronze/Silver/Gold y las reglas de escritura por capa ([12 §7.4](./12_Politica_Ingenieria_Datos_Batch_Streaming.md#74-proyectos-del-data-warehouse)) |
| **Cloud Healthcare API (FHIR)** | Almacén FHIR R4 con CMEK y VPC Service Controls; Data Access Logs obligatorios y no deshabilitables en PRD; desidentificación ejecutada dentro del proyecto productivo, nunca copiando datos identificables fuera; acceso a PHI identificable solo por break-the-glass con revisión posterior ([13](./13_Politica_Datos_Salud_FHIR.md)) |
| **Pipelines (batch / streaming)** | Un flujo batch y uno de tiempo real nunca comparten proceso, cuenta de servicio ni tabla de escritura; nomenclatura `pl-[modo]-[dominio]-[origen]-a-[destino]-[ambiente]`; dead-letter topic en todo flujo de streaming; idempotencia y marca de agua declaradas; ante degradación se detiene el pipeline, no la base de datos ([12](./12_Politica_Ingenieria_Datos_Batch_Streaming.md)) |

---

## 8. PLAN 30-60-90 DÍAS (RESUMEN EJECUTIVO)

| Hito | Junior | Proficient | Senior | Líder Técnico |
|---|---|---|---|---|
| **30 días** | Políticas leídas, acceso DEV activo, reporte diario de salud ejecutado con supervisión | Acceso QA operativo, primera migración DEV→QA acompañada, pipelines de su dominio clasificados por modo de procesamiento | Modelo Spanner/BigQuery revisado, RPO/RTO de un sistema definido, estándar de ventanas de mantenimiento propuesto | Gap analysis de políticas completado, estructura y RACI del equipo formalizados |
| **60 días** | Usuarios de BD gestionados de forma autónoma en DEV, extracción automatizada del inventario en producción, diccionario de datos actualizado | HA probada en Cloud SQL, TLS validado en un sistema, controles de protección de origen en CDC activos | Simulacro DR liderado, región secundaria de DR definida, lifecycle de BigQuery implementado | Alcance FHIR formalizado con Legal/CISO, piloto de migraciones automatizadas (Flyway/Liquibase) en marcha |
| **90 días** | Shadowing de elevación JIT completado, primeros tickets resueltos con revisión, entrada evaluada a la rotación de guardias | Prueba de restauración liderada, contrato de datos definido, exposición a segundo motor iniciada | Plan de migración on-prem→GCP diseñado, runbooks transferidos a un respaldo, mentoría formal iniciada | Recertificación trimestral ejecutada, herramienta de terceros certificada, roadmap de gobernanza presentado |

---

## 9. CHECKLIST DE CIERRE DE ONBOARDING (SIGN-OFF)

- [ ] Todas las políticas del índice en [README.md](./README.md) leídas y acuse firmado.
- [ ] Accesos otorgados corresponden exactamente a la matriz de su rol y ambiente (sin sobre-aprovisionamiento).
- [ ] Plan de competencias de 90 días completado y validado por el mentor/Lead.
- [ ] Evidencia registrada en el inventario de accesos y en el sistema de auditoría.
- [ ] Rol confirmado en la matriz RACI y en la rotación de guardias ([14](./14_Estructura_Equipo_RACI_Guardias.md)), con respaldo nombrado para su dominio.
- [ ] Formación de [13 Datos de Salud/FHIR](./13_Politica_Datos_Salud_FHIR.md) acreditada, si el rol implica cualquier acceso a proyectos con PHI.
- [ ] Reunión de cierre con DBA Lead / Líder Técnico: retroalimentación y siguientes pasos de desarrollo.

**Firma de aprobación:**

| Rol | Nombre | Fecha |
|---|---|---|
| Nuevo integrante | | |
| Mentor / Buddy | | |
| DBA Lead / Líder Técnico | | |

---

**Nota:** Este documento se debe revisar junto con las políticas oficiales cada vez que estas se actualicen (ver vigencia en [README.md](./README.md#vigencia-y-actualizaciones)).
