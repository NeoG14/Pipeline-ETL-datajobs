WITH vigentes AS (
    SELECT job_id, fecha_descarga, categoria, alcance, seniority
    FROM {{ ref('ofertas_vigentes') }}
),

textos AS (
    SELECT
        job_id,
        fecha_descarga,
        concat_ws(' ', descripcion, funciones, deseables) AS texto
    FROM {{ ref('stg_ofertas') }}
)

SELECT
    v.job_id,
    v.fecha_descarga,
    v.categoria,
    v.alcance,
    v.seniority,
    k.skill
FROM vigentes AS v
JOIN textos AS t
  ON t.job_id = v.job_id
 AND t.fecha_descarga = v.fecha_descarga
JOIN {{ ref('ref_skills') }} AS k
  ON t.texto ~* k.patron