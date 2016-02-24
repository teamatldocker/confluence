FROM blacklabelops/java:jre8
MAINTAINER Steffen Bleul <sbl@blacklabelops.com>

ARG CONFLUENCE_VERSION=5.9.5
# permissions
ARG CONTAINER_UID=1000
ARG CONTAINER_GID=1000

# Setup useful environment variables
ENV CONF_HOME=/var/atlassian/confluence \
    CONF_INSTALL=/opt/atlassian/confluence \
    MYSQL_DRIVER_VERSION=5.1.38 \
    POSTGRESQL_DRIVER_VERSION=9.4.1207

# Install Atlassian Confluence and helper tools and setup initial home
# directory structure.
RUN export CONTAINER_USER=confluence                &&  \
    export CONTAINER_GROUP=confluence               &&  \
    addgroup -g $CONTAINER_GID $CONTAINER_GROUP     &&  \
    adduser -u $CONTAINER_UID                           \
            -G $CONTAINER_GROUP                         \
            -h /home/$CONTAINER_USER                    \
            -s /bin/bash                                \
            -S $CONTAINER_USER                      &&  \
    apk add --update                                    \
      ca-certificates                                   \
      gzip                                              \
      tar                                               \
      wget                                          &&  \
    apk add xmlstarlet --update-cache                   \
      --repository                                      \
      http://dl-3.alpinelinux.org/alpine/edge/testing/  \
      --allow-untrusted                               && \
    wget --directory-prefix=/tmp https://github.com/andyshinn/alpine-pkg-glibc/releases/download/2.22-r8/glibc-i18n-2.22-r5.apk && \
    apk --allow-untrusted add glibc-i18n-2.22-r5.apk && \
    /usr/glibc-compat/bin/localedef -i en_US -f UTF-8 en_US.UTF-8 && \
    mkdir -p ${CONF_HOME} \
    && chown -R confluence:confluence ${CONF_HOME} \
    && mkdir -p ${CONF_INSTALL}/conf \
    && wget -O /tmp/atlassian-confluence-${CONFLUENCE_VERSION}.tar.gz http://www.atlassian.com/software/confluence/downloads/binary/atlassian-confluence-${CONFLUENCE_VERSION}.tar.gz && \
    tar xzf /tmp/atlassian-confluence-${CONFLUENCE_VERSION}.tar.gz --strip-components=1 -C ${CONF_INSTALL} && \
    # Install database drivers
    rm -f                                               \
      ${CONF_INSTALL}/lib/mysql-connector-java*.jar &&  \
    wget -O /tmp/mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz                                              \
      http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz && \
    tar xzf /tmp/mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz                                              \
      -C /tmp && \
    cp /tmp/mysql-connector-java-${MYSQL_DRIVER_VERSION}/mysql-connector-java-${MYSQL_DRIVER_VERSION}-bin.jar     \
      ${CONF_INSTALL}/lib/mysql-connector-java-${MYSQL_DRIVER_VERSION}-bin.jar                                &&  \
    rm -f ${CONF_INSTALL}/lib/postgresql-*.jar                                                                &&  \
    wget -O ${CONF_INSTALL}/lib/postgresql-${POSTGRESQL_DRIVER_VERSION}.jar                                       \
      https://jdbc.postgresql.org/download/postgresql-${POSTGRESQL_DRIVER_VERSION}.jar && \
    chown -R confluence:confluence ${CONF_INSTALL} && \
    # Clean caches and tmps
    rm -rf /var/cache/apk/*                         &&  \
    rm -rf /tmp/*                                   &&  \
    rm -rf /var/log/*


# Expose default HTTP connector port.
EXPOSE 8090

# Set volume mount points for installation and home directory. Changes to the
# home directory needs to be persisted as well as parts of the installation
# directory due to eg. logs.
VOLUME ["/var/atlassian/confluence","/opt/atlassian/confluence/logs"]
# Set the default working directory as the Confluence home directory.
WORKDIR ${CONF_HOME}
COPY docker-entrypoint.sh /home/confluence/docker-entrypoint.sh
ENTRYPOINT ["/home/confluence/docker-entrypoint.sh"]
CMD ["confluence"]
