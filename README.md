# Dockerized Atlassian Confluence

Extensive documentation can be found here: https://github.com/cptactionhank/docker-atlassian-confluence

This image enables the configuration of a proxy! Proxy configuration is required by Atlassian products when used behind a proxy.

# Log File Configuration

You can reconfigure the logfile location with the environment variable CONFLUENCE_LOGFILE_LOCATION!

Example:

~~~~
$ docker run -d --name confluence \
    -e "CONFLUENCE_LOGFILE_LOCATION=/var/atlassian/confluence/logs" \
    blacklabelops/confluence
~~~~

> Will write logs to /var/atlassian/confluence/logs. Note: Must be accessible by daemon:daemon user!

# Proxy Configuration

You can specify your proxy host and proxy port with the environment variables CONFLUENCE_PROXY_NAME and CONFLUENCE_PROXY_PORT. The value will be set inside the Atlassian server.xml at startup!

When you use https then you also have to include the environment variable CONFLUENCE_PROXY_SCHEME.

Example HTTPS:

* Proxy Name: myhost.example.com
* Proxy Port: 443
* Poxy Protocol Scheme: https

Just type:

~~~~
$ docker run -d --name confluence \
    -e "CONFLUENCE_PROXY_NAME=myhost.example.com" \
    -e "CONFLUENCE_PROXY_PORT=443" \
    -e "CONFLUENCE_PROXY_SCHEME=https" \
    blacklabelops/confluence
~~~~

> Will set the values inside the server.xml in /opt/confluence/conf/server.xml

# NGINX HTTP Proxy

This is an example on running Atlassian Confluence behind NGINX with 2 Docker commands!

First start Confluence:

~~~~
$ docker run -d --name confluence \
    -e "CONFLUENCE_PROXY_NAME=www.example.com" \
    -e "CONFLUENCE_PROXY_PORT=80" \
    -e "CONFLUENCE_PROXY_SCHEME=http" \
    blacklabelops/confluence
~~~~

Then start NGINX:

~~~~
$ docker run -d \
    -p 80:8080 \
    --name nginx \
    --link confluence:confluence
    -e "SERVER1REVERSE_PROXY_LOCATION1=/" \
    -e "SERVER1REVERSE_PROXY_PASS1=http://confluence:8090" \
    blacklabelops/nginx
~~~~

> Confluence will be available at http://boot2docker-ip or http://localhost. Depends if you running Docker locally or if you use Dockertools.

# NGINX HTTPS Proxy

This is an example on running Atlassian Confluence behind NGINX with 2 Docker commands!

Note: This is a self-signed certificate! Trusted certificates by letsencrypt are supported. Documentation can be found here: [blacklabelops/nginx](https://github.com/blacklabelops/nginx)

First start Confluence:

~~~~
$ docker run -d --name confluence \
    -e "CONFLUENCE_PROXY_NAME=crusty.springfield.com" \
    -e "CONFLUENCE_PROXY_PORT=443" \
    -e "CONFLUENCE_PROXY_SCHEME=https" \
    blacklabelops/confluence
~~~~

Then start NGINX:

~~~~
$ docker run -d \
    -p 443:44300 \
    --name nginx \
    --link confluence:confluence
    -e "SERVER1REVERSE_PROXY_LOCATION1=/" \
    -e "SERVER1REVERSE_PROXY_PASS1=http://confluence:8090" \
    -e "SERVER1CERTIFICATE_DNAME=/CN=CrustyClown/OU=SpringfieldEntertainment/O=crusty.springfield.com/L=Springfield/C=US" \
    -e "SERVER1HTTPS_ENABLED=true" \
    -e "SERVER1HTTP_ENABLED=false" \
    blacklabelops/nginx
~~~~

> Confluence will be available at https://boot2docker-ip or https://localhost. Depends if you running Docker locally or if you use Dockertools.
