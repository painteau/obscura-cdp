#!/bin/sh
./obscura serve --port 9222 --stealth &
sleep 1
nginx -g "daemon off;"
