FROM debian:10-slim

RUN apt-get update && apt-get -y install --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    cron \
    neovim \
    git \
    jq \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/* 

RUN mkdir -p /dobby/scripts
RUN mkdir -p /dobby/logs
RUN mkdir -p /dobby/git
RUN touch /dobby/logs/dobby.log

COPY ./scripts/script-cron.sh /dobby/scripts/script-cron.sh
COPY ./scripts/script-launch-cron.sh /dobby/scripts/script-launch-cron.sh

RUN  find /dobby/scripts/ -name "*.sh" -exec chmod +x '{}' \;

RUN (crontab -l ; echo "\n\
  * * * * * /etc/.profile;           /dobby/scripts/script-cron.sh >> /dobby/logs/dobby.log \n\
  * * * * * /etc/.profile; sleep 10; /dobby/scripts/script-cron.sh >> /dobby/logs/dobby.log \n\
  * * * * * /etc/.profile; sleep 20; /dobby/scripts/script-cron.sh >> /dobby/logs/dobby.log \n\
  * * * * * /etc/.profile; sleep 30; /dobby/scripts/script-cron.sh >> /dobby/logs/dobby.log \n\
  * * * * * /etc/.profile; sleep 40; /dobby/scripts/script-cron.sh >> /dobby/logs/dobby.log \n\
  * * * * * /etc/.profile; sleep 50; /dobby/scripts/script-cron.sh >> /dobby/logs/dobby.log \n\
\n") | crontab

CMD /dobby/scripts/script-launch-cron.sh