FROM openliberty/open-liberty:kernel-java8-openj9-ubi

COPY src/main/liberty/config /config/
COPY target/inventory.war /config/apps

RUN configure.sh