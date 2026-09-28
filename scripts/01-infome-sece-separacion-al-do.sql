WITH
movidas AS (
  SELECT DISTINCT r.escuela_id AS id FROM rutas r WHERE r.fase = 2
),
filtradas AS (
  SELECT id FROM movidas
),
por_escuela AS (
  SELECT esc.id AS escuela_id,
         esc.en_intervencion_certificacion AS intervenida,
         EXISTS (SELECT 1 FROM certificacion_acceso ca
                 WHERE ca.escuela_id = esc.id AND ca.resultado = 'incidente') AS percance,
         EXISTS (SELECT 1 FROM reporte_seccion_faltante rsf
                 WHERE rsf.escuela_id = esc.id) AS seccion_faltante,
         EXISTS (SELECT 1 FROM registro_incidente_ce ric
                 WHERE ric.escuela_id = esc.id AND ric.estado = 'resuelto') AS caso_cerrado,
         EXISTS (SELECT 1 FROM cierre_parcial_ce cp
                 WHERE cp.escuela_id = esc.id) AS cerrado_temporal,
         COALESCE(sec.vigentes, 0) AS vigentes,
         COALESCE(sec.enviadas, 0) AS enviadas,
         COALESCE(sec.capturando, 0) AS capturando
  FROM filtradas f
  JOIN escuelas esc ON esc.id = f.id
  LEFT JOIN LATERAL (
    SELECT COUNT(*) AS vigentes,
           COUNT(*) FILTER (WHERE est.codigo = 'capturada')  AS enviadas,
           COUNT(*) FILTER (WHERE est.codigo = 'capturando') AS capturando
    FROM ruta_seccion rs
    JOIN rutas r ON r.id = rs.ruta_id AND r.fase IN (2, 3)   -- fase 3 cuenta como fase 2
    JOIN seccion_grado sg ON sg.id = rs.seccion_id
    LEFT JOIN estado est ON est.id = rs.estado_id AND est.ambito = 'ruta_seccion'
    WHERE r.escuela_id = esc.id
      AND rs.descartada = false AND sg.descartada = false AND sg.grado IS NOT NULL
  ) sec ON TRUE
),
docentes_elegibles AS (
  SELECT pe.escuela_id, COUNT(DISTINCT lower(btrim(pe.email)))::int AS cuentas
  FROM filtradas f
  JOIN personal_escuela pe ON pe.escuela_id = f.id
  JOIN cargos_personal cp ON cp.id = pe.cargo_id
  WHERE pe.deleted_at IS NULL
    AND (cp.nombre = 'docente' OR pe.is_teacher = true)
    AND pe.email IS NOT NULL AND btrim(pe.email) <> ''
    AND EXISTS (SELECT 1 FROM docente_seccion ds
                JOIN seccion_grado sg ON sg.id = ds.seccion_id
                WHERE ds.personal_id = pe.id AND ds.deleted_at IS NULL
                  AND sg.grado IS NOT NULL AND sg.descartada = false)
  GROUP BY pe.escuela_id
),
estudiantes_elegibles AS (
  SELECT es.escuela_id, COUNT(DISTINCT lower(btrim(es.nie)))::int AS cuentas
  FROM filtradas f
  JOIN estudiantes es ON es.escuela_id = f.id
  JOIN seccion_grado sg ON sg.id = es.seccion_id
  WHERE es.deleted_at IS NULL
    AND es.nie IS NOT NULL AND btrim(es.nie) <> ''
    AND sg.grado IS NOT NULL AND sg.descartada = false
    AND NOT EXISTS (SELECT 1 FROM revisiones_estudiante re
                    WHERE re.estudiante_id = es.id AND re.estado = 'descartado')
  GROUP BY es.escuela_id
),
cuentas_confirmadas AS (
  SELECT escuela_id, COUNT(*)::int AS cuentas
  FROM (
    SELECT ca.escuela_id
    FROM certificacion_acceso ca
    JOIN personal_escuela pe ON pe.id = ca.personal_id
    WHERE ca.escuela_id IN (SELECT id FROM filtradas)
      AND pe.email IS NOT NULL AND btrim(pe.email) <> '' AND pe.deleted_at IS NULL
    GROUP BY ca.escuela_id, lower(btrim(pe.email))
    HAVING BOOL_AND(ca.resultado = 'correcto' OR EXISTS (
      SELECT 1 FROM reporte_incidente_ce ri
      WHERE ri.origen = 'acceso' AND ri.origen_id = ca.id
        AND ri.resuelto = true AND ri.descartado = false))
    UNION ALL
    SELECT ca.escuela_id
    FROM certificacion_acceso ca
    JOIN estudiantes es ON es.id = ca.estudiante_id
    WHERE ca.escuela_id IN (SELECT id FROM filtradas)
      AND es.nie IS NOT NULL AND btrim(es.nie) <> '' AND es.deleted_at IS NULL
      AND NOT EXISTS (SELECT 1 FROM revisiones_estudiante re
                      WHERE re.estudiante_id = es.id AND re.estado = 'descartado')
    GROUP BY ca.escuela_id, lower(btrim(es.nie))
    HAVING BOOL_AND(ca.resultado = 'correcto' OR EXISTS (
      SELECT 1 FROM reporte_incidente_ce ri
      WHERE ri.origen = 'acceso' AND ri.origen_id = ca.id
        AND ri.resuelto = true AND ri.descartado = false))
  ) cuenta
  GROUP BY escuela_id
),

