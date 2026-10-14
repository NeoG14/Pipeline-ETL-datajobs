# Fase 1 · Extracción

## Objetivo
Descargar las ofertas de trabajo de la API pública de Get on Board y guardarlas sin
modificar en PostgreSQL, para analizar después qué habilidades más demandadas.

## Qué hice y por qué
- Consulto con `requests` la ruta `/categories/{categoria}/jobs`. Probé con
  `data-science-analytics` (110 ofertas) y `programming` (326).
- El script recibe la categoría por línea de comandos con `argparse`.
- Guardo cada oferta completa como JSON (`JSONB`) en la tabla `raw_ofertas`, sin
  transformar. Así puedo reprocesar los datos sin volver a descargarlos, y si la API
  cambia su formato no pierdo información.
- La contraseña de la base está en un archivo `.env` que no se sube a Git.

## Problemas y cómo los resolví
- **Paginación:** la ruta de la categoría no documenta el parámetro `page`, pero la API
  lo respeta. El script pide páginas hasta `meta["total_pages"]` y verifica que
  `meta["page"]` coincida con la pedida; si no, corta para no guardar repetidas.
- **Ids de texto:** el id de cada oferta es un slug, no un número. La clave primaria
  es `(job_id, fecha_descarga)`.
- **Duplicados:** con esa clave y `INSERT ... ON CONFLICT DO UPDATE`, correr el script
  dos veces el mismo día no repite filas, y cada día queda una foto nueva.
- **Errores de red:** `timeout` y `try/except` con `raise_for_status()`.

## Cómo verificarlo
(los comandos: correr el script (pasandole la categoria a descargar) y el SELECT COUNT(*) antes y después de una segunda corrida)

## Qué encontré en los datos
- 436 ofertas en total. Solo 4 mencionan Argentina como país.
- `Remote` como país no implica que esté abierta a cualquiera: hay ofertas
  `remote_local` listadas como `Remote`.
- Modalidad: hybrid 185, remote_local 138, fully_remote 80, no_remote 33.
- Hipótesis a verificar: `fully_remote` sería la modalidad abierta a candidatos de Argentina.

## Límites
- Una sola fuente, de toda Latinoamérica.
- Solo se descargan las ofertas publicadas al momento de correr el script.