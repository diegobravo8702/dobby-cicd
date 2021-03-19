FROM jboss/wildfly

USER root

RUN /opt/jboss/wildfly/bin/add-user.sh admin admin --silent
#ADD https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/9.2.0.jre11/mssql-jdbc-9.2.0.jre11.jar /tmp/
ADD https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/9.2.0.jre8/mssql-jdbc-9.2.0.jre8.jar /tmp/
RUN  find /tmp/ -name "*.jar" -exec chmod +r '{}' \;
# ADD mssql-jdbc-9.2.0.jre11.jar /tmp/
ADD config.sh /tmp/
ADD batch.cli /tmp/
RUN /tmp/config.sh

#

RUN echo 'alias deploy="/tmp/exchange/deploy.sh"' >> ~/.bashrc
RUN echo 'alias deployforce="/tmp/exchange/deploy-force.sh"' >> ~/.bashrc
