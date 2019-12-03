#!/bin/bash
set -euxo pipefail

##############################################################################
##
##  Travis CI test script
##
##############################################################################

mvn -q package

oc registry login --skip-check=true

docker build -t `oc registry info`/`oc project -q`/system:test system/.
docker build -t `oc registry info`/`oc project -q`/inventory:test inventory/.

oc apply -f ../scripts/test.yaml

sleep 15

oc get pods

oc get events --field-selector involvedObject.name=system-deployment

SYSTEM_IP=`oc get route system-route -o=jsonpath='{.spec.host}'`
INVENTORY_IP=`oc get route inventory-route -o=jsonpath='{.spec.host}'`

curl -s http://$SYSTEM_IP/system/properties
curl -s http://$INVENTORY_IP/inventory/systems/system-service

mvn verify -q -Ddockerfile.skip=true -Dsystem.ip=$SYSTEM_IP -Dinventory.ip=$INVENTORY_IP

oc logs $(oc get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}' | grep system)
oc logs $(oc get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}' | grep inventory)