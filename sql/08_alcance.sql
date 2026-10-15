DROP VIEW IF EXISTS ofertas_alcance;

CREATE VIEW ofertas_alcance AS
SELECT
    v.*,
    CASE
        WHEN v.modalidad_remota = 'fully_remote' THEN 'Remoto global'
        WHEN v.modalidad_remota = 'remote_local' THEN 'Remoto con residencia en un país'
        ELSE 'Presencial o híbrido'
    END AS alcance
FROM ofertas_vigentes AS v;