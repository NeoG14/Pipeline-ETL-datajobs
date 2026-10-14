CREATE TABLE IF NOT EXISTS ref_seniorities (
    seniority_id INT PRIMARY KEY,
    nombre       TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS ref_modalities (
    modality_id INT PRIMARY KEY,
    nombre      TEXT NOT NULL
);