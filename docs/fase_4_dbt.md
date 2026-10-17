# Fase 4: Modelado con dbt

## Objetivo

Reemplazar las vistas SQL sueltas de la fase 2 por un proyecto **dbt**: transformaciones versionadas, con dependencias explícitas, tests automáticos y documentación generada.

## Por qué dbt

En la fase 2, las transformaciones eran archivos `.sql` que creaban vistas en el esquema `public`. Funcionaba, pero:

- El orden de ejecución dependía de correr los archivos en el orden correcto a mano.
- No había forma automática de comprobar que los datos cumplieran lo esperado (por ejemplo, que `job_id` no se repita).
- Agregar otra fuente de datos implicaba más archivos sueltos, sin estructura.

dbt resuelve las tres cosas: cada modelo declara de qué depende con `ref()` y `source()`, dbt calcula el orden solo, y los tests corren en cada ejecución.

## Versiones

- `dbt-core 1.12.6` + `dbt-postgres 1.11.0`.
- dbt v2 (el motor nuevo en Rust) todavía no soporta PostgreSQL, por eso se usa dbt Core.

## Estructura

```
dbt_ofertas/
├── dbt_project.yml
├── seeds/
│   └── ref_skills.csv          # 19 habilidades con su patrón regex
└── models/
    ├── staging/
    │   ├── _sources.yml        # tablas crudas que carga el ETL
    │   ├── _staging.yml        # tests de staging
    │   └── stg_ofertas.sql     # vista: columnas tipadas desde el JSON
    └── marts/
        ├── _marts.yml          # tests y descripciones
        ├── ofertas_vigentes.sql
        ├── ofertas_skills.sql
        └── ofertas_paises.sql
```

## Linaje

```
raw_ofertas ──► stg_ofertas ──► ofertas_vigentes ──┬──► ofertas_skills ◄── ref_skills (seed)
                                     ▲              └──► ofertas_paises
ref_seniorities ─────────────────────┤
ref_modalities ──────────────────────┘
```

## Capas

| Capa | Materialización | Esquema | Por qué |
|---|---|---|---|
| Sources | (tablas del ETL) | `public` | Datos crudos. dbt no los toca, solo los lee |
| Staging | vista | `analytics` | Solo renombra y tipa columnas. Una vista no ocupa espacio y siempre está al día |
| Marts | tabla | `analytics` | Lo que consumen Power BI y los informes. Una tabla se lee rápido |

## Modelos

### `stg_ofertas`
Extrae del JSON crudo las columnas que se usan (título, categoría, modalidad remota, salarios, seniority, tipo de contrato, países, textos de la oferta) con su tipo correcto.

### `ofertas_vigentes`
**Grano: una fila por oferta.** Como el ETL guarda una foto por día, la misma oferta aparece muchas veces. Este modelo se queda con la **última fecha de descarga de cada categoría**, que es el estado actual del mercado.

Agrega:
- `alcance`: "Remoto global", "Remoto con residencia en un país" o "Presencial o híbrido", a partir de `modalidad_remota`.
- `seniority` y `tipo_contrato`: nombres traídos de las tablas de referencia.
- `seniority_orden`: el id numérico del seniority, para que Power BI ordene Junior → Expert y no alfabéticamente.

### `ofertas_skills`
**Grano: oferta × habilidad.** Une cada oferta vigente con las habilidades cuyo patrón regex aparece en el título, la descripción, las funciones o los deseables. Los patrones usan `\y` (límite de palabra) para no contar "R" dentro de otras palabras, y `\y(py)?spark\y` cuenta también PySpark.

### `ofertas_paises`
**Grano: oferta × país.** Abre el array JSON de países con `jsonb_array_elements_text` y excluye el valor `'Remote'`, que no es un país. En la práctica, todas sus filas son ofertas presenciales o híbridas.

## Tests (14)

| Modelo | Tests |
|---|---|
| `stg_ofertas` | `job_id` y `fecha_descarga` no nulos; `modalidad_remota` con valores aceptados; `seniority_id` y `modality_id` existen en sus tablas de referencia |
| `ofertas_vigentes` | `job_id` único y no nulo; `alcance` con valores aceptados; `seniority` no nulo |
| `ofertas_skills` | `skill` no nulo y existente en `ref_skills` |
| `ofertas_paises` | `job_id` no nulo y existente en `ofertas_vigentes`; `pais` no nulo |

**Criterio:** los tests protegen **reglas que siempre tienen que cumplirse** (invariantes). Por ejemplo, no hay test de valores aceptados para `pais`: la API puede sumar países nuevos en cualquier momento, y eso no es un error.

## Dos perfiles de conexión

| Dónde corre dbt | Perfil | Conexión |
|---|---|---|
| En la PC | `~/.dbt/profiles.yml` (fuera del repo) | `localhost:5433` |
| En Airflow | `airflow/dbt_profiles/profiles.yml` (en el repo) | `postgres:5432`, todo leído con `env_var()` |

El perfil del repo no tiene ninguna contraseña escrita: la lee de las variables de entorno que vienen del `.env`.

## Migración desde la fase 2

1. Se construyeron los modelos dbt al lado de las vistas viejas.
2. Se compararon los resultados (por ejemplo, 971 filas en la vista vieja y 971 en dbt, y la misma distribución de alcance).
3. Con los números coincidiendo, se borraron las vistas viejas de `public` y sus archivos `.sql`. Los informes de `sql/informes/` ahora leen de `analytics`.

## Comandos

```powershell
dbt debug          # prueba la conexión
dbt build          # seeds + modelos + tests, en orden
dbt docs generate  # genera la documentación
dbt docs serve     # la abre en el navegador
```

En producción, Airflow corre `dbt build` todos los días después de las descargas (ver fase 3).
