FROM golang:1.17-alpine as builder
ARG CLOAK_VER=2.5.5
WORKDIR /cloak
RUN adduser -D -g '' appuser
RUN apk add --update git curl make
RUN curl -LO https://github.com/cbeuw/Cloak/archive/refs/tags/v${CLOAK_VER}.tar.gz && \
    tar -xzf v${CLOAK_VER}.tar.gz -C /cloak --strip-components=1
RUN make server

FROM alpine:3.14
RUN apk add --update tini bash jo tzdata ca-certificates && \
    rm -rf /var/cache/apk/*
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /cloak/build/ck-server /usr/local/bin/ck-server
COPY ./run.sh /usr/local/bin/
RUN mkdir /opt/cloak && chown 1000:1000 /opt/cloak
VOLUME [ "/opt/cloak" ]
USER appuser
EXPOSE 443/tcp
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["run.sh"]
