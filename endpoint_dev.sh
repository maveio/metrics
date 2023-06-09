#!/bin/bash

source .envrc

# Wait until Postgres is ready
while ! pg_isready -q -h $PGHOST -p $PGPORT -U $PGUSER
do
  echo "$(date) - waiting for database to start"
  sleep 2
done

# Create, migrate, and seed database if it doesn't exist.
if [[ -z `psql -Atqc "\\list $PGDATABASE"` ]]; then
  echo "Database $PGDATABASE does not exist. Creating..."
  createdb -E UTF8 $PGDATABASE -l en_US.UTF-8 -T template0
  mix ecto.create
  mix ecto.migrate
  echo "Database $PGDATABASE created."
else
  echo "Database $PGDATABASE already exists. Doing nothing."
fi

mix deps.get
mix assets.deploy
echo y | mix ua_inspector.download
mix run priv/repo/seeds.exs
mix phx.server
