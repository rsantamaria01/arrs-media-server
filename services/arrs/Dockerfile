ARG APP

FROM lscr.io/linuxserver/${APP}:latest

ENV APP=${APP}

COPY init-envs.sh /custom-cont-init.d/init-envs.sh
RUN chmod +x /custom-cont-init.d/init-envs.sh

COPY setup.sh /custom-services.d/setup
RUN chmod +x /custom-services.d/setup