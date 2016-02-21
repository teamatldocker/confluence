# Dockerized Atlassian Confluence


[![Circle CI](https://circleci.com/gh/blacklabelops/confluence/tree/master.svg?style=shield)](https://circleci.com/gh/blacklabelops/confluence/tree/master)

## Supported tags and respective Dockerfile links

| Product |Version | Tags  | Dockerfile |
|---------|--------|-------|------------|
| Confluence | 5.9.5 | 5.9.5, latest | [Dockerfile](https://github.com/blacklabelops/confluence/blob/master/Dockerfile) |

# Make It Short

~~~~
$ docker run -d -p 80:8090 --name confluence blacklabelops/confluence
~~~~

> Confluence will be available at http://yourdockerhost

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

# Build The Image

The build process can take the following argument:

* CONFLUENCE_VERSION: The specific Confluence version number.

Examples:

Build image with the default Confluence release:

~~~~
$ docker build -t blacklabelops/confluence .
~~~~

> Note: Dockerfile must be inside the current directory!

Build image with a specific Confluence release:

~~~~
$ docker build --build-arg CONFLUENCE_VERSION=5.9.5  -t blacklabelops/confluence .
~~~~

> Note: Dockerfile must be inside the current directory!

# Using Docker Compose

The build configuration are specified inside the following area:

~~~~
jenkins:
  build:
    context: .
    dockerfile: Dockerfile
    args:
      CONFLUENCE_VERSION: 5.9.5
~~~~

> Adjust CONFLUENCE_VERSION for your personal needs.

Build the latest release with docker-compose:

~~~~
$ docker-compose build
~~~~

# Container Permissions

Simply: You can set user-id and group-id matching to a user and group from your host machine!

Due to security considerations this image is not running in root mode! The Jenkins process user inside the container is `confluence` and the user's group is `confluence`. This project offers a simplified mechanism for user- and group-mapping. You can set the uid of the user and gid of the user's group during build time.

The process permissions are relevant when using volumes and mounted folders from the host machine. Confluence need read and write permissions on the host machine. You can set UID and GID of the Confluence's process during build time! UID and GID should resemble credentials from your host machine.

The following build arguments can be used:

* CONTAINER_UID: Set the user-id of the process. (default: 1000)
* CONTAINER_GID: Set the group-id of the process. (default: 1000)

Example:

~~~~
$ docker build --build-arg CONTAINER_UID=2000 --build-arg CONTAINER_GID=2000 -t blacklabelops/confluence .
~~~~

> The container will write and read files with UID 2000 and GID 2000.

# Vagrant

First install:

* [Vagrant](https://www.vagrantup.com/)
* [Virtualbox](https://www.virtualbox.org/)

Vagrant is fabulous tool for pulling and spinning up virtual machines like docker with containers. I can configure my development and test environment and simply pull it online. And so can you! Install Vagrant and Virtualbox and spin it up. Change into the project folder and build the project on the spot!

~~~~
$ vagrant up
$ vagrant ssh
[vagrant@localhost ~]$ cd /vagrant
[vagrant@localhost ~]$ docker-compose up
~~~~

> Confluence will be available on localhost:8080 on the host machine.

# Support & Feature Requests

Leave a message and ask questions on Hipchat: [blacklabelops/hipchat](https://www.hipchat.com/geogBFvEM)

# Credits

This project is very grateful for code and examples from the repositories:

* [atlassianlabs/atlassian-docker](https://bitbucket.org/atlassianlabs/atlassian-docker)
* [cptactionhank/docker-atlassian-confluence](https://github.com/cptactionhank/docker-atlassian-confluence)

## References
* [Atlassian Confluence](https://www.atlassian.com/software/confluence)
* [Docker Homepage](https://www.docker.com/)
* [Docker Compose](https://docs.docker.com/compose/)
* [Docker Userguide](https://docs.docker.com/userguide/)
* [Oracle Java](https://java.com/de/download/)
