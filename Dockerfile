FROM cptactionhank/atlassian-confluence:5.9.4
MAINTAINER Steffen Bleul <sbl@blacklabelops.com>

COPY docker-entrypoint.sh $CONF_INSTALL/docker-entrypoint.sh
ENTRYPOINT ["/opt/atlassian/confluence/docker-entrypoint.sh"]
CMD ["confluence"]
