SELECT alcance, COUNT(*) AS ofertas
FROM ofertas_alcance
WHERE categoria = 'data-science-analytics'
GROUP BY alcance
ORDER BY ofertas DESC;

SELECT pais, COUNT(*) AS ofertas
FROM ofertas_alcance,
     jsonb_array_elements_text(paises) AS pais
WHERE categoria = 'data-science-analytics'
  AND alcance = 'Presencial o híbrido'
GROUP BY pais
ORDER BY ofertas DESC;