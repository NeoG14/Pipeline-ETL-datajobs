WITH ofertas AS (
    SELECT * FROM {{ ref('stg_ofertas') }}
),

ultima_descarga AS (
    SELECT categoria, MAX(fecha_descarga) AS ultima_fecha
    FROM ofertas
    GROUP BY categoria
)

SELECT
    o.job_id,
    o.fecha_descarga,
    o.categoria,
    o.titulo,
    o.modalidad_remota,
    CASE
        WHEN o.modalidad_remota = 'fully_remote' THEN 'Remoto global'
        WHEN o.modalidad_remota = 'remote_local' THEN 'Remoto con residencia en un país'
        ELSE 'Presencial o híbrido'
    END AS alcance,
    o.salario_min,
    o.salario_max,
    o.fecha_publicacion,
    o.postulaciones,
    o.company_id,
    o.paises,
    o.url,
    s.nombre AS seniority,
    m.nombre AS tipo_contrato
FROM ofertas AS o
JOIN ultima_descarga AS u
  ON u.categoria = o.categoria
 AND u.ultima_fecha = o.fecha_descarga
LEFT JOIN {{ source('getonboard', 'ref_seniorities') }} AS s
  ON s.seniority_id = o.seniority_id
LEFT JOIN {{ source('getonboard', 'ref_modalities') }} AS m
  ON m.modality_id = o.modality_id