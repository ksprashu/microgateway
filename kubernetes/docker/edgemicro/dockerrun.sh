#!/bin/bash

docker run -P -p 8000:8000 -d --name edgemicro -e EDGEMICRO_ORG=$EDGEMICRO_ORG -e EDGEMICRO_ENV=$EDGEMICRO_ENV -e EDGEMICRO_KEY=$EDGEMICRO_KEY -e EDGEMICRO_SECRET=$EDGEMICRO_SECRET -e EDGEMICRO_CONFIG=$EDGEMICRO_CONFIG -e SERVICE_NAME=edgemicro --user apigee:apigee --security-opt=no-new-privileges --cap-drop=ALL gcr.io/apigee-microgateway/edgemicro:latest

echo "Testing the api"
sleep 5
curl http://localhost:8000;echo;
