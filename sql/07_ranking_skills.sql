SELECT
    skill,
    COUNT(*) AS ofertas,
    ROUND(100.0 * COUNT(*) / (
        SELECT COUNT(*)
        FROM ofertas_vigentes
        WHERE categoria = 'data-science-analytics'
    ), 1) AS porcentaje
FROM ofertas_skills
WHERE categoria = 'data-science-analytics'
GROUP BY skill
ORDER BY ofertas DESC;