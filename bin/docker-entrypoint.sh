#!/bin/bash
#
# A helper script for ENTRYPOINT.
#
# If first CMD argument is 'confluence', then the script will bootstrap Confluence
# If CMD argument is overriden and not 'confluence', then the user wants to run
# his own process.

set -o errexit

[[ ${DEBUG} == true ]] && set -x

SERAPH_CONFIG_FILE="/opt/atlassian/confluence/confluence/WEB-INF/classes/seraph-config.xml"
CROWD_PROPERTIES_FILE="/opt/atlassian/confluence/confluence/WEB-INF/classes/crowd.properties"

function updateProperties() {
  local propertyfile=$1
  local propertyname=$2
  local propertyvalue=$3
  sed -i "/${propertyname}/d" ${propertyfile}
  echo "${propertyname}=${propertyvalue}" >> ${propertyfile}
}

#
# Enable crowd sso authenticator java class in image config file
#
function enableCrowdSSO() {
  xmlstarlet ed -P -S -L --delete "//authenticator" $SERAPH_CONFIG_FILE
  xmlstarlet ed -P -S -L -s "//security-config" --type elem -n authenticator -i "//authenticator[not(@class)]" -t attr -n class -v "com.atlassian.confluence.user.ConfluenceCrowdSSOAuthenticator" $SERAPH_CONFIG_FILE
  if [ -f "${CROWD_PROPERTIES_FILE}" ]; then
    rm -f ${CROWD_PROPERTIES_FILE}
    touch ${CROWD_PROPERTIES_FILE}
  fi
  if [ -n "${CROWD_SSO_APPLICATION_NAME}" ]; then
    updateProperties ${CROWD_PROPERTIES_FILE} "application.name" "${CROWD_SSO_APPLICATION_NAME}"
  fi
  if [ -n "${CROWD_SSO_APPLICATION_PASSWORD}" ]; then
    updateProperties ${CROWD_PROPERTIES_FILE} "application.password" "${CROWD_SSO_APPLICATION_PASSWORD}"
  fi
  if [ -n "${CROWD_SSO_BASE_URL}" ]; then
    updateProperties ${CROWD_PROPERTIES_FILE} "crowd.base.url" "${CROWD_SSO_BASE_URL}"
    updateProperties ${CROWD_PROPERTIES_FILE} "crowd.server.url" "${CROWD_SSO_BASE_URL}services/"
  fi
  if [ -n "${CROWD_SSO_SESSION_VALIDATION}" ]; then
    updateProperties ${CROWD_PROPERTIES_FILE} "session.validationinterval" ${CROWD_SSO_SESSION_VALIDATION}
  else
    updateProperties ${CROWD_PROPERTIES_FILE} "session.validationinterval" "2"
  fi
  echo 'application.login.url
session.isauthenticated=session.isauthenticated
session.tokenkey=session.tokenkey
session.lastvalidation=session.lastvalidation
  ' >> ${CROWD_PROPERTIES_FILE}
}

#
# Enable confluence authenticator java class in image config file
#
function enableConfluenceAuth() {
  xmlstarlet ed -P -S -L --delete "//authenticator" $SERAPH_CONFIG_FILE
  xmlstarlet ed -P -S -L -s "//security-config" --type elem -n authenticator -i "//authenticator[not(@class)]" -t attr -n class -v "com.atlassian.confluence.user.ConfluenceAuthenticator" $SERAPH_CONFIG_FILE
}

#
# Will either enable, disable Crowd SSO support or ignore current setting at all
#
function controlCrowdSSO() {
  local setting=$1
  case "$setting" in
    true)
      enableCrowdSSO
    ;;
    false)
      enableConfluenceAuth
    ;;
    *)
      echo "Crowd SSO settings ingored because of setting ${setting}"
    esac
}

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
    xmlstarlet ed -P -S -L --update "//Context[contains(@docBase,'../confluence')]/@path" --value "${CONFLUENCE_CONTEXT_PATH}" ${CONF_INSTALL}/conf/server.xml
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
  local counter=1
  if [ -f "${CONF_HOME}/confluence.cfg.xml" ]; then
    for (( counter=1; ; counter++ ))
    do
      VAR_CONFLUENCE_CONFIG_PROPERTY="CONFLUENCE_CONFIG_PROPERTY$counter"
      VAR_CONFLUENCE_CONFIG_VALUE="CONFLUENCE_CONFIG_VALUE$counter"
      if [ -z "${!VAR_CONFLUENCE_CONFIG_PROPERTY}" ]; then
        break
      fi
      setConfluenceConfigurationProperty ${!VAR_CONFLUENCE_CONFIG_PROPERTY} ${!VAR_CONFLUENCE_CONFIG_VALUE}
    done
  fi
}

function processCatalinaDefaultConfiguration() {
  if [ -f "${CONF_INSTALL}/bin/setenv.sh" ]; then
    sed -i "/export CATALINA_OPTS/d" ${CONF_INSTALL}/bin/setenv.sh
    sed -i "/CATALINA_OPTS=/d" ${CONF_INSTALL}/bin/setenv.sh
    echo 'CATALINA_OPTS="-Dconfluence.document.conversion.fontpath=/usr/share/fonts/truetype/msttcorefonts ${CATALINA_OPTS}"
CATALINA_OPTS="-XX:-PrintGCDetails ${CATALINA_OPTS}"
CATALINA_OPTS="-XX:+PrintGCDateStamps ${CATALINA_OPTS}"
CATALINA_OPTS="-XX:-PrintTenuringDistribution ${CATALINA_OPTS}"
CATALINA_OPTS="-Xloggc:$LOGBASEABS/logs/gc-`date +%F_%H-%M-%S`.log ${CATALINA_OPTS}"
CATALINA_OPTS="-XX:+UseGCLogFileRotation ${CATALINA_OPTS}"
CATALINA_OPTS="-XX:NumberOfGCLogFiles=5 ${CATALINA_OPTS}"
CATALINA_OPTS="-XX:GCLogFileSize=2M ${CATALINA_OPTS}"
CATALINA_OPTS="-XX:G1ReservePercent=20 ${CATALINA_OPTS}"
CATALINA_OPTS="-Djava.awt.headless=true ${CATALINA_OPTS}"
CATALINA_OPTS="-Datlassian.plugins.enable.wait=300 ${CATALINA_OPTS}"
CATALINA_OPTS="-Xms1024m ${CATALINA_OPTS}"
CATALINA_OPTS="-Xmx1024m ${CATALINA_OPTS}"
CATALINA_OPTS="-XX:+UseG1GC ${CATALINA_OPTS}"
CATALINA_OPTS="${START_CONFLUENCE_JAVA_OPTS} ${CATALINA_OPTS}"
CATALINA_OPTS="-Dsynchrony.enable.xhr.fallback=true ${CATALINA_OPTS}"
CATALINA_OPTS="-Dorg.apache.tomcat.websocket.DEFAULT_BUFFER_SIZE=32768 ${CATALINA_OPTS}"
CATALINA_OPTS="-Dconfluence.context.path=${CONFLUENCE_CONTEXT_PATH} ${CATALINA_OPTS}"' >> ${CONF_INSTALL}/bin/setenv.sh
    echo "export CATALINA_OPTS" >> ${CONF_INSTALL}/bin/setenv.sh
  fi
}

function setCatalinaConfigurationProperty() {
  local configurationProperty=$1
  local configurationValue=$2
  local catalinaproperty=""
  if [ -n "${configurationProperty}" ]; then
    sed -i "/${configurationProperty}/d" ${CONF_INSTALL}/bin/setenv.sh
    catalinaproperty="CATALINA_OPTS=\""${configurationProperty}
    if [ -n "${configurationValue}" ]; then
      catalinaproperty=${catalinaproperty}${configurationValue}
    fi
    catalinaproperty=${catalinaproperty}" "'${CATALINA_OPTS}'"\""
    echo ${catalinaproperty} >> ${CONF_INSTALL}/bin/setenv.sh
  fi
}

function processCatalinaConfigurationSettings() {
  local counter=1
  local VAR_CATALINA_PARAMETER="CATALINA_PARAMETER1"
  local VAR_CATALINA_PARAMETER_VALUE="CATALINA_PARAMETER_VALUE1"
  if [ -n "${!VAR_CATALINA_PARAMETER}" ]; then
    if [ -f "${CONF_INSTALL}/bin/setenv.sh" ]; then
      sed -i "/export CATALINA_OPTS/d" ${CONF_INSTALL}/bin/setenv.sh
      for (( counter=1; ; counter++ ))
      do
        VAR_CATALINA_PARAMETER="CATALINA_PARAMETER$counter"
        VAR_CATALINA_PARAMETER_VALUE="CATALINA_PARAMETER_VALUE$counter"
        if [ -z "${!VAR_CATALINA_PARAMETER}" ]; then
          break
        fi
        setCatalinaConfigurationProperty ${!VAR_CATALINA_PARAMETER} ${!VAR_CATALINA_PARAMETER_VALUE}
      done
      echo "export CATALINA_OPTS" >> ${CONF_INSTALL}/bin/setenv.sh
    fi
  fi
}

if [ -n "${CONFLUENCE_DELAYED_START}" ]; then
  sleep ${CONFLUENCE_DELAYED_START}
fi

createConfluenceTempDirectory

processConfluenceProxySettings

processContextPath

processConfluenceConfigurationSettings

if [ -n "${CATALINA_PARAMETER1}" ]; then
  processCatalinaDefaultConfiguration
fi

if [ -n "${CATALINA_PARAMETER1}" ]; then
  processCatalinaConfigurationSettings
fi

if [ -n "${CONFLUENCE_LOGFILE_LOCATION}" ]; then
  processConfluenceLogfileSettings
  relayConfluenceLogFiles
fi

if [ -n "${CONFLUENCE_CROWD_SSO}" ]; then
  controlCrowdSSO ${CONFLUENCE_CROWD_SSO}
fi

if [ "$1" = 'confluence' ]; then
  source /usr/bin/dockerwait
  exec ${CONF_INSTALL}/bin/start-confluence.sh -fg
else
  exec "$@"
fi
