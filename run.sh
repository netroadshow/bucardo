#!/bin/bash
set -Eeuxo pipefail

docker-compose build

docker-compose run --rm bucardo \
    -p 'pg1:5432:*:postgres:test' \
    -m 'pg1:test4' \
    -c 'pg1:test>pg1:test4' \
    -b 'add db test dbhost=pg1 dbname=test dbuser=postgres' \
    -b 'add db test4 dbhost=pg1 dbname=test4 dbuser=postgres' \
    -b 'add relgroup testgroup' \
    -b 'add all tables db=test relgroup=testgroup' \
    -b 'add all sequences db=test relgroup=testgroup' \
    -b 'add sync testsync dbs=test,test4 relgroup=testgroup onetimecopy=2' \
    -b 'activate testsync'

#docker stop bucardo_pg1_1
#docker rm bucardo_pg1_1
