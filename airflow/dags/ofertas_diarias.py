from datetime import timedelta

import pendulum
from airflow.sdk import DAG
from airflow.providers.standard.operators.bash import BashOperator

with DAG(
    dag_id="ofertas_diarias",
    schedule="0 15 * * *",
    start_date=pendulum.datetime(2026, 10, 15, tz="America/Argentina/Buenos_Aires"),
    catchup=False,
    default_args={"retries": 2, "retry_delay": timedelta(minutes=5)},
    tags=["ofertas"],
) as dag:
    datos = BashOperator(
        task_id="descargar_datos",
        bash_command="python /opt/airflow/proyecto/ETL.py data-science-analytics",
    )
    programacion = BashOperator(
        task_id="descargar_programming",
        bash_command="python /opt/airflow/proyecto/ETL.py programming",
    )

    datos >> programacion