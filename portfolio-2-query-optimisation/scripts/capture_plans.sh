#!/usr/bin/env sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
query_file="portfolio-2-query-optimisation/queries/001_business_queries.sql"

cd "$repo_root"
docker compose exec -T postgres \
    psql -X -v ON_ERROR_STOP=1 -U astermart_user -d astermart \
    < "$query_file"
