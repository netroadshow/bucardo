#!/bin/bash
set -Eeuxo pipefail

docker-compose build
docker-compose run --rm bucardo -p 'pg1:5432:*:postgres:test' -m 'pg1:test3' -c 'pg1:test>pg1:test3'
docker stop bucardo_pg1_1
docker rm bucardo_pg1_1
