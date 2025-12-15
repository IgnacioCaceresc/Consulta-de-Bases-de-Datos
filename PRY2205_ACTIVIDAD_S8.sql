/* ****************************
 *
 * USUARIO ADMIN - SYS - SYSTEM
 *
 * ****************************/

 -- código ejecutado por usuario ADMIN - SYS - SYSTEM

------------------CASO N°1------------------

--------Creacion USER1--------
CREATE USER PRY2205_USER1 
IDENTIFIED BY "PRY2205.user1_S8"
DEFAULT TABLESPACE DATA
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON DATA;

--------Creacion USER2--------
CREATE USER PRY2205_USER2 
IDENTIFIED BY "PRY2205.user2_S8"
DEFAULT TABLESPACE DATA
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON DATA;

--------Creal rol ----------
CREATE ROLE PRY2205_ROL_D;

--------Crear rol USER2--------
CREATE ROLE PRY2205_ROL_P;

--------Asignacion de privilegios al rol PRY2205_ROL_D--------

--Privilegios para crear objetos--
GRANT CREATE SESSION TO PRY2205_ROL_D;
GRANT CREATE TABLE TO PRY2205_ROL_D;
GRANT CREATE VIEW TO PRY2205_ROL_D;
GRANT CREATE SEQUENCE TO PRY2205_ROL_D;
GRANT CREATE PROCEDURE TO PRY2205_ROL_D;
GRANT CREATE TRIGGER TO PRY2205_ROL_D;
GRANT CREATE SYNONYM TO PRY2205_ROL_D;

--Privilegios para índices--
GRANT CREATE ANY INDEX TO PRY2205_ROL_D;


--Privilegios para analizar planes de ejecución--
GRANT SELECT_CATALOG_ROLE TO PRY2205_ROL_D;

--Asignacion de privilegios al rol PRY2205_ROL_P--

--Privilegios de sistemas básicos--
GRANT CREATE SESSION TO PRY2205_ROL_P;
GRANT CREATE TABLE TO PRY2205_ROL_P;
GRANT CREATE SEQUENCE TO PRY2205_ROL_P;
GRANT CREATE TRIGGER TO PRY2205_ROL_P;
GRANT CREATE SYNONYM TO PRY2205_USER2;

--------Asignacion de roles a usuarios--------
GRANT PRY2205_ROL_D TO PRY2205_USER1;
GRANT PRY2205_ROL_P TO PRY2205_USER2;

--------Establecer roles como predeterminados--------
ALTER USER PRY2205_USER1 DEFAULT ROLE PRY2205_ROL_D;
ALTER USER PRY2205_USER2 DEFAULT ROLE PRY2205_ROL_P;


 /* ****************************
 *
 * USER_1
 *
 * ****************************/

 -- código ejecutado por usuario USER_1

-- creación y poblamiento de tablas (no se agrega el script pero se indica)

------------------CASO N°1------------------

---------PERMISOS ESPECÍFICOS PARA EL USER 2---------
GRANT SELECT ON PRY2205_USER1.LIBRO TO PRY2205_USER2;
GRANT SELECT ON PRY2205_USER1.EJEMPLAR TO PRY2205_USER2;
GRANT SELECT ON PRY2205_USER1.PRESTAMO TO PRY2205_USER2;
GRANT SELECT ON PRY2205_USER1.EMPLEADO TO PRY2205_USER2;

------------------CASO N°3------------------
--CREACION DE VISTA VW_DETALLE_MULTAS--
DROP VIEW VW_DETALLE_MULTAS;
CREATE VIEW VW_DETALLE_MULTAS AS
SELECT 
    P.PRESTAMOID,
    
    -- Nombre completo del alumno (función de caracteres: CONCAT, ||)
    A.NOMBRE || ' ' || A.APATERNO || ' ' || A.AMATERNO AS NOMBRE_ALUMNO,
    
    -- Nombre de la carrera
    C.DESCRIPCION AS NOMBRE_CARRERA,
    
    -- Código y precio del libro
    L.LIBROID AS CODIGO_LIBRO,
    L.PRECIO AS PRECIO_LIBRO,
    
    -- Fechas de devolución (programada y efectiva)
    P.FECHA_TERMINO AS FECHA_DEVOLUCION_PROGRAMADA,
    P.FECHA_ENTREGA AS FECHA_DEVOLUCION_EFECTIVA,
    
    -- Días de atraso (función de fecha: diferencia entre fechas)
    TRUNC(P.FECHA_ENTREGA - P.FECHA_TERMINO) AS DIAS_ATRASO,
    
    -- Cálculo de multa (3% del precio por cada día de atraso)
    -- Función numérica: ROUND para redondear a 2 decimales
    ROUND(
        L.PRECIO * 0.03 * TRUNC(P.FECHA_ENTREGA - P.FECHA_TERMINO),
        2
    ) AS MULTA,
    
    -- Cálculo de rebaja según convenio de carrera
    -- Función condicional: CASE
    -- Función de manejo de nulos: NVL
    ROUND(
        (L.PRECIO * 0.03 * TRUNC(P.FECHA_ENTREGA - P.FECHA_TERMINO)) * 
        (NVL(
            (SELECT RM.PORC_REBAJA_MULTA 
             FROM REBAJA_MULTA RM 
             WHERE RM.CARRERAID = C.CARRERAID),
            0
        ) / 100),
        2
    ) AS REBAJA

