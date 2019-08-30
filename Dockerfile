FROM adoptopenjdk/openjdk8-openj9:alpine-jre
# this image already contains glibc

ARG CONFLUENCE_VERSION=6.15.9

# permissions
ARG CONTAINER_UID=1000
ARG CONTAINER_GID=1000

# Language Settings
ARG LANG_LANGUAGE=en
ARG LANG_COUNTRY=US

# Setup useful environment variables
ENV CONF_HOME=/var/atlassian/confluence \
    CONF_INSTALL=/opt/atlassian/confluence \
    MYSQL_DRIVER_VERSION=5.1.47

# Install Atlassian Confluence
RUN export CONTAINER_USER=confluence                &&  \
    export CONTAINER_GROUP=confluence               &&  \
    addgroup -g $CONTAINER_GID $CONTAINER_GROUP     &&  \
    adduser -u $CONTAINER_UID                           \
            -G $CONTAINER_GROUP                         \
            -h /home/$CONTAINER_USER                    \
            -s /bin/bash                                \
            -S $CONTAINER_USER                          \
    # glibc and pub key already installed by parent image; we need to install latest bin and i18n \
    && export GLIBC_VERSION=2.29-r0                            \
    && export GLIBC_DOWNLOAD_URL=https://github.com/sgerrand/alpine-pkg-glibc/releases/download/$GLIBC_VERSION \
    && export GLIBC_BIN=glibc-bin-$GLIBC_VERSION.apk           \
    && export GLIBC_I18N=glibc-i18n-$GLIBC_VERSION.apk         \
    && wget -O $GLIBC_BIN $GLIBC_DOWNLOAD_URL/$GLIBC_BIN       \
    && wget -O $GLIBC_I18N $GLIBC_DOWNLOAD_URL/$GLIBC_I18N     \
    && apk add --update --no-cache                    \
        gzip                                              \
        curl                                              \
        tar                                               \
        bash                                              \
        su-exec                                           \
        tini                                              \
        xmlstarlet                                        \
        msttcorefonts-installer                           \
        ttf-dejavu					                              \
        fontconfig                                        \
        ghostscript				                               	\
        graphviz                                          \
        motif					                                  	\
        wget                                              \
        $GLIBC_BIN                                        \
        $GLIBC_I18N                                       \
    # Installing true type fonts                        \
    && update-ms-fonts                                  \
    && fc-cache -f                                      \
    # Setting Locale                                    \
    && /usr/glibc-compat/bin/localedef -i ${LANG_LANGUAGE}_${LANG_COUNTRY} -f UTF-8 ${LANG_LANGUAGE}_${LANG_COUNTRY}.UTF-8 \
    # Dockerize                                                \
    && export DOCKERIZE_VERSION=v0.6.1                         \
    && export DOCKERIZE_DOWNLOAD_URL=https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    # Install Dockerize                                        \
    && wget -O dockerize.tar.gz $DOCKERIZE_DOWNLOAD_URL        \
    && tar -C /usr/local/bin -xzvf dockerize.tar.gz            \
    && rm dockerize.tar.gz                                     \
    # Installing Confluence                                    \
    && mkdir -p ${CONF_HOME} \
    && chown -R confluence:confluence ${CONF_HOME} \
    && mkdir -p ${CONF_INSTALL}/conf \
    && wget -O /tmp/atlassian-confluence-${CONFLUENCE_VERSION}.tar.gz https://www.atlassian.com/software/confluence/downloads/binary/atlassian-confluence-${CONFLUENCE_VERSION}.tar.gz && \
    tar xzf /tmp/atlassian-confluence-${CONFLUENCE_VERSION}.tar.gz --strip-components=1 -C ${CONF_INSTALL} && \
    echo "confluence.home=${CONF_HOME}" > ${CONF_INSTALL}/confluence/WEB-INF/classes/confluence-init.properties && \
    # Install database drivers
    rm -f                                               \
      ${CONF_INSTALL}/lib/mysql-connector-java*.jar &&  \
    wget -O /tmp/mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz                                              \
      https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz && \
    tar xzf /tmp/mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz                                              \
      -C /tmp && \
    cp /tmp/mysql-connector-java-${MYSQL_DRIVER_VERSION}/mysql-connector-java-${MYSQL_DRIVER_VERSION}-bin.jar     \
      ${CONF_INSTALL}/lib/mysql-connector-java-${MYSQL_DRIVER_VERSION}-bin.jar                                &&  \
    chown -R confluence:confluence ${CONF_INSTALL} && \
    # Adding letsencrypt-ca to truststore
    export KEYSTORE=$JAVA_HOME/lib/security/cacerts && \
    wget -P /tmp/ https://letsencrypt.org/certs/letsencryptauthorityx1.der && \
    wget -P /tmp/ https://letsencrypt.org/certs/letsencryptauthorityx2.der && \
    wget -P /tmp/ https://letsencrypt.org/certs/lets-encrypt-x1-cross-signed.der && \
    wget -P /tmp/ https://letsencrypt.org/certs/lets-encrypt-x2-cross-signed.der && \
    wget -P /tmp/ https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.der && \
    wget -P /tmp/ https://letsencrypt.org/certs/lets-encrypt-x4-cross-signed.der && \
    keytool -trustcacerts -keystore $KEYSTORE -storepass changeit -noprompt -importcert -alias isrgrootx1 -file /tmp/letsencryptauthorityx1.der && \
    keytool -trustcacerts -keystore $KEYSTORE -storepass changeit -noprompt -importcert -alias isrgrootx2 -file /tmp/letsencryptauthorityx2.der && \
    keytool -trustcacerts -keystore $KEYSTORE -storepass changeit -noprompt -importcert -alias letsencryptauthorityx1 -file /tmp/lets-encrypt-x1-cross-signed.der && \
    keytool -trustcacerts -keystore $KEYSTORE -storepass changeit -noprompt -importcert -alias letsencryptauthorityx2 -file /tmp/lets-encrypt-x2-cross-signed.der && \
    keytool -trustcacerts -keystore $KEYSTORE -storepass changeit -noprompt -importcert -alias letsencryptauthorityx3 -file /tmp/lets-encrypt-x3-cross-signed.der && \
    keytool -trustcacerts -keystore $KEYSTORE -storepass changeit -noprompt -importcert -alias letsencryptauthorityx4 -file /tmp/lets-encrypt-x4-cross-signed.der && \
    # Install atlassian ssl tool
    wget -O /home/${CONTAINER_USER}/SSLPoke.class https://confluence.atlassian.com/kb/files/779355358/779355357/1/1441897666313/SSLPoke.class && \
    chown -R confluence:confluence /home/${CONTAINER_USER} && \
    # Clean caches and tmps
    rm -rf /var/cache/apk/*                         &&  \
    rm -rf /tmp/*                                   &&  \
    rm -rf /var/log/*

# Expose default HTTP connector port.
EXPOSE 8090 8091

USER confluence
VOLUME ["/var/atlassian/confluence"]
# Set the default working directory as the Confluence home directory.
WORKDIR ${CONF_HOME}
COPY bin/docker-entrypoint.sh /home/confluence/docker-entrypoint.sh
COPY bin/dockerwait.sh /usr/bin/dockerwait
ENTRYPOINT ["/sbin/tini","--","/home/confluence/docker-entrypoint.sh"]
CMD ["confluence"]

# Image Build Date By Buildsystem
ARG BUILD_DATE=undefined

# Image Metadata
LABEL maintainer="Jonathan Hult <teamatldocker@JonathanHult.com>"                                  \
    org.opencontainers.image.authors="Jonathan Hult <teamatldocker@JonathanHult.com>"              \
    org.opencontainers.image.url="https://hub.docker.com/r/teamatldocker/confluence/"              \
    org.opencontainers.image.title=Confluence                                                      \
    org.opencontainers.image.description="Confluence $CONFLUENCE_VERSION running on Alpine Linux"  \
    org.opencontainers.image.source="https://github.com/teamatldocker/confluence/"                 \
    org.opencontainers.image.created=$BUILD_DATE                                                   \
    org.opencontainers.image.version=$CONFLUENCE_VERSION
