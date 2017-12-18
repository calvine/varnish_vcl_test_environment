#!/bin/sh

docker-compose down
docker-compose run -d app
docker-compose run cache /bin/bash