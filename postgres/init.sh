#!/bin/bash

set -e

cd "/home/sql"

export PGPASSWORD=$POSTGRES_PASSWORD;

psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f "deploy.sql" -W