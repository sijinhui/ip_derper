FROM golang:latest AS builder

LABEL org.opencontainers.image.source=https://github.com/yangchuansheng/ip_derper

WORKDIR /app

ADD tailscale /app/tailscale

# build modified derper
RUN cd /app/tailscale/cmd/derper && \
    CGO_ENABLED=0 /usr/local/go/bin/go build -buildvcs=false -ldflags "-s -w" -o /app/derper && \
    cd /app && \
    rm -rf /app/tailscale

FROM ubuntu:20.04
WORKDIR /app

# ========= CONFIG =========
# - derper args
ENV DERP_ADDR=:443
ENV DERP_HTTP_PORT=80
ENV DERP_DOMAIN=127.0.0.1
ENV DERP_CERTS=/app/certs/
ENV DERP_STUN=true
ENV DERP_VERIFY_CLIENTS=false
ENV DERP_STUN_PORT=3478
# ==========================

# apt
RUN apt-get update && \
    apt-get install -y openssl curl

COPY build_cert.sh /app/
COPY --from=builder /app/derper /app/derper

# build self-signed certs && start derper
CMD /app/derper --hostname=$DERP_DOMAIN \
    -certmode=manual \
    -certdir=$DERP_CERTS \
    -stun=$DERP_STUN  \
    -a=$DERP_ADDR \
    -http-port=$DERP_HTTP_PORT \
    -stun-port=$DERP_STUN_PORT \
    -verify-clients=$DERP_VERIFY_CLIENTS
