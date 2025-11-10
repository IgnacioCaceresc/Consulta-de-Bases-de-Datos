-- Caso 1: Listado de Clientes con Rango de Renta

SELECT 
   -- Columna 1 --
    TO_CHAR(TRUNC(c.numrut_cli), 'FM99G999G999') || '-' || c.dvrut_cli AS "RUT Cliente",
    
   -- Columna 2 -- 
    INITCAP(c.nombre_cli || ' ' || c.appaterno_cli || ' ' || c.apmaterno_cli) AS "Nombre Completo Cliente",
    
   -- Columna 3 -- 
    INITCAP(c.direccion_cli) AS "Dirección Cliente",
    
   -- Columna 4 -- 
    '$' || TO_CHAR(ROUND(c.renta_cli), 'FM999G999G999') AS "Renta Cliente",
    
   -- Columna 5 -- 
    SUBSTR(TO_CHAR(c.celular_cli), 1, 2) || '-' || 
    SUBSTR(TO_CHAR(c.celular_cli), 3, 3) || '-' || 
    SUBSTR(TO_CHAR(c.celular_cli), 6, 4) AS "Celular Cliente",
    
    -- Columna 6 --
    CASE
        WHEN c.renta_cli > 500000 THEN 'TRAMO 1'
        WHEN c.renta_cli BETWEEN 400000 AND 500000 THEN 'TRAMO 2'
        WHEN c.renta_cli BETWEEN 200000 AND 399999 THEN 'TRAMO 3'
        WHEN c.renta_cli < 200000 THEN 'TRAMO 4'
    END AS "Tramo Renta Cliente"

FROM 
    cliente c

WHERE 
    c.celular_cli IS NOT NULL
    AND c.renta_cli BETWEEN &RENTA_MINIMA AND &RENTA_MAXIMA

ORDER BY 
    c.nombre_cli || c.appaterno_cli || c.apmaterno_cli ASC;
    
-- Caso 2: Sueldo Promedio por Categoría de Empleado 

SELECT 
    -- Columna 1 --
    e.id_categoria_emp AS "CODIGO_CATEGORIA",
    
    -- Columna 2 --
    CASE e.id_categoria_emp
        WHEN 1 THEN 'Gerente'
        WHEN 2 THEN 'Supervisor'
        WHEN 3 THEN 'Ejecutivo de Arriendo'
        WHEN 4 THEN 'Auxiliar'
        ELSE 'Sin Categoría'
    END AS "DESCRIPCION_CATEGORIA",
    
    -- Columna 3 --
    COUNT(e.numrut_emp) AS "CANTIDAD_EMPLEADOS",
    
    -- Columna 4 --
    CASE e.id_sucursal
        WHEN 10 THEN 'Sucursal Las Condes'
        WHEN 20 THEN 'Sucursal Santiago Centro'
        WHEN 30 THEN 'Sucursal Providencia'
        WHEN 40 THEN 'Sucursal Vitacura'
        ELSE 'Sin Sucursal'
    END AS "SUCURSAL",
    
    -- Columna 5 --
    '$' || TO_CHAR(ROUND(AVG(e.sueldo_emp)), 'FM999G999G999') AS "SUELDO_PROMEDIO"

FROM 
    empleado e

GROUP BY 
    e.id_categoria_emp,
    e.id_sucursal

HAVING 
    AVG(e.sueldo_emp) >= &SUELDO_PROMEDIO_MINIMO

ORDER BY 
    AVG(e.sueldo_emp) DESC;
    
-- Caso 3: Arriendo Promedio por Tipo de Propiedad

SELECT 
    -- Columna 1 --
    p.id_tipo_propiedad AS "CODIGO_TIPO",
    
    -- Columna 2 --
    CASE p.id_tipo_propiedad
        WHEN 'A' THEN 'CASA'
        WHEN 'B' THEN 'DEPARTAMENTO'
        WHEN 'C' THEN 'LOCAL'
        WHEN 'D' THEN 'PARCELA SIN CASA'
        WHEN 'E' THEN 'PARCELA CON CASA'
        ELSE 'Sin Tipo'
    END AS "DESCRIPCION_TIPO",
    
    -- Columna 3 --
    COUNT(p.nro_propiedad) AS "TOTAL_PROPIEDADES",
    
    -- Columna 4 --
    '$' || TO_CHAR(ROUND(AVG(p.valor_arriendo)), 'FM999G999G999') AS "PROMEDIO_ARRIENDO",
    
    -- Columna 5 --
    TO_CHAR(ROUND(AVG(p.superficie), 2), 'FM999G999G990D00') AS "PROMEDIO_SUPERFICIE",
    
    -- Columna 6 --
    '$' || TO_CHAR(ROUND(AVG(p.valor_arriendo) / AVG(p.superficie)), 'FM999G999G999') AS "VALOR_ARRIENDO_M2",
    
    -- Columna 7 --
    CASE
        WHEN ROUND(AVG(p.valor_arriendo) / AVG(p.superficie)) < 5000 THEN 'Economico'
        WHEN ROUND(AVG(p.valor_arriendo) / AVG(p.superficie)) BETWEEN 5000 AND 10000 THEN 'Medio'
        WHEN ROUND(AVG(p.valor_arriendo) / AVG(p.superficie)) > 10000 THEN 'Alto'
        ELSE 'Sin Clasificación'
    END AS "CLASIFICACION"

FROM 
    propiedad p

GROUP BY 
    p.id_tipo_propiedad

HAVING 
    ROUND(AVG(p.valor_arriendo) / AVG(p.superficie)) > 1000

ORDER BY 
    AVG(p.valor_arriendo) / AVG(p.superficie) DESC;