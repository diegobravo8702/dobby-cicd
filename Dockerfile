FROM debian:10-slim

RUN apt-get update && apt-get -y install --no-install-recommends \
    cron \
    neovim \
    && rm -rf /var/lib/apt/lists/* 

RUN mkdir -p /dobby/scripts
RUN mkdir -p /dobby/logs
RUN touch /dobby/logs/dobby.log

COPY ./scripts/script-cron.sh /dobby/scripts/script-cron.sh
COPY ./scripts/script-launch-cron.sh /dobby/scripts/script-launch-cron.sh

RUN  find /dobby/scripts/ -name "*.sh" -exec chmod +x '{}' \;

RUN (crontab -l ; echo "\n#scripts de dobby\n  * * * * * /etc/.profile; /dobby/scripts/script-cron.sh >> /dobby/logs/dobby.log \n#final\n") | crontab

CMD /dobby/scripts/script-launch-cron.sh