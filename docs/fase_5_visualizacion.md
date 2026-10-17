# Fase 5: Visualización con Power BI

## Objetivo

Un tablero que responda, a simple vista, **qué piden las ofertas de datos en Latinoamérica**, construido sobre las tablas de `analytics` que genera dbt.

Archivos en `power_bi/`:

| Archivo | Contenido |
|---|---|
| `Ofertas.pbix` | El tablero |
| `Dashboard.png` | Captura para el README |
| `Preguntas.md` | Las preguntas que guían el tablero |
| `Querys_viz.sql` | Consultas SQL usadas para validar cada gráfico |

## Primero las preguntas, después los gráficos

Cada gráfico existe porque responde una pregunta concreta de alguien que busca trabajo en datos:

| Pregunta | Gráfico | Medida |
|---|---|---|
| ¿Qué habilidades piden? | Barras horizontales | % de ofertas que mencionan cada habilidad |
| ¿Qué seniority piden? | Columnas | % de las ofertas |
| ¿Se puede trabajar en remoto? | Barras horizontales | % de las ofertas |
| ¿Dónde están las ofertas presenciales o híbridas? | Barras horizontales | Cantidad de ofertas |

Arriba hay tres tarjetas: **ofertas vigentes**, **% remotas desde cualquier país** y **fecha de los datos**. Un segmentador permite elegir el área (`data-science-analytics` o `programming`).

## Conexión

- Conector **PostgreSQL**, `localhost:5433`, base `ofertas_db`.
- Modo **Import**: Power BI copia los datos dentro del `.pbix`. Es más rápido y permite todo el DAX. DirectQuery consultaría la base en cada clic, y con este volumen de datos no hace falta.
- Tablas importadas, con nombres para el informe:

| Tabla en Power BI | Modelo dbt | Grano |
|---|---|---|
| `Ofertas` | `ofertas_vigentes` | 1 fila por oferta |
| `Habilidades` | `ofertas_skills` | oferta × habilidad |
| `Paises` | `ofertas_paises` | oferta × país |

## Modelo

```
                 ┌──────────────┐
                 │   Ofertas    │
                 │  (job_id)    │
                 └──────────────┘
       1 ↓↑ *                      1 ↓ *
┌──────────────┐            ┌──────────────┐
│ Habilidades  │            │    Paises    │
└──────────────┘            └──────────────┘
```

- `Ofertas` → `Paises`: uno a varios, **dirección simple**.
- `Ofertas` ↔ `Habilidades`: uno a varios, **bidireccional**. Así, al hacer clic en una habilidad (por ejemplo Python), el resto del tablero se filtra a las ofertas que la piden.
- `Habilidades` y `Paises` no se relacionan entre sí: se conectan solo a través de `Ofertas`.

**El problema de la bidireccional.** Con la relación en ambas direcciones, el filtro de cada barra del gráfico de habilidades (`skill = "SQL"`) viaja hacia `Ofertas`. El total de ofertas pasa a ser solo las que piden SQL, y todas las barras dan 100 %. Se resuelve quitando el filtro de la columna `Habilidades[skill]` en el denominador, con `REMOVEFILTERS` (ver medidas).

**Cuidado: columna, no tabla.** Una primera versión usaba `REMOVEFILTERS(Habilidades)`, sobre la tabla entera. En DAX, una tabla del lado "varios" incluye, a través de la relación, las columnas de la tabla del lado "uno" (la *tabla expandida*). Quitar los filtros de `Habilidades` quitaba también los de `Ofertas`, incluido el segmentador de área: el denominador pasaba de 115 a 434 y SQL caía de 66,1 % a 17,5 %. Quitando el filtro solo de la columna `skill`, el resto de los filtros se respeta.

## Medidas (DAX)

```dax
Total ofertas = COUNTROWS(Ofertas)

Ofertas con habilidad = DISTINCTCOUNT(Habilidades[job_id])

% de ofertas =
DIVIDE(
    [Ofertas con habilidad],
    CALCULATE([Total ofertas], REMOVEFILTERS(Habilidades[skill]))
)

% del Total =
DIVIDE([Total ofertas], CALCULATE([Total ofertas], ALLSELECTED(Ofertas)))

Ofertas por pais = DISTINCTCOUNT(Paises[job_id])

% remoto global =
DIVIDE(
    CALCULATE([Total ofertas], Ofertas[alcance] = "Remoto global"),
    [Total ofertas]
)

Datos al = MAX(Ofertas[fecha_descarga])
```

