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

RUN echo 'alias log="tail -f /dobby/logs/dobby.log"' >> ~/.bashrc
RUN echo 'alias cdgit="cd /dobby/git; ls -lah"' >> ~/.bashrc
RUN echo 'alias cdscripts="cd /dobby/scripts; ls -lah"' >> ~/.bashrc
RUN echo 'alias cdlogs="cd /dobby/logs; ls -lah"' >> ~/.bashrc

RUN echo "echo \"\n\
MMMMMMMMMMMMMMMMMMMMWKo::,.         .;oOXWMMMMMMMMMMMMMMMMMM\n\
MMMMMMMMMMMMMMMMMW0dc.                 ..:ONMMMMMMMMMMMMMMMM    Bienvenido, soy dobby y estoy a su servicio\n\
MMMMMMMMMMMMMNOxxc.                       .:dOXMMMMMMMMMMMMM\n\
MMMMMMMMMMMNx;.                                :dXWMMMMMMMMM\n\
MMMMMMMMMNk,                                      dXWMMMMMMM     puede utilizar estos comandos rápidos:\n\
MMMMMMMMXl.                                        ;0MMMMMMM\n\
MMMMMMMNd.                                         .lXMMMMMM        --> [log] <--       para ver los logs\n\
MMMMMMMO.                                           .xMMMMMM       --> [cdgit] <--      para moverse y ver el contenido de la carpeta con los repositorios descargados\n\
MMMMMMMO.  .;,.                                ;;;  .xMMMMMM      --> [cdscripts] <--   para moverse y ver el contenido de la carpeta de scripts\n\
MMMMMMMXx:lKWWKx:...                     ..:dkXWWWXkkXMMMMMM       --> [cdlogs] <--     para moverse y ver el contenido de la carpeta de logs\n\
MMMMMMMMWNWMMMMMWXX0l.                .:xKXWMMMMMMMMMMMMMMMM\n\
MMMMMMMMMMMMMMMMMMMMWO               .oKNXKKNWMMMMMMMMMMMMMM\n\
MMMMMMMMMMMMNKKNNK00Od.              . ;, .. lKMMMMMMMMMMMMM\n\
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