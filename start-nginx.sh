#!/bin/bash

echo "{\"host\": \"$ENV_REGISTRY_PROXY_FQDN\", \"port\": $ENV_REGISTRY_PROXY_PORT}" > /var/www/html/registry-host.json

nginx -g 'daemon off;'
