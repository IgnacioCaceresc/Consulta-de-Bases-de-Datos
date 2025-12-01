---------------Caso 1: Reportería de Asesorías---------------

SELECT 
    p.id_profesional AS "ID",
    p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre AS "PROFESIONAL",
    NVL(b.asesorias_banca, 0) AS "NRO ASESORIA BANCA",
    LPAD(TO_CHAR(NVL(b.honorarios_banca, 0), '$99G999G999', 'NLS_NUMERIC_CHARACTERS=,.'), 20) AS "MONTO_TOTAL_BANCA",
    NVL(r.asesorias_retail, 0) AS "NRO ASESORIA RETAIL",
    LPAD(TO_CHAR(NVL(r.honorarios_retail, 0), '$99G999G999', 'NLS_NUMERIC_CHARACTERS=,.'), 20) AS "MONTO_TOTAL_RETAIL",
    NVL(b.asesorias_banca, 0) + NVL(r.asesorias_retail, 0) AS "TOTAL ASESORIAS",
    LPAD(TO_CHAR(NVL(b.honorarios_banca, 0) + NVL(r.honorarios_retail, 0), '$99G999G999', 'NLS_NUMERIC_CHARACTERS=,.'), 20) AS "TOTAL HONORARIOS"
FROM 
    profesional p
    INNER JOIN (
        SELECT 
            a.id_profesional,
            COUNT(*) AS asesorias_banca,
            SUM(a.honorario) AS honorarios_banca
        FROM 
            asesoria a
            INNER JOIN empresa e ON a.cod_empresa = e.cod_empresa
        WHERE 
            e.cod_sector = 3
        GROUP BY 
            a.id_profesional
    ) b ON p.id_profesional = b.id_profesional
    INNER JOIN (
        SELECT 
            a.id_profesional,
            COUNT(*) AS asesorias_retail,
            SUM(a.honorario) AS honorarios_retail
        FROM 
            asesoria a
            INNER JOIN empresa e ON a.cod_empresa = e.cod_empresa
        WHERE 
            e.cod_sector = 4
        GROUP BY 
            a.id_profesional
    ) r ON p.id_profesional = r.id_profesional
WHERE
    p.id_profesional IN (
        SELECT id_profesional 
        FROM asesoria a
        INNER JOIN empresa e ON a.cod_empresa = e.cod_empresa
        WHERE e.cod_sector = 3
        INTERSECT
        SELECT id_profesional 
        FROM asesoria a
        INNER JOIN empresa e ON a.cod_empresa = e.cod_empresa
        WHERE e.cod_sector = 4
    )
ORDER BY 
    p.id_profesional ASC;
    
---------------Caso 2: Resumen de Honorarios---------------
--Eliminación de tabla si es que existe--
DROP TABLE REPORTE_MES CASCADE CONSTRAINTS;
--Creacion de tabla REPORTE_MES--
CREATE TABLE REPORTE_MES (
    ID_PROF NUMBER(10),
    NOMBRE_COMPLETO VARCHAR2(100),
    NOMBRE_PROFESION VARCHAR2(50),
    NOM_COMUNA VARCHAR2(50),
    NRO_ASESORIAS NUMBER(5),
    MONTO_TOTAL_HONORARIOS NUMBER(10),
    PROMEDIO_HONORARIO NUMBER(10),
    HONORARIO_MINIMO NUMBER(10),
    HONORARIO_MAXIMO NUMBER(10)
);

--Poblado de tabla--
INSERT INTO REPORTE_MES
--Consulta--
SELECT 
    p.id_profesional AS ID_PROF,
    p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre AS NOMBRE_COMPLETO,
    pr.nombre_profesion AS NOMBRE_PROFESION,
    NVL(c.nom_comuna, 'Sin Comuna') AS NOM_COMUNA,
    COUNT(*) AS NRO_ASESORIAS,
    ROUND(SUM(a.honorario), 0) AS MONTO_TOTAL_HONORARIOS,
    ROUND(AVG(a.honorario), 0) AS PROMEDIO_HONORARIO,
    ROUND(MIN(a.honorario), 0) AS HONORARIO_MINIMO,
    ROUND(MAX(a.honorario), 0) AS HONORARIO_MAXIMO
FROM 
    profesional p
    INNER JOIN asesoria a ON p.id_profesional = a.id_profesional
    INNER JOIN profesion pr ON p.cod_profesion = pr.cod_profesion
    LEFT JOIN comuna c ON p.cod_comuna = c.cod_comuna
WHERE 
    TO_CHAR(a.fin_asesoria, 'MM') = '04'
    AND TO_CHAR(a.fin_asesoria, 'YYYY') = TO_CHAR(ADD_MONTHS(SYSDATE, -12), 'YYYY')
GROUP BY 
    p.id_profesional,
    p.appaterno,
    p.apmaterno,
    p.nombre,
    pr.nombre_profesion,
    c.nom_comuna
ORDER BY 
    p.id_profesional ASC;
COMMIT;

---------------Caso 3: Modificación de Honorarios---------------

--Consulta antes de actualizar sueldos--

SELECT 
    SUM(a.honorario) AS HONORARIO,
    p.id_profesional AS ID_PROFESIONAL,
    p.numrun_prof AS NUMRUN_PROF,
    p.sueldo AS SUELDO
FROM 
    profesional p
    INNER JOIN asesoria a ON p.id_profesional = a.id_profesional
WHERE 
    TO_CHAR(a.fin_asesoria, 'MM') = '03'
    AND TO_CHAR(a.fin_asesoria, 'YYYY') = TO_CHAR(ADD_MONTHS(SYSDATE, -12), 'YYYY')
GROUP BY 
    p.id_profesional,
    p.numrun_prof,
    p.sueldo
ORDER BY 
    ID_PROFESIONAL ASC;

--Actualización de sueldos--

UPDATE profesional p
SET p.sueldo = CASE 
    WHEN (
        SELECT NVL(SUM(a.honorario), 0)
        FROM asesoria a
        WHERE a.id_profesional = p.id_profesional
            AND TO_CHAR(a.fin_asesoria, 'MM') = '03'
            AND TO_CHAR(a.fin_asesoria, 'YYYY') = TO_CHAR(ADD_MONTHS(SYSDATE, -12), 'YYYY')
    ) < 1000000 THEN 
        ROUND(p.sueldo * 1.10, 0)  
    WHEN (
        SELECT NVL(SUM(a.honorario), 0)
        FROM asesoria a
        WHERE a.id_profesional = p.id_profesional
            AND TO_CHAR(a.fin_asesoria, 'MM') = '03'
            AND TO_CHAR(a.fin_asesoria, 'YYYY') = TO_CHAR(ADD_MONTHS(SYSDATE, -12), 'YYYY')
    ) >= 1000000 THEN 
        ROUND(p.sueldo * 1.15, 0)  
    ELSE 
        p.sueldo 
END
WHERE p.id_profesional IN (
    SELECT DISTINCT a.id_profesional
    FROM asesoria a
    WHERE TO_CHAR(a.fin_asesoria, 'MM') = '03'
        AND TO_CHAR(a.fin_asesoria, 'YYYY') = TO_CHAR(ADD_MONTHS(SYSDATE, -12), 'YYYY')
);

COMMIT;

--Consulta después de actualizar sueldos--

SELECT 
    SUM(a.honorario) AS HONORARIO,
    p.id_profesional AS ID_PROFESIONAL,
    p.numrun_prof AS NUMRUN_PROF,
    p.sueldo AS SUELDO
FROM 
    profesional p
    INNER JOIN asesoria a ON p.id_profesional = a.id_profesional
WHERE 
    TO_CHAR(a.fin_asesoria, 'MM') = '03'
    AND TO_CHAR(a.fin_asesoria, 'YYYY') = TO_CHAR(ADD_MONTHS(SYSDATE, -12), 'YYYY')
GROUP BY 
    p.id_profesional,
    p.numrun_prof,
    p.sueldo
ORDER BY 
    ID_PROFESIONAL ASC;