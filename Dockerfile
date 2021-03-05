#FROM debian:10-slim
#FROM debian:stretch
FROM debian:buster

RUN apt-get update && apt-get -y install --no-install-recommends \
    curl \
    wget \
    apt-transport-https \
    ca-certificates \
    cron \
    neovim \
    git \
    jq \
    #openjdk-8-jdk \
    default-jdk \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/* 

ARG MAVEN_VERSION=3.6.3
ARG USER_HOME_DIR="/root"
ARG BASE_URL=https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries

RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
 && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
 && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
 && rm -f /tmp/apache-maven.tar.gz \
 && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"

# Define commonly used JAVA_HOME variable
#ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
ENV JAVA_HOME /usr/lib/jvm/default-java/


# wkhtmltopdf
RUN apt update && wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.buster_amd64.deb \
 && apt install -y ./wkhtmltox_0.12.6-1.buster_amd64.deb


RUN mkdir -p /dobby/scripts
RUN mkdir -p /dobby/logs
RUN mkdir -p /dobby/git
RUN touch /dobby/logs/dobby.log

COPY ./scripts/script-cron.sh /dobby/scripts/script-cron.sh
COPY ./scripts/script-launch-cron.sh /dobby/scripts/script-launch-cron.sh
COPY ./scripts/script-mvn.sh /dobby/scripts/script-mvn.sh

RUN  find /dobby/scripts/ -name "*.sh" -exec chmod +x '{}' \;

##RUN (crontab -l ; echo "\n\
##  10 * * * * /etc/.profile;           /dobby/scripts/script-cron.sh >> /dobby/logs/dobby.log \n\
##\n") | crontab

RUN (crontab -l ; echo "\n\
  * * * * * /etc/.profile;           /dobby/scripts/script-cron.sh >> /dobby/logs/dobby.log \n\
  * * * * * /etc/.profile; sleep 10; /dobby/scripts/script-cron.sh >> /dobby/logs/dobby.log \n\
  * * * * * /etc/.profile; sleep 20; /dobby/scripts/script-cron.sh >> /dobby/logs/dobby.log \n\
  * * * * * /etc/.profile; sleep 30; /dobby/scripts/script-cron.sh >> /dobby/logs/dobby.log \n\
  * * * * * /etc/.profile; sleep 40; /dobby/scripts/script-cron.sh >> /dobby/logs/dobby.log \n\
  * * * * * /etc/.profile; sleep 50; /dobby/scripts/script-cron.sh >> /dobby/logs/dobby.log \n\
\n") | crontab

RUN echo 'alias logs="tail -f /dobby/logs/dobby.log"' >> ~/.bashrc
RUN echo 'alias cdgit="cd /dobby/git; ls -lah"' >> ~/.bashrc
RUN echo 'alias cdscripts="cd /dobby/scripts; ls -lah"' >> ~/.bashrc
RUN echo 'alias cdlogs="cd /dobby/logs; ls -lah"' >> ~/.bashrc
RUN echo 'alias build="cd /dobby/scripts/; ./script-cron.sh"' >> ~/.bashrc
RUN echo 'alias unlock="rm /dobby/exchange/status"' >> ~/.bashrc
RUN echo 'alias status="echo [stop CTRL + c]; for i in {1..1000}; do cat /dobby/exchange/status; sleep 1; done"' >> ~/.bashrc


RUN echo "echo \"\n\
MMMMMMMMMMMMMMMMMMMMWKo::,.         .;oOXWMMMMMMMMMMMMMMMMMM\n\
MMMMMMMMMMMMMMMMMW0dc.                 ..:ONMMMMMMMMMMMMMMMM    DOBBY ESTA A SU SERVICIO\n\
MMMMMMMMMMMMMNOxxc.                       .:dOXMMMMMMMMMMMMM\n\
MMMMMMMMMMMNx;.                                :dXWMMMMMMMMM\n\
MMMMMMMMMNk,                                      dXWMMMMMMM     puede utilizar estos comandos rápidos:\n\
MMMMMMMMXl.                                        ;0MMMMMMM\n\
MMMMMMMNd.                                         .lXMMMMMM        $ logs       :      para ver los logs\n\
MMMMMMMO.                                           .xMMMMMM        $ cdgit      :      ir a repositorios descargados\n\
MMMMMMMO.  .;,.                                ;;;  .xMMMMMM        $ cdscripts  :      ir a scripts\n\
MMMMMMMXx:lKWWKx:...                     ..:dkXWWWXkkXMMMMMM        $ cdlogs     :      ir a logs \n\
MMMMMMMMWNWMMMMMWXX0l.                .:xKXWMMMMMMMMMMMMMMMM        $ build      :      ejecutar script build a demanda\n\
MMMMMMMMMMMMMMMMMMMMWO               .oKNXKKNWMMMMMMMMMMMMMM        $ unlock     :      elimina el archivo status\n\
MMMMMMMMMMMMNKKNNK00Od.              . ;, .. lKMMMMMMMMMMMMM        $ status     :      muestra el contenido de status\n\
MMMMMMMMMMWO;..;;...                         .kMMMMMMMMMMMMM\n\
MMMMMMMMMMWl                                 .lXMMMMMMMMMMMM\n\
MMMMMMMMMW0;                                    oXWMMMMMMMMM\n\
MMMMMMMWKd.                                       dKWMMMMMMM\n\
MMMMMMXo                                            xNMMMMMM\n\
MMMWKo                                              .oXMMMMM\n\
MWKo       ,,                                         ,xXMMM\n\
Ko       ,xXd.                                          ;kNM\n\
       .dXMMd.                                    c      .dN\n\
       .l0NWx.                                   kN0,     .;\n\
x,       .;o:.                                  c0kl.       \n\
MXx: .                                          ..       . l\n\
MMMWNO:.                                              . lkXW\n\
MMMMMMWKOc.                                       .,cx0XMMMM\n\
MMMMMMMMMWKxc.                                 .:dONMMMMMMMM\n\
MMMMMMMMMMMMWKl.                               oNMMMMMMMMMMM\n\
\"" >> ~/.bashrc

CMD /dobby/scripts/script-launch-cron.sh