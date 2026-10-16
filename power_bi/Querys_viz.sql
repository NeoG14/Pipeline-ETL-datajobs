SELECT COUNT(*) AS filas, COUNT(DISTINCT job_id) as ofertas
FROM analytics.ofertas_vigentes;

SELECT COUNT(*) AS filas, COUNT(DISTINCT job_id) as ofertas
FROM analytics.ofertas_skills;

-- Contar cuantos paises aparecen por cantidad de ofertas
SELECT jsonb_array_length(paises) AS cantidad_paises,
COUNT(*) AS ofertas
FROM analytics.ofertas_vigentes
GROUP BY 1
ORDER BY 1;


SELECT COUNT(*)
FROM analytics.ofertas_vigentes AS v,
     jsonb_array_elements_text(v.paises) AS pais;

--contar paises y la etiqueta remote
SELECT pais, COUNT(*) AS filas
FROM analytics.ofertas_vigentes AS v,
     jsonb_array_elements_text(v.paises) AS pais
GROUP BY pais
ORDER BY filas DESC;

--comprobar si no aparece remote junto a otro pais y contar
SELECT jsonb_array_length(paises) AS cantidad_paises, COUNT(*) AS ofertas
FROM analytics.ofertas_vigentes
WHERE paises @> '["Remote"]'
GROUP BY cantidad_paises;

--contar cuantas quedan que no sean remote
SELECT v.alcance, COUNT(*) AS filas
FROM analytics.ofertas_vigentes AS v,
     jsonb_array_elements_text(v.paises) AS pais
WHERE pais <> 'Remote'
GROUP BY v.alcance;

-- ver todas las ofertas no remote
SELECT
    v.job_id,
    pais
FROM analytics.ofertas_vigentes AS v,
     jsonb_array_elements_text(v.paises) AS pais
WHERE pais <> 'Remote'