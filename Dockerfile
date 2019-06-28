FROM postgres:10
RUN BUCARDO_VERSION=5.5.0 DBIXSAFE_VERSION=1.2.5 && \
    apt-get update && apt-get install -yy postgresql-plperl-10 libdbi-perl libdbd-pg-perl curl make && apt-get clean && \
    mkdir -p /bucardo /dbixsafe && \
    curl https://bucardo.org/downloads/Bucardo-${BUCARDO_VERSION}.tar.gz | tar xvz -C /bucardo --strip-components=1 && \
    curl https://bucardo.org/downloads/DBIx-Safe-${DBIXSAFE_VERSION}.tar.gz | tar xvz -C /dbixsafe --strip-components=1 && \
    (cd /dbixsafe && perl Makefile.PL && make install) && \
    (cd /bucardo && perl Makefile.PL && make install) && \
    rm -rf /bucardo /dbixsafe /docker-entrypoint.sh /docker-entrypoint-initdb.d

COPY fs/ /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
