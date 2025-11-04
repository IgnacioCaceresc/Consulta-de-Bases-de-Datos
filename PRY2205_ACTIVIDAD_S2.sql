--Caso N° 1--

SELECT 
    numfactura AS "N° Factura",
    TO_CHAR(fecha, 'DD') || ' de ' || 
    CASE TO_CHAR(fecha, 'MM')
        WHEN '01' THEN 'Enero'
        WHEN '02' THEN 'Febrero'
        WHEN '03' THEN 'Marzo'
        WHEN '04' THEN 'Abril'
        WHEN '05' THEN 'Mayo'
        WHEN '06' THEN 'Junio'
        WHEN '07' THEN 'Julio'
        WHEN '08' THEN 'Agosto'
        WHEN '09' THEN 'Septiembre'
        WHEN '10' THEN 'Octubre'
        WHEN '11' THEN 'Noviembre'
        WHEN '12' THEN 'Diciembre'
    END || ' ' || EXTRACT(YEAR FROM fecha) AS "Fecha Emisión",
    LPAD(rutcliente, 10, '0') AS "RUT Cliente",
    TO_CHAR(neto, '$999,999') AS "Monto Neto",
    TO_CHAR(iva, '$999,999') AS "Monto Iva",
    TO_CHAR(total, '$999,999') AS "Total Factura",
    CASE 
        WHEN total <= 50000 THEN 'Bajo'
        WHEN total <= 100000 THEN 'Medio'
        ELSE 'Alto'
    END AS "Categoría Monto",
    CASE codpago
        WHEN 1 THEN 'EFECTIVO'
        WHEN 2 THEN 'TARJETA DEBITO'
        WHEN 3 THEN 'TARJETA CREDITO'
        ELSE 'CHEQUE'
    END AS "Forma de pago"
FROM factura
WHERE EXTRACT(YEAR FROM fecha) = EXTRACT(YEAR FROM SYSDATE) - 1
ORDER BY fecha DESC, neto DESC;

--Caso N°2--

SELECT 
    LPAD(rutcliente, 13, '*') AS "RUT",
    nombre AS "Cliente",
    NVL(TO_CHAR(telefono), 'Sin teléfono') AS "TELEFONO",
    NVL(TO_CHAR(codcomuna), 'Sin comuna') AS "COMUNA",
    estado AS "ESTADO",
    CASE 
        WHEN (saldo / credito) < 0.5 THEN 'Bueno ( ' || TO_CHAR(credito - saldo, '$9,999,999') || ')'
        WHEN (saldo / credito) BETWEEN 0.5 AND 0.8 THEN 'Regular ( ' || TO_CHAR(saldo, '$9,999,999') || ')'
        ELSE 'Critico'
    END AS "Estado Crédito",
    NVL(SUBSTR(mail, INSTR(mail, '@') + 1), 'Correo no registrado') AS "Dominio Correo"
FROM cliente
WHERE estado = 'A' 
  AND credito > 0
ORDER BY nombre ASC;

--Caso N°3--

DEFINE TIPOCAMBIO_DOLAR = 950
DEFINE UMBRAL_BAJO = 40
DEFINE UMBRAL_ALTO = 60

SELECT 
    codproducto AS "ID",
    INITCAP(descripcion) AS "Descripción de Producto",
    CASE 
        WHEN valorcompradolar IS NULL THEN 'Sin registro'
        ELSE TO_CHAR(valorcompradolar, '99.99') || ' USD'
    END AS "Compra en USD",
    CASE 
        WHEN valorcompradolar IS NULL THEN 'Sin registro'
        ELSE TO_CHAR(valorcompradolar * &TIPOCAMBIO_DOLAR, '$99,999') || ' PESOS'
    END AS "USD convertido",
    NVL(TO_CHAR(totalstock), 'Sin datos') AS "Stock",
    CASE 
        WHEN totalstock IS NULL THEN 'Sin datos'
        WHEN totalstock < &UMBRAL_BAJO THEN '¡ALERTA stock muy bajo!'
        WHEN totalstock >= &UMBRAL_BAJO AND totalstock <= &UMBRAL_ALTO THEN '¡Reabastecer pronto!'
        ELSE 'OK'
    END AS "Alerta Stock",
    CASE 
        WHEN totalstock > 80 THEN TO_CHAR(vunitario * 0.9, '$99,999')
        ELSE 'N/A'
    END AS "Precio Oferta"
FROM producto
WHERE UPPER(descripcion) LIKE '%ZAPATO%' 
  AND UPPER(procedencia) = 'I'
ORDER BY codproducto DESC;