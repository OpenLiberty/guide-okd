FROM open-liberty

COPY src/main/liberty/config /config/
COPY target/inventory.war /config/apps

RUN configure.sh