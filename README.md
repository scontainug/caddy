# Confidential `caddy`

This repository contains a simple example of how to use the `golang` images that we maintain on <https://github.com/scontain/golang/pkgs/container/golang> to build Go applications that link with `glibc` or `musl` instead of calling Linux system calls directly. This requires a minor patch of the `golang` runtime.

The upstream `golang` images are automatically transformed on a daily basis: We run our CI pipeline once per day to transform the upstream `golang` images on docker hub (<https://hub.docker.com/_/golang>) to the `golang` images that use `glibc` or `musl` to issue system calls.

## `caddy`

`caddy` is a popular `Go` application. We show how to transform `caddy` into a confidential application, i.e., it runs inside of an **enclave**. When we talk about **enclaves**, this does run on Intel SGX as well as AMD SEV SNP, Intel TDX, and in future, ARM CCA.

## Background

This repository contains a simple example of how to use the the `golang` images that we maintain on `ghcr.io` to build a confidential Go application. These `golang` images are slightly patched in the sense that the `Go` runtime uses `glibc` or `musl` to isse system calls. In this way, we can intercept system calls more efficiently: we use this,e.g., to transparently attest applications, encrypt / decrypt files and network traffic.

Note: You need access to images on `registry.scontain.com/scone.cloud` and `registry.scontain.com/sconecuratedimages` to be able to build and run `caddy` confidential.

## Organization

1. `build_and_run.sh`: creates the container image `caddy` and then runs the confidential `caddy` using `docker compose` using file `docker-compose.yaml`.

2. Image `caddy` is built using `Dockerfile`: it contains two versions of `caddy`: 
   - a native version built with the help of the `golang` image
   - a confidential version created by transforming the native binary with the help of `scone-signer` 
   - we embed in the confidential version the files that are served by `caddy` to protect the integrity of the served files.

3. Within container `caddy` we run script `run_test.sh` to benchmark `confidential caddy`. Note that this is only used for performance benchmarking. For production usage, one needs to extend the CAS policy.

## Screencast

The screencast shows an execution of `build_and_run.sh`:

![demo](docs/demo.svg)

You can create a new screencast by executing `make`.
