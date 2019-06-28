#!/bin/bash
set -Eeuo pipefail
# For testing purposes, you can use -Eeuxo, but never commit with that as it can cause credential leakage in logs.

# .pgpass format is "host:port:dbname:user:pass"

# pg_dump -s -h pg1 -x -n public test | psql -h pg1 -d test2
# bucardo add sync testsync dbs=test,test2 tables=test
# bucardo activate testsync

touch ~/.pgpass && chmod 600 ~/.pgpass && mkdir /var/log/bucardo && chmod 777 /var/log/bucardo

ADMIN_CREDS=""
BUCARDO_CREDS=""
POSTGRES_PATH="/usr/lib/postgresql/10/bin/postgres"

start_postgres() {
    su postgres -c \
        'export PATH="$PATH:/usr/lib/postgresql/10/bin"
        initdb
        pg_ctl -D "$PGDATA" -w start'
}

bucardo_cmd() {
    su postgres -c "cd ~/ && bucardo $(echo -n $@)"
}

add_pgpass() {
    su postgres -c "cd ~/ && echo $1 >> ~/.pgpass"
}

make_db() {
    su postgres -c "psql -h $1 -c 'CREATE DATABASE $2;'" || true
}

copy_db() {
    su postgres -c "pg_dump -s -h $1 -x -n public $2 | psql -h $3 -d $4" || true
}

start_postgres
bucardo_cmd install --batch -U postgres -d postgres

while getopts p:s:c:m: o; do
    case "$o" in
    c)
        dbs=($(echo -n "$OPTARG" | tr ">" "\n"))
        set1=($(echo -n "${dbs[0]}" | tr ":" "\n"))
        set2=($(echo -n "${dbs[1]}" | tr ":" "\n"))
        copy_db "${set1[0]}" "${set1[1]}" "${set2[0]}" "${set2[1]}"
        ;;
    m)
        args=($(echo -n "$OPTARG" | tr ":" "\n"))
        make_db "${args[0]}" "${args[1]}"
        ;;
    p)
        add_pgpass $OPTARG
        ;;
    s)
        sleep $OPTARG
        ;;
    [?])
        echo "Usage: $0 [-p pgpass entry] [-s sleep time] [-m newdbhost:newdbname] [-c fromdbhost:fromdbname>todbhost:todbname]" >&2
        exit 1
        ;;
    esac
done

bucardo_cmd start

exec /bin/bash
