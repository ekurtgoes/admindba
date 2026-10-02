-- ============================================================================
-- ALTA DE 5 USUARIOS - DIRECTORES DE CENTRO ESCOLAR - Aplicativo de Agendamiento
-- Base: formacion-docentes-db   ·   Backend: datos-formacion-docente-backend
--
--   Los 5, sin excepcion, con rol «Director».
--
-- Origen: «email.txt» (5 correos, sin nombre, sin Codigo de centro, sin DUI).
-- Plantilla: «alta-usuarios-agendamiento-directores.sql» (tanda de 639). Mismos
-- pasos, mismas reglas; solo cambian los datos.
-- ============================================================================
--
-- QUE HACE, EN UNA LINEA
--
--   Crea a los que no existen, con rol «Director». Al que ya exista, no lo toca.
--   Excepcion: corrige el correo de D629 (ver abajo) en vez de duplicarlo.
--
-- ----------------------------------------------------------------------------
-- LOS 5 CORREOS, CONTRA LA TANDA DE 639
-- ----------------------------------------------------------------------------
--
--   Cuatro no aparecen en la tanda de 639 (ni por correo ni por nombre):
--     oscar.guevara@clases.edu.sv
--     kevin.garzona@clases.edu.sv
--     ruben.ramirez@clases.edu.sv
--     adilson.dela.o@clases.edu.sv
--
--   Uno SI aparece, pero escrito distinto:
--     D629  CE 12714  José Baltazar Sigarán
--       tanda de 639: jose.barltazar.sigaran@clases.edu.sv   (typo: «barltazar»)
--       email.txt:    jose.baltazar.sigaran@clases.edu.sv
--
--   Se asume que email.txt trae el correo bueno. Si la cuenta con el typo ya
--   existe, el PASO 3-bis le corrige el correo (conserva su id, DUI 900005629 y
--   lo que ya haya agendado) y el PASO 4 ya no la crea de nuevo. Si no existe,
--   el PASO 4 la crea con el correo bueno. Nunca quedan dos cuentas.
--
-- ----------------------------------------------------------------------------
-- NOMBRES
-- ----------------------------------------------------------------------------
--
--   email.txt no trae nombres. Los 4 nuevos llevan el nombre armado a partir
--   del correo, en Mayuscula Inicial y sin tildes (no hay de donde sacarlas):
--   «adilson.dela.o» queda «Adilson De La O». Si se consigue el nombre
--   completo, cambiarlo en los VALUES del PASO 4 antes de ejecutarlo.
--   D629 conserva el nombre de la tanda de 639: «José Baltazar Sigarán».
--   `name` y `username` llevan el mismo valor.
--
-- ----------------------------------------------------------------------------
-- LOS DUI Y LOS TELEFONOS
-- ----------------------------------------------------------------------------
--
--   Marcador de DUI, bloque nuevo:
--
--     900006001 ... 900006005   esta tanda (el numero es su orden en email.txt)
--
--   Bloques ya usados, sin choque:
--     900000001-900000110  1a tanda
--     900000111-900000119  2a tanda, Zona Central
--     900001001-900001120  2a tanda, Zona Oriental
--     900002001            Juan Irigoyen, cuenta institucional
--     900003001-900003030  Zona Occidente
--     900004001-900004020  cuentas director-demo (SOLO QA/DEV, no Produccion)
--     900005001-900005639  Directores, tanda de 639
--
--   900006005 (Baltazar) solo se usa si su cuenta NO existia. Si el PASO 3-bis
--   la corrigio, sigue con su DUI original 900005629.
--
--   TELEFONOS: marcador '00000000', igual que la tanda de 639.
--
-- ----------------------------------------------------------------------------
-- LA CONTRASENA
-- ----------------------------------------------------------------------------
--
--   No se escribe `password` (ver tanda de 639). Estas cuentas entran con Google.
--
-- ----------------------------------------------------------------------------
-- COMO SE EJECUTA EN CLOUD SQL STUDIO
-- ----------------------------------------------------------------------------
--
--   UN PASO A LA VEZ. Se copia un paso, se ejecuta, se LEE el resultado, y solo
--   entonces se pasa al siguiente. NO se pega el archivo entero. NO escribir
--   BEGIN ni COMMIT.
--
--   Orden normal:  1 -> 1-bis -> 2 -> (2-bis si hace falta) -> 3 -> 3-bis -> 4 -> 5
--   Si el 5 no cuadra:  6
--   Opcionales:         7 (corregir rol de los que ya existian)
--                       8 (deshacer: BORRA)
--
--   Los pasos que escriben en el camino normal son el 3-bis y el 4.
--
-- ############################################################################


