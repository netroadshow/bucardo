#!/bin/bash
# .pgpass format is "host:port:dbname:user:pass"

touch ~/.pgpass && chmod 600 ~/.pgpass

run_cmd() {
    echo "bucardo $@"
}

setup_defaults() {
    echo $1 >> ~/.pgpass
    rc_args=($(echo -n "$1" | tr ":" "\n"))
    echo "piddir = /tmp/" > /etc/bucardorc
    echo "dbhost = ${rc_args[0]}" >> /etc/bucardorc
    echo "dbport = ${rc_args[1]}" >> /etc/bucardorc
    echo "dbuser = ${rc_args[3]}" >> /etc/bucardorc
    echo "dbname = ${rc_args[2]}" >> /etc/bucardorc
}

install() {
    echo $1 >> ~/.pgpass
    i_args=($(echo -n "$1" | tr ":" "\n"))
    run_cmd install --pid-dir /tmp/ -P ${i_args[4]} -U ${i_args[3]} -p ${i_args[1]} -d ${i_args[2]} -h ${i_args[0]}
}

while getopts h:i:p:d:s o
do
    case "$o" in
    h)
        setup_defaults $OPTARG ;;
    i)
        install $OPTARG ;;
	d)
        echo "$OPTARG" ;;
	s)
        echo "ss" ;;
	[?])
    	echo "Usage: $0 [-s] [-d seplist] file ..." >&2 
		exit 1;;
	esac
done

exec /bin/bash
