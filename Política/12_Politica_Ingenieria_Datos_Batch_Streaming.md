# POLÍTICA DE INGENIERÍA DE DATOS — PROCESAMIENTO BATCH Y EN TIEMPO REAL

> **Aplicable a:** Todo flujo de ingesta, transformación, replicación y publicación de datos entre plataformas institucionales (Cloud SQL, AlloyDB, Spanner, Firestore/Firebase, MongoDB Atlas, FHIR, BigQuery, Cloud Storage)
> **Responsables:** DBA Lead, DBA Senior, DBA Profesional de Plataforma Analítica, Data Engineering, DevOps, Data Owners
> **Documentos base:** [07 Gobierno y Modelado](./07_Politica_Gobierno_Modelado_Documentacion.md) · [08 Aprovisionamiento GCP](./08_Politica_Aprovisionamiento_Plataformas_Datos_GCP.md) · [09 Continuidad y DR](./09_Politica_Continuidad_Mantenimiento_DR.md) · [01 Gestión de Accesos](./01_Politica_Gestion_Accesos_Bases_Datos.md)
> **Última actualización:** 2026-09-17

---

## ÍNDICE

1. [Objetivo](#1-objetivo)
2. [Principio de separación entre batch y tiempo real](#2-principio-de-separación-entre-batch-y-tiempo-real)
3. [Taxonomía de cargas de datos](#3-taxonomía-de-cargas-de-datos)
4. [Criterios de decisión: ¿batch o tiempo real?](#4-criterios-de-decisión-batch-o-tiempo-real)
5. [Arquitectura de referencia — procesamiento batch](#5-arquitectura-de-referencia--procesamiento-batch)
6. [Arquitectura de referencia — procesamiento en tiempo real](#6-arquitectura-de-referencia--procesamiento-en-tiempo-real)
7. [Separación de recursos, nomenclatura y etiquetado](#7-separación-de-recursos-nomenclatura-y-etiquetado)
8. [Contratos de datos y evolución de esquema](#8-contratos-de-datos-y-evolución-de-esquema)
9. [Protección de la base de datos fuente (CDC)](#9-protección-de-la-base-de-datos-fuente-cdc)
10. [SLA, SLO y observabilidad por modo](#10-sla-slo-y-observabilidad-por-modo)
11. [Reprocesamiento, backfill y recuperación](#11-reprocesamiento-backfill-y-recuperación)
12. [Seguridad y datos sensibles en pipelines](#12-seguridad-y-datos-sensibles-en-pipelines)
13. [FinOps de procesamiento de datos](#13-finops-de-procesamiento-de-datos)
14. [Criterios de paso a producción de un pipeline](#14-criterios-de-paso-a-producción-de-un-pipeline)
15. [Prohibiciones](#15-prohibiciones)

---

## 1. OBJETIVO

Establecer cómo se diseñan, aíslan, operan y gobiernan los flujos de datos institucionales, separando de forma explícita el **procesamiento por lotes (batch)** del **procesamiento en tiempo real (streaming/CDC)**, para que cada uno tenga su propia arquitectura, recursos, SLA, controles de seguridad y responsables.

Esta política complementa la arquitectura medallón definida en [07 §4.2](./07_Politica_Gobierno_Modelado_Documentacion.md#42-arquitectura-medallion): el medallón define **qué madurez** tiene el dato; esta política define **cómo y con qué latencia** se mueve.

---

## 2. PRINCIPIO DE SEPARACIÓN ENTRE BATCH Y TIEMPO REAL

### 2.1 Regla fundamental

> **Un flujo batch y un flujo en tiempo real nunca comparten el mismo proceso de ejecución, la misma cuenta de servicio ni la misma tabla de escritura.**

Pueden converger en la capa Silver o Gold, pero su ingesta, cómputo y control de errores deben ser independientes.

### 2.2 Justificación

| Riesgo de mezclar ambos modos | Consecuencia observada |
|---|---|
| Un backfill batch satura los slots compartidos | El flujo en tiempo real acumula lag y rompe su SLA de frescura |
| Una tabla recibe `streaming inserts` y un `MERGE` batch simultáneo | Conflictos de streaming buffer, duplicados y conteos inconsistentes |
| Una misma cuenta de servicio ejecuta ambos | Imposible aplicar mínimo privilegio ni atribuir costos o incidentes |
| Un error en el pipeline batch detiene el consumo de Pub/Sub | Crecimiento del backlog y pérdida de mensajes al vencer la retención |
| Un mismo runbook cubre ambos | La respuesta a incidentes es ambigua bajo presión |

### 2.3 Criterio de convergencia permitido

La convergencia (patrón *lambda* controlado) se permite únicamente cuando:

- Existen **tablas físicas separadas** por modo en Bronze (`..._rt` y `..._batch`).
- La unificación ocurre en Silver mediante una transformación **idempotente y versionada**, con regla de precedencia documentada ante conflicto.
- El cuadro semántico ([07 §7](./07_Politica_Gobierno_Modelado_Documentacion.md#7-cuadros-semánticos-y-métricas)) declara explícitamente la frescura resultante de la métrica.

---

## 3. TAXONOMÍA DE CARGAS DE DATOS

| Modo | Latencia objetivo | Disparo | Uso típico | Tecnología de referencia en GCP |
|---|---|---|---|---|
| **Batch programado** | Horas a 1 día | Calendario (Cloud Scheduler / Composer) | Cargas nocturnas, consolidación, datamarts, reportería institucional | Composer/Airflow, Dataform, Dataflow batch, `bq load`, Dataproc |
| **Micro-batch** | 5 a 60 min | Calendario frecuente o llegada de archivo | Tableros operativos, sincronizaciones intradía | Cloud Scheduler + Dataform, Dataflow con ventanas, BigQuery scheduled queries |
| **Streaming (eventos)** | Segundos | Publicación de evento | Telemetría, notificaciones, eventos de aplicación, IoT | Pub/Sub → Dataflow → BigQuery / BigQuery Subscriptions |
| **CDC (cambio de BD)** | Segundos a minutos | Cambio en la BD fuente | Réplica analítica de OLTP, sincronización entre sistemas | Datastream, Debezium sobre Pub/Sub/Kafka |
| **Bajo demanda / request-response** | Milisegundos | Llamada de aplicación | Consulta operacional, API | Cloud SQL / Firestore / Spanner directo — **no es un pipeline de datos** |

> Todo flujo debe declarar su modo en el catálogo. Un flujo sin modo declarado no se aprueba para producción.

---

## 4. CRITERIOS DE DECISIÓN: ¿BATCH O TIEMPO REAL?

El modo se elige por requisito de negocio verificable, no por preferencia técnica.

### 4.1 Matriz de decisión

| Criterio | Favorece batch | Favorece tiempo real |
|---|---|---|
| **Frescura exigida por el negocio** | El consumidor tolera datos de ayer o de hace horas | La decisión pierde valor si el dato tiene más de minutos |
| **Naturaleza del consumo** | Reportes, cierres, consolidaciones, modelos entrenados | Alertas, monitoreo operativo, detección, sincronización entre sistemas |
| **Volumen por unidad de tiempo** | Grandes volúmenes concentrados | Flujo continuo de eventos pequeños |
| **Necesidad de reproceso completo** | Frecuente y esperado | Excepcional; requiere diseño explícito de replay |
| **Complejidad de la transformación** | Joins amplios, agregaciones históricas, ventanas largas | Transformaciones acotadas por evento o ventana corta |
| **Costo** | Menor por dato procesado | Mayor: infraestructura permanente y operación continua |
| **Costo de la operación 24/7** | No requiere guardia dedicada | Requiere monitoreo de lag y guardia |
| **Tolerancia a duplicados** | Se resuelve en la carga | Debe resolverse con clave de deduplicación e idempotencia |

### 4.2 Regla de decisión

- Si la frescura requerida es **mayor o igual a 1 hora**, se usa batch o micro-batch. El tiempo real requiere justificación escrita.
- El tiempo real solo se aprueba con: (a) requisito de latencia firmado por el Data Owner, (b) estimación de costo mensual, (c) responsable de guardia identificado, (d) runbook de lag y de *dead letter*.
- **Prohibido** implementar streaming "por si acaso en el futuro se necesita". La sobreingeniería de latencia es un costo operativo permanente.

### 4.3 Aprobación

| Caso | Aprobadores mínimos |
|---|---|
| Nuevo pipeline batch en DEV/QA | DBA Profesional de Plataforma Analítica |
| Nuevo pipeline batch en PRD | DBA Lead + Data Owner |
| Nuevo pipeline en tiempo real (cualquier ambiente) | DBA Lead + DBA Senior + Data Owner |
| CDC sobre una base de datos productiva | DBA Lead + DBA responsable del motor + Product Owner del sistema fuente |
| Pipeline que transporta PII/PHI | Lo anterior + CISO ([13](./13_Politica_Datos_Salud_FHIR.md) si es dato de salud) |

---

## 5. ARQUITECTURA DE REFERENCIA — PROCESAMIENTO BATCH

### 5.1 Flujo

```text
Fuente (Cloud SQL / Mongo / Firestore / SFTP / API)
    │  extracción programada (export, bq load, Dataflow batch)
    ▼
Cloud Storage (landing, inmutable, particionado por fecha)
    │
    ▼
BigQuery BRONZE  (tabla cruda, particionada por fecha de ingesta)
    │  Dataform / dbt — transformación versionada e idempotente
    ▼
BigQuery SILVER  (validada, tipificada, deduplicada, conformada)
    │
    ▼
BigQuery GOLD    (datamart, modelo estrella, métricas certificadas)
    │
    ▼
Consumo: Looker / BI / API analítica
```

### 5.2 Reglas obligatorias

| Regla | Detalle |
|---|---|
| **Orquestación declarada** | Todo job batch se ejecuta desde un orquestador aprobado (Composer, Cloud Scheduler + Workflows, Dataform). Prohibidos los `cron` en máquinas personales o VMs no inventariadas. |
| **Idempotencia** | Reejecutar el job con los mismos parámetros debe producir el mismo resultado. Usar `MERGE` por clave de negocio o sobrescritura de partición, nunca `INSERT` ciego. |
| **Watermark explícito** | Cada carga incremental registra la marca de agua (fecha, LSN, `updated_at`) usada, en una tabla de control. |
| **Particionado por fecha de ingesta** | Obligatorio en Bronze; permite reprocesar una partición sin tocar el resto. |
| **Ventana de ejecución** | Los procesos masivos se ejecutan fuera de horas pico y no se solapan con la ventana de mantenimiento de la fuente ([09 §6.1](./09_Politica_Continuidad_Mantenimiento_DR.md#61-ventanas-de-mantenimiento)). |
| **Aislamiento de la fuente** | La extracción desde una BD productiva se realiza contra **réplica de lectura** cuando exista; si no existe, con límite de concurrencia y fuera de ventana crítica. |
| **Control de conteos** | Toda carga valida conteo origen vs destino y registra la diferencia ([07 §10.2](./07_Politica_Gobierno_Modelado_Documentacion.md#102-evidencia-requerida)). |
| **Límite de bytes** | Todo job debe enviar `maximum_bytes_billed` ([01 §6.3](./01_Politica_Gestion_Accesos_Bases_Datos.md#63-implementación-y-garantía-del-límite)). |
| **Reintentos acotados** | Máximo 3 reintentos con backoff exponencial; al agotarse, alerta al responsable, no reintento infinito. |
| **Estado registrado** | Cada ejecución registra origen, destino, filas leídas/escritas/rechazadas, duración, versión de la transformación y resultado de los controles de calidad. |

### 5.3 Ventanas de carga institucional

| Franja (UTC) | Uso | Regla |
|---|---|---|
| 02:00 – 05:00 | Cargas masivas Bronze → Silver | Ventana preferente; coordinar con ventanas de mantenimiento de Cloud SQL |
| 05:00 – 07:00 | Construcción de Gold y datamarts | No debe invadir el horario de consumo |
| 07:00 – 20:00 | Solo micro-batch y cargas incrementales acotadas | Procesos masivos requieren autorización del DBA Lead |
| 20:00 – 02:00 | Mantenimiento, backfills y reprocesos planificados | Requiere notificación previa a consumidores |

---

## 6. ARQUITECTURA DE REFERENCIA — PROCESAMIENTO EN TIEMPO REAL

### 6.1 Flujo de eventos

```text
Aplicación / dispositivo
    │  publica evento (esquema registrado)
    ▼
Pub/Sub  (tópico por dominio + suscripción por consumidor + dead letter topic)
    │
    ▼
Dataflow streaming  (validación, enriquecimiento, ventanas, deduplicación)
    │
    ▼
BigQuery BRONZE_RT  (append-only, particionada por hora de ingesta)
    │  transformación near-real-time (Dataform incremental / vista materializada)
    ▼
BigQuery SILVER  →  GOLD  →  Consumo operativo
```

### 6.2 Flujo CDC desde base de datos transaccional

```text
Cloud SQL PostgreSQL / MySQL / SQL Server (PRD)
    │  Datastream o Debezium — usuario dedicado de replicación, solo lectura
    ▼
Cloud Storage o Pub/Sub  (stream de cambios)
    │
    ▼
BigQuery BRONZE_CDC  (historial de cambios: op, ts, pk, before/after)
    │  MERGE incremental por clave primaria
    ▼
BigQuery SILVER  (estado actual conformado)
```

### 6.3 Reglas obligatorias

| Regla | Detalle |
|---|---|
| **Esquema registrado** | Todo tópico Pub/Sub declara su esquema (Avro/Protobuf) y su versión. Prohibido publicar JSON sin contrato ([§8](#8-contratos-de-datos-y-evolución-de-esquema)). |
| **Dead letter obligatorio** | Toda suscripción define *dead letter topic* con retención mínima de 7 días y alerta al superar el umbral acordado. |
| **Deduplicación** | Cada evento porta un `event_id` estable; el consumidor deduplica por ventana. No se asume entrega exactamente-una-vez. |
| **Manejo de datos tardíos** | Toda ventana declara su *allowed lateness* y el destino de los eventos que llegan fuera de ella (no se descartan en silencio). |
| **Orden no garantizado** | El diseño no puede depender del orden global de llegada; si se requiere orden, usar clave de ordenamiento o `ordering key` por partición. |
| **Retención de Pub/Sub** | Mínimo 7 días en tópicos de PRD, para permitir replay tras un incidente. |
| **Sin transformaciones pesadas en el stream** | Los joins amplios y las agregaciones históricas pertenecen a Silver/Gold en batch, no al pipeline de streaming. |
| **Streaming buffer** | Ninguna tabla que reciba `streaming inserts` puede ser modificada simultáneamente por procesos batch (DML/`MERGE`). Separar tablas. |
| **Autoescalado con techo** | Todo job Dataflow streaming declara máximo de *workers* para evitar costo descontrolado ante un pico o un bucle. |
| **Guardia asignada** | Todo pipeline de tiempo real en PRD tiene responsable primario y de respaldo ([14 §4](./14_Estructura_Equipo_RACI_Guardias.md#4-asignación-de-dominios-técnicos-primario-y-respaldo)). |

---

## 7. SEPARACIÓN DE RECURSOS, NOMENCLATURA Y ETIQUETADO

### 7.1 Separación obligatoria

| Recurso | Batch | Tiempo real |
|---|---|---|
| **Cuenta de servicio** | `sa-[sistema]-[ambiente]-batch` | `sa-[sistema]-[ambiente]-stream` |
| **Dataset Bronze** | `bronze_[dominio]` | `bronze_[dominio]_rt` |
| **Tabla de control** | `_ctl_batch_runs` | `_ctl_stream_health` |
| **Reservation / slots BigQuery** | Asignación batch (puede usar capacidad flexible) | Asignación reservada; no comparte con backfills |
| **Bucket de landing** | `gs://[org]-[amb]-landing-batch/` | `gs://[org]-[amb]-landing-stream/` |
| **Alertas** | Fallo de job, retraso de ventana | Lag, backlog, *dead letter*, caída de worker |
| **Runbook** | Reejecución de partición | Replay de suscripción y drenaje de backlog |

### 7.2 Nomenclatura de pipelines

```text
pl-[modo]-[dominio]-[origen]-a-[destino]-[ambiente]

Ejemplos:
pl-batch-academico-cloudsql-a-bronze-prd
pl-cdc-telemedicina-mssql-a-bronze-prd
pl-stream-monitoreo-pubsub-a-bronze-qa
```

Valores permitidos de `[modo]`: `batch`, `mbatch`, `stream`, `cdc`.

### 7.3 Etiquetas obligatorias

Además de las etiquetas de [08 §7.1](./08_Politica_Aprovisionamiento_Plataformas_Datos_GCP.md#71-etiquetas-obligatorias), todo recurso de pipeline lleva:

```yaml
processing_mode: batch|micro_batch|stream|cdc
pipeline: pl-<nombre-completo>
medallion_layer: bronze|silver|gold
source_system: <sistema_origen>
data_freshness_sla: <p.ej. 15m|4h|24h>
grupo_consumo: grupo01|grupo02|grupo03
```

### 7.4 Proyectos del data warehouse

El data warehouse institucional usa proyectos separados por capa y por ambiente (9 combinaciones). Las reglas de escritura son:

| Capa | Escribe | Lee |
|---|---|---|
| **Bronze** | Solo cuentas de servicio de ingesta (`*-batch`, `*-stream`) | Silver, DBA, auditoría |
| **Silver** | Solo cuentas de servicio de transformación | Gold, ingeniería de datos, DBA |
| **Gold** | Solo cuentas de servicio de publicación | BI, aplicaciones, analistas (vistas autorizadas) |

Ninguna persona escribe directamente en Bronze, Silver o Gold de PRD. Los cambios se promueven por pipeline versionado ([Build-Once-Promote-Everywhere](./10_Onboarding_Bases_de_Datos.md#6-onboarding--líder-técnico-bases-de-datos)).

---

## 8. CONTRATOS DE DATOS Y EVOLUCIÓN DE ESQUEMA

### 8.1 Contrato de datos obligatorio

Todo flujo entre un sistema productor y la plataforma de datos requiere un contrato versionado en repositorio que declare:

| Elemento | Descripción |
|---|---|
| **Productor y consumidor** | Sistemas y responsables funcionales |
| **Esquema** | Campos, tipos, obligatoriedad, dominios válidos |
| **Clave de negocio** | Identificador estable usado para deduplicar y hacer `MERGE` |
| **Modo y frecuencia** | `batch`/`stream`/`cdc` y cadencia o latencia objetivo |
| **SLA de frescura y completitud** | Valores medibles y alertables |
| **Clasificación de datos** | Según [07 §2.2](./07_Politica_Gobierno_Modelado_Documentacion.md#22-clasificación-de-datos) |
| **Política de datos tardíos y nulos** | Qué se hace con registros fuera de ventana o incompletos |
| **Versión y fecha de vigencia** | Semántica `MAJOR.MINOR` |

### 8.2 Reglas de evolución

- **Cambio compatible** (agregar campo opcional): versión `MINOR`, no requiere coordinación con consumidores, sí actualización del diccionario.
- **Cambio incompatible** (eliminar campo, cambiar tipo, cambiar semántica o granularidad): versión `MAJOR`; requiere periodo de convivencia de al menos **30 días** con ambas versiones y notificación a todos los consumidores registrados.
- **Prohibido** modificar el significado de un campo sin cambiar su nombre o su versión.
- Todo cambio de esquema sigue el flujo de aprobación de [07 §9](./07_Politica_Gobierno_Modelado_Documentacion.md#9-aprobación-de-cambios-de-modelo).

---

## 9. PROTECCIÓN DE LA BASE DE DATOS FUENTE (CDC)

El CDC introduce riesgo operativo directo sobre bases de datos productivas. Estos controles son obligatorios antes de habilitarlo.

### 9.1 Controles comunes

- Usuario de replicación **dedicado, nominativo por pipeline y de solo lectura**; nunca el usuario de la aplicación ni un superusuario.
- Credenciales en Secret Manager con rotación según [08 §6.2](./08_Politica_Aprovisionamiento_Plataformas_Datos_GCP.md#62-identidad-y-acceso).
- Conectividad privada (PSC, VPC Peering o Cloud SQL Auth Proxy). Prohibida la IP pública.
- Alerta de **lag de replicación** con umbral acordado por sistema ([09 §8.3](./09_Politica_Continuidad_Mantenimiento_DR.md#83-controles-de-replicación)).
- Prueba documentada en QA antes de habilitar en PRD, incluyendo el comportamiento ante caída del consumidor.

### 9.2 Controles por motor

| Motor | Riesgo principal | Control obligatorio |
|---|---|---|
| **PostgreSQL** | Un *replication slot* sin consumir retiene WAL y **llena el disco de la instancia primaria** | Alerta de `pg_replication_slots` inactivos y de crecimiento de WAL; procedimiento documentado de eliminación de slot huérfano; `max_slot_wal_keep_size` configurado |
| **MySQL** | Retención de binlog insuficiente rompe el CDC; retención excesiva consume disco | Definir `binlog_expire_logs_seconds` acorde a la ventana de recuperación del pipeline; alerta de uso de disco |
| **SQL Server** | `CDC`/`Change Tracking` sin limpieza infla las tablas de cambios | Job de retención configurado y monitoreado; validar impacto en el plan de mantenimiento |
| **MongoDB Atlas** | *Oplog* insuficiente provoca `resume token` inválido | Dimensionar oplog para cubrir la máxima indisponibilidad tolerada del consumidor |
| **Firestore** | Costo por lectura en exportaciones y *listeners* | Usar exportaciones programadas para batch; los *listeners* en tiempo real requieren justificación de costo |

### 9.3 Regla de degradación

> Si un pipeline CDC pone en riesgo la disponibilidad de la base de datos fuente productiva, **se detiene el pipeline**, no la base de datos. El DBA de guardia está autorizado a suspender la replicación sin aprobación previa, con notificación posterior dentro de la hora.

---

## 10. SLA, SLO Y OBSERVABILIDAD POR MODO

### 10.1 Indicadores mínimos

| Indicador | Batch | Tiempo real |
|---|---|---|
| **Frescura** | Hora de la última carga exitosa vs ventana comprometida | Antigüedad del último evento procesado (p95) |
| **Latencia** | Duración del job vs línea base | Tiempo evento → disponible en Bronze (p50, p95, p99) |
| **Completitud** | Conteo origen vs destino; registros rechazados | Mensajes recibidos vs procesados vs enviados a *dead letter* |
| **Salud del consumo** | Jobs fallidos, reintentos, solapamientos | Backlog de Pub/Sub, edad del mensaje más antiguo, lag de CDC |
| **Costo** | Bytes procesados y slot-hours por ejecución | Costo por hora del job streaming y de la reserva asignada |

### 10.2 Alertas obligatorias en PRD

| Alerta | Umbral de referencia | Severidad |
|---|---|---|
| Job batch crítico fallido | 1 fallo | P1 |
| Ventana de carga excedida | > 150 % de la duración de línea base | P2 |
| Frescura fuera de SLA | SLA + 1 periodo | P1 |
| Backlog de Pub/Sub creciente | Edad del mensaje más antiguo > 15 min | P1 |
| Mensajes en *dead letter* | > 0 en sistema crítico | P1 |
| Lag de CDC | > umbral acordado por sistema | P1 |
| *Replication slot* inactivo en PostgreSQL | > 1 h | **P0** (riesgo de llenar disco de PRD) |
| Costo diario de BigQuery | > 130 % del promedio de 7 días | P2 |

### 10.3 Documentación de la frescura al consumidor

Todo tablero, reporte o API analítica debe exponer visiblemente la **fecha y hora del dato**, no la fecha de consulta. Un consumidor que no sabe cuán fresco es el dato tomará decisiones equivocadas aunque el pipeline funcione correctamente.

---

## 11. REPROCESAMIENTO, BACKFILL Y RECUPERACIÓN

- Todo pipeline debe soportar **reproceso de un rango de fechas** sin intervención manual sobre los datos.
- Los backfills se ejecutan **en la ventana 20:00–02:00 UTC** y con reserva/slots separados de la operación diaria.
- Un backfill sobre Gold requiere aviso previo a los consumidores y registro del impacto en métricas certificadas.
- El replay de un tópico Pub/Sub se realiza mediante *snapshot* o *seek* documentado; nunca republicando manualmente eventos desde una estación de trabajo.
- Toda ejecución de backfill se registra con: rango, motivo, ejecutor, filas afectadas, verificación posterior.
- Los datos de Bronze son la fuente de verdad para reprocesar. **Está prohibido borrar Bronze** para "limpiar" un error; se corrige la transformación y se reprocesa.

---

## 12. SEGURIDAD Y DATOS SENSIBLES EN PIPELINES

- Los datos clasificados como **sensibles o regulados** ([07 §2.2](./07_Politica_Gobierno_Modelado_Documentacion.md#22-clasificación-de-datos)) no se publican en tópicos ni en datasets de propósito general sin tokenización, enmascaramiento o *policy tags*.
- **Prohibido** enviar PII/PHI a ambientes DEV/QA a través de un pipeline sin anonimización aprobada, aunque sea "solo para probar el flujo".
- Los mensajes en *dead letter* pueden contener datos sensibles: aplican los mismos controles de acceso y retención que la fuente.
- Los logs de los pipelines no deben registrar el contenido de los registros; solo identificadores técnicos y conteos.
- Las cuentas de servicio de pipeline tienen permisos por dataset y operación, nunca roles amplios de proyecto.
- Los pipelines que tocan datos de salud siguen adicionalmente [13 Datos de Salud / FHIR](./13_Politica_Datos_Salud_FHIR.md).

---

## 13. FINOPS DE PROCESAMIENTO DE DATOS

| Control | Regla |
|---|---|
| **Estimación previa** | Todo pipeline nuevo declara costo mensual estimado antes de aprobarse |
| **Límite por consulta** | `maximum_bytes_billed` obligatorio en todos los jobs |
| **Particionado y clustering** | Obligatorio en tablas grandes; las consultas del pipeline deben filtrar por partición |
| **Evitar `SELECT *`** | En todo el pipeline, incluidas las etapas intermedias |
| **Ciclo de vida** | Expiración de particiones en Bronze según retención acordada; transición a Nearline/Coldline/Archive en Cloud Storage |
| **Streaming bajo revisión** | Todo pipeline de tiempo real se revisa trimestralmente: si su latencia real no se aprovecha, se degrada a micro-batch |
| **Atribución** | Todo job lleva etiquetas de `pipeline`, `processing_mode`, `owner` y `cost_center` para atribuir el gasto |
| **Revisión mensual** | El DBA Senior revisa los 10 pipelines más costosos y propone optimizaciones ([14 §8](./14_Estructura_Equipo_RACI_Guardias.md#8-cadencias-operativas-del-área)) |

---

## 14. CRITERIOS DE PASO A PRODUCCIÓN DE UN PIPELINE

Antes de habilitar un pipeline en PRD se debe validar:

- [ ] Modo declarado (`batch`/`micro_batch`/`stream`/`cdc`) y justificado según §4.
- [ ] Contrato de datos versionado y aprobado por el Data Owner.
- [ ] Infraestructura creada por IaC y revisada.
- [ ] Cuentas de servicio separadas por modo, con permisos mínimos.
- [ ] Capa medallón de destino identificada, con propietario y clasificación.
- [ ] Idempotencia demostrada: ejecución doble sin duplicados.
- [ ] Controles de calidad implementados y probados (conteos, nulos, dominios).
- [ ] Alertas de §10.2 configuradas y probadas con un fallo simulado.
- [ ] Runbook de incidente redactado y validado por el respaldo designado.
- [ ] Prueba de reproceso/backfill ejecutada en QA.
- [ ] Para CDC: prueba de caída del consumidor y control de retención de WAL/binlog/oplog.
- [ ] Costo mensual estimado y etiquetas aplicadas.
- [ ] Diccionario de datos y linaje actualizados.

---

## 15. PROHIBICIONES

1. Ejecutar procesos de datos programados fuera de un orquestador aprobado (cron en VMs no inventariadas, tareas en estaciones personales, hojas de cálculo automatizadas).
2. Escribir directamente desde una persona hacia Bronze, Silver o Gold de PRD.
3. Mezclar escritura por streaming y DML batch sobre la misma tabla.
4. Habilitar CDC sobre una base productiva sin los controles de §9.
5. Publicar eventos sin esquema registrado o sin `event_id`.
6. Operar un pipeline de tiempo real sin responsable de guardia asignado.
7. Ejecutar backfills masivos en horario de consumo sin autorización del DBA Lead.
8. Mover PII/PHI a ambientes no productivos sin anonimización aprobada.
9. Descartar silenciosamente registros rechazados o eventos tardíos sin registrarlos.
10. Depender de `time travel` de BigQuery como estrategia de recuperación de un pipeline ([09 §3.1](./09_Politica_Continuidad_Mantenimiento_DR.md#31-matriz-general)).

---

**IMPORTANTE:** Un pipeline sin contrato de datos, sin modo declarado, sin alertas y sin responsable no es un activo institucional: es una dependencia oculta. No debe promoverse a producción.
