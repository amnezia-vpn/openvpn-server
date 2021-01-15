FROM alpine:3.11.3

LABEL maintainer="Anton B"

ENV APP_NAME amneziavpn
ENV APP_INSTALL_PATH /opt/${APP_NAME}
ENV APP_PERSIST_DIR /opt/${APP_NAME}_data
ENV EASYRSA_BATCH 1
ENV PATH="/usr/share/easy-rsa:${PATH}"

WORKDIR ${APP_INSTALL_PATH}

COPY scripts .
COPY config ./config

#Install required packages
RUN apk add --no-cache openvpn easy-rsa bash netcat-openbsd dumb-init rng-tools

RUN cp ${APP_INSTALL_PATH}/config/server.conf /etc/openvpn/server.conf

EXPOSE 1194/udp

ENTRYPOINT [ "dumb-init", "./start.sh" ]
CMD [ "" ]
