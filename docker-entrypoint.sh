#!/bin/bash
#
# A helper script for ENTRYPOINT.
#
# If first CMD argument is 'confluence', then the script will bootstrap Jenkins
# If CMD argument is overriden and not 'confluence', then the user wants to run
# his own process.

if [ -n "${CONFLUENCE_PROXY_NAME}" ]; then
  xmlstarlet ed -P -S -L --insert "//Connector[not(@proxyName)]" --type attr -n proxyName --value "${CONFLUENCE_PROXY_NAME}" ${CONF_INSTALL}/conf/server.xml
fi

if [ -n "${CONFLUENCE_PROXY_PORT}" ]; then
  xmlstarlet ed -P -S -L --insert "//Connector[not(@proxyPort)]" --type attr -n proxyPort --value "${CONFLUENCE_PROXY_PORT}" ${CONF_INSTALL}/conf/server.xml
fi

if [ -n "${CONFLUENCE_LOGFILE_LOCATION}" ]; then
  TARGET_PROPERTY=1catalina.org.apache.juli.AsyncFileHandler.directory
  sed -i "/${TARGET_PROPERTY}/d" ${CONF_INSTALL}/conf/logging.properties
  echo "${TARGET_PROPERTY} = ${CONFLUENCE_LOGFILE_LOCATION}" >> ${CONF_INSTALL}/conf/logging.properties
  TARGET_PROPERTY=2localhost.org.apache.juli.AsyncFileHandler.directory
  sed -i "/${TARGET_PROPERTY}/d" ${CONF_INSTALL}/conf/logging.properties
  echo "${TARGET_PROPERTY} = ${CONFLUENCE_LOGFILE_LOCATION}" >> ${CONF_INSTALL}/conf/logging.properties
  TARGET_PROPERTY=3manager.org.apache.juli.AsyncFileHandler.directory
  sed -i "/${TARGET_PROPERTY}/d" ${CONF_INSTALL}/conf/logging.properties
  echo "${TARGET_PROPERTY} = ${CONFLUENCE_LOGFILE_LOCATION}" >> ${CONF_INSTALL}/conf/logging.properties
  TARGET_PROPERTY=4host-manager.org.apache.juli.AsyncFileHandler.directory
  sed -i "/${TARGET_PROPERTY}/d" ${CONF_INSTALL}/conf/logging.properties
  echo "${TARGET_PROPERTY} = ${CONFLUENCE_LOGFILE_LOCATION}" >> ${CONF_INSTALL}/conf/logging.properties
  mkdir -p ${CONFLUENCE_LOGFILE_LOCATION}
fi

# cat ${CONF_INSTALL}/conf/server.xml
# cat ${CONF_INSTALL}/conf/logging.properties

if [ "$1" = 'confluence' ]; then
  /opt/atlassian/confluence/bin/start-confluence.sh -fg
fi

exec "$@"
