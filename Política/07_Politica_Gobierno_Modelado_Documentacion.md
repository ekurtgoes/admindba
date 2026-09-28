# POLÍTICA DE GOBIERNO, MODELADO Y DOCUMENTACIÓN DE DATOS

> **Aplicable a:** Bases de datos transaccionales, analíticas, documentales y semánticas  
> **Responsables:** DBA Lead, Arquitectura de Datos, Gobierno de Datos, Product Owners  
> **Última actualización:** 2026-09-04

---

## ÍNDICE

1. [Objetivo](#1-objetivo)
2. [Principios de Gobierno de Datos](#2-principios-de-gobierno-de-datos)
3. [Política de Modelado OLTP](#3-política-de-modelado-oltp)
4. [Política de Modelado OLAP](#4-política-de-modelado-olap)
5. [Modelos NoSQL y Documentales](#5-modelos-nosql-y-documentales)
6. [Diccionario de Datos y Catálogo](#6-diccionario-de-datos-y-catálogo)
7. [Cuadros Semánticos y Métricas](#7-cuadros-semánticos-y-métricas)
8. [Diagramas y Artefactos Obligatorios](#8-diagramas-y-artefactos-obligatorios)
9. [Aprobación de Cambios de Modelo](#9-aprobación-de-cambios-de-modelo)
10. [Controles de Calidad](#10-controles-de-calidad)

---

## 1. OBJETIVO

Establecer criterios obligatorios para diseñar, documentar, gobernar y evolucionar modelos de datos que soporten sistemas OLTP, OLAP, NoSQL y analíticos, garantizando consistencia, trazabilidad, seguridad, calidad y entendimiento común entre equipos técnicos y funcionales.

---

## 2. PRINCIPIOS DE GOBIERNO DE DATOS

### 2.1 Propiedad de Datos

Todo dominio, base de datos, dataset, tabla, colección o entidad debe tener:

| Elemento | Requisito |
|----------|-----------|
| **Data Owner** | Responsable funcional del significado, uso y autorización del dato |
| **Data Steward** | Responsable operativo de calidad, definición y documentación |
| **Custodio Técnico** | DBA, Data Engineer o equipo responsable de plataforma |
| **Clasificación** | Pública, interna, confidencial, sensible, regulada |
| **Sistema fuente** | Aplicación o proceso maestro del dato |
| **Consumidores** | Aplicaciones, reportes, integraciones o áreas usuarias |

### 2.2 Clasificación de Datos

| Clasificación | Ejemplos | Controles mínimos |
|---------------|----------|-------------------|
| **Pública** | Catálogos publicados, datos abiertos | Integridad y disponibilidad |
| **Interna** | Parámetros operativos, métricas agregadas | IAM, auditoría básica |
| **Confidencial** | Datos financieros, contratos, operación interna | Cifrado, mínimo privilegio, logs |
| **Sensible** | PII, PHI, datos biométricos, menores de edad | Enmascaramiento, DLP, auditoría reforzada |
| **Regulada** | Salud, identidad, datos sujetos a ley | Retención legal, trazabilidad completa, aprobación CISO |

### 2.3 Reglas Generales

- Todo nuevo modelo debe pasar por revisión de arquitectura de datos antes de producción.
- Ningún dato sensible debe crearse sin clasificación, propietario y justificación de uso.
- Todo cambio estructural debe estar versionado en repositorio y asociado a ticket.
- Los modelos deben diseñarse para minimizar duplicidad, ambigüedad semántica y dependencia de consultas ad hoc no documentadas.
- La documentación es parte del entregable; un modelo sin diccionario, diagrama y responsables no está listo para producción.

### 2.4 Gobierno del Consumo de Plataformas Analíticas

El consumo de plataformas analíticas, incluyendo BigQuery, debe gobernarse junto con el acceso a los datos. La autorización para leer un dataset no implica autorización para consumir recursos ilimitados de la plataforma.

#### 2.4.1 Clasificación de grupos de consumo

Cada usuario o servicio que ejecute consultas debe pertenecer a un grupo de consumo aprobado. La clasificación inicial para BigQuery es:

| Grupo | Perfil de consumo | Límite de bytes procesados por consulta | Límite de slots de referencia |
|-------|-------------------|-----------------------------------------|-------------------------------|
| **Grupo01** | Usuarios analíticos | Definido por el propietario de la plataforma | 200 slots |
| **Grupo02** | Aplicaciones | Definido por el propietario de la plataforma | 1,000 slots |
| **Grupo03** | Ingeniería de datos | Definido por el propietario de la plataforma | 500 slots |

Los valores de la tabla deben formalizarse en el catálogo o registro de cuotas de la plataforma. Cualquier cambio debe tener justificación, responsable, fecha de vigencia y aprobación del propietario de BigQuery.

#### 2.4.2 Reglas de consumo

- Las consultas deben ejecutarse sobre datasets autorizados y mediante el proyecto de ejecución institucional definido para la carga de trabajo.
- Las consultas interactivas y los procesos automatizados deben utilizar un límite de bytes procesados por consulta (`maximum_bytes_billed`) cuando la herramienta o aplicación lo permita.
- El límite de bytes procesados es un control por consulta y no sustituye las cuotas acumuladas, el monitoreo ni la asignación de capacidad.
- Los límites de slots deben implementarse mediante Reservations, assignments, cuotas u otros controles nativos de BigQuery disponibles para la arquitectura aprobada.
- Cuando BigQuery no permita aplicar el límite directamente por grupo de identidad, la plataforma debe asegurar la separación mediante proyectos de ejecución, aplicaciones intermediarias o mecanismos equivalentes.
- Las cargas de trabajo deben etiquetarse para permitir la trazabilidad por grupo, aplicación, proyecto, propietario y centro de costo.
- El propietario de la plataforma debe monitorear bytes procesados, slots consumidos, errores por exceso de límite y tendencias de crecimiento.

#### 2.4.3 Excepciones

Toda excepción a los límites definidos debe:

- estar asociada a un ticket o solicitud aprobada;
- indicar la justificación técnica y el periodo de vigencia;
- identificar al responsable de la carga de trabajo y al propietario de los datos;
- definir el riesgo, el impacto esperado y las medidas de control;
- revisarse al finalizar el periodo autorizado.

El procedimiento técnico de BigQuery debe documentar la configuración concreta de cuotas, Reservations, alertas, etiquetas y límites de `maximum_bytes_billed`. Los permisos de usuarios y grupos se documentan en la política institucional de Access Management.

---

## 3. POLÍTICA DE MODELADO OLTP

### 3.1 Objetivo OLTP

Los modelos OLTP deben priorizar integridad transaccional, consistencia, bajo tiempo de respuesta, concurrencia controlada y claridad operativa.

### 3.2 Reglas de Diseño

| Aspecto | Política |
|---------|----------|
| **Normalización** | Diseñar como mínimo en 3FN, salvo excepciones documentadas por rendimiento |
| **Llaves primarias** | Toda tabla debe tener PK estable, no ambigua y no reutilizable |
| **Llaves foráneas** | Obligatorias cuando el motor las soporte y no exista impedimento técnico aprobado |
| **Nombres** | Usar nomenclatura estándar, descriptiva y consistente por dominio |
| **Auditoría de filas** | Tablas críticas deben incluir campos de creación, modificación y usuario/proceso |
| **Estados** | Usar catálogos o dominios controlados; evitar cadenas libres para estados de negocio |
| **Borrado** | Preferir borrado lógico en entidades críticas; borrado físico requiere justificación |
| **Transacciones** | Operaciones críticas deben ser atómicas, idempotentes cuando apliquen y recuperables |

### 3.3 Campos Mínimos Recomendados

```sql
created_at       TIMESTAMP NOT NULL
created_by       VARCHAR(100) NULL
updated_at       TIMESTAMP NULL
updated_by       VARCHAR(100) NULL
deleted_at       TIMESTAMP NULL
is_active        BOOLEAN NOT NULL DEFAULT TRUE
```

### 3.4 Restricciones

- Prohibido usar tablas sin PK en producción, excepto staging temporal documentado.
- Prohibido almacenar múltiples valores en una sola columna cuando el motor permite modelado relacional correcto.
- Prohibido crear columnas genéricas como `campo1`, `valor`, `descripcion2` sin definición formal.
- Prohibido usar datos sensibles como llave primaria de negocio cuando exista alternativa técnica.

---

## 4. POLÍTICA DE MODELADO OLAP

### 4.1 Objetivo OLAP

Los modelos OLAP deben priorizar análisis confiable, rendimiento en consultas, trazabilidad desde fuentes, gobernanza de métricas y entendimiento funcional.

### 4.2 Arquitectura Medallion

La arquitectura Medallion es el patrón de referencia para organizar los flujos analíticos implementados sobre el lago de datos, lakehouse o BigQuery. Los datos deben avanzar por capas con responsabilidades y controles diferenciados, aumentando su calidad y valor de negocio en cada etapa.

> **Implementación institucional:** cada capa se despliega en su **propio proyecto de GCP** y cada ambiente en un proyecto distinto — nueve proyectos en total (`dw-[bronze|silver|gold]-[dev|qa|prd]`). El estándar de nomenclatura y las reglas de aislamiento están en [08 §3.7](./08_Politica_Aprovisionamiento_Plataformas_Datos_GCP.md#37-proyectos-del-data-warehouse-medallón); las reglas de escritura por capa y la separación entre procesamiento batch y en tiempo real, en [12 §7.4](./12_Politica_Ingenieria_Datos_Batch_Streaming.md#74-proyectos-del-data-warehouse).

| Capa | Propósito | Contenido y controles mínimos |
|------|-----------|-------------------------------|
| **Bronze** | Captura y preservación de la fuente | Datos en formato original o con transformaciones mínimas, historial de ingesta, metadatos de origen, fecha de carga y trazabilidad. No debe alterarse la evidencia original sin conservar una copia reproducible. |
| **Silver** | Limpieza y conformación | Datos validados, tipificados, deduplicados y estandarizados; aplicación de reglas de calidad, claves técnicas, normalización de fechas y homologación de dominios. |
| **Gold** | Consumo analítico y de negocio | Datos agregados, integrados y certificados para datamarts, métricas, reportes, dashboards y productos de datos. Deben contar con definición funcional, propietario y reglas de actualización. |

#### 4.2.1 Reglas de implementación

- Toda fuente analítica nueva debe identificar su capa Medallion, propietario, frecuencia de carga, reglas de retención y consumidores autorizados.
- Bronze debe conservar la trazabilidad suficiente para reprocesar las capas posteriores cuando cambien las reglas de negocio o sea necesario auditar el dato.
- Silver debe ser la capa de referencia para aplicar controles de calidad, estandarización y conformación entre fuentes.
- Gold debe ser la capa preferida para consumo institucional, BI y métricas certificadas; no deben publicarse reportes productivos directamente sobre Bronze.
- Las transformaciones entre capas deben ser versionadas, idempotentes cuando aplique y ejecutables de forma reproducible.
- Cada flujo debe registrar su origen, destino, fecha de ejecución, versión de transformación, resultado de controles de calidad y estado de la carga.
- El acceso de escritura y modificación debe restringirse por capa. Bronze, Silver y Gold deben tener propietarios y cuentas de servicio claramente identificados.
- La arquitectura puede implementarse con Cloud Storage, BigQuery, Dataflow, Dataproc, Dataform u otras herramientas aprobadas, siempre que se mantengan las responsabilidades y controles de cada capa.

#### 4.2.2 Relación con los modelos OLAP

La arquitectura Medallion define el flujo y la madurez del dato; el modelo dimensional, Data Vault, ODS o wide table define su estructura para un propósito concreto. Por tanto, ambos enfoques pueden coexistir:

| Capa Medallion | Modelado OLAP habitual |
|----------------|------------------------|
| **Bronze** | Landing, staging o tablas de ingesta |
| **Silver** | ODS, Data Vault integrado, entidades conformadas o dimensiones base |
| **Gold** | Modelo estrella, copo de nieve, wide tables, vistas semánticas y datamarts |

### 4.3 Patrones Permitidos

| Patrón | Uso recomendado |
|--------|-----------------|
| **Modelo estrella** | Datamarts de consumo, BI, dashboards ejecutivos |
| **Copo de nieve** | Dimensiones jerárquicas complejas o compartidas |
| **Data Vault** | Integración histórica, múltiples fuentes, trazabilidad avanzada |
| **ODS** | Consolidación operacional cercana a fuente |
| **Wide table** | Consumo específico, alto rendimiento, con linaje y dueño definido |

### 4.4 Reglas para Hechos y Dimensiones

| Elemento | Política |
|----------|----------|
| **Tabla de hechos** | Debe declarar granularidad exacta antes de diseño físico |
| **Dimensiones** | Deben tener llave sustituta cuando exista historización o integración de fuentes |
| **Métricas** | Deben estar definidas en cuadro semántico aprobado |
| **Fechas** | Usar dimensión calendario para reportes institucionales |
| **Historización** | Definir SCD Tipo 1, 2, 3 o estrategia equivalente |
| **Particionado** | Obligatorio para tablas grandes en BigQuery y recomendado en motores analíticos |
| **Clustering** | Definir según patrones reales de consulta |

### 4.5 Granularidad

Toda tabla de hechos debe documentar:

- Evento o proceso de negocio representado.
- Unidad mínima de registro.
- Frecuencia de carga.
- Fuente maestra.
- Llaves de dimensión.
- Métricas aditivas, semi-aditivas y no aditivas.

### 4.6 Restricciones OLAP

- Prohibido publicar dashboards productivos sobre tablas raw sin capa curada o semantic layer.
- Prohibido duplicar métricas institucionales con fórmulas distintas sin gobierno de datos.
- Prohibido modificar la definición de una métrica certificada sin versionado, aprobación y comunicación.

---

## 5. MODELOS NOSQL Y DOCUMENTALES

### 5.1 Firestore, Firebase y MongoDB

Los modelos NoSQL deben justificarse por necesidades de flexibilidad, baja latencia, distribución, estructura documental, sincronización móvil o escalabilidad horizontal.

### 5.2 Reglas de Diseño

| Aspecto | Política |
|---------|----------|
| **Colecciones/documentos** | Documentar estructura esperada, campos requeridos y variantes permitidas |
| **Desnormalización** | Permitida cuando mejore rendimiento y exista estrategia de consistencia |
| **Índices** | Todo índice compuesto debe estar ligado a una consulta de negocio |
| **Tamaño de documento** | Debe respetar límites del motor y evitar documentos crecientes sin control |
| **Reglas de seguridad** | Obligatorias antes de publicar aplicaciones cliente |
| **TTL** | Obligatorio para datos temporales, sesiones, tokens o eventos efímeros |
| **Esquema lógico** | Aunque el motor no lo exija, el esquema debe documentarse y versionarse |

### 5.3 Restricciones

- Prohibido usar colecciones sin reglas de seguridad revisadas.
- Prohibido almacenar secretos, tokens o credenciales en documentos accesibles por cliente.
- Prohibido usar NoSQL para relaciones críticas complejas si no existe estrategia clara de consistencia.

---

## 6. DICCIONARIO DE DATOS Y CATÁLOGO

### 6.1 Campos Obligatorios del Diccionario

| Campo | Descripción |
|-------|-------------|
| **Sistema** | Sistema, dominio o producto propietario |
| **Base/Dataset** | Nombre de base de datos, esquema, dataset o colección |
| **Objeto** | Tabla, vista, materialized view, tópico, colección o entidad |
| **Campo** | Nombre técnico del atributo |
| **Definición funcional** | Significado comprensible para negocio |
| **Tipo de dato** | Tipo físico en el motor correspondiente |
| **Obligatoriedad** | Requerido, opcional, derivado, calculado |
| **Clasificación** | Pública, interna, confidencial, sensible, regulada |
| **Regla de calidad** | Dominio válido, formato, unicidad, rango, completitud |
| **Fuente** | Sistema origen o proceso de derivación |
| **Transformación** | Regla ETL/ELT aplicada si corresponde |
| **Owner/Steward** | Responsables funcionales |
| **Retención** | Tiempo de conservación requerido |

### 6.2 Frecuencia de Actualización

- Cambios de modelo: actualizar antes de liberar a QA.
- Nuevas métricas: actualizar antes de publicar dashboards.
- Cambios de clasificación: actualizar de inmediato y notificar a Seguridad.
- Revisión formal: trimestral para datos críticos y semestral para datos no críticos.

---

## 7. CUADROS SEMÁNTICOS Y MÉTRICAS

### 7.1 Definición

Un cuadro semántico es el contrato funcional que define métricas, dimensiones, filtros, jerarquías, reglas de cálculo y restricciones de uso para consumo analítico.

### 7.2 Elementos Obligatorios

| Elemento | Requisito |
|----------|-----------|
| **Nombre de métrica** | Nombre oficial y alias permitidos |
| **Definición funcional** | Qué mide y qué no mide |
| **Fórmula** | Expresión de cálculo con filtros incluidos |
| **Grano** | Nivel al que se calcula correctamente |
| **Dimensiones válidas** | Campos por los que puede analizarse |
| **Filtros obligatorios** | Fechas, estado, vigencia, institución, territorio |
| **Fuente certificada** | Tabla, vista, modelo o dataset autorizado |
| **Dueño** | Área funcional que aprueba el indicador |
| **Frecuencia** | Diario, mensual, tiempo real, bajo demanda |
| **Limitaciones** | Sesgos, exclusiones o condiciones de interpretación |

### 7.3 Control de Métricas

- Toda métrica usada en informes ejecutivos debe estar certificada.
- Cambios de fórmula requieren versionado y fecha efectiva.
- Métricas obsoletas deben marcarse como depreciadas antes de eliminarse.
- BI, Data Engineering y Data Owner deben usar la misma definición aprobada.

---

## 8. DIAGRAMAS Y ARTEFACTOS OBLIGATORIOS

### 8.1 Artefactos por Tipo de Modelo

| Tipo | Artefactos obligatorios |
|------|-------------------------|
| **OLTP** | Diagrama ER, diccionario de datos, matriz de CRUD, reglas de integridad |
| **OLAP estrella** | Diagrama estrella, matriz hecho-dimensión, definición de grano, cuadro semántico |
| **OLAP copo de nieve** | Diagrama jerárquico, relaciones entre dimensiones, reglas SCD |
| **Data Vault** | Hubs, Links, Satellites, linaje de fuentes, reglas de carga |
| **NoSQL** | Diagrama de colecciones, estructura documental, reglas de seguridad, índices |
| **BigQuery** | Datasets, tablas, vistas, particiones, clustering, linaje y consumo |

### 8.2 Formatos Permitidos

- Mermaid, PlantUML, ERD generado por herramienta, draw.io o herramienta corporativa aprobada.
- El formato fuente editable debe versionarse en repositorio.
- Las imágenes exportadas no sustituyen el artefacto editable.

---

## 9. APROBACIÓN DE CAMBIOS DE MODELO

### 9.1 Cambios Menores

Ejemplos: agregar columna nullable no sensible, índice no disruptivo, vista nueva sin exposición de PII.

**Aprobación:** DBA o Data Engineer + Product Owner.

### 9.2 Cambios Mayores

Ejemplos: eliminar columnas, cambiar tipos de datos, crear nuevas entidades críticas, modificar granularidad de hechos, publicar métrica institucional.

**Aprobación:** DBA Lead + Arquitectura de Datos + Product Owner + Seguridad si incluye datos sensibles.

### 9.3 Cambios Críticos

Ejemplos: eliminación de datos, cambio de llave primaria, migración de motor, cambio de modelo maestro, exposición externa de dataset regulado.

**Aprobación:** CISO + CTO o comité de cambios + DBA Lead + Data Owner.

---

## 10. CONTROLES DE CALIDAD

### 10.1 Reglas Mínimas

| Dimensión | Control |
|-----------|---------|
| **Completitud** | Campos obligatorios no nulos según regla funcional |
| **Unicidad** | Llaves y códigos únicos sin duplicados no autorizados |
| **Validez** | Dominios, catálogos y rangos permitidos |
| **Consistencia** | Integridad entre entidades, fuentes y reportes |
| **Oportunidad** | Datos actualizados dentro del SLA definido |
| **Trazabilidad** | Registro de origen, carga y transformación |

### 10.2 Evidencia Requerida

- Resultado de pruebas de calidad antes de producción.
- Validación de conteos entre fuente y destino en procesos ETL/ELT.
- Reporte de excepciones y plan de remediación.
- Aprobación del Data Owner para datos críticos.

---

**IMPORTANTE:** Ningún modelo de datos debe promoverse a Producción si no cuenta con propietario, clasificación, diccionario, diagrama, controles de calidad y aprobación correspondiente.