cuentas_confirmadas_docentes AS (
  SELECT escuela_id, COUNT(*)::int AS cuentas
  FROM (
    SELECT ca.escuela_id
    FROM certificacion_acceso ca
    JOIN personal_escuela pe ON pe.id = ca.personal_id
    WHERE ca.escuela_id IN (SELECT id FROM filtradas)
      AND pe.email IS NOT NULL AND btrim(pe.email) <> '' AND pe.deleted_at IS NULL
    GROUP BY ca.escuela_id, lower(btrim(pe.email))
    HAVING BOOL_AND(ca.resultado = 'correcto' OR EXISTS (
      SELECT 1 FROM reporte_incidente_ce ri
      WHERE ri.origen = 'acceso' AND ri.origen_id = ca.id
        AND ri.resuelto = true AND ri.descartado = false))
  ) cuenta
  GROUP BY escuela_id
),

cuentas_confirmadas_estudiantes AS (
  SELECT escuela_id, COUNT(*)::int AS cuentas
  FROM (
    SELECT ca.escuela_id
    FROM certificacion_acceso ca
    JOIN estudiantes es ON es.id = ca.estudiante_id
    WHERE ca.escuela_id IN (SELECT id FROM filtradas)
      AND es.nie IS NOT NULL AND btrim(es.nie) <> '' AND es.deleted_at IS NULL
      AND NOT EXISTS (SELECT 1 FROM revisiones_estudiante re
                      WHERE re.estudiante_id = es.id AND re.estado = 'descartado')
    GROUP BY ca.escuela_id, lower(btrim(es.nie))
    HAVING BOOL_AND(ca.resultado = 'correcto' OR EXISTS (
      SELECT 1 FROM reporte_incidente_ce ri
      WHERE ri.origen = 'acceso' AND ri.origen_id = ca.id
        AND ri.resuelto = true AND ri.descartado = false))
  ) cuenta
  GROUP BY escuela_id
),

