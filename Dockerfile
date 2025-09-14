ARG SCONE_VERSION=6.0.2
FROM registry.scontain.com/scone.cloud/scone-alpine-pkgs:${SCONE_VERSION} AS packages

FROM alpine:3.22 AS builder-wrk
    # build wrk2 load generator - had issues on newer alpine versions ; we stick with alpine 3.20 for now
RUN apk add gcc musl-dev make git openssl-dev  zlib-dev && \
    cd / && git clone --depth 1 https://github.com/giltene/wrk2.git && \
    cd wrk2 && make -j $(nproc)

FROM ghcr.io/scontain/golang:1-alpine AS builder

RUN apk add git gcc musl-dev && \
    cd / && git clone --depth 1 -b v2.10.2 "https://github.com/caddyserver/caddy.git" && \
    cd caddy && \
    cd cmd/caddy && go build && \
    cp caddy caddy.native

COPY --from=packages /packages/scone-cli.apk /packages/

RUN apk add --allow-untrusted --no-network /packages/scone-cli.apk 

RUN mkdir /binary-fs-dir && \
    # create binaryfs lib. include caddy to have some files to serve; host-path will contain tls certs
    # see https://sconedocs.github.io/binary_fs/
    SCONE_MODE=SIM SCONE_HEAP=3G scone binaryfs / /binary-fs-dir -v \
	--include "/caddy/*" \
        --host-path "/root/.local/share/caddy/" && \
    cd /binary-fs-dir && \
    gcc /binary-fs-dir/binary_fs_blob.s ./libbinary_fs_template.a -shared -o /libbinaryfs.so && \
    mv /libbinaryfs.so /usr/lib && \
    scone-signer sign --sconify --extensions libbinaryfs.so --heap 2g --syslibs 1 --dlopen 0 /caddy/cmd/caddy/caddy

FROM alpine
COPY --from=builder /caddy/cmd/caddy/caddy /caddy
COPY --from=builder /caddy/cmd/caddy/caddy.native /caddy.native
COPY --from=builder /usr/lib/libbinaryfs.so /usr/lib
COPY --from=builder /opt/scone/lib/libc.scone-x86_64.so.1 /opt/scone/lib/libc.scone-x86_64.so.1
COPY --from=builder /opt/scone/lib/ld-scone-x86_64.so.1 /lib/ld-scone-x86_64.so
COPY --from=builder-wrk /wrk2/wrk /usr/bin
COPY run_test.sh /bin/run_test.sh
RUN apk add libgcc curl nss-tools p11-kit-trust ca-certificates
CMD ["/bin/run_test.sh"]
