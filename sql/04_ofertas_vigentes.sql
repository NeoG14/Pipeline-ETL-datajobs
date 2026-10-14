DROP VIEW IF EXISTS ofertas_vigentes;

CREATE VIEW ofertas_vigentes AS
SELECT
    s.job_id,
    s.fecha_descarga,
    s.categoria,
    s.titulo,
    s.modalidad_remota,
    s.salario_min,
    s.salario_max,
    s.fecha_publicacion,
    s.postulaciones,
    s.company_id,
    s.paises,
    s.url,
    se.nombre AS seniority,
    tc.nombre AS tipo_contrato
FROM stg_ofertas AS s
JOIN (
    SELECT categoria, MAX(fecha_descarga) AS ultima_fecha
    FROM stg_ofertas
    GROUP BY categoria
) AS u ON u.categoria = s.categoria AND u.ultima_fecha = s.fecha_descarga
LEFT JOIN ref_seniorities AS se ON se.seniority_id = s.seniority_id
LEFT JOIN ref_modalities  AS tc ON tc.modality_id  = s.modality_id;