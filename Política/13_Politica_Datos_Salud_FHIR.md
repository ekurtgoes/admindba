# POLÍTICA DE DATOS DE SALUD Y PLATAFORMA FHIR

> **Aplicable a:** Cloud Healthcare API (almacenes FHIR, HL7v2, DICOM), bases de datos y datasets que contengan información de salud (PHI), y todo sistema de telemedicina, expediente clínico, laboratorio, farmacia o copiloto médico
> **Responsables:** DBA Lead, DBA Senior, CISO, Data Owner clínico, Legal/Cumplimiento
> **Documentos base:** [01 Gestión de Accesos](./01_Politica_Gestion_Accesos_Bases_Datos.md) · [07 Gobierno y Modelado](./07_Politica_Gobierno_Modelado_Documentacion.md) · [08 Aprovisionamiento GCP](./08_Politica_Aprovisionamiento_Plataformas_Datos_GCP.md) · [09 Continuidad y DR](./09_Politica_Continuidad_Mantenimiento_DR.md) · [12 Batch y Streaming](./12_Politica_Ingenieria_Datos_Batch_Streaming.md)
> **Última actualización:** 2026-09-17

---

## ÍNDICE

1. [Objetivo y alcance](#1-objetivo-y-alcance)
2. [Clasificación y principios](#2-clasificación-y-principios)
3. [Arquitectura y separación de ambientes](#3-arquitectura-y-separación-de-ambientes)
4. [Controles obligatorios del almacén FHIR](#4-controles-obligatorios-del-almacén-fhir)
5. [Modelo de acceso a datos de salud](#5-modelo-de-acceso-a-datos-de-salud)
6. [Desidentificación para ambientes no productivos](#6-desidentificación-para-ambientes-no-productivos)
7. [Integración con el data warehouse](#7-integración-con-el-data-warehouse)
8. [Modelado e interoperabilidad](#8-modelado-e-interoperabilidad)
9. [Continuidad, respaldo y retención](#9-continuidad-respaldo-y-retención)
10. [Auditoría y cumplimiento](#10-auditoría-y-cumplimiento)
11. [Gestión de incidentes con PHI](#11-gestión-de-incidentes-con-phi)
12. [Prohibiciones](#12-prohibiciones)
13. [Responsabilidades](#13-responsabilidades)

---

## 1. OBJETIVO Y ALCANCE

Establecer los controles obligatorios para almacenar, procesar, exponer y respaldar información de salud protegida (PHI) en la plataforma institucional, incluyendo los almacenes FHIR de Cloud Healthcare API y toda base de datos relacional, documental o analítica que contenga datos clínicos.

### 1.1 Alcance

Aplica a:

- **Almacenes FHIR** (Cloud Healthcare API), HL7v2 y DICOM.
- **Bases de datos transaccionales** de sistemas de telemedicina, expediente clínico, farmacia, laboratorio, imagenología y agenda médica.
- **Datasets analíticos** del data warehouse que deriven de fuentes clínicas.
- **Pipelines** batch y de tiempo real que transporten datos de salud ([12](./12_Politica_Ingenieria_Datos_Batch_Streaming.md)).
- **Modelos e integraciones de IA** que consuman datos clínicos (copilotos médicos, asistentes de diagnóstico, agentes).

### 1.2 Definición de PHI

Se considera PHI toda información de salud que, sola o combinada, permita identificar a una persona: identificadores directos (nombre, documento de identidad, número de expediente, contacto, biometría, imágenes), fechas específicas asociadas al paciente, y cualquier dato clínico vinculable a un individuo.

> **Regla de partida:** todo dato de salud se clasifica como **Regulado** ([07 §2.2](./07_Politica_Gobierno_Modelado_Documentacion.md#22-clasificación-de-datos)) mientras no exista una desidentificación validada y documentada.

---

## 2. CLASIFICACIÓN Y PRINCIPIOS

### 2.1 Principios específicos

| Principio | Aplicación |
|---|---|
| **Mínimo necesario** | El acceso se limita al conjunto mínimo de recursos FHIR, pacientes y campos necesarios para la función. El acceso a un almacén FHIR no implica acceso a todos los recursos ni a todos los pacientes. |
| **Finalidad declarada** | Todo acceso a PHI responde a una finalidad registrada: atención, operación, facturación, investigación autorizada, auditoría o soporte técnico. |
| **Trazabilidad individual** | Toda lectura de PHI en producción queda registrada con identidad, recurso, finalidad y momento. Sin excepciones para personal técnico. |
| **Desidentificación por defecto** | Fuera de producción, el dato de salud está desidentificado. La excepción requiere aprobación de CISO y Legal. |
| **Separación clínico-analítica** | El sistema de atención nunca depende del data warehouse, y el data warehouse nunca escribe hacia el sistema clínico. |
| **Consentimiento verificable** | Los usos secundarios (investigación, entrenamiento de modelos, analítica no operativa) requieren base legal y registro de consentimiento o autorización institucional. |

### 2.2 Niveles de dato de salud

| Nivel | Contenido | Ambientes permitidos | Controles |
|---|---|---|---|
| **N1 — PHI identificable** | Datos clínicos con identificadores directos | Solo PRD | CMEK, conectividad privada, Data Access Logs, acceso JIT, retención legal |
| **N2 — Seudonimizado** | Identificadores sustituidos por token reversible con llave separada | PRD y QA con aprobación | Llave de reidentificación custodiada por Seguridad, separada del dato |
| **N3 — Desidentificado** | Sin identificadores, fechas generalizadas, sin riesgo razonable de reidentificación | PRD, QA, DEV | Validación documentada de desidentificación antes de su uso |
| **N4 — Sintético** | Datos generados artificialmente | Cualquiera | Prohibido derivarlos de un solo paciente real |

---

## 3. ARQUITECTURA Y SEPARACIÓN DE AMBIENTES

### 3.1 Separación por proyecto

- Los almacenes FHIR productivos residen en **proyectos GCP dedicados a salud**, separados de DEV y QA por proyecto, red, secretos y políticas IAM ([08 §3.1](./08_Politica_Aprovisionamiento_Plataformas_Datos_GCP.md#31-separación-de-ambientes)).
- Los proyectos de salud tienen su propia **carpeta organizacional** con políticas de organización más restrictivas: IP pública deshabilitada, CMEK obligatorio, restricción de regiones permitidas.
- No se comparten cuentas de servicio entre proyectos de salud y proyectos de propósito general.

### 3.2 Nomenclatura

```text
Dataset de Healthcare API:  hds-[dominio]-[ambiente]
Almacén FHIR:               fhir-[sistema]-[ambiente]
Almacén HL7v2:              hl7-[sistema]-[ambiente]
Almacén DICOM:              dcm-[sistema]-[ambiente]

Ejemplos:
hds-telemedicina-prd
fhir-expediente-prd
fhir-expediente-qa
```

Las bases de datos relacionales de sistemas clínicos siguen el patrón general de [08 §3.3.1](./08_Politica_Aprovisionamiento_Plataformas_Datos_GCP.md#331-instancias-de-bases-de-datos), con etiqueta `data_classification: regulada`.

### 3.3 Etiquetas obligatorias adicionales

```yaml
data_classification: regulada
phi: "true"
phi_level: n1|n2|n3|n4
clinical_owner: <responsable_clinico>
legal_basis: atencion|operacion|investigacion_autorizada|auditoria
retention_policy: <referencia_normativa>
```

---

## 4. CONTROLES OBLIGATORIOS DEL ALMACÉN FHIR

| Control | DEV | QA | PRD |
|---|---|---|---|
| **Versión FHIR** | R4 (estándar institucional) | R4 | R4 |
| **Datos permitidos** | Sintéticos (N4) | Desidentificados (N3) o seudonimizados (N2) con aprobación | PHI real (N1) |
| **CMEK** | Opcional | Obligatorio si hay N2 | **Obligatorio** |
| **Conectividad privada / VPC-SC** | Recomendada | Obligatoria | **Obligatoria** (perímetro de VPC Service Controls) |
| **Cloud Audit Logs — Admin Activity** | Habilitado | Habilitado | Habilitado |
| **Cloud Audit Logs — Data Access** | Opcional | Habilitado | **Obligatorio y no deshabilitable** |
| **Exportación a BigQuery** | No aplica | Solo datos N3 | Solo a dataset clasificado con *policy tags* |
| **Notificaciones Pub/Sub** | Permitidas | Permitidas | Permitidas sin contenido clínico en el mensaje (solo referencia de recurso) |
| **Perfiles de validación** | Recomendado | Obligatorio | **Obligatorio** (rechazo de recursos no conformes) |
| **Consent management** | No aplica | Según caso | Obligatorio para usos secundarios |
| **Retención de logs** | 90 días | 365 días | Según retención legal, mínimo 7 años |

### 4.1 Reglas adicionales

- El almacén FHIR se aprovisiona por **Terraform**; los cambios manuales solo por emergencia documentada.
- **Prohibido** habilitar `disableReferentialIntegrity` en PRD sin aprobación de CISO y del Data Owner clínico.
- Las notificaciones Pub/Sub transportan la **referencia del recurso**, nunca su contenido clínico ([12 §12](./12_Politica_Ingenieria_Datos_Batch_Streaming.md#12-seguridad-y-datos-sensibles-en-pipelines)).
- Toda aplicación cliente se conecta mediante cuenta de servicio dedicada por sistema, ambiente y función; nunca con credenciales de usuario.
- El acceso desde aplicaciones móviles o web **nunca** se hace directo al almacén FHIR: siempre a través de una capa de API institucional que aplica autorización por paciente y registra la finalidad.

---

## 5. MODELO DE ACCESO A DATOS DE SALUD

### 5.1 Matriz de acceso

| Rol | DEV (N4) | QA (N3/N2) | PRD (N1) |
|---|---|---|---|
| **DBA Lead** | Admin | Admin | Admin JIT (máx. 4 h) + registro de finalidad |
| **DBA Senior** | Admin | Admin | Admin JIT (máx. 4 h) + registro de finalidad |
| **DBA Profesional** | Admin | Admin | Lectura de metadatos; operación JIT con aprobación del Lead |
| **DBA Junior** | Lectura/escritura | Lectura | **Sin acceso** |
| **Desarrollador** | Lectura/escritura | Lectura | Sin acceso |
| **Data Engineer** | Operación de pipelines | Operación de pipelines | Solo cuenta de servicio; sin acceso personal |
| **BI/Analytics** | Lectura | Lectura | Solo vistas autorizadas sobre datos N3 |
| **Personal clínico** | No aplica | No aplica | Acceso por aplicación, limitado a sus pacientes |
| **Proveedor externo** | Temporal con NDA sobre N4 | Excepcional sobre N3 | **Prohibido** |
| **Modelos/agentes de IA** | Datos N4 | Datos N3 | Solo con aprobación de CISO + Legal y registro de finalidad |

### 5.2 Acceso de emergencia (*break the glass*)

Cuando un incidente P0 requiere acceso inmediato a PHI en producción:

1. El DBA de guardia declara el incidente y solicita elevación JIT indicando **finalidad clínica u operativa**.
2. La elevación se otorga por un máximo de **4 horas**, con grabación de sesión o registro completo de comandos.
3. La aprobación posterior (no previa) la realizan DBA Lead y CISO dentro de las **24 horas** siguientes.
4. Se genera **revisión obligatoria a posteriori** del alcance de los datos consultados dentro de 48 h.
5. Si el acceso resultó innecesario o excesivo, se registra como hallazgo de cumplimiento.

> El acceso de emergencia es un control, no un atajo. Su uso reiterado por la misma causa indica un defecto de diseño que debe remediarse.

### 5.3 Acceso de proveedores y soporte de fabricante

- Prohibido el acceso a PHI. El soporte se presta sobre datos desidentificados o mediante sesión supervisada por un DBA, sin exportación.
- Cualquier excepción requiere contrato con cláusula de tratamiento de datos de salud, NDA, aprobación de CISO y Legal, sesión supervisada y expiración máxima de 4 horas ([01 §3.3](./01_Politica_Gestion_Accesos_Bases_Datos.md#33-proveedores-externos)).

---

## 6. DESIDENTIFICACIÓN PARA AMBIENTES NO PRODUCTIVOS

### 6.1 Regla

Ningún dato N1 sale de producción sin pasar por un proceso de desidentificación aprobado. Esto incluye copias para depuración, pruebas de rendimiento, demostraciones y entrenamiento de modelos.

### 6.2 Proceso obligatorio

1. **Solicitud** con finalidad, volumen, campos requeridos y periodo de vigencia.
2. **Aprobación** de Data Owner clínico + CISO.
3. **Ejecución** mediante la operación de desidentificación de Cloud Healthcare API (o un proceso equivalente aprobado), **dentro del proyecto productivo**; el dato identificable nunca se copia fuera para luego anonimizarse.
4. **Transformaciones mínimas:** eliminación o sustitución de identificadores directos, generalización de fechas, desplazamiento consistente de fechas por paciente cuando se requiera preservar intervalos, redacción de texto libre y de metadatos embebidos en imágenes DICOM.
5. **Validación de riesgo de reidentificación** documentada antes de la entrega, con atención a cuasi-identificadores (fecha de nacimiento + código postal + diagnóstico raro).
6. **Registro** en el inventario: origen, método, versión del proceso, fecha, solicitante, destino y fecha de destrucción.
7. **Destrucción** del conjunto al vencer la vigencia autorizada.

### 6.3 Texto libre e imágenes

Las notas clínicas en texto libre y los metadatos DICOM son la principal fuente de fuga de PHI. Su desidentificación requiere revisión por muestreo manual además del proceso automatizado, y aprobación explícita del Data Owner clínico.

---

## 7. INTEGRACIÓN CON EL DATA WAREHOUSE

### 7.1 Flujo permitido

```text
Almacén FHIR PRD (N1)
    │  exportación programada o streaming, cuenta de servicio dedicada
    ▼
BRONZE salud (proyecto bronce PRD, dataset restringido, CMEK, policy tags)
    │  seudonimización / desidentificación en la transformación
    ▼
SILVER salud (N2/N3, acceso por policy tag)
    │
    ▼
GOLD salud (N3 agregado, vistas autorizadas, row access policies)
    │
    ▼
BI y reportería institucional
```

### 7.2 Reglas

- El dataset Bronze de salud **no es de acceso general**: su IAM se restringe a la cuenta de servicio de ingesta, al DBA Lead y al DBA Senior.
- Toda columna con PHI lleva **policy tag** de Data Catalog; el acceso a la etiqueta se concede por persona y se recertifica trimestralmente.
- Las capas Gold expuestas a BI contienen **solo datos N3** o agregados que no permiten reidentificación (regla de supresión de celdas con conteos pequeños).
- Las consultas sobre datasets de salud registran Data Access Logs; **prohibido** desactivarlos por costo.
- Los pipelines de salud siguen la separación batch/tiempo real de [12](./12_Politica_Ingenieria_Datos_Batch_Streaming.md) y declaran `phi: "true"` en sus etiquetas.
- **Prohibida** la exportación de datasets de salud a hojas de cálculo, estaciones de trabajo o herramientas no institucionales.

### 7.3 Uso para inteligencia artificial

- El entrenamiento, ajuste fino o evaluación de modelos con datos clínicos requiere base legal, aprobación de CISO y Legal, y registro de finalidad.
- Por defecto se usan datos **N3 o N4**. El uso de N1/N2 es excepcional y requiere controles compensatorios documentados.
- Los *prompts* y las respuestas de sistemas de IA que procesen PHI se consideran PHI: aplican los mismos controles de registro, retención y acceso.
- Prohibido enviar PHI a servicios de terceros que no estén cubiertos por el contrato institucional y evaluados por Seguridad.

---

## 8. MODELADO E INTEROPERABILIDAD

| Aspecto | Política |
|---|---|
| **Estándar** | FHIR R4 como estándar institucional de intercambio clínico |
| **Perfiles** | Todo recurso debe conformar a los perfiles institucionales publicados; la validación se activa en QA y PRD |
| **Identificadores** | Todo `Patient` debe tener identificador institucional estable; prohibido usar el documento de identidad como llave primaria técnica ([07 §3.4](./07_Politica_Gobierno_Modelado_Documentacion.md#34-restricciones)) |
| **Terminologías** | Usar catálogos estándar (SNOMED CT, LOINC, ICD, CIE) o el catálogo institucional mapeado; prohibido el texto libre para valores codificables |
| **Extensiones** | Toda extensión FHIR se documenta, versiona y aprueba antes de su uso en PRD |
| **Versionado de recursos** | Historial de versiones habilitado; prohibido el borrado físico de recursos clínicos |
| **Relación con OLTP** | Si existe una base relacional maestra del expediente, se documenta cuál es el sistema fuente de verdad y cuál es la proyección |
| **Diccionario** | Los recursos FHIR y sus mapeos hacia Silver/Gold se documentan en el diccionario de datos ([07 §6](./07_Politica_Gobierno_Modelado_Documentacion.md#6-diccionario-de-datos-y-catálogo)) |

---

## 9. CONTINUIDAD, RESPALDO Y RETENCIÓN

### 9.1 Criticidad

Todo sistema clínico productivo se clasifica por defecto como **Crítico** ([09 §2.1](./09_Politica_Continuidad_Mantenimiento_DR.md#21-niveles-de-criticidad)): RPO 15 min – 1 h, RTO 1 – 4 h. Una clasificación menor requiere aceptación formal de riesgo por el Data Owner clínico y el CISO.

### 9.2 Respaldo por plataforma

| Plataforma | Método | Periodicidad PRD | Retención |
|---|---|---|---|
| **Almacén FHIR** | Exportación programada a Cloud Storage (bucket con CMEK, *versioning*, *uniform bucket-level access*) o a BigQuery restringido | Diaria | Según retención legal; mínimo 5–7 años |
| **Cloud SQL clínico** | Backups automáticos + PITR + export mensual | Diario + logs continuos | 30 días operativos + retención legal del export |
| **DICOM** | Exportación a Cloud Storage con clase de almacenamiento por antigüedad | Diaria | Según norma de imagenología aplicable |
| **BigQuery salud** | Snapshots + export; no depender de *time travel* | Según criticidad del dataset | 30–365 días + retención legal |

### 9.3 Reglas

- Los respaldos de PHI se cifran con CMEK y se almacenan en región autorizada por residencia de datos.
- **Prohibido** descargar respaldos clínicos a estaciones de trabajo ([09 §4.1](./09_Politica_Continuidad_Mantenimiento_DR.md#41-almacenamiento)).
- Las pruebas de restauración de sistemas clínicos son **trimestrales**, con evidencia según [09 §5.2](./09_Politica_Continuidad_Mantenimiento_DR.md#52-evidencia-obligatoria); la restauración se realiza en un proyecto aislado y el conjunto se destruye al finalizar.
- El plan DR de cada sistema clínico incluye el procedimiento de operación degradada durante la indisponibilidad (qué hace el personal clínico mientras el sistema no está).
- La eliminación de datos clínicos al vencer la retención requiere aprobación de Legal y registro de la destrucción; existe *legal hold* que suspende el borrado ante litigio o investigación.

---

## 10. AUDITORÍA Y CUMPLIMIENTO

### 10.1 Registros obligatorios

- Toda lectura, creación, modificación y eliminación de recursos FHIR en PRD.
- Toda ejecución de desidentificación o exportación.
- Todo cambio de IAM, *policy tag* o configuración del almacén.
- Todo acceso de emergencia (*break the glass*) con su revisión posterior.
- Toda consulta a datasets de salud en BigQuery.

### 10.2 Revisiones

| Revisión | Frecuencia | Responsable |
|---|---|---|
| Accesos activos a PHI y vigencia de su justificación | Mensual | DBA Senior |
| Uso de accesos de emergencia y proporcionalidad | Mensual | DBA Lead + CISO |
| Recertificación de *policy tags* y vistas autorizadas | Trimestral | Data Owner clínico |
| Revisión de conjuntos desidentificados vigentes y su destrucción | Trimestral | DBA Senior |
| Evaluación de riesgo de reidentificación de datasets publicados | Semestral | DBA Lead + CISO |
| Auditoría integral de cumplimiento en salud | Anual | Cumplimiento + CISO |

### 10.3 Marco normativo

Esta política soporta el cumplimiento de HIPAA (cuando aplique contractualmente), GDPR para categorías especiales de datos, la Ley de Protección de Datos Personales local ([referencia](./Ley_Proteccion_Datos_Personales_ES.pdf)), ISO 27001 y SOC 2. Los controles de esta política deben mapearse explícitamente en el paquete de evidencias de [06 §7](./06_Auditoria_Cumplimiento.md).

---

## 11. GESTIÓN DE INCIDENTES CON PHI

1. **Detección y contención inmediata:** suspender el acceso involucrado y preservar los logs.
2. **Notificación al CISO dentro de 1 hora** de la detección; a Legal dentro de 4 horas.
3. **Evaluación de alcance:** qué pacientes, qué campos, por cuánto tiempo, quién accedió, si hubo exportación.
4. **Determinación de obligación de notificación** a autoridad y a titulares, según la normativa aplicable y los plazos legales.
5. **Post-mortem obligatorio en 48 h** con acciones correctivas, responsables y fechas.
6. **Registro** en el expediente de cumplimiento del área.

Todo incidente que involucre PHI es automáticamente **P0**, independientemente del número de registros afectados.

---

## 12. PROHIBICIONES

1. Copiar PHI a DEV o QA sin desidentificación aprobada.
2. Deshabilitar Data Access Logs en proyectos de salud.
3. Exponer un almacén FHIR directamente a aplicaciones cliente sin capa de autorización institucional.
4. Usar el documento de identidad del paciente como llave primaria técnica.
5. Enviar PHI en mensajes de Pub/Sub, en logs de aplicación o en tickets de soporte.
6. Otorgar acceso permanente a PHI en producción a personal técnico.
7. Compartir conjuntos desidentificados fuera del alcance y la vigencia autorizados.
8. Entrenar o evaluar modelos con PHI sin base legal y aprobación registrada.
9. Descargar respaldos o exportaciones clínicas a equipos personales.
10. Borrar físicamente recursos clínicos o registros de auditoría.

---

## 13. RESPONSABILIDADES

| Rol | Responsabilidad |
|---|---|
| **DBA Lead (Kurt de León)** | Dueño de esta política; aprueba excepciones junto a CISO; valida el diseño de nuevos sistemas clínicos |
| **DBA Senior (Pastor Ortega)** | Primario de la plataforma FHIR: configuración, respaldo, DR, auditoría de accesos a PHI, revisión mensual |
| **DBA Profesional — Analítica (Karina Méndez)** | Respaldo de FHIR; diseño y operación de la integración hacia el data warehouse con *policy tags* y desidentificación |
| **DBA Profesional — Transaccional (Marvin Méndez)** | Bases relacionales de sistemas clínicos: HA, backups, tuning, migraciones de esquema |
| **DBA Junior (Kenneth Callejas)** | Monitoreo de salud y capacidad de las instancias clínicas; **sin acceso a contenido PHI en PRD** |
| **CISO / Seguridad** | Aprueba accesos excepcionales, revisa *break the glass*, lidera la respuesta a incidentes con PHI |
| **Data Owner clínico** | Define finalidad, aprueba desidentificaciones y recertifica accesos |
| **Legal / Cumplimiento** | Determina retención, base legal y obligaciones de notificación |
| **DevOps** | Conectividad privada, VPC-SC, secretos y CI/CD de los proyectos de salud |

---

**IMPORTANTE:** En datos de salud, la disponibilidad y la confidencialidad tienen igual peso: un sistema clínico caído afecta la atención del paciente, y una fuga de PHI afecta su vida. Ningún sistema clínico debe recibir datos reales sin CMEK, conectividad privada, Data Access Logs, respaldo probado y matriz de accesos aprobada.
