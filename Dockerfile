FROM debian:jessie

LABEL maintainer="insidesc.igor@gmail.com"

ENV PREFIX=/opt/firebird
ENV VOLUME=/firebird
ENV DEBIAN_FRONTEND noninteractive
ENV FBURL=http://web.firebirdsql.org/downloads/prerelease/v40beta1/Firebird-4.0.0.1436-Beta1.amd64.tar.gz
ENV DBPATH=/firebird/data

COPY build.sh ./build.sh

RUN chmod +x ./build.sh && \
    sync && \
    ./build.sh && \
    rm -f ./build.sh

VOLUME ["/firebird"]

EXPOSE 3050/tcp

COPY docker-entrypoint.sh ${PREFIX}/docker-entrypoint.sh
RUN chmod +x ${PREFIX}/docker-entrypoint.sh

COPY docker-healthcheck.sh ${PREFIX}/docker-healthcheck.sh
RUN chmod +x ${PREFIX}/docker-healthcheck.sh \
    && apt-get update \
    && apt-get -qy install netcat \
    && rm -rf /var/lib/apt/lists/*
HEALTHCHECK CMD /opt/firebird/docker-healthcheck.sh || exit 1

ENTRYPOINT ["/opt/firebird/docker-entrypoint.sh"]

CMD ["/opt/firebird/bin/fbguard"]
