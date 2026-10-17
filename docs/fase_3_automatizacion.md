# Fase 3: Automatización con Docker y Airflow

## Objetivo

Que el pipeline corra **todos los días sin intervención manual**: descargar las ofertas de Get on Board, guardarlas en PostgreSQL y transformarlas, a una hora fija y con reintentos si algo falla.

Hasta la fase 2, todo se corría a mano desde la terminal y la base de datos estaba instalada directamente en Windows. En esta fase todo pasa a correr en **contenedores Docker**, orquestados por **Apache Airflow**.

## Arquitectura

```
                    docker compose
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  airflow-scheduler ──► ejecuta el DAG a las 15:00 (ARG)     │
│        │                                                    │
│        ├─► ETL.py data-science-analytics ─┐                 │
│        ├─► ETL.py programming ────────────┼─► postgres      │
│        └─► dbt build ─────────────────────┘   (pg-ofertas)  │
│                                                  │          │
│  airflow-apiserver (UI en :8080)                 │          │
│  airflow-dag-processor                           │          │
│  airflow-db (metadatos de Airflow)               │          │
└──────────────────────────────────────────────────┼──────────┘
                                                   │ :5433
                                          pgAdmin / Power BI
```

| Servicio | Imagen | Para qué |
|---|---|---|
| `postgres` (`pg-ofertas`) | `postgres:18` | La base de datos del proyecto (`ofertas_db`) |
| `airflow-db` | `postgres:18` | Base interna de Airflow (estado de DAGs, ejecuciones). Separada de los datos del proyecto |
| `airflow-apiserver` | imagen propia | Interfaz web en `localhost:8080` |
| `airflow-scheduler` | imagen propia | Decide cuándo corre cada tarea y la ejecuta |
| `airflow-dag-processor` | imagen propia | Lee los archivos de `airflow/dags/` |
| `airflow-init` | imagen propia | Corre una sola vez: migra la base de Airflow y crea el usuario |

## Archivos de esta fase

| Archivo | Contenido |
|---|---|
| `docker-compose.yml` | Definición de todos los servicios, volúmenes y variables |
| `Dockerfile` | Imagen propia basada en `apache/airflow:3.3.2`, con `python-dotenv` y dbt |
| `.dockerignore` | Excluye `.venv/`, `.git/`, logs y `dbt_ofertas/target/` de la imagen |
| `airflow/dags/ofertas_diarias.py` | El DAG con las tres tareas |
| `airflow/dbt_profiles/profiles.yml` | Perfil de dbt para correr dentro del contenedor |
| `sql/01_raw_ofertas.sql`, `sql/03_ref_tables.sql` | Scripts de creación de tablas, que Postgres ejecuta al iniciar con un volumen vacío |
| `.env.example` | Plantilla de variables (el `.env` real no se sube al repo) |

## El DAG `ofertas_diarias`

```
descargar_datos  >>  descargar_programming  >>  dbt_build
```

- **Horario:** `0 15 * * *`, todos los días a las 15:00 hora de Argentina.
- **`catchup=False`:** si la PC estuvo apagada varios días, no intenta recuperar las ejecuciones perdidas. Las ofertas son una foto del momento: no se puede descargar "la foto de ayer".
- **Reintentos:** 2, con 5 minutos de espera. Cubre caídas momentáneas de la API o de la red.
- **Tareas en serie:** primero las dos descargas y después dbt, que necesita que los datos nuevos ya estén cargados.

Las tareas son `BashOperator` que llaman a los mismos comandos que se usaban a mano. El código del ETL no cambió para correr en Airflow.

## Decisiones

**Imagen propia en vez de la oficial.** La imagen oficial de Airflow no trae `python-dotenv` ni dbt. El `Dockerfile` los agrega.

**dbt en un entorno virtual separado** (`/home/airflow/dbt_venv`). Airflow y dbt tienen muchas dependencias en común con versiones distintas. Instalarlos juntos puede romper alguno de los dos. Por eso el DAG llama a dbt con su ruta completa: `/home/airflow/dbt_venv/bin/dbt`.

**LocalExecutor.** Las tareas corren dentro del mismo contenedor del scheduler. La configuración oficial usa CeleryExecutor con Redis y workers, pensada para repartir trabajo entre varias máquinas. Para tres tareas diarias en una PC es complejidad innecesaria.

**Sin triggerer.** Ese servicio solo hace falta para tareas "diferibles", y este DAG no tiene ninguna. Por eso la UI muestra el triggerer en rojo: es esperado.

**Proyecto montado como solo lectura.** La carpeta del proyecto se monta en `/opt/airflow/proyecto:ro`. Airflow puede leer el ETL y los modelos de dbt, pero no modificarlos. Como consecuencia, dbt escribe sus archivos temporales en `/tmp` (`DBT_TARGET_PATH`, `DBT_LOG_PATH`).

**Dos formas de llegar a Postgres.**

| Desde | Host | Puerto |
|---|---|---|
| La PC (pgAdmin, Power BI, dbt local) | `localhost` | `5433` |
| Otro contenedor (Airflow) | `postgres` | `5432` |

Dentro de la red de Docker, los contenedores se encuentran por el **nombre del servicio**. El compose sobrescribe `DB_HOST` y `DB_PORT` para los contenedores de Airflow, así el mismo `ETL.py` funciona en los dos lados. Se usa el 5433 en la PC para no chocar con el Postgres instalado en Windows.

**Zona horaria.** Postgres arranca con `timezone=America/Argentina/Buenos_Aires`. Sin eso, la fecha de descarga se calculaba en UTC y una corrida a las 21:00 de Argentina quedaba registrada con la fecha del día siguiente.

**Arranque automático.** Todos los servicios tienen `restart: always`. Con Docker Desktop configurado para iniciar con Windows, el pipeline vuelve a estar activo al prender la PC, sin correr ningún comando.

## Tablas de referencia

Se agregó al ETL la función `cargar_referencia()`, que descarga los endpoints `/seniorities` y `/modalities` de la API y los guarda en `ref_seniorities` y `ref_modalities` con un upsert (`ON CONFLICT DO UPDATE`). Así los nombres ("Semi Senior", "Full time") vienen de la fuente y no están escritos a mano.

## Problemas encontrados

| Problema | Causa | Solución |
|---|---|---|
| El contenedor de Postgres terminaba con `Exited (1)` | El volumen tenía datos de Postgres 17, y la 18 usa otra ruta (`/var/lib/postgresql`) | Recrear el volumen y montarlo en la ruta nueva |
| Los scripts de `sql/` no se ejecutaban | Postgres solo los corre si el volumen está **vacío**, y además ignora subcarpetas | Recrear el volumen. Los informes quedaron en `sql/informes/` |
| `volumes must be a mapping` | Indentación incorrecta en el YAML | Reescribir el bloque con la indentación correcta |
| Ofertas con fecha del día siguiente | Postgres corría en UTC | Configurar la zona horaria y volver a cargar ese día |

## Cómo correrlo

```powershell
docker compose up -d     # levanta todo (la primera vez construye la imagen)
docker compose ps        # estado de los servicios
```

Interfaz de Airflow: `http://localhost:8080`. El DAG se crea pausado y hay que activarlo una vez.

> **Nunca usar `docker compose down -v`**: la `-v` borra los volúmenes, y con ellos todas las ofertas descargadas, que no se pueden volver a obtener. Para apagar todo alcanza con `docker compose down`.
