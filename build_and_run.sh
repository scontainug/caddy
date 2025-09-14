#!/usr/bin/env bash

set -ex

docker build -t caddy .
docker pull registry.scontain.com/sconecuratedimages/sconecli:alpine
docker pull registry.scontain.com/sconecuratedimages/services:cas.preprovisioned
docker compose up -d --pull=never
docker wait $(docker compose ps -q test) 2> /dev/null || true
docker compose logs
docker compose down
