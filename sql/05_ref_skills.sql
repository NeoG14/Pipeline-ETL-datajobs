CREATE TABLE IF NOT EXISTS ref_skills (
    skill  TEXT PRIMARY KEY,
    patron TEXT NOT NULL
);

INSERT INTO ref_skills (skill, patron) VALUES
    ('SQL',        '\ysql\y'),
    ('Python',     '\ypython\y'),
    ('ETL/ELT',    '\y(etl|elt)\y'),
    ('Power BI',   '\ypower ?bi\y'),
    ('AWS',        '\yaws\y'),
    ('Azure',      '\yazure\y'),
    ('Airflow',    '\yairflow\y'),
    ('dbt',        '\ydbt\y'),
    ('Spark',      '\y(py)?spark\y'),
    ('Excel',      '\yexcel\y'),
    ('Tableau',    '\ytableau\y'),
    ('Git',        '\ygit\y'),
    ('Docker',     '\ydocker\y'),
    ('Databricks', '\ydatabricks\y'),
    ('GCP',        '\y(gcp|google cloud)\y'),
    ('BigQuery',   '\ybig ?query\y'),
    ('Snowflake',  '\ysnowflake\y'),
    ('Pandas',     '\ypandas\y'),
    ('Kafka',      '\ykafka\y')
ON CONFLICT (skill) DO UPDATE SET patron = EXCLUDED.patron;