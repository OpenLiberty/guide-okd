#!/bin/bash
set -euxo pipefail

# Set up Minikube

curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x kubectl
sudo ln -s $(pwd)/kubectl /usr/local/bin/kubectl
wget https://github.com/kubernetes/minikube/releases/download/v0.28.2/minikube-linux-amd64 -q -O minikube
chmod +x minikube

sudo apt-get update -y
sudo apt-get install -y conntrack

sudo minikube start --vm-driver=none --bootstrapper=kubeadm

# Set up OC

sudo mount --make-rshared /
wget -nv https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz
tar -xvf openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz
cd openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit
export PATH=`pwd`:$PATH
cd ..
sudo mv ../scripts/daemon.json /etc/docker/
sudo systemctl restart docker
oc cluster up

# Test app

mvn -q package

oc registry login --skip-check=true

docker pull openliberty/open-liberty:kernel-java8-openj9-ubi

docker build -t `oc registry info`/`oc project -q`/system:test system/.
docker build -t `oc registry info`/`oc project -q`/inventory:test inventory/.

oc apply -f ../scripts/test.yaml

sleep 60

oc get pods

oc describe pods

oc get routes

SYSTEM_IP=`oc get route system-route -o=jsonpath='{.spec.host}'`
INVENTORY_IP=`oc get route inventory-route -o=jsonpath='{.spec.host}'`

timeout=20
curl http://$SYSTEM_IP/system/properties
count=`curl http://$INVENTORY_IP/inventory/systems/system-service | grep -c Time-out` || true
while (( $count > 0 && $timeout != 0 )); do
    echo wait for a while...$timeout; sleep 15; 
    timeout=$(($timeout-1));
    count=`curl http://$INVENTORY_IP/inventory/systems/system-service | grep -c Time-out` || true; 
done

mvn verify -Ddockerfile.skip=true -Dsystem.ip=$SYSTEM_IP -Dinventory.ip=$INVENTORY_IP

oc logs $(oc get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}' | grep system)
oc logs $(oc get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}' | grep inventory)
