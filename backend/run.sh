#!/bin/bash
export HAPI_KEY=$HACCHOME/deployment/tls.key
export HAPI_CERTIFICATE=$HACCHOME/deployment/tls.pem
export HAPI_DATABASE=postgresql://heatserver:heatserver@172.17.0.2:5432/heat
export HAPI_JWT_SESSION_LENGTH=3600
export HAPI_PASSWORD_COST=10
stack exec accessibility-server