-- ############################################################################
-- PASO 1 - Existe el rol «Director», y con que id?
--
-- Que mirar: UNA fila, name = 'Director'. Si no sale, PARAR.
-- ############################################################################
SELECT id, name, comments
FROM "Role"
WHERE name = 'Director';


-- ############################################################################
-- PASO 1-bis - FRENO DURO. Detiene el script si el rol no esta.
-- ############################################################################
DO $$
DECLARE n int;
BEGIN
    SELECT COUNT(*) INTO n FROM "Role" WHERE name = 'Director';
    IF n = 0 THEN
        RAISE EXCEPTION 'No existe el rol Director en esta base. Crearlo antes de continuar.';
    ELSIF n > 1 THEN
        RAISE EXCEPTION 'Hay % roles llamados Director. Resolver el duplicado antes de continuar.', n;
    END IF;
END $$;


-- ############################################################################
-- PASO 2 - ENSAYO. Que va a pasar con cada uno de los 5.  (no escribe)
--
-- Que mirar, en la columna `accion`:
--   SE INSERTA   -> no existe. Lo crea el paso 4.
--   SE CORRIGE   -> existe con el correo viejo (typo). Lo corrige el paso 3-bis.
--   YA EXISTE    -> alguien ya tiene ese correo. El paso 4 NO lo toca. Si hay
--                   que corregirle el rol, es el paso 7.
--   CONFLICTO    -> existen AMBOS correos (el viejo y el bueno). PARAR y
--                   decidir a mano cual cuenta se queda.
--
-- `dui_ocupado_por` con valor es la otra razon por la que alguien puede quedar
-- fuera. Lo esperable es que salga vacia en las 5 filas.
-- ############################################################################
WITH objetivo(email, rol, dui, email_anterior) AS (VALUES
    ('oscar.guevara@clases.edu.sv'        , 'Director', '900006001', NULL),
    ('kevin.garzona@clases.edu.sv'        , 'Director', '900006002', NULL),
    ('ruben.ramirez@clases.edu.sv'        , 'Director', '900006003', NULL),
    ('adilson.dela.o@clases.edu.sv'       , 'Director', '900006004', NULL),
    ('jose.baltazar.sigaran@clases.edu.sv', 'Director', '900006005', 'jose.barltazar.sigaran@clases.edu.sv')  -- D629  CE 12714
)
SELECT
    CASE
        WHEN u.id IS NOT NULL AND v.id IS NOT NULL THEN 'CONFLICTO'
        WHEN u.id IS NOT NULL                      THEN 'YA EXISTE'
        WHEN v.id IS NOT NULL                      THEN 'SE CORRIGE'
        ELSE                                            'SE INSERTA'
    END                                     AS accion,
    o.email,
    v.email                                 AS email_actual_con_typo,
    COALESCE(r.name, rv.name, '-')          AS rol_actual,
    o.rol                                   AS rol_nuevo,
    COALESCE(u.id, v.id)                    AS user_id,
    CASE WHEN v.id IS NULL THEN ocupa.email END AS dui_ocupado_por
FROM objetivo o
LEFT JOIN "User" u     ON lower(u.email) = o.email
LEFT JOIN "Role" r     ON r.id = u."roleId"
LEFT JOIN "User" v     ON lower(v.email) = o.email_anterior
LEFT JOIN "Role" rv    ON rv.id = v."roleId"
LEFT JOIN "User" ocupa ON ocupa.dui = o.dui AND lower(ocupa.email) <> o.email
ORDER BY accion, o.email;


-- ############################################################################
-- PASO 2-bis - Correos guardados con mayusculas.  (solo si el paso 2 marco algo)
--
-- El login hace `email.toLowerCase()` y luego busca coincidencia EXACTA. Un
-- correo con una mayuscula deja la cuenta viva en la tabla pero inalcanzable, y
-- el indice unico tampoco equipara mayusculas, asi que el paso 4 lo duplicaria.
--
-- Solo BUSCA. Si devuelve filas, decidir a mano si se normalizan
-- (UPDATE "User" SET email = lower(email) WHERE id = ...) antes de seguir.
-- ############################################################################
SELECT id, email, name
FROM "User"
WHERE email <> lower(email)
  AND lower(email) IN (
      'oscar.guevara@clases.edu.sv',
      'kevin.garzona@clases.edu.sv',
      'ruben.ramirez@clases.edu.sv',
      'adilson.dela.o@clases.edu.sv',
      'jose.baltazar.sigaran@clases.edu.sv',
      'jose.barltazar.sigaran@clases.edu.sv'
  )
