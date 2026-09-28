# POLÍTICA DE APROVISIONAMIENTO DE PLATAFORMAS DE DATOS EN GCP

> **Aplicable a:** Cloud SQL, Spanner, AlloyDB, Firestore, Firebase, MongoDB Atlas, BigQuery y Cloud Healthcare API  
> **Responsables:** DBA, DevOps, Arquitectura Cloud, Seguridad, Data Engineering  
> **Estado real de la plataforma:** [15_Linea_Base_Inventario_CloudSQL.md](./15_Linea_Base_Inventario_CloudSQL.md)  
> **Última actualización:** 2026-09-17

---

## ÍNDICE

1. [Objetivo](#1-objetivo)
2. [Principios de Aprovisionamiento](#2-principios-de-aprovisionamiento)
3. [Estándares Generales en GCP](#3-estándares-generales-en-gcp)
   - [3.3 Estándar de Nomenclatura](#33-estándar-de-nomenclatura)
   - [3.4 Golden Path de Versiones de Motor](#34-golden-path-de-versiones-de-motor)
   - [3.5 Ventana de Mantenimiento y Canal de Actualización](#35-ventana-de-mantenimiento-y-canal-de-actualización)
   - [3.6 Región Institucional](#36-región-institucional)
   - [3.7 Proyectos del Data Warehouse Medallón](#37-proyectos-del-data-warehouse-medallón)
4. [Criterios de Selección de Motor](#4-criterios-de-selección-de-motor)
5. [Política por Plataforma](#5-política-por-plataforma)
6. [Red, Seguridad e Identidad](#6-red-seguridad-e-identidad)
7. [Etiquetado, Inventario y Costos](#7-etiquetado-inventario-y-costos)
8. [Proceso de Solicitud y Aprobación](#8-proceso-de-solicitud-y-aprobación)
9. [Criterios de Producción](#9-criterios-de-producción)

---

## 1. OBJETIVO

Definir controles obligatorios para solicitar, diseñar, aprovisionar, configurar y operar plataformas de datos en Google Cloud Platform y servicios administrados conectados, asegurando seguridad, disponibilidad, cumplimiento, rendimiento y control de costos desde el primer despliegue.

---

## 2. PRINCIPIOS DE APROVISIONAMIENTO

- Toda infraestructura de datos debe crearse mediante IaC, preferiblemente Terraform.
- Producción debe estar separada de DEV y QA por proyecto, red, secretos y políticas IAM.
- Todo recurso debe tener dueño, ambiente, clasificación de datos, criticidad y centro de costo.
- Las plataformas deben usar conectividad privada cuando el servicio lo soporte.
- Toda base productiva debe tener backups, monitoreo, alertas, auditoría y plan de recuperación antes de recibir datos reales.
- La elección del motor debe responder a requisitos de negocio y técnicos, no a preferencia individual.

---

## 3. ESTÁNDARES GENERALES EN GCP

### 3.1 Separación de Ambientes

| Ambiente | Proyecto | Datos permitidos | Controles |
|----------|----------|------------------|-----------|
| **DEV** | Proyecto independiente | Sintéticos o anonimizados | Seguridad básica, costos limitados |
| **QA/STG** | Proyecto independiente | Anonimizados o subconjunto controlado | Auditoría media, pruebas de cambios |
| **PRD** | Proyecto productivo | Datos reales autorizados | Seguridad completa, HA/DR, auditoría completa |

### 3.2 Requisitos Mínimos de Todo Recurso

| Requisito | Política |
|-----------|----------|
| **IaC** | Terraform o pipeline aprobado; cambios manuales solo emergencia documentada |
| **Secretos** | Secret Manager; prohibido guardar credenciales en código o archivos planos |
| **Cifrado** | Cifrado en reposo y tránsito; CMEK obligatorio para datos regulados |
| **Logs** | Cloud Audit Logs habilitado; Data Access Logs en PRD cuando aplique |
| **Monitoreo** | Métricas de disponibilidad, latencia, almacenamiento, conexiones y errores |
| **Backups** | Política definida antes de producción |
| **Etiquetas** | `env`, `owner`, `system`, `data_classification`, `cost_center`, `criticality` |

### 3.3 Estándar de Nomenclatura

Todo recurso de datos debe utilizar un nombre descriptivo, consistente, trazable y único dentro de su alcance. Los nombres deben escribirse en minúsculas, sin espacios, tildes ni caracteres especiales, utilizando guion medio (`-`) como separador.

#### 3.3.1 Instancias de bases de datos

Las instancias administradas de bases de datos deben seguir el patrón:

```text
svr-[motor]-[nombre_aplicacion]-[ambiente][NN]
```

Ejemplos:

```text
svr-pstr-sigma-dev01
svr-pstr-sigma-qa01
svr-pstr-sigma-prd01
svr-mysq-avanzo-prd01
svr-mssq-siges-qa01
```

Abreviaturas aprobadas para `[motor]` (cuatro caracteres):

| Código | Motor |
|--------|-------|
| `pstr` | PostgreSQL |
| `mysq` | MySQL |
| `mssq` | Microsoft SQL Server |
| `span` | Cloud Spanner |
| `ally` | AlloyDB |
| `mong` | MongoDB |

> **Nota de versión:** los códigos `pstr` y `mysq` reemplazan a `pg` y `myql` de la versión anterior de esta política. Se adoptan los códigos que el parque ya usaba de hecho, para no invalidar las 40 instancias existentes que sí seguían el prefijo `svr-` ([15 §5](./15_Linea_Base_Inventario_CloudSQL.md#5-nomenclatura)). El estándar se ajusta a la realidad, no al revés.

Reglas:

- `[nombre_aplicacion]` debe corresponder al sistema o producto propietario de la instancia.
- `[ambiente]` debe ser `dev`, `qa`, `stg` o `prd`. **Nunca `prod`**: existen instancias con esa variante y no se acepta en nombres nuevos.
- `[NN]` es una secuencia de dos dígitos, obligatoria cuando exista más de una instancia del mismo sistema y ambiente.
- Las réplicas de lectura se nombran con el sufijo `-replica[NN]` sobre el nombre de su primaria.
- El nombre debe permitir identificar motor, aplicación y ambiente sin consultar el inventario.
- No incluir contraseñas, identificadores personales, **regiones** ni datos sensibles en el nombre. Incluir la región dificulta las migraciones regionales y contradice el plan de DR.
- BigQuery no utiliza instancias con este patrón; sus proyectos, datasets, tablas y vistas deben seguir la nomenclatura definida para recursos analíticos y conservar las etiquetas obligatorias.

#### 3.3.2 Aplicación retroactiva del estándar

Renombrar una instancia de Cloud SQL obliga a recrearla. Por lo tanto, el estándar se aplica así:

| Situación | ¿Aplica el estándar? |
|---|---|
| Instancia nueva | **Sí, obligatorio.** No se aprueba el aprovisionamiento sin nombre conforme. |
| Instancia existente que se migra, recrea o actualiza de versión mayor | **Sí, obligatorio** en la recreación. |
| Instancia productiva estable | **No se fuerza el renombrado.** Se registra la excepción en el inventario con fecha prevista de regularización. |
| Etiquetas obligatorias (§7.1) | **Siempre exigibles**, cumpla o no el nombre. No requieren recrear nada. |

---

### 3.4 Golden Path de Versiones de Motor

Toda instancia nueva se aprovisiona en la versión Golden Path vigente. Estas versiones se derivan del inventario real y se revisan semestralmente por el Líder Técnico junto con el DBA Senior.

| Motor | Golden Path | Mínimo aceptable | Prohibido en PRD |
|---|---|---|---|
| **PostgreSQL** | 18.x | 16.x | ≤ 14.x |
| **MySQL** | 8.4 LTS | 8.0.x actualizada | 5.7 y anteriores |
| **SQL Server** | 2022 Standard | 2019 Standard | ≤ 2017 |

Reglas:

- Una versión distinta al Golden Path requiere justificación técnica aprobada por el Líder Técnico.
- La edición **Enterprise** de SQL Server requiere justificación funcional documentada (características realmente utilizadas) y validación de costo. Por defecto se aprovisiona Standard.
- Las versiones menores dentro de una misma rama se homogenizan durante la ventana de mantenimiento; no se mantienen múltiples versiones menores del mismo motor sin razón operativa.
- Una instancia con motor fuera de soporte del proveedor constituye un hallazgo de severidad **Crítica** y debe remediarse en 30 días.

---

### 3.5 Ventana de Mantenimiento y Canal de Actualización

Toda instancia debe tener ventana y canal **explícitos**. El valor por defecto no se considera configuración válida.

| Ambiente | Canal | Ventana (UTC) |
|---|---|---|
| **DEV** | Anticipado (canary) | Martes 05:00 |
| **QA / STG** | Anticipado (canary) | Miércoles 05:00 |
| **PRD** | Producción (stable) | Domingo 06:00–08:00 |

- **Producción nunca usa el canal anticipado.** El propósito del canal es validar las actualizaciones en ambientes inferiores antes de que lleguen a PRD.
- La ventana de una **réplica** se programa en un horario distinto al de su primaria, para no perder ambas simultáneamente.
- Las ventanas de mantenimiento no deben solaparse con las ventanas de carga batch definidas en [12 §5.3](./12_Politica_Ingenieria_Datos_Batch_Streaming.md#53-ventanas-de-carga-institucional).
- Las ventanas de PRD se comunican a los Product Owners con al menos 5 días hábiles de anticipación.

---

### 3.6 Región Institucional

| Uso | Región |
|---|---|
| **Región primaria** | `us-east1` |
| **Región secundaria (DR)** | A definir y ratificar por el DBA Senior; debe quedar declarada antes del próximo simulacro de DR |
| Excepciones | Requieren justificación por latencia, residencia de datos o requisito contractual, aprobada por el Líder Técnico |

- El 80 % del parque está hoy concentrado en `us-east1`. Esa concentración es aceptable como decisión de estandarización, pero **exige una estrategia de DR interregional explícita y probada** ([09 §9](./09_Politica_Continuidad_Mantenimiento_DR.md#9-disaster-recovery)).
- Las instancias dispersas en regiones sin justificación deben consolidarse o documentar su excepción.
- Para datos regulados y de salud, la región debe validarse contra los requisitos de residencia de [13 §3](./13_Politica_Datos_Salud_FHIR.md#3-arquitectura-y-separación-de-ambientes).

---

### 3.7 Proyectos del Data Warehouse Medallón

El Data Warehouse se despliega como **nueve proyectos**: una capa × un ambiente por proyecto. Nunca se mezclan capas ni ambientes dentro de un mismo proyecto.

```text
dw-[capa]-[ambiente]

Capas:     bronze | silver | gold
Ambientes: dev | qa | prd

dw-bronze-dev   dw-silver-dev   dw-gold-dev
dw-bronze-qa    dw-silver-qa    dw-gold-qa
dw-bronze-prd   dw-silver-prd   dw-gold-prd
```

Reglas:

- La separación por proyecto es **de seguridad y de costo**, no solo organizativa: permite IAM, cuotas de slots y presupuestos independientes por capa y ambiente.
- Un proyecto de una capa **nunca escribe** en el proyecto de otra capa fuera del flujo declarado en [12 §7.4](./12_Politica_Ingenieria_Datos_Batch_Streaming.md#74-proyectos-del-data-warehouse).
- Ningún proyecto de DEV o QA puede leer datos de un proyecto PRD.
- Los datos de salud identificables no se copian al Data Warehouse; solo ingresan desidentificados o seudonimizados según [13 §7](./13_Politica_Datos_Salud_FHIR.md#7-integración-con-el-data-warehouse).
- Las etiquetas obligatorias de §7.1 aplican a los nueve proyectos, más la etiqueta `medallion_layer`.

---

## 4. CRITERIOS DE SELECCIÓN DE MOTOR

| Necesidad | Plataforma recomendada |
|-----------|------------------------|
| Transacciones relacionales tradicionales | Cloud SQL PostgreSQL/MySQL/SQL Server |
| PostgreSQL administrado de alto rendimiento | AlloyDB |
| Escala global relacional, alta concurrencia, consistencia fuerte | Cloud Spanner |
| Documentos con sincronización móvil/web y reglas cliente | Firestore/Firebase |
| Documentos flexibles, agregaciones, ecosistema MongoDB | MongoDB Atlas |
| Analítica, BI, data warehouse, datasets masivos | BigQuery |
| Métricas certificadas y cuadros semánticos | BigQuery + capa semántica aprobada |

### 4.1 Criterios Obligatorios de Evaluación

- Volumen actual y crecimiento esperado.
- Latencia requerida de lectura y escritura.
- Consistencia requerida.
- Patrón de consultas y transacciones.
- Requisitos de HA/DR y residencia de datos.
- Clasificación de datos y regulaciones aplicables.
- Costo estimado mensual y costo de operación.
- Capacidades del equipo para operar el motor.

---

## 5. POLÍTICA POR PLATAFORMA

### 5.1 Cloud SQL

| Control | DEV | QA | PRD |
|---------|-----|----|-----|
| **IP pública** | Evitar | Prohibida salvo excepción | Prohibida |
| **Private IP** | Recomendada | Obligatoria | Obligatoria |
| **Backups automáticos** | Recomendado | Obligatorio | Obligatorio |
| **HA regional** | No requerido | Recomendado | Obligatorio para sistemas críticos |
| **PITR** | Opcional | Recomendado | Obligatorio |
| **CMEK** | Opcional | Según clasificación | Obligatorio para regulados |
| **Auditoría** | Básica | Completa para cambios | Completa |

Reglas adicionales:

- Usar Cloud SQL Auth Proxy, IAM DB Authentication o conectividad privada aprobada.
- Configurar parámetros del motor según carga real y recomendaciones DBA.
- Habilitar slow query log o equivalente para análisis de rendimiento.
- Definir ventana de mantenimiento y canal de actualizaciones.

### 5.2 AlloyDB

| Control | Política |
|---------|----------|
| **Uso** | Cargas PostgreSQL críticas, analíticas operacionales o alto rendimiento |
| **Red** | Private Service Connect o conectividad privada |
| **HA** | Clúster regional en PRD para sistemas críticos |
| **Backups** | Automáticos + PITR según criticidad |
| **Migración** | Requiere prueba de compatibilidad PostgreSQL, rendimiento y rollback |
| **Acceso** | IAM, roles mínimos y cuentas separadas por aplicación |

### 5.3 Cloud Spanner

| Control | Política |
|---------|----------|
| **Uso** | Escala horizontal, consistencia fuerte, alta disponibilidad regional/multirregional |
| **Modelo** | Diseñar llaves primarias para evitar hotspots |
| **Índices** | Crear solo índices respaldados por consultas reales |
| **Backups** | Backups programados y exportaciones para retención extendida |
| **Cambios DDL** | Evaluar impacto por operaciones online y tiempo de propagación |
| **IAM** | Separar administración de instancia, base y lectura de datos |

### 5.4 Firestore y Firebase

| Control | Política |
|---------|----------|
| **Modo** | Definir Native o Datastore antes de creación; no reversible sin migración |
| **Reglas** | Security Rules obligatorias y probadas antes de producción |
| **Índices** | Versionar índices compuestos requeridos por consultas |
| **TTL** | Aplicar a datos temporales cuando sea posible |
| **Backups/export** | Exportaciones programadas a Cloud Storage para datos críticos |
| **Cliente** | No exponer datos sensibles por reglas permisivas o filtros solo en frontend |

### 5.5 MongoDB Atlas

| Control | Política |
|---------|----------|
| **Conectividad** | Private Service Connect, VPC Peering o IP allowlist mínima |
| **Autenticación** | Usuarios por aplicación/persona; prohibidas cuentas compartidas |
| **Backups** | Cloud Backups habilitados en PRD |
| **Cifrado** | En tránsito y reposo; evaluar CMK para regulados |
| **Auditoría** | Database auditing en clusters críticos |
| **Índices** | Revisión periódica de índices, queries lentas y cardinalidad |

### 5.6 BigQuery

| Control | Política |
|---------|----------|
| **Datasets** | Separar raw, curated, semantic y sandbox |
| **Ubicación** | Definir región según residencia de datos y cercanía a fuentes |
| **Particionado** | Obligatorio para tablas grandes o de eventos por fecha |
| **Clustering** | Recomendado para filtros frecuentes y reducción de costo |
| **IAM** | Preferir acceso por dataset, authorized views, row access policies y policy tags |
| **Costos** | Presupuestos, cuotas, alertas y revisión de consultas costosas |
| **Retención** | Expiración de tablas temporales y snapshots controlados |

---

## 6. RED, SEGURIDAD E IDENTIDAD

### 6.1 Controles de Red

- Producción debe usar conectividad privada siempre que el motor lo soporte.
- Las reglas de firewall deben limitar origen, puerto y destino.
- El acceso administrativo debe pasar por VPN, IAP, bastion aprobado o proxy seguro.
- No se permite exponer motores de base de datos directamente a Internet en PRD.

### 6.2 Identidad y Acceso

- Usar cuentas nominativas para personas y mecanismos de identidad aprobados para aplicaciones.
- Prohibidas cuentas compartidas en producción.
- MFA obligatorio para accesos administrativos y consolas cloud.
- Privilegios administrativos permanentes en PRD solo por excepción aprobada.
- Rotación de secretos al menos cada 90 días o según política de seguridad.

### 6.3 Seguridad de Datos

- Cifrado en tránsito obligatorio con TLS.
- Cifrado en reposo obligatorio; CMEK cuando exista dato regulado o requerimiento contractual.
- DLP, enmascaramiento, tokenización o vistas autorizadas para exposición de PII/PHI.
- Los ambientes DEV/QA no deben contener datos reales sin anonimización aprobada.

---

## 7. ETIQUETADO, INVENTARIO Y COSTOS

### 7.1 Etiquetas Obligatorias

```yaml
env: dev|qa|prd
owner: correo_o_equipo_responsable
system: nombre_sistema
data_classification: publica|interna|confidencial|sensible|regulada
criticality: baja|media|alta|critica
cost_center: codigo_presupuestario
managed_by: terraform|manual-excepcion
```

### 7.2 Inventario

El inventario debe registrar:

- Plataforma y versión.
- Proyecto GCP, región y red.
- Owner, steward y custodio técnico.
- Ambientes existentes.
- Clasificación de datos.
- Política de backup y retención.
- Usuarios administrativos y mecanismos de identidad de aplicaciones.
- Dependencias, consumidores y ventanas de mantenimiento.

---

## 8. PROCESO DE SOLICITUD Y APROBACIÓN

### 8.1 Información Requerida

- Objetivo de negocio.
- Motor solicitado y justificación.
- Ambiente.
- Clasificación de datos.
- Estimación de volumen, crecimiento y concurrencia.
- Requisitos de disponibilidad, RPO y RTO.
- Integraciones y consumidores.
- Responsable funcional y técnico.
- Estimación de costo mensual.

### 8.2 Aprobaciones

| Caso | Aprobadores mínimos |
|------|---------------------|
| DEV sin datos sensibles | Product Owner + DBA/DevOps |
| QA con datos anonimizados | Product Owner + DBA Lead |
| PRD no regulado | Product Owner + DBA Lead + Arquitectura Cloud |
| PRD sensible/regulado | Product Owner + DBA Lead + CISO + Arquitectura Cloud |
| Motor nuevo en la organización | CTO/Arquitectura + DBA Lead + Seguridad |

---

## 9. CRITERIOS DE PRODUCCIÓN

Antes de pasar a producción se debe validar:

- Infraestructura creada por IaC y revisada.
- Red privada, IAM y secretos configurados.
- Backups, PITR y restauración probados según criticidad.
- Monitoreo, alertas y logs habilitados.
- Diccionario de datos, diagrama y clasificación completos.
- Plan de mantenimiento y ventana definida.
- Matriz de accesos aprobada.
- Prueba de carga o validación de rendimiento para sistemas críticos.
- Runbook de operación y procedimiento de incidentes.

---

**IMPORTANTE:** Ninguna plataforma de datos debe recibir información productiva si no cumple los criterios mínimos de seguridad, respaldo, monitoreo, documentación y aprobación definidos en esta política.