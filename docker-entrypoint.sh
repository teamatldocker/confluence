#!/bin/bash -x
#
# A helper script for ENTRYPOINT.
#
# If first CMD argument is 'confluence', then the script will bootstrap Confluence
# If CMD argument is overriden and not 'confluence', then the user wants to run
# his own process.

function createConfluenceTempDirectory() {
  CONFLUENCE_CATALINA_TMPDIR=${CONF_HOME}/temp

  if [ -n "${CATALINA_TMPDIR}" ]; then
    CONFLUENCE_CATALINA_TMPDIR=$CATALINA_TMPDIR
  fi

  if [ ! -d "${CONFLUENCE_CATALINA_TMPDIR}" ]; then
    mkdir -p ${CONFLUENCE_CATALINA_TMPDIR}
    export CATALINA_TMPDIR="$CONFLUENCE_CATALINA_TMPDIR"
  fi
}

function processConfluenceLogfileSettings() {
  if [ -n "${CONFLUENCE_LOGFILE_LOCATION}" ]; then
    confluence_logfile=${CONFLUENCE_LOGFILE_LOCATION}
  fi

  if [ ! -d "${confluence_logfile}" ]; then
    mkdir -p ${confluence_logfile}
  fi
}

function processConfluenceProxySettings() {
  if [ -n "${CONFLUENCE_PROXY_NAME}" ]; then
    xmlstarlet ed -P -S -L --insert "//Connector[not(@proxyName)]" --type attr -n proxyName --value "${CONFLUENCE_PROXY_NAME}" ${CONF_INSTALL}/conf/server.xml
  fi

  if [ -n "${CONFLUENCE_PROXY_PORT}" ]; then
    xmlstarlet ed -P -S -L --insert "//Connector[not(@proxyPort)]" --type attr -n proxyPort --value "${CONFLUENCE_PROXY_PORT}" ${CONF_INSTALL}/conf/server.xml
  fi

  if [ -n "${CONFLUENCE_PROXY_SCHEME}" ]; then
    xmlstarlet ed -P -S -L --insert "//Connector[not(@scheme)]" --type attr -n scheme --value "${CONFLUENCE_PROXY_SCHEME}" ${CONF_INSTALL}/conf/server.xml
  fi
}

function processContextPath() {
  if [ -n "${CONFLUENCE_CONTEXT_PATH}" ]; then
    xmlstarlet ed -P -S -L --update "//Context/@path" --value "${CONFLUENCE_CONTEXT_PATH}" ${CONF_INSTALL}/conf/server.xml
  fi
}

function relayConfluenceLogFiles() {
  TARGET_PROPERTY=1catalina.org.apache.juli.AsyncFileHandler.directory
  sed -i "/${TARGET_PROPERTY}/d" ${CONF_INSTALL}/conf/logging.properties
  echo "${TARGET_PROPERTY} = ${confluence_logfile}" >> ${CONF_INSTALL}/conf/logging.properties
  TARGET_PROPERTY=2localhost.org.apache.juli.AsyncFileHandler.directory
  sed -i "/${TARGET_PROPERTY}/d" ${CONF_INSTALL}/conf/logging.properties
  echo "${TARGET_PROPERTY} = ${confluence_logfile}" >> ${CONF_INSTALL}/conf/logging.properties
  TARGET_PROPERTY=3manager.org.apache.juli.AsyncFileHandler.directory
  sed -i "/${TARGET_PROPERTY}/d" ${CONF_INSTALL}/conf/logging.properties
  echo "${TARGET_PROPERTY} = ${confluence_logfile}" >> ${CONF_INSTALL}/conf/logging.properties
  TARGET_PROPERTY=4host-manager.org.apache.juli.AsyncFileHandler.directory
  sed -i "/${TARGET_PROPERTY}/d" ${CONF_INSTALL}/conf/logging.properties
  echo "${TARGET_PROPERTY} = ${confluence_logfile}" >> ${CONF_INSTALL}/conf/logging.properties
}

function setConfluenceConfigurationProperty() {
  local configurationProperty=$1
  local configurationValue=$2
  if [ -n "${configurationProperty}" ]; then
    local propertyCount=$(xmlstarlet sel -t -v "count(//property[@name='${configurationProperty}'])" ${CONF_HOME}/confluence.cfg.xml)
    if [ "${propertyCount}" = '0' ]; then
      # Element does not exist, we insert new property
      xmlstarlet ed --pf --inplace --subnode '//properties' --type elem --name 'property' --value "${configurationValue}" -i '//properties/property[not(@name)]' --type attr --name 'name' --value "${configurationProperty}" ${CONF_HOME}/confluence.cfg.xml
    else
      # Element exists, we update the existing property
      xmlstarlet ed --pf --inplace --update "//property[@name='${configurationProperty}']" --value "${configurationValue}" ${CONF_HOME}/confluence.cfg.xml
    fi
  fi
}

function processConfluenceConfigurationSettings() {
  if [ -f "${CONF_HOME}/confluence.cfg.xml" ]; then
    for (( i=1; ; i++ ))
    do
      VAR_CONFLUENCE_CONFIG_PROPERTY="CONFLUENCE_CONFIG_PROPERTY$i"
      VAR_CONFLUENCE_CONFIG_VALUE="CONFLUENCE_CONFIG_VALUE$i"
      if [ ! -n "${!VAR_CONFLUENCE_CONFIG_PROPERTY}" ]; then
        break
      fi
      setConfluenceConfigurationProperty ${!VAR_CONFLUENCE_CONFIG_PROPERTY} ${!VAR_CONFLUENCE_CONFIG_VALUE}
    done
  fi
}

if [ -n "${CONFLUENCE_DELAYED_START}" ]; then
  sleep ${CONFLUENCE_DELAYED_START}
fi

createConfluenceTempDirectory

processConfluenceProxySettings

processContextPath

processConfluenceConfigurationSettings

if [ -n "${CONFLUENCE_LOGFILE_LOCATION}" ]; then
  processConfluenceLogfileSettings
  relayConfluenceLogFiles
fi

if [ "$1" = 'confluence' ]; then
  source /usr/bin/dockerwait
  exec /opt/atlassian/confluence/bin/start-confluence.sh -fg
else
  exec "$@"
fi