ORDER BY email;


-- ############################################################################
-- PASO 3 - Sincronizar la secuencia de "User"."id".  (defensivo, no cambia datos)
-- ############################################################################
SELECT setval(
    pg_get_serial_sequence('"User"', 'id'),
    COALESCE((SELECT MAX(id) FROM "User"), 1),
    true
) AS secuencia_en;


-- ############################################################################
-- PASO 3-bis - Corregir el correo de D629.   <<< ESCRIBE >>>
--
-- Cambia jose.barltazar.sigaran@ -> jose.baltazar.sigaran@ SOLO si la cuenta
-- con el typo existe y el correo bueno todavia no esta tomado. Si el paso 2
-- dijo CONFLICTO, NO correr este paso.
--
-- Que mirar: UPDATE 1 si la cuenta existia; UPDATE 0 si no (el paso 4 la crea).
-- Correrlo dos veces no hace nada la segunda vez.
-- ############################################################################
UPDATE "User" u
SET email = 'jose.baltazar.sigaran@clases.edu.sv'
WHERE lower(u.email) = 'jose.barltazar.sigaran@clases.edu.sv'
  AND NOT EXISTS (SELECT 1 FROM "User" x WHERE lower(x.email) = 'jose.baltazar.sigaran@clases.edu.sv')
RETURNING u.id, u.email, u.dui;


-- ############################################################################
-- PASO 4 - INSERTAR.   <<< ESCRIBE >>>
--
-- Idempotente: salta cualquier fila cuyo correo O cuyo DUI ya esten en la
-- tabla (dos NOT EXISTS y no ON CONFLICT: "User" tiene DOS indices unicos).
-- Si el paso 3-bis corrigio a Baltazar, su fila se salta aqui sola.
--
-- El roleId se resuelve por nombre, no a mano.
--
-- Que mirar: INSERT 0 5 si Baltazar no existia; INSERT 0 4 si el paso 3-bis
-- lo corrigio.
-- ############################################################################
INSERT INTO "User" (email, name, username, telephone, dui, "roleId", verified)
SELECT d.email,
       d.name,
       d.username,
       d.telephone,
       d.dui,
       (SELECT id FROM "Role" WHERE name = d.rol),
       true       -- verified
FROM (VALUES
    ('oscar.guevara@clases.edu.sv'        , 'Oscar Guevara'        , 'Oscar Guevara'        , '00000000', '900006001', 'Director'),
    ('kevin.garzona@clases.edu.sv'        , 'Kevin Garzona'        , 'Kevin Garzona'        , '00000000', '900006002', 'Director'),
    ('ruben.ramirez@clases.edu.sv'        , 'Ruben Ramirez'        , 'Ruben Ramirez'        , '00000000', '900006003', 'Director'),
    ('adilson.dela.o@clases.edu.sv'       , 'Adilson De La O'      , 'Adilson De La O'      , '00000000', '900006004', 'Director'),
    ('jose.baltazar.sigaran@clases.edu.sv', 'José Baltazar Sigarán', 'José Baltazar Sigarán', '00000000', '900006005', 'Director')   -- D629  CE 12714
) AS d(email, name, username, telephone, dui, rol)
WHERE NOT EXISTS (SELECT 1 FROM "User" u WHERE lower(u.email) = d.email)
  AND NOT EXISTS (SELECT 1 FROM "User" u WHERE u.dui         = d.dui);


-- ############################################################################
-- PASO 5 - Verificacion final.
--
-- Que mirar, exactamente esto:
--
--   rol_esperado   correctos   no_existen   con_rol_distinto   total
--   Director               5            0                  0       5
--
-- Cualquier otra cosa: pasar al paso 6.
-- ############################################################################
WITH objetivo(email, rol) AS (VALUES
    ('oscar.guevara@clases.edu.sv'        , 'Director'),
    ('kevin.garzona@clases.edu.sv'        , 'Director'),
    ('ruben.ramirez@clases.edu.sv'        , 'Director'),
    ('adilson.dela.o@clases.edu.sv'       , 'Director'),
    ('jose.baltazar.sigaran@clases.edu.sv', 'Director')
)
SELECT o.rol                                                        AS rol_esperado,
       COUNT(*) FILTER (WHERE r.name = o.rol)                       AS correctos,
       COUNT(*) FILTER (WHERE u.id IS NULL)                         AS no_existen,
       COUNT(*) FILTER (WHERE u.id IS NOT NULL AND r.name <> o.rol) AS con_rol_distinto,
       COUNT(*)                                                     AS total
