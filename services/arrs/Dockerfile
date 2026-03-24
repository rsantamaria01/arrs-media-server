ARG APP

FROM lscr.io/linuxserver/${APP}:latest

ARG PORT
ENV PORT=${PORT}

COPY ../setup.sh /custom-cont-init.d/setup.sh
RUN chmod +x /custom-cont-init.d/setup.sh
