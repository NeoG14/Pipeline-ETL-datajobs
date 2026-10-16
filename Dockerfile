FROM apache/airflow:3.3.2

RUN pip install --no-cache-dir python-dotenv

RUN python -m venv /home/airflow/dbt_venv \
 && /home/airflow/dbt_venv/bin/pip install --no-cache-dir dbt-core==1.12.6 dbt-postgres==1.11.0