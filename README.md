# Habilidades más pedidas en ofertas de datos (Latinoamérica)

Recolectar y analizar las ofertas de trabajo en latinoamerica con respectos al campo de los datos (data analyst, data science, data engineer) y determinar cuales son las habilidades mas demandadas
(De momento solo se utiliza la API de Get On Board planeo agregar mas fuentes en el futuro)

## Resultado

Sobre 106 ofertas de la categoría `data-science-analytics` de Get on Board
(descargadas el 2026-10-14):

| Habilidad | % de ofertas que la mencionan |
|---|---|
| SQL | 66,0 |
| Python | 62,3 |
| ETL/ELT | 34,9 |
| AWS | 31,1 |
| Power BI | 30,2 |

Ranking completo y metodología en [docs/fase_2_transformacion.md](docs/fase_2_transformacion.md).

## Cómo funciona

`API de Get on Board` → `ETL.py` → `raw_ofertas` (JSON tal cual) → `stg_ofertas` → `ofertas_vigentes` → `ofertas_skills` → ranking

- **Extracción** (Python): [docs/fase_1_extraccion.md](docs/fase_1_extraccion.md)
- **Transformación** (SQL en PostgreSQL): [docs/fase_2_transformacion.md](docs/fase_2_transformacion.md)

## Cómo correrlo

Requisitos: Docker Desktop.
1. Copiar `.env.example` a `.env` y completar los valores.
2. Levantar todo: `docker compose up -d`
   - Crea la base `ofertas_db` con sus tablas y vistas (scripts de `sql/`).
   - Levanta Airflow en http://localhost:8080 (usuario y contraseña: `airflow`).
3. En Airflow, activar el DAG `ofertas_diarias`. Descarga las ofertas todos los días a las 15:00 (hora de Argentina).
4. Para ver los resultados, ejecutar las consultas de `sql/informes/`.

## Límites

- Una sola fuente (Get on Board), de toda Latinoamérica.
- Se miden menciones en el texto, no requisitos obligatorios.
- Con 106 ofertas, diferencias de uno o dos puntos son ruido.

## Qué sigue
- **Filtrar por trabajos desde Argentina:** distinguir qué ofertas puede tomar alguien que vive acá (por ejemplo, las completamente remotas).
- **Airflow:** programar la descarga diaria (`ETL.py`) y las transformaciones.
- **dbt:** pasar las vistas de `sql/` a modelos de dbt, con tests y documentación.
- **Docker:** empaquetar PostgreSQL y Airflow para correrlos con un solo comando.