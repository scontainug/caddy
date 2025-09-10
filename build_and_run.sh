#!/bin/env bash

set -e

docker build -t caddy .
docker pull registry.scontain.com/sconecuratedimages/sconecli:alpine
docker pull registry.scontain.com/sconecuratedimages/services:cas.preprovisioned
docker compose up -d --pull=never
docker compose logs