- **`DISTINCTCOUNT` en vez de `COUNTROWS`** en las tablas de detalle: una oferta tiene varias filas en `Habilidades` o en `Paises`, pero tiene que contarse una vez.
- **`ALLSELECTED`** en `% del Total`: quita los filtros del propio gráfico (cada barra) pero respeta los de afuera (segmentador, clics en otros gráficos). Por eso los porcentajes siempre suman 100 % dentro de la selección.
- Medidas y no columnas calculadas: se recalculan según el contexto de filtro.

## Decisiones de diseño

- **Títulos como preguntas** y subtítulos que dicen qué se mide. "Mencionan" en vez de "requieren": la habilidad aparece en el texto, pero no sabemos si es obligatoria o deseable.
- **Porcentajes en vez de conteos**, para comparar entre áreas con distinta cantidad de ofertas. La excepción es países: una oferta puede listar varios, así que los porcentajes no sumarían 100 %. Por eso ese gráfico usa conteos y lo aclara en el subtítulo.
- **Barras en vez de tortas o mapas.** Las longitudes se comparan con más precisión que los ángulos o las áreas. Con 4 países, un mapa ocupa mucho espacio y transmite poco.
- **Seniority en orden natural** (Junior → Expert), con *Ordenar por columna* usando `seniority_orden`. Es una variable ordinal: ordenarla alfabéticamente rompería su significado.
- **Sin ejes ni cuadrícula** donde las barras tienen etiqueta: el mismo dato aparecía dos veces.
- **Conteos en el tooltip.** Con 115 ofertas, un 2,6 % son 3 ofertas. Ver el conteo ayuda a juzgar qué tan sólido es cada porcentaje.
- **Filtrado cruzado** en lugar del resaltado que trae Power BI por defecto. El resaltado está pensado para mostrar una parte de un total, y con porcentajes no tiene sentido.
- **Un solo color**: todas las barras representan lo mismo (ofertas), así que el color no tiene que distinguir nada.

## Validación

Cada gráfico se comparó contra una consulta SQL sobre `analytics` (ver `Querys_viz.sql`) antes de darlo por bueno. Además, se hicieron controles de consistencia dentro del propio tablero. Ejemplos con los datos del 16/10/2026, área `data-science-analytics` (115 ofertas):

| Control | Resultado |
|---|---|
| La tarjeta de remoto global coincide con la barra "Remoto global" | 7,0 % en ambas |
| El gráfico de alcance suma 100 % | 62,6 + 30,4 + 7,0 |
| El seniority suma 100 % (salvo redondeo) | 7,8 + 47,8 + 40,0 + 4,3 = 99,9 |
| El tooltip de Kafka coincide con su porcentaje | 2,6 % × 115 ≈ 3 ofertas |
| Los países suman más que las ofertas presenciales | 84 contra ~72: hay ofertas con varios países |

Los filtros cruzados se probaron con la misma lógica: al elegir un valor, la tarjeta de ofertas vigentes tiene que coincidir con el porcentaje de esa barra por 115.

## Lo que se descartó

**Rango salarial por seniority.** Solo el 37 % de las ofertas informa salario, la API no indica la moneda, algunos grupos tenían 2 o 3 ofertas y había valores claramente anómalos (un mínimo de 100). Un gráfico con esos datos transmitiría más precisión de la que hay.

## Limitaciones

- **Actualización manual.** En modo Import, el `.pbix` muestra los datos de la última vez que se tocó *Actualizar*, aunque el pipeline corra todos los días. La tarjeta "Datos al" indica de qué día es la foto.
- **Habilidades por texto.** Se detectan con expresiones regulares sobre el texto de la oferta. Una habilidad mencionada como "deseable" cuenta igual que una obligatoria.
- **Muestras chicas.** Con un centenar de ofertas por área, las habilidades poco frecuentes pueden variar bastante de un día a otro.
- **"Remoto con residencia en un país"**: la API no indica en qué país hay que residir.

## Cómo actualizar el tablero

1. Verificar que el pipeline haya corrido (Airflow, `localhost:8080`).
2. Abrir `power_bi/Ofertas.pbix`.
3. **Inicio → Actualizar.**
