SELECT
    v.job_id,
    pais
FROM {{ ref('ofertas_vigentes') }} AS v,
     jsonb_array_elements_text(v.paises) AS pais
WHERE pais <> 'Remote'