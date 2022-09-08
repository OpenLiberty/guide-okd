#!/bin/bash
set -euxo pipefail

# TEST 1:  Running the application in a Docker container

mvn -Dhttp.keepAlive=false \
    -Dmaven.wagon.http.pool=false \
    -Dmaven.wagon.httpconnectionManager.ttlSeconds=120 \
    -q clean package

docker pull openliberty/open-liberty:kernel-java8-openj9-ubi

docker build -t system:1.0-SNAPSHOT system/.
docker build -t inventory:1.0-SNAPSHOT inventory/.

docker run -d --name system -p 9080:9080 system:1.0-SNAPSHOT
docker run -d --name inventory -p 9081:9080 inventory:1.0-SNAPSHOT

sleep 60

systemStatus="$(curl --write-out "%{http_code}\n" --silent --output /dev/null "http://localhost:9080/system/properties")"
inventoryStatus="$(curl --write-out "%{http_code}\n" --silent --output /dev/null "http://localhost:9081/inventory/systems")"
if [ "$systemStatus" == "200" ] && [ "$inventoryStatus" == "200" ]
then 
  echo ENDPOINT OK
else 
  echo system status:
  echo "$systemStatus"
  echo inventory status:
  echo "$inventoryStatus"
  echo ENDPOINT NOT OK
  exit 1
fi

docker stop system inventory 
docker rm system inventory

# TEST 2: Building and running the application

mvn -Dhttp.keepAlive=false \
    -Dmaven.wagon.http.pool=false \
    -Dmaven.wagon.httpconnectionManager.ttlSeconds=120 \
    -pl system -q clean package liberty:create liberty:install-feature liberty:deploy
mvn -Dhttp.keepAlive=false \
    -Dmaven.wagon.http.pool=false \
    -Dmaven.wagon.httpconnectionManager.ttlSeconds=120 \
    -pl inventory -q clean package liberty:create liberty:install-feature liberty:deploy

mvn -pl system liberty:start
mvn -pl inventory liberty:start

mvn -Dhttp.keepAlive=false \
    -Dmaven.wagon.http.pool=false \
    -Dmaven.wagon.httpconnectionManager.ttlSeconds=120 \
    -pl system failsafe:integration-test
mvn -Dhttp.keepAlive=false \
    -Dmaven.wagon.http.pool=false \
    -Dmaven.wagon.httpconnectionManager.ttlSeconds=120 \
    -Dsystem.ip=localhost:9080 \
    -Dinventory.ip=localhost:9081 \
    -pl inventory failsafe:integration-test

mvn -pl system liberty:stop
mvn -pl inventory liberty:stop

mvn failsafe:verify