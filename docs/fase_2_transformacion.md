## Objetivo
Transformar los JSON crudos guardados en la fase 1 en una tabla que indique qué habilidades menciona cada oferta, para saber cuáles son las más pedidas.

## Capas
`raw_ofertas` → `stg_ofertas` → `ofertas_vigentes` → `ofertas_skills`

- `raw_ofertas` (tabla): los JSON tal cual llegan de la API. Una fila por oferta y por día de descarga.
- `stg_ofertas` (view): extrae del JSON las columnas útiles con nombre y tipo correctos, sin lógica de negocio.
- `ofertas_vigentes` (view): se queda con la última descarga de cada categoría y suma los nombres de seniority (`seniority_id`) y tipo de contrato (`modality_id`) usando `ref_seniorities` y `ref_modalities`.
- `ofertas_skills` (view): una fila por cada par (oferta, habilidad mencionada). Detecta las habilidades buscando los patrones de `ref_skills` en `description`, `functions` y `desirable`.

## Decisiones y por qué
- **Una foto por oferta y por día** (aunque haya valores repetidos): permite ver cómo cambia el mercado en el tiempo y detectar ofertas que se dan de baja. Si la clave fuera solo `job_id`, cada descarga pisaría la anterior y esa historia se perdería.
- **"Vigente" se calcula por categoría**: cada categoría se descarga por separado, y filtrar por la fecha más reciente de toda la tabla dejaría afuera las que no se descargaron ese día.
- **Las vistas no guardan datos**: se recalculan al consultarlas. Lo único que se acumula es `raw_ofertas`.
- **Tablas `ref_seniorities` y `ref_modalities`**: guardan el id y el nombre que da la API, y se cargan desde `ETL.py`.
- **Diccionario `ref_skills`**: una fila por habilidad con su patrón de búsqueda (expresión regular). Agregar o corregir una habilidad es cambiar una fila. Los patrones usan límites de palabra (`\y`) para que "SQL" no cuente dentro de "MySQL" ni "NoSQL".

## Problemas y cómo los resolví
- **Conteos inflados por fotos de días distintos.** Al ejecutar el script otro día se guardó una segunda foto de las mismas ofertas, y contar sobre `stg_ofertas` duplicaba cada oferta (542 filas en lugar de 432). Se resolvió con `ofertas_vigentes`, que se queda con la última descarga de cada categoría.
- **"PySpark" no se contaba como Spark.** El patrón `\yspark\y` exige un límite de palabra antes de "spark", y en "PySpark" no lo hay. Spark daba 11,3% frente al 15% de la medición hecha en Python. Con el patrón `\y(py)?spark\y` pasó a 15,1%.

## Resultados
Ofertas de `data-science-analytics` vigentes al 2026-10-14 (106 ofertas).

| Habilidad | Ofertas | % |
|---|---|---|
| SQL | 70 | 66,0 |
| Python | 66 | 62,3 |
| ETL/ELT | 37 | 34,9 |
| AWS | 33 | 31,1 |
| Power BI | 32 | 30,2 |
| Azure | 26 | 24,5 |
| Excel | 20 | 18,9 |
| GCP | 18 | 17,0 |
| Databricks | 18 | 17,0 |
| Spark | 16 | 15,1 |
| Airflow | 16 | 15,1 |
| Git | 15 | 14,2 |
| dbt | 14 | 13,2 |
| Tableau | 12 | 11,3 |
| BigQuery | 8 | 7,5 |
| Pandas | 8 | 7,5 |
| Snowflake | 5 | 4,7 |
| Docker | 4 | 3,8 |
| Kafka | 2 | 1,9 |

- SQL y Python aparecen en dos de cada tres ofertas.
- Entre las nubes, AWS (31%) lidera, seguida de Azure (25%) y GCP (17%).
- Databricks (17%) aparece más que Airflow (15%) y dbt (13%).
- El ranking coincide con la medición hecha al principio en Python (diferencias de 1-2 puntos), lo que da confianza en las consultas.

### Alcance geográfico
| Grupo | Ofertas |
|---|---|
| Presencial o híbrido | 66 |
| Remoto con residencia en un país | 32 |
| Remoto global | 8 |

Presenciales o híbridas por país (una oferta con varios países cuenta en cada uno):
Chile 62, México 6, Colombia 4, Perú 3.

## Límites
- Una sola fuente (Get on Board) y de toda Latinoamérica, no solo de Argentina.
- Es una foto del momento en que se corre el script, no un histórico completo de las ofertas.
- Se miden **menciones** en el texto, no si la habilidad es obligatoria o deseable.
- Con 106 ofertas, una oferta vale cerca de un punto: diferencias de uno o dos puntos no son significativas.
- La búsqueda por texto puede dar falsos positivos o negativos
- Todavía no se distingue qué ofertas puede tomar alguien que vive en Argentina.
- A las ofertas `remote_local` no se les puede asignar país: la API no lo informa en la oferta.
- "Remoto global" se basa en el texto de Get on Board para `fully_remote` ("puedes residir en cualquier parte del mundo"), verificado en una oferta.