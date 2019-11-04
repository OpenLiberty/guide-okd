FROM open-liberty

USER ROOT
COPY target/test /opt/ol
#RUN unzip guide-okd.zip \
#&& rm guide-okd.zip
#RUN chown -R 1001:0 /opt/ol
#COPY src/main/liberty/config/ /config/
#COPY target/*.war /config/apps/
USER 1001
