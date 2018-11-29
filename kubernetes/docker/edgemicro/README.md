# Docker for Microgateway
The following steps will allow you to run Microgateway as a Docker container.

## Pre-requisites
* Microgateway is configured against an org/environment
* User has the configuration file for microgateway
* User has the credentials to start microgateway

### Step 1: Download Microgateway container for docker
```
docker pull gcr.io/apigee-microgateway/edgemicro:latest
```
Use a tag to download a specific version

### Step 2: Base64 encode the microgateway configuration file
```
export EDGEMICRO_CONFIG=`base64 $HOME/.edgemicro/org-test-config.yaml`
```

NOTE: This version of docker accepts a microgateway configuration as a base64 encoded string. This allows you to pass the configuration file as an environment variable. When using Kubernetes, the configuration file can be stored in a Kubernetes Secret entity.

### Step 3: Start Microgateway with params
```
docker run -P -p 8000:8000 -d --name edgemicro -v /var/tmp:/opt/apigee/logs -e EDGEMICRO_PROCESS=1 -e EDGEMICRO_ORG=org -e EDGEMICRO_ENV=test -e EDGEMICRO_KEY=xxx -e EDGEMICRO_SECRET=xxx -e EDGEMICRO_CONFIG=$EDGEMICRO_CONFIG -e SERVICE_NAME=edgemicro --security-opt=no-new-privileges --cap-drop=ALL gcr.io/apigee-microgateway/edgemicro:latest
```

P = publish all exposed ports to the host
d = run in detached mode
v = volume mount for logs
expose port 8443 if you are expose node.js over TLS

List of environment variables
* `EDGEMICRO_ORG` = Apigee Edge org name
* `EDGEMICRO_ENV` = Apigee Edge environment name
* `EDGEMICRO_PROCESS` = Number of worker processes to start
* `EDGEMICRO_KEY` = Microgateway key 
* `EDGEMICRO_SECRET` = Microgateway secret
* `EDGEMICRO_CONFIG` = A base64 encoded string of the microgateway config file
* `SERVICE_NAME` = set to "edgemicro" (used in Kubernetes)
* `DEBUG` = `*` to enable debugging

### Step 4: Stop Microgateway
```
docker stop edgemicro
```

NOTE: You can now restart Microgateway using this command
```
docker start edgemicro
```

## TLS certificates
The container has a mount point on `/opt/apigee/.edgemicro`. You can load the certificates on the mount point and refer to it from the `org-env-config.yaml`

## Using custom plugins
There are two options to deal with custom plugins:

### Option 1: Mount the plugins

Plugins can be mounted on the volume `/opt/apigee/plugins`
```
docker run -v /volume/mount:/opt/apigee/plugins .....
```

### Option 2: Build plugins into the container

Build a new container with the plugins

Here is an example:
```
FROM gcr.io/apigee-microgateway/edgemicro:latest
RUN apt-get install unzip
COPY plugins.zip /opt/apigee/
RUN chown apigee:apigee /opt/apigee/plugins.zip
RUN su - apigee -c "unzip /opt/apigee/plugins.zip -d /opt/apigee"
EXPOSE 8000
EXPOSE 8443
USER apigee
ENTRYPOINT ["entrypoint"]
```
