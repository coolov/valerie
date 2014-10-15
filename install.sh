#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CWDIR=$(pwd)

echo "Installing Valerie... $V"

cd $DIR

git pull

sudo cp valerie.sh /usr/local/bin/valerie
sudo chmod a+x /usr/local/bin/valerie

# Make sure docker users can write to nginx config
sudo chown :docker /etc/nginx/sites-enabled
sudo chmod g+w /etc/nginx/sites-enabled

cd $CWDIR
