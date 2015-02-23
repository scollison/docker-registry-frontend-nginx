#!/bin/bash

echo "{\"host\": \"$REGISTRY_FQDN\", \"port\": $REGISTRY_PORT}" > /var/www/html/registry-host.json

nginx -g 'daemon off;'
