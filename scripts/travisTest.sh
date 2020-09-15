#!/bin/bash
set -euxo pipefail

##############################################################################
##
##  Travis CI test script
##
##############################################################################

mvn -q package

oc registry login --skip-check=true

docker pull openliberty/open-liberty:kernel-java8-openj9-ubi

docker build -t `oc registry info`/`oc project -q`/system:test system/.
docker build -t `oc registry info`/`oc project -q`/inventory:test inventory/.

oc apply -f ../scripts/test.yaml

sleep 120

oc get pods

oc describe pods

oc get routes

SYSTEM_IP=`oc get route system-route -o=jsonpath='{.spec.host}'`
INVENTORY_IP=`oc get route inventory-route -o=jsonpath='{.spec.host}'`

timeout=24
curl http://$SYSTEM_IP/system/properties
curl http://$INVENTORY_IP/inventory/systems/system-service | grep Time-out | grep Time-out
while (( $? == 0 && $timeout !=0 ))
do echo wait for a while...$timeout; sleep 5; timeout=$(($timeout-1)); curl http://$INVENTORY_IP/inventory/systems/system-service | grep Time-out; done

mvn verify -Ddockerfile.skip=true -Dsystem.ip=$SYSTEM_IP -Dinventory.ip=$INVENTORY_IP

oc logs $(oc get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}' | grep system)
oc logs $(oc get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}' | grep inventory)
