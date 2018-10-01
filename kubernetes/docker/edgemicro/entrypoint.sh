#!/bin/bash

# Log Location on Server.
LOG_LOCATION=/opt/apigee/logs
exec > >(tee -i $LOG_LOCATION/edgemicro.log)
exec 2>&1

echo "Log Location should be: [ $LOG_LOCATION ]"


SERVICE_NAME=$(env | grep POD_NAME=| cut -d '=' -f2| cut -d '-' -f1 | tr '[a-z]' '[A-Z]')

if [[ ${CONTAINER_PORT} != "" ]]; then
    SERVICE_PORT=${CONTAINER_PORT}
else
  ## We should create a Service name label if the deployment name is not same as service name
  ## In most of the cases it will work. The workaround is to add a containerPort label
  
  SERVICE_PORT=$(env | grep ${SERVICE_NAME}_SERVICE_PORT_HTTP=| cut -d '=' -f 2)
fi

proxy_name=edgemicro_${SERVICE_NAME}
target_port=$SERVICE_PORT
base_path=/

if [[ ${EDGEMICRO_CONFIG} != "" ]]; then
	#echo ${EDGEMICRO_CONFIG} >> /tmp/test.txt
	echo ${EDGEMICRO_CONFIG} | base64 --decode > /opt/apigee/.edgemicro/$EDGEMICRO_ORG-$EDGEMICRO_ENV-config.yaml

  chown apigee:apigee /opt/apigee/.edgemicro/*
fi

#Always override the port with 8000 for now.
sed -i.back "s/port.*/port: 8000/g" /opt/apigee/.edgemicro/$EDGEMICRO_ORG-$EDGEMICRO_ENV-config.yaml

if [[ -n "$EDGEMICRO_OVERRIDE_edgemicro_config_change_poll_interval" ]]; then
  sed -i.back "s/config_change_poll_interval.*/config_change_poll_interval: $EDGEMICRO_OVERRIDE_edgemicro_config_change_poll_interval/g" /opt/apigee/.edgemicro/$EDGEMICRO_ORG-$EDGEMICRO_ENV-config.yaml
fi

if [[ ${EDGEMICRO_LOCAL_PROXY} != "1" ]]; then
  commandString="cd /opt/apigee && edgemicro start -o $EDGEMICRO_ORG -e $EDGEMICRO_ENV -k $EDGEMICRO_KEY -s $EDGEMICRO_SECRET  -d /opt/apigee/plugins &"
else
  commandString="cd /opt/apigee && export EDGEMICRO_DECORATOR=$EDGEMICRO_DECORATOR &&  export EDGEMICRO_LOCAL_PROXY=$EDGEMICRO_LOCAL_PROXY && edgemicro start -o $EDGEMICRO_ORG -e $EDGEMICRO_ENV -k $EDGEMICRO_KEY -s $EDGEMICRO_SECRET -d /opt/apigee/plugins -a $proxy_name -v 1 -b / -t http://localhost:$target_port  &"
fi

if [[ ${EDGEMICRO_DOCKER} != "" ]]; then
	su - apigee -c "$commandString"
else 
	su - apigee -m -c "$commandString"
fi 
#edgemicro start &

# SIGUSR1-handler
my_handler() {
  echo "my_handler" >> /tmp/entrypoint.log
  su - apigee -m -c "cd /opt/apigee && edgemicro stop"
}

# SIGTERM-handler
term_handler() {
  echo "term_handler" >> /tmp/entrypoint.log
  su - apigee -m -c "cd /opt/apigee && edgemicro stop"
  exit 143; # 128 + 15 -- SIGTERM
}

# setup handlers
# on callback, kill the last background process, which is `tail -f /dev/null` and execute the specified handler
trap 'kill ${!}; my_handler' SIGUSR1
trap 'kill ${!}; term_handler' SIGTERM

while true
do
        tail -f /dev/null & wait ${!}
done