tasa_confirmacion AS (
  SELECT escuela_id, confirmadas,
         CASE WHEN confirmadas > 0 THEN GREATEST(entregadas, elegibles) ELSE entregadas END AS otorgadas
  FROM (
    SELECT f.id AS escuela_id,
           COALESCE(conf.cuentas, 0) AS confirmadas,
           (CASE WHEN entrega.docentes    THEN COALESCE(doc.cuentas, 0) ELSE 0 END
          + CASE WHEN entrega.estudiantes THEN COALESCE(est.cuentas, 0) ELSE 0 END) AS entregadas,
           (COALESCE(doc.cuentas, 0) + COALESCE(est.cuentas, 0)) AS elegibles
    FROM filtradas f
    LEFT JOIN docentes_elegibles doc ON doc.escuela_id = f.id
    LEFT JOIN estudiantes_elegibles est ON est.escuela_id = f.id
    LEFT JOIN cuentas_confirmadas conf ON conf.escuela_id = f.id
    LEFT JOIN LATERAL (
      SELECT
        EXISTS (SELECT 1 FROM bloque_exportacion_escuela be
                JOIN bloques_exportacion b ON b.id = be.bloque_id
                WHERE be.escuela_id = f.id AND be.cliente = 'kira-docentes'
                  AND b.estado = 'listo-asignar-ruta') AS docentes,
        EXISTS (SELECT 1 FROM bloque_exportacion_escuela be
                JOIN bloques_exportacion b ON b.id = be.bloque_id
                WHERE be.escuela_id = f.id AND be.cliente = 'kira-estudiantes'
                  AND b.estado = 'listo-asignar-ruta') AS estudiantes
    ) entrega ON TRUE
  ) base
),
predicados AS (
  SELECT p.*,
         (p.vigentes > 0 AND p.enviadas = p.vigentes)                AS finalizado,
         (p.intervenida IS TRUE)                                     AS en_intervencion,
         (p.percance OR p.seccion_faltante)                          AS hay_registros,
         ((p.percance OR p.seccion_faltante) AND NOT p.caso_cerrado) AS por_revisar,
         t.confirmadas::int AS accesos_confirmados,
         t.otorgadas::int   AS accesos_otorgados,
         CASE WHEN t.otorgadas > 0 THEN ROUND(t.confirmadas * 100.0 / t.otorgadas)::int ELSE 0 END
           AS pct_confirmado
  FROM por_escuela p
  JOIN tasa_confirmacion t ON t.escuela_id = p.escuela_id
),
clasificadas AS (
  SELECT *,
         CASE
           WHEN en_intervencion THEN 'Intervención'
           WHEN ((por_revisar AND (finalizado OR cerrado_temporal))
                 OR (hay_registros AND cerrado_temporal AND NOT finalizado))
                AND pct_confirmado <= 50 THEN 'Incidencias · Rango bajo (0-50%)'
           WHEN ((por_revisar AND (finalizado OR cerrado_temporal))
                 OR (hay_registros AND cerrado_temporal AND NOT finalizado))
                AND pct_confirmado <= 90 THEN 'Incidencias · Rango medio (51-90%)'
           WHEN ((por_revisar AND (finalizado OR cerrado_temporal))
                 OR (hay_registros AND cerrado_temporal AND NOT finalizado))
                THEN 'Incidencias · Rango alto (91-99%)'
           WHEN cerrado_temporal AND NOT finalizado THEN 'Rezagados · Cerrados temporalmente'
           WHEN enviadas = 0 AND capturando = 0     THEN 'Rezagados · Pendientes de visita'
           WHEN NOT finalizado                      THEN 'Certificación en sitio'
           ELSE 'Certificado'
         END AS estado_tablero
  FROM predicados
)
SELECT
    e.codigo_escuela,
    e.nombre_escuela,
    d.nombre AS departamento,
    c.estado_tablero,
    e.en_intervencion,
    e.en_intervencion_certificacion,
    c.vigentes,
    c.enviadas,
    c.capturando,
    ccd.cuentas cuentas_docentes_confirmada,
    cce.cuentas cuentas_estudiantes_confirmada,
    c.accesos_confirmados,
    cde.cuentas cuentas_docentes_otorgados,
    cee.cuentas cuentas_estudiantes_otorgados,
    c.accesos_otorgados,
    c.pct_confirmado,
    c.percance,
    c.seccion_faltante,
    c.caso_cerrado,
    c.cerrado_temporal
FROM clasificadas c
JOIN escuelas e ON e.id = c.escuela_id
JOIN departamentos d ON d.id = e.departamento_id
JOIN cuentas_confirmadas_estudiantes cce ON cce.escuela_id = c.escuela_id
JOIN cuentas_confirmadas_docentes ccd ON ccd.escuela_id = c.escuela_id
JOIN docentes_elegibles cde ON cde.escuela_id = c.escuela_id
JOIN estudiantes_elegibles cee ON cee.escuela_id = c.escuela_id
ORDER BY c.estado_tablero, e.codigo_escuela;