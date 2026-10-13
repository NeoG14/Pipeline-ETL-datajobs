import requests
import argparse
import time
import os
import psycopg2
from psycopg2.extras import Json, execute_values
from dotenv import load_dotenv


ENDPOINT = "https://www.getonbrd.com/api/v0"
load_dotenv()

def extraer_ofertas(categoria):
    todas = []
    pagina = 1
    total_paginas = 1          # por ahora suponemos 1; se corrige con la primera respuesta

    while pagina <= total_paginas:
        try:
            response = requests.get(
                f"{ENDPOINT}/categories/{categoria}/jobs",
                params={"page": pagina, "per_page": 120},
                timeout=30,
            )
            response.raise_for_status()
            resultado = response.json()
        except requests.exceptions.RequestException as e:
            print(f"Error en la página {pagina}: {e}")
            return None

        meta = resultado["meta"]
        if meta["page"] != pagina:
            print(f"Pedí la página {pagina} pero llegó la {meta['page']}. Corto para no duplicar.")
            return None

        todas.extend(resultado["data"])
        total_paginas = meta["total_pages"]
        print(f"Página {pagina}/{total_paginas}: {len(resultado['data'])} ofertas")
        pagina += 1
        time.sleep(1)          # pausa de 1 segundo para no saturar la API

    ids = {ofer["id"] for ofer in todas}
    print(f"Total: {len(todas)} ofertas, {len(ids)} ids únicos")
    return todas

def conectar():
    return psycopg2.connect(
        host=os.environ.get("DB_HOST"),
        dbname=os.environ.get("DB_NAME"),
        user=os.environ.get("DB_USER"),
        password=os.environ["DB_PASSWORD"],
    )


def guardar_ofertas(ofertas, categoria):
    # un diccionario no admite claves repetidas: si un id viniera dos veces, queda una sola
    unicas = {o["id"]: o for o in ofertas}.values()
    filas = [(o["id"], categoria, Json(o)) for o in unicas]

    conn = conectar()
    try:
        with conn:
            with conn.cursor() as cur:
                execute_values(
                    cur,
                    """
                    INSERT INTO raw_ofertas (job_id, categoria, payload)
                    VALUES %s
                    ON CONFLICT (job_id, fecha_descarga)
                    DO UPDATE SET payload = EXCLUDED.payload,
                                  categoria = EXCLUDED.categoria
                    """,
                    filas,
                )
    finally:
        conn.close()
    print(f"Guardadas {len(filas)} ofertas en raw_ofertas")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Descarga ofertas de Get on Board")
    parser.add_argument("categoria", help="slug de la categoría, ej: data-science-analytics")
    args = parser.parse_args()

    ofertas = extraer_ofertas(args.categoria)
    if ofertas is None:
        print("No se pudo descargar nada")
    else:
        guardar_ofertas(ofertas, args.categoria)