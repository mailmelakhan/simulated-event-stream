FROM xemuliam/dbt:bigquery
WORKDIR /usr/app

COPY transformations transformations/
WORKDIR /usr/app/transformations

RUN dbt deps

ENTRYPOINT ["dbt", "run", "--target", "dev"]