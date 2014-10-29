#!/bin/bash

HOST_NAME=$2
PORT=80
MAN="Usage: valerie [<options>] {start|stop|refresh|info} [<args>]"

function quit { echo $1; exit 1; }

# Validate
[ -d .git ]           || quit "The current path need to be a git repo"
[ -f Dockerfile ]     || quit "No Dockerfile is present"
[ -n "$HOST_NAME" ]   || quit "$MAN"

# Get process info if it's running
PROCESS=$(docker ps -a | grep $HOST_NAME'\s*$')

# Get Image Name from git repo
IMAGE_NAME=$(git config --get remote.origin.url | grep -oP '(?<=\.com:|\.com/).*(?=.git)')

case "$1" in

  start)
    [ -n "$PROCESS" ] && quit "$HOST_NAME is running"
    
    # Build docker image
    docker build -q --tag="$IMAGE_NAME" ./ > /dev/null
    
    # Start Docker
    PID=$(docker run --name="$HOST_NAME" -d -p 127.0.0.1::$PORT -i -t $IMAGE_NAME)
    DOCKER_HOST=$(docker port $PID $PORT)

    # Reload nginx
    NGINX_CONF="server {
        listen 80;
        server_name $HOST_NAME;
        location / {
          proxy_set_header X-Real-IP \$remote_addr;
          proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
          proxy_set_header Host \$http_host;
          proxy_set_header X-NginX-Proxy true;
          proxy_pass http://$DOCKER_HOST;
          proxy_redirect off;
        }
    }"
    echo "$NGINX_CONF" > /etc/nginx/sites-enabled/$HOST_NAME
    nginx -s reload
    ;;
    
  info)
    if [[ -n "$PROCESS" ]]; then
      PID=$(echo $PROCESS | awk '{print $1}')
      echo " * $HOST_NAME is running at $(docker port $PID $PORT)"
    else
      echo " * $HOST_NAME is not running"
    fi
    ;;

  refresh)
    # Check for updates
    [ "$(sudo -u olov git pull)" == "Already up-to-date." ] && exit 1
    
    valerie stop $HOST_NAME
    valerie start $HOST_NAME
    ;;

  stop)
    [ -z "$PROCESS" ] && quit "$HOST_NAME is not running"
    
    # Remove hostname from nginx
    rm /etc/nginx/sites-enabled/$HOST_NAME
    nginx -s reload
    
    # Remove and force docker to stop
    docker rm -f $HOST_NAME
    ;;
   
  *)
    quit $MAN
esac