-- USAR SINÓNIMOS DEL CASO 1 (no PRY2205_USER1.TABLA)
FROM PRESTAMO P
-- Joins de tablas usando sinónimos
INNER JOIN ALUMNO A ON P.ALUMNOID = A.ALUMNOID
INNER JOIN CARRERA C ON A.CARRERAID = C.CARRERAID
INNER JOIN LIBRO L ON P.LIBROID = L.LIBROID

WHERE 
    -- Préstamos terminados hace 2 años
    EXTRACT(YEAR FROM P.FECHA_TERMINO) = (EXTRACT(YEAR FROM SYSDATE) - 2)
    -- Solo préstamos con atraso (fecha_termino < fecha_entrega)
    AND P.FECHA_TERMINO < P.FECHA_ENTREGA
    -- Manejo de nulos: Solo préstamos con fecha de entrega registrada
    AND P.FECHA_ENTREGA IS NOT NULL

-- Ordenamiento descendente por fecha de entrega
ORDER BY P.FECHA_ENTREGA DESC;


---CONSULTAR VISTA COMPLETA
SELECT * FROM VW_DETALLE_MULTAS;

--Obtencion del plan de ejecucion de la consulta de la vista--
EXPLAIN PLAN FOR
SELECT * FROM VW_DETALLE_MULTAS;

--Ver el plan de ejecución--
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

--Creacion de índices--
--Elimina el TABLE ACCESS FULL de PRÉSTAMO--
CREATE INDEX IDX_PRESTAMO_MULTAS 
ON PRESTAMO(FECHA_TERMINO, FECHA_ENTREGA, ALUMNOID, LIBROID);

--Índice en FECHA_TERMINO--
CREATE INDEX IDX_PRESTAMO_FECHA_TERM 
ON PRESTAMO(FECHA_TERMINO);

--Índice en FECHA_ENTREGA--
CREATE INDEX IDX_PRESTAMO_FECHA_ENT 
ON PRESTAMO(FECHA_ENTREGA DESC);

-- Recolectar estadísticas actualizadas
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'PRESTAMO');
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'ALUMNO');
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'LIBRO');
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'CARRERA');
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'REBAJA_MULTA');

-- Obtener el nuevo plan de ejecución
EXPLAIN PLAN FOR
SELECT * FROM VW_DETALLE_MULTAS;

-- Ver el plan de ejecución mejorado
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);


 /* ****************************
 *
 * USUARIO USER_2
 *
 * ****************************/

 -- código ejecutado por usuario USER_2

------------------CASO N°1------------------
-- Probar acceso a través de sinónimos públicos
SELECT COUNT(*) AS TOTAL_LIBROS FROM LIBRO;
SELECT COUNT(*) AS TOTAL_EJEMPLARES FROM EJEMPLAR;
SELECT COUNT(*) AS TOTAL_PRESTAMOS FROM PRESTAMO;
SELECT COUNT(*) AS TOTAL_EMPLEADOS FROM EMPLEADO;

-- Crear sinónimos privados
CREATE SYNONYM LIBRO FOR PRY2205_USER1.LIBRO;
CREATE SYNONYM EJEMPLAR FOR PRY2205_USER1.EJEMPLAR;
CREATE SYNONYM PRESTAMO FOR PRY2205_USER1.PRESTAMO;
CREATE SYNONYM EMPLEADO FOR PRY2205_USER1.EMPLEADO;
CREATE SYNONYM ALUMNO FOR PRY2205_USER1.ALUMNO;
CREATE SYNONYM CARRERA FOR PRY2205_USER1.CARRERA;
CREATE SYNONYM ESCUELA FOR PRY2205_USER1.ESCUELA;
CREATE SYNONYM AUTOR FOR PRY2205_USER1.AUTOR;
CREATE SYNONYM EDITORIAL FOR PRY2205_USER1.EDITORIAL;
CREATE SYNONYM REBAJA_MULTA FOR PRY2205_USER1.REBAJA_MULTA;
CREATE SYNONYM VALOR_MULTA_PRESTAMO FOR PRY2205_USER1.VALOR_MULTA_PRESTAMO;


------------------CASO N°2------------------

--Creacion de secuencia--

CREATE SEQUENCE SEQ_CONTROL_STOCK
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;

--Creacion de tabla CONTROL_STOCK_LIBROS--

CREATE TABLE CONTROL_STOCK_LIBROS AS
SELECT 
    ROWNUM AS ID_CONTROL,
    LIBRO_ID,
    NOMBRE_LIBRO,
    TOTAL_EJEMPLARES,
    EN_PRESTAMO,
    DISPONIBLES,
    PORCENTAJE_PRESTAMO,
    STOCK_CRITICO
FROM (
    SELECT 
        L.LIBROID AS LIBRO_ID,
        L.NOMBRE_LIBRO AS NOMBRE_LIBRO,
        
        -- Total de ejemplares por libro
        (SELECT COUNT(*) 
         FROM EJEMPLAR E 
         WHERE E.LIBROID = L.LIBROID) AS TOTAL_EJEMPLARES,
        
        -- Ejemplares en préstamo (en el periodo de 2 años atrás)
        NVL((SELECT COUNT(DISTINCT P.EJEMPLARID)
             FROM PRESTAMO P
             WHERE P.LIBROID = L.LIBROID
               AND P.EMPLEADOID IN (190, 180, 150)
               AND EXTRACT(YEAR FROM P.FECHA_INICIO) = (EXTRACT(YEAR FROM SYSDATE) - 2)
        ), 0) AS EN_PRESTAMO,
        
        -- Ejemplares disponibles (Total - En Préstamo)
        (SELECT COUNT(*) 
         FROM EJEMPLAR E 
         WHERE E.LIBROID = L.LIBROID) - 
        NVL((SELECT COUNT(DISTINCT P.EJEMPLARID)
             FROM PRESTAMO P
             WHERE P.LIBROID = L.LIBROID
               AND P.EMPLEADOID IN (190, 180, 150)
               AND EXTRACT(YEAR FROM P.FECHA_INICIO) = (EXTRACT(YEAR FROM SYSDATE) - 2)
        ), 0) AS DISPONIBLES,
        
        -- Porcentaje de ejemplares en préstamo
        CASE 
            WHEN (SELECT COUNT(*) FROM EJEMPLAR E WHERE E.LIBROID = L.LIBROID) > 0 THEN
                ROUND(
                    (NVL((SELECT COUNT(DISTINCT P.EJEMPLARID)
                          FROM PRESTAMO P
                          WHERE P.LIBROID = L.LIBROID
                            AND P.EMPLEADOID IN (190, 180, 150)
                            AND EXTRACT(YEAR FROM P.FECHA_INICIO) = (EXTRACT(YEAR FROM SYSDATE) - 2)
                    ), 0) * 100.0) / 
                    (SELECT COUNT(*) FROM EJEMPLAR E WHERE E.LIBROID = L.LIBROID)
                , 2)
            ELSE 0
        END AS PORCENTAJE_PRESTAMO,
        
        -- Indicador de stock crítico
        CASE 
            WHEN ((SELECT COUNT(*) FROM EJEMPLAR E WHERE E.LIBROID = L.LIBROID) - 
                  NVL((SELECT COUNT(DISTINCT P.EJEMPLARID)
                       FROM PRESTAMO P
                       WHERE P.LIBROID = L.LIBROID
                         AND P.EMPLEADOID IN (190, 180, 150)
                         AND EXTRACT(YEAR FROM P.FECHA_INICIO) = (EXTRACT(YEAR FROM SYSDATE) - 2)
                  ), 0)) > 2 
            THEN 'S'
            ELSE 'N'
        END AS STOCK_CRITICO
        
    FROM LIBRO L
    WHERE EXISTS (
        SELECT 1 
        FROM PRESTAMO P
        WHERE P.LIBROID = L.LIBROID
          AND P.EMPLEADOID IN (190, 180, 150)
          AND EXTRACT(YEAR FROM P.FECHA_INICIO) = (EXTRACT(YEAR FROM SYSDATE) - 2)
    )
    ORDER BY L.LIBROID
);
--Consulta--
SELECT * FROM CONTROL_STOCK_LIBROS
ORDER BY LIBRO_ID;