FROM objetivo o
LEFT JOIN "User" u ON lower(u.email) = o.email
LEFT JOIN "Role" r ON r.id = u."roleId"
GROUP BY o.rol;


-- ############################################################################
-- PASO 6 - Quien quedo fuera y por que.  (solo si el paso 5 no cuadro)
--
-- `dui_ocupado_por` con valor explica el caso mas probable: el DUI sintetico
-- que le tocaba ya lo tenia otra persona. Se le da otro numero libre del mismo
-- bloque y se repite el paso 4 solo con esa fila.
-- ############################################################################
WITH objetivo(email, rol, dui) AS (VALUES
    ('oscar.guevara@clases.edu.sv'        , 'Director', '900006001'),
    ('kevin.garzona@clases.edu.sv'        , 'Director', '900006002'),
    ('ruben.ramirez@clases.edu.sv'        , 'Director', '900006003'),
    ('adilson.dela.o@clases.edu.sv'       , 'Director', '900006004'),
    ('jose.baltazar.sigaran@clases.edu.sv', 'Director', '900006005')
)
SELECT o.email,
       o.rol                 AS rol_esperado,
       COALESCE(r.name, '-') AS rol_actual,
       o.dui                 AS dui_asignado,
       ocupa.email           AS dui_ocupado_por,
       u.id                  AS user_id
FROM objetivo o
LEFT JOIN "User" u     ON lower(u.email) = o.email
LEFT JOIN "Role" r     ON r.id = u."roleId"
LEFT JOIN "User" ocupa ON ocupa.dui = o.dui AND lower(ocupa.email) <> o.email
WHERE u.id IS NULL OR r.name IS DISTINCT FROM o.rol
ORDER BY o.email;


-- ############################################################################
-- PASO 7 - OPCIONAL. Corregir el rol de los que YA existian.   <<< ESCRIBE >>>
--
-- Solo si el paso 2 marco «YA EXISTE» para alguien. Va comentado A PROPOSITO:
-- antes hay que MIRAR que rol tiene hoy esa persona. Si aparece con un rol que
-- no sea «Director», PREGUNTAR antes de cambiarlo.
--
-- Para usarlo: descomentar y dejar SOLO los correos que se decidio cambiar.
-- ############################################################################
-- UPDATE "User" u
-- SET "roleId" = (SELECT id FROM "Role" WHERE name = 'Director')
-- FROM (VALUES
--     ('oscar.guevara@clases.edu.sv'),
--     ('kevin.garzona@clases.edu.sv'),
--     ('ruben.ramirez@clases.edu.sv'),
--     ('adilson.dela.o@clases.edu.sv'),
--     ('jose.baltazar.sigaran@clases.edu.sv')
-- ) AS o(email)
-- WHERE lower(u.email) = o.email
--   AND u."roleId" IS DISTINCT FROM (SELECT id FROM "Role" WHERE name = 'Director')
-- RETURNING u.id, u.email;


-- ############################################################################
-- PASO 8 - DESHACER.   <<< BORRA >>>   Va comentado a proposito.
--
-- Borra SOLO a los que creo el paso 4, identificados por su bloque de DUI,
-- que es exclusivo de esta tanda. No toca la tanda de 639.
--
-- Si el paso 3-bis corrigio a Baltazar, su cuenta (DUI 900005629) NO se borra
-- aqui; para devolverle el correo anterior, usar el UPDATE comentado de abajo.
--
-- NO correrlo si esta gente ya agendo algo: las FK de "ActivityCalendar" y
-- "RefreshToken" haran fallar el DELETE, que es justamente la red de seguridad.
-- Primero mirar:
--
--   SELECT u.email, COUNT(a.id) AS actividades
--   FROM "User" u
--   LEFT JOIN "ActivityCalendar" a ON a."userId" = u.id
--   WHERE u.dui BETWEEN '900006001' AND '900006005'
--   GROUP BY u.email
--   ORDER BY actividades DESC;
--
-- DELETE FROM "User"
-- WHERE dui BETWEEN '900006001' AND '900006005'
-- RETURNING id, email;
--
-- UPDATE "User"
-- SET email = 'jose.barltazar.sigaran@clases.edu.sv'
-- WHERE lower(email) = 'jose.baltazar.sigaran@clases.edu.sv'
--   AND dui = '900005629'
-- RETURNING id, email;
-- ############################################################################
