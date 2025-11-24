------------Caso N°1: Listado de clientes------------

SELECT 
    TO_CHAR(c.numrun, 'FM99G999G999') || '-' || c.dvrun AS "RUT Cliente",
    INITCAP(c.pnombre || ' ' || c.appaterno) AS "Nombre Cliente",
    UPPER(po.nombre_prof_ofic) AS "Profesión Cliente",
    TO_CHAR(c.fecha_inscripcion, 'DD-MM-YYYY') AS "Fecha de Inscripción",
    INITCAP(c.direccion) AS "Dirección Cliente"
FROM 
    cliente c
    INNER JOIN profesion_oficio po ON c.cod_prof_ofic = po.cod_prof_ofic
    INNER JOIN tipo_cliente tc ON c.cod_tipo_cliente = tc.cod_tipo_cliente
WHERE 
    tc.nombre_tipo_cliente = 'Trabajadores dependientes'
    AND UPPER(po.nombre_prof_ofic) IN ('CONTADOR', 'VENDEDOR')
    AND EXTRACT(YEAR FROM c.fecha_inscripcion) > (
        SELECT ROUND(AVG(EXTRACT(YEAR FROM fecha_inscripcion)))
        FROM cliente
    )
ORDER BY 
    c.numrun ASC;
    
------------Caso N°2: Aumento de crédito------------

CREATE TABLE clientes_cupos_compra AS
SELECT 
    c.numrun || '-' || c.dvrun AS "RUT_CLIENTE",
    TRUNC(MONTHS_BETWEEN(SYSDATE, c.fecha_nacimiento) / 12) AS "EDAD",
    TO_CHAR(tc.cupo_disp_compra, '$999G999G999') AS "CUPO_DISPONIBLE_COMPRA",
    UPPER(tip.nombre_tipo_cliente) AS "TIPO_CLIENTE"
FROM 
    cliente c
    INNER JOIN tarjeta_cliente tc ON c.numrun = tc.numrun
    INNER JOIN tipo_cliente tip ON c.cod_tipo_cliente = tip.cod_tipo_cliente
WHERE 
    tc.cupo_disp_compra >= (
        SELECT MAX(tc2.cupo_disp_compra)
        FROM tarjeta_cliente tc2
        WHERE EXTRACT(YEAR FROM tc2.fecha_solic_tarjeta) = EXTRACT(YEAR FROM SYSDATE) - 1
    )
ORDER BY 
    TRUNC(MONTHS_BETWEEN(SYSDATE, c.fecha_nacimiento) / 12) ASC;


--Consulta de tabla creada--    
SELECT * FROM clientes_cupos_compra;