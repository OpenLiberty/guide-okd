FROM open-liberty

USER ROOT
#ADD target/guide-okd.tar.gz /opt/ol
#RUN chown -R 1001:0 /opt/ol
COPY src/main/liberty/config/ /config/
COPY target/*.war /config/apps/
USER 1001
