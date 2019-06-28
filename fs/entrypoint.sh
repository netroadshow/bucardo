#!/bin/bash
set -Eeuo pipefail
# For testing purposes, you can use -Eeuxo, but never commit with that as it can cause credential leakage in logs.
# .pgpass format is "host:port:dbname:user:pass"
mkdir -p /var/log/bucardo && chmod 777 /var/log/bucardo

start_postgres() {
    su postgres -c \
        'export PATH="$PATH:/usr/lib/postgresql/10/bin"
        initdb
        pg_ctl -w start'
}

sql() {
    su postgres -c "psql -h $1 -c '$2;'"
}

bucardo_cmd() {
    su postgres -c "cd ~/ && bucardo $(echo -n $@)"
}

shutdown() {
    PID=$(head -n 1 /tmp/bucardo.mcp.pid)
    bucardo_cmd stop
    tail --pid=$PID -f /dev/null
    su postgres -c \
        'export PATH="$PATH:/usr/lib/postgresql/10/bin"
        pg_ctl -w stop'
    exit 0
}

add_pgpass() {
    su postgres -c "echo $1 >> ~/.pgpass && chmod 600 ~/.pgpass"
}

make_db() {
    sql $1 "CREATE DATABASE $2" || true
}

copy_db() {
    su postgres -c "pg_dump -s -x -N bucardo -h $1 $2 | psql -h $3 -d $4" || true
}

start_postgres
bucardo_cmd install --batch -U postgres -d postgres || bucardo_cmd upgrade

while getopts b:p:c:m: o; do
    case "$o" in
    b)
        bucardo_cmd $OPTARG
        ;;
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
    [?])
        echo "Usage: $0 [-p 'pgpass entry'] [-m 'new db'] [-m 'newdbhost:newdbname'] [-c 'fromdbhost:fromdbname>todbhost:todbname']" >&2
        exit 1
        ;;
    esac
done

bucardo_cmd start
trap 'shutdown' SIGINT SIGTERM
TAIL_PID=$(head -n 1 /tmp/bucardo.mcp.pid)
tail --pid=$TAIL_PID -f /var/log/bucardo/log.bucardo
