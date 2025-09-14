#!/bin/sh

set -e
export SCONE_MODE=hw
export SCONE_VERSION=1
export SCONE_CONFIG_ID=caddy/binaryfs
export SCONE_EXTENSIONS_PATH=libbinaryfs.so
export SCONE_EDMM_MODE=auto

# first time run natively - it will install ca cert (this process requires fork+execve)
/caddy.native file-server --domain localhost 2>&1 &
CADDY_NATIVE_PID=$!

echo waiting for caddy to start

COUNTER=0
while ! nc -z localhost 443 2>/dev/null; do
    COUNTER=`expr $COUNTER + 1`
    sleep 1
    if [ $COUNTER -eq 30 ]; then
        echo ERROR: Native caddy failed to start
        exit 1
    fi
done

echo caddy started

kill -SIGTERM $CADDY_NATIVE_PID
wait $CADDY_NATIVE_PID

echo starting caddy in SCONE
/caddy 2>&1  | tee /tmp/caddy.log &

COUNTER=0
while ! nc -z localhost 443 2>/dev/null; do
    COUNTER=`expr $COUNTER + 1`
    sleep 1
    if [ $COUNTER -eq 60 ]; then
        echo ERROR: Confidential caddy failed to start
        exit 1
    fi
done

# make sure the server is set up properly - we can use tls and it serves a file with expected content
# The server servs its own source:
curl https://localhost/caddy/caddy.go | grep 'package caddy'

wrk  -c 8 -t 8 -R 1000 -d 30 https://localhost/caddy/caddy.go

CADDY_PID=$(pidof caddy)
kill -SIGTERM $CADDY_PID

grep "SCONE version:" /tmp/caddy.log

# make sure process exited
COUNTER=0
while kill -0 $CADDY_PID 2>/dev/null; do
    COUNTER=`expr $COUNTER + 1`
    sleep 1
    if [ $COUNTER -eq 600 ]; then
        echo ERROR: Confidential caddy failed to stop
        exit 1
    fi
done

cat /tmp/caddy.log
grep '"msg":"shutdown complete","signal":"SIGTERM","exit_code":0' /tmp/caddy.log
