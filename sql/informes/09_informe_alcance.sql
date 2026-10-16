SELECT alcance, COUNT(*) AS ofertas
FROM analytics.ofertas_vigentes
WHERE categoria = 'data-science-analytics'
GROUP BY alcance
ORDER BY ofertas DESC;

SELECT pais, COUNT(*) AS ofertas
FROM analytics.ofertas_vigentes,
     jsonb_array_elements_text(paises) AS pais
WHERE categoria = 'data-science-analytics'
  AND alcance = 'Presencial o híbrido'
GROUP BY pais
ORDER BY ofertas DESC;