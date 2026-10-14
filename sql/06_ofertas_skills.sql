DROP VIEW IF EXISTS ofertas_skills;

CREATE VIEW ofertas_skills AS
SELECT v.job_id, v.categoria, k.skill
FROM ofertas_vigentes AS v
JOIN raw_ofertas AS r
  ON r.job_id = v.job_id
 AND r.fecha_descarga = v.fecha_descarga
JOIN ref_skills AS k
  ON concat_ws(' ',
         r.payload->'attributes'->>'description',
         r.payload->'attributes'->>'functions',
         r.payload->'attributes'->>'desirable') ~* k.patron;