# POLÍTICA DE CONTINUIDAD, MANTENIMIENTO, REPLICACIÓN Y DR

> **Aplicable a:** Plataformas de bases de datos operacionales, analíticas y documentales  
> **Responsables:** DBA, SRE/DevOps, Seguridad, Product Owner, Arquitectura Cloud  
> **Última actualización:** 2026-08-21

---

## ÍNDICE

1. [Objetivo](#1-objetivo)
2. [Criticidad, RPO y RTO](#2-criticidad-rpo-y-rto)
3. [Política de Respaldos por Motor](#3-política-de-respaldos-por-motor)
4. [Almacenamiento, Retención y Protección](#4-almacenamiento-retención-y-protección)
5. [Pruebas de Restauración](#5-pruebas-de-restauración)
6. [Mantenimientos e Índices](#6-mantenimientos-e-índices)
7. [Performance y Optimización de Consultas](#7-performance-y-optimización-de-consultas)
8. [Replicación y Alta Disponibilidad](#8-replicación-y-alta-disponibilidad)
9. [Disaster Recovery](#9-disaster-recovery)
10. [Runbooks y Evidencia](#10-runbooks-y-evidencia)

---

## 1. OBJETIVO

Definir políticas para proteger la disponibilidad, integridad y recuperabilidad de los datos mediante respaldos, retención, pruebas de restauración, mantenimiento preventivo, optimización, replicación, alta disponibilidad y recuperación ante desastres.

---

## 2. CRITICIDAD, RPO Y RTO

### 2.1 Niveles de Criticidad

| Criticidad | Descripción | RPO objetivo | RTO objetivo |
|------------|-------------|--------------|--------------|
| **Crítica** | Servicios esenciales, salud, identidad, financieros, operación 24/7 | 15 min - 1 h | 1 - 4 h |
| **Alta** | Sistemas importantes con impacto institucional | 4 h | 8 h |
| **Media** | Sistemas operativos con tolerancia moderada | 24 h | 24 h |
| **Baja** | Desarrollo, pruebas, datos reconstruibles | 24 - 72 h | 48 - 72 h |

### 2.2 Reglas

- Todo sistema debe tener criticidad aprobada por Product Owner y DBA Lead.
- RPO/RTO deben documentarse antes del aprovisionamiento productivo.
- Si el RPO/RTO requerido no puede cumplirse con la arquitectura actual, debe existir plan de remediación o aceptación formal de riesgo.

---

## 3. POLÍTICA DE RESPALDOS POR MOTOR

### 3.1 Matriz General

| Motor | Metodología | Periodicidad PRD | Retención mínima PRD | Observaciones |
|-------|-------------|------------------|----------------------|---------------|
| **Cloud SQL** | Backups automáticos + PITR + export periódico | Diario + logs continuos | 30 días operativos + export mensual 1 año | Sistemas regulados: retención legal según norma |
| **AlloyDB** | Continuous backup/PITR + backups bajo demanda | Continuo + diario lógico si aplica | 30 días | Probar restore a clúster alterno |
| **Spanner** | Backups programados + export a BigQuery/GCS si aplica | Diario o según criticidad | 30-90 días | Backups consistentes sin bloqueo operacional |
| **Firestore** | Export programado a Cloud Storage | Diario para críticos, semanal para medios | 30-90 días | Validar restauración por colección/proyecto |
| **Firebase RTDB** | Export JSON/backup programado | Diario para críticos | 30 días | Controlar tamaño y cifrado del bucket |
| **MongoDB Atlas** | Cloud Backup snapshots + PITR si tier lo soporta | Continuo/snapshot diario | 30 días mínimo | Habilitar PITR para cargas críticas |
| **BigQuery** | Time travel, snapshots, table clones, exports | Según criticidad de dataset | 7 días time travel + snapshots 30-365 días | Evitar depender solo de time travel |

### 3.2 Ambientes No Productivos

| Ambiente | Periodicidad | Retención |
|----------|--------------|-----------|
| **DEV** | Bajo demanda o semanal | 3-7 días |
| **QA/STG** | Diario si soporta pruebas críticas | 7-15 días |
| **PRD** | Según matriz por motor y criticidad | 30 días mínimo |

### 3.3 Respaldos Lógicos vs Físicos

| Tipo | Uso | Consideración |
|------|-----|---------------|
| **Físico/snapshot** | Recuperación rápida de instancia o clúster | Debe probarse restore completo |
| **Lógico/export** | Portabilidad, retención extendida, migraciones | Puede tardar más y requerir validación de consistencia |
| **PITR** | Recuperación a punto en el tiempo | Requiere logs continuos y ventana definida |
| **Snapshot de tabla/dataset** | BigQuery y analítica | Útil para rollback de procesos ELT |

---

## 4. ALMACENAMIENTO, RETENCIÓN Y PROTECCIÓN

### 4.1 Almacenamiento

- Respaldos productivos deben almacenarse en ubicación aprobada y separada lógicamente del origen.
- Exports de larga retención deben ir a Cloud Storage con versioning, lifecycle y retención configurada.
- Para datos regulados, usar bucket con CMEK, uniform bucket-level access y acceso restringido.
- Prohibido descargar respaldos productivos a estaciones personales.

### 4.2 Retención Recomendada

| Tipo de dato | Retención mínima | Retención recomendada |
|--------------|------------------|-----------------------|
| Operacional no regulado | 30 días | 90 días |
| Financiero/administrativo | 90 días | 1-5 años según norma |
| Salud, identidad o regulado | Según ley/contrato | 5-7 años o política legal |
| Logs de auditoría | 365 días | 7 años para compliance |
| Datos temporales | Según TTL | Eliminación automática |

### 4.3 Lifecycle

- Definir transición a Nearline/Coldline/Archive para retención extendida.
- Definir eliminación automática al vencer retención, salvo legal hold.
- Documentar excepciones aprobadas por Legal/CISO.

---

## 5. PRUEBAS DE RESTAURACIÓN

### 5.1 Frecuencia

| Criticidad | Frecuencia de prueba |
|------------|----------------------|
| **Crítica** | Trimestral |
| **Alta** | Semestral |
| **Media** | Anual |
| **Baja** | Bajo demanda |

### 5.2 Evidencia Obligatoria

- Fecha, motor, instancia/dataset y backup utilizado.
- Responsable que ejecutó la prueba.
- Tiempo real de restauración.
- Validación de conteos, integridad y acceso de aplicación.
- Incidentes encontrados y acciones correctivas.
- Comparación contra RPO/RTO objetivo.

---

## 6. MANTENIMIENTOS E ÍNDICES

### 6.1 Ventanas de Mantenimiento

| Ambiente | Política |
|----------|----------|
| **DEV** | Flexible, coordinada con equipo de desarrollo |
| **QA** | Previa notificación, evitando ciclos de prueba críticos |
| **PRD** | Ventana aprobada, comunicación previa y plan de rollback |

### 6.2 Índices por Motor

| Motor | Política de mantenimiento |
|-------|---------------------------|
| **PostgreSQL/Cloud SQL/AlloyDB** | Revisar bloat, `VACUUM`, `ANALYZE`, índices no usados y queries lentas |
| **MySQL** | Revisar slow queries, cardinalidad, fragmentación y estadísticas |
| **SQL Server** | Revisar fragmentación, update statistics, planes y missing indexes |
| **Spanner** | Validar hotspots, interleaving, índices secundarios y latencia de commits |
| **Firestore** | Revisar índices compuestos, lecturas excesivas y estructura documental |
| **MongoDB Atlas** | Revisar query profiler, índices no usados, cardinalidad y working set |
| **BigQuery** | Revisar particiones, clustering, bytes procesados y materialized views |

### 6.3 Reglas para Índices

- Todo índice nuevo en PRD debe tener consulta justificante, impacto esperado y plan de rollback.
- Índices duplicados o no usados deben evaluarse trimestralmente.
- En tablas grandes, crear índices con mecanismos online/concurrentes cuando el motor lo permita.
- No crear índices para cada columna sin análisis de selectividad, cardinalidad y patrón de consulta.

---

## 7. PERFORMANCE Y OPTIMIZACIÓN DE CONSULTAS

### 7.1 Controles Mínimos

- Slow query log o equivalente habilitado en ambientes productivos.
- Alertas por CPU, memoria, almacenamiento, conexiones, latencia y errores.
- Revisión mensual de consultas más costosas en sistemas críticos.
- Pruebas de carga para releases con cambios relevantes de modelo o consultas.

### 7.2 Reglas de Consultas

- Evitar `SELECT *` en procesos productivos y APIs.
- Consultas batch deben tener límites, filtros y ventanas controladas.
- Procesos masivos deben ejecutarse fuera de horas pico o con throttling.
- En BigQuery, toda consulta recurrente debe optimizar bytes procesados y usar particiones cuando existan.
- Cambios de consulta que incrementen costo o latencia significativamente requieren revisión.

---

## 8. REPLICACIÓN Y ALTA DISPONIBILIDAD

### 8.1 Alta Disponibilidad

| Motor | Política HA |
|-------|-------------|
| **Cloud SQL** | HA regional obligatoria para PRD crítico; read replicas según carga |
| **AlloyDB** | Nodos/región según criticidad; replicas para lectura si aplica |
| **Spanner** | Configuración regional o multirregional según RTO/RPO y residencia |
| **Firestore/Firebase** | Seleccionar ubicación regional/multirregional según criticidad |
| **MongoDB Atlas** | Replica set multi-AZ obligatorio en PRD |
| **BigQuery** | Evaluar replicación administrada, snapshots y exports para continuidad |

### 8.2 Replicación

| Tipo | Uso | Reglas |
|------|-----|--------|
| **Read replica** | Descarga de lecturas y reporting operacional | No sustituye backup |
| **CDC/Debezium** | Integración, eventos, data warehouse | Monitorear lag, slots y retención |
| **Cross-region replica** | Continuidad regional | Probar promoción/failover |
| **Export/ELT** | Analítica y retención | Validar completitud y reintentos |

### 8.3 Controles de Replicación

- Monitorear lag y generar alerta si excede umbral acordado.
- Documentar origen, destino, frecuencia, transformación y dueño.
- Cifrar tráfico y limitar permisos del usuario de replicación.
- Probar recuperación cuando la réplica sea parte del plan DR.

---

## 9. DISASTER RECOVERY

### 9.1 Plan DR Obligatorio

Todo sistema crítico debe contar con un plan DR que incluya:

- Escenario cubierto: pérdida de instancia, zona, región, corrupción lógica, borrado accidental.
- RPO/RTO objetivo y RPO/RTO probado.
- Arquitectura de recuperación.
- Procedimiento de activación y criterios de decisión.
- Responsables, contactos y escalamiento.
- Pasos de failover/failback.
- Validaciones funcionales posteriores.
- Comunicación interna y externa.

### 9.2 Frecuencia de Simulacros

| Criticidad | Simulacro DR |
|------------|--------------|
| **Crítica** | Anual completo + prueba técnica trimestral |
| **Alta** | Anual |
| **Media** | Cada 18-24 meses |
| **Baja** | No obligatorio, salvo dependencia crítica |

### 9.3 Criterios de Activación

- Pérdida de disponibilidad mayor al RTO tolerable.
- Corrupción de datos confirmada sin recuperación rápida local.
- Pérdida de región o servicio administrado prolongada.
- Incidente de seguridad que requiere aislamiento y restauración controlada.

---

## 10. RUNBOOKS Y EVIDENCIA

### 10.1 Runbooks Obligatorios

- Backup manual y validación.
- Restore completo y parcial.
- Failover y failback.
- Rotación de credenciales.
- Manejo de query degradada o bloqueo.
- Crecimiento de almacenamiento.
- Corrupción lógica o borrado accidental.
- Incidente de seguridad con base de datos.

### 10.2 Evidencia Operativa

El DBA Lead debe conservar evidencia de:

- Backups ejecutados y fallidos.
- Pruebas de restore.
- Cambios de configuración.
- Mantenimientos ejecutados.
- Revisión de índices y performance.
- Simulacros DR.
- Incidentes y lecciones aprendidas.

---

**IMPORTANTE:** Un backup no probado no se considera recuperable. Todo sistema productivo crítico debe demostrar restauración, failover y cumplimiento de RPO/RTO mediante evidencia verificable.