--------------Caso 1: Listado de Trabajadores--------------

SELECT 
    UPPER(TRIM(t.nombre) || ' ' || TRIM(t.appaterno) || ' ' || TRIM(t.apmaterno)) AS "Nombre Completo Trabajador",
    TO_CHAR(t.numrut, 'FM99G999G999') || '-' || t.dvrut AS "RUT Trabajador",
    UPPER(tt.desc_categoria) AS "Tipo Trabajador",
    UPPER(cc.nombre_ciudad) AS "Ciudad Trabajador",
    LPAD('$' || TO_CHAR(t.sueldo_base, 'FM999G999G999'), 15) AS "Sueldo Base"
FROM 
    trabajador t
    INNER JOIN comuna_ciudad cc ON t.id_ciudad = cc.id_ciudad
    INNER JOIN tipo_trabajador tt ON t.id_categoria_t = tt.id_categoria
WHERE 
    t.sueldo_base BETWEEN 650000 AND 3000000
ORDER BY 
    cc.nombre_ciudad DESC,
    t.sueldo_base ASC;
    
--------------Caso 2: Listado Cajeros--------------

SELECT 
    TO_CHAR(t.numrut, 'FM99G999G999') || '-' || t.dvrut AS "RUT Trabajador",
    INITCAP(TRIM(t.nombre)) || ' ' || UPPER(TRIM(t.appaterno)) AS "Nombre Trabajador",
    COUNT(tc.nro_ticket) AS "Total Tickets",
    LPAD('$' || TO_CHAR(SUM(tc.monto_ticket), 'FM999G999G999'), 15) AS "Total Vendido",
    LPAD('$' || TO_CHAR(SUM(NVL(ct.valor_comision, 0)), 'FM999G999G999'), 15) AS "Comisión Total",
    UPPER(tt.desc_categoria) AS "Tipo Trabajador",
    UPPER(cc.nombre_ciudad) AS "Ciudad Trabajador"
FROM 
    trabajador t
    INNER JOIN tipo_trabajador tt ON t.id_categoria_t = tt.id_categoria
    INNER JOIN comuna_ciudad cc ON t.id_ciudad = cc.id_ciudad
    INNER JOIN tickets_concierto tc ON t.numrut = tc.numrut_t
    LEFT JOIN comisiones_ticket ct ON tc.nro_ticket = ct.nro_ticket
WHERE 
    UPPER(tt.desc_categoria) = 'CAJERO'
GROUP BY 
    t.numrut,
    t.dvrut,
    t.nombre,
    t.appaterno,
    tt.desc_categoria,
    cc.nombre_ciudad
HAVING 
    SUM(tc.monto_ticket) > 50000
ORDER BY 
    SUM(tc.monto_ticket) DESC;
    
--------------Caso 3: Listado de Bonificaciones--------------

SELECT 
    TO_CHAR(t.numrut, 'FM99G999G999') || '-' || t.dvrut AS "RUT Trabajador",
    INITCAP(TRIM(t.nombre) || ' ' || TRIM(t.appaterno)) AS "Trabajador Nombre",
    EXTRACT(YEAR FROM t.fecing) AS "Año Ingreso",
    TRUNC(MONTHS_BETWEEN(SYSDATE, t.fecing) / 12) AS "Años Antigüedad",
    COUNT(DISTINCT af.numrut_carga) AS "Num. Cargas Familiares",
    INITCAP(i.nombre_isapre) AS "Nombre Isapre",
    LPAD('$' || TO_CHAR(t.sueldo_base, 'FM999G999G999'), 15) AS "Sueldo Base",
    LPAD('$' || TO_CHAR(
        CASE 
            WHEN UPPER(i.nombre_isapre) = 'FONASA' THEN ROUND(t.sueldo_base * 0.01)
            ELSE 0
        END, 
        'FM999G999G999'
    ), 15) AS "Bono Fonasa",
    LPAD('$' || TO_CHAR(
        CASE 
            WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, t.fecing) / 12) <= 10 THEN ROUND(t.sueldo_base * 0.10)
            ELSE ROUND(t.sueldo_base * 0.15)
        END,
        'FM999G999G999'
    ), 15) AS "Bono Antigüedad",
    INITCAP(a.nombre_afp) AS "Nombre AFP",
    UPPER(ec.desc_estcivil) AS "Estado Civil"
FROM 
    trabajador t
    INNER JOIN isapre i ON t.cod_isapre = i.cod_isapre
    INNER JOIN afp a ON t.cod_afp = a.cod_afp
    INNER JOIN est_civil esc ON t.numrut = esc.numrut_t
    INNER JOIN estado_civil ec ON esc.id_estcivil_est = ec.id_estcivil
    LEFT JOIN asignacion_familiar af ON t.numrut = af.numrut_t
WHERE 
    (esc.fecter_estcivil IS NULL OR esc.fecter_estcivil > SYSDATE)
GROUP BY 
    t.numrut,
    t.dvrut,
    t.nombre,
    t.appaterno,
    t.fecing,
    t.sueldo_base,
    i.nombre_isapre,
    a.nombre_afp,
    ec.desc_estcivil
ORDER BY 
    t.numrut ASC;