CREATE TABLE IF NOT EXISTS raw_ofertas (
    job_id          TEXT   NOT NULL,                       -- id de la oferta (es un slug de texto)
    fecha_descarga  DATE   NOT NULL DEFAULT CURRENT_DATE,  -- día en que se descargó
    categoria       TEXT   NOT NULL,                       -- categoría consultada en la API
    payload         JSONB  NOT NULL,                       -- la oferta completa en JSON, sin transformar
    PRIMARY KEY (job_id, fecha_descarga)                   -- evita duplicados dentro del mismo día
);