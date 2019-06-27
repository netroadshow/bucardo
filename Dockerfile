FROM alpine as builder
ENV BUCARDO_VERSION=5.5.0 DBIXSAFE_VERSION=1.2.5
RUN apk add --update perl perl-dbd-pg build-base make curl tar gzip && \
    mkdir -p /bucardo /dbixsafe && \
    curl https://bucardo.org/downloads/Bucardo-${BUCARDO_VERSION}.tar.gz | tar xvz -C /bucardo --strip-components=1 && \
    curl https://bucardo.org/downloads/DBIx-Safe-${DBIXSAFE_VERSION}.tar.gz | tar xvz -C /dbixsafe --strip-components=1 && \
    (cd /dbixsafe && perl Makefile.PL && make install) && \
    (cd /bucardo && perl Makefile.PL && make install)

FROM alpine
RUN apk add --no-cache --update perl perl-dbd-pg postgresql-client bash
COPY --from=builder /bucardo/bucardo /usr/local/bin/bucardo
COPY --from=builder /usr/local/lib/perl5/site_perl/auto/DBIx /usr/local/lib/perl5/site_perl/auto/DBIx
COPY --from=builder /usr/local/share/perl5/site_perl/DBIx /usr/local/share/perl5/site_perl/DBIx
COPY --from=builder /usr/local/share/man/man3/DBIx::Safe.3pm /usr/local/share/man/man3/DBIx::Safe.3pm
COPY --from=builder /usr/local/share/bucardo/bucardo.schema /usr/local/share/bucardo/bucardo.schema
COPY fs/ /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
