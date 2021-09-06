# Dockerized Atlassian Confluence

"One place for all your team's work - Spend less time hunting things down and more time making things happen. Organize your work, create documents, and discuss everything in one place." - [[Source](https://www.atlassian.com/software/confluence)]

# Supported Tags And Respective Dockerfile Links

| Product |Version | Tags  | Dockerfile |
|---------|--------|-------|------------|
| Confluence | 7.11.6 | 7.11.6, latest | [Dockerfile](https://github.com/teamatldocker/confluence/blob/master/Dockerfile) |

# Related Images

You may also like:

* [teamatldocker/jira](https://github.com/teamatldocker/jira): The #1 software development tool used by agile teams
* [teamatldocker/confluence](https://github.com/teamatldocker/confluence): Create, organize, and discuss work with your team
* [teamatldocker/bitbucket](https://github.com/teamatldocker/bitbucket): Code, Manage, Collaborate
* [teamatldocker/crowd](https://github.com/teamatldocker/crowd): Identity management for web apps
* [blacklabelops-legacy/crucible](https://github.com/blacklabelops-legacy/crucible): Source Code Review

# Make It Short

~~~~
$ docker run -d -p 80:8090 --name confluence teamatldocker/confluence
~~~~

# Setup

1. Start the database container
2. Start Confluence
3. Setup Confluence

First start the database server:

> Note: Change Password!

~~~~
$ docker network create confluencenet
$ docker run --name postgres -d \
    --network confluencenet \
    -e 'POSTGRES_USER=jira' \
    -e 'POSTGRES_PASSWORD=jellyfish' \
    -e 'POSTGRES_ENCODING=UTF8' \
    -e 'POSTGRES_COLLATE=C' \
    -e 'POSTGRES_COLLATE_TYPE=C' \
    postgres
~~~~

> This is the blacklabelops postgres image.

Secondly start Confluence with a link to postgres:

~~~~
$ docker run -d --name confluence \
	  --network confluencenet \
	  -p 80:8090 teamatldocker/confluence
~~~~

>  Start the Confluence and link it to the postgresql instance.

Thirdly, configure your Confluence yourself and fill it with a test license.

1. Choose `Production Installation` because we have a postgres!
2. Enter license information
3. In `Choose a Database Configuration` choose `PostgeSQL` and press `External Database`
4. In `Configure Database` press `Direct JDBC`
5. In `Configure Database` fill out the form:

* Driver Class Name: `org.postgresql.Driver`
* Database URL: `jdbc:postgresql://postgres:5432/confluencedb`
* User Name: `confluencedb`
* Password: `jellyfish`

> Note: Change Password!

# Demo Database Setup

> Note: It's not recommended to use a default initialized database for Confluence in production! The default databases are all using a not recommended database configuration! Please use this for demo purposes only!

This is a demo "by foot" using the docker cli. In this example we setup an empty PostgreSQL container. Then we connect and configure the Confluence accordingly. Afterwards the Confluence container can always resume on the database.

Steps:

* Start Database container
* Start Confluence

## PostgreSQL

Let's take an PostgreSQL Docker Image and set it up:

Postgres Official Docker Image:

~~~~
$ docker network create confluencenet
$ docker run --name postgres -d \
    --network confluencenet \
    -e 'POSTGRES_DB=confluencedb' \
    -e 'POSTGRES_USER=confluencedb' \
    -e 'POSTGRES_PASSWORD=jellyfish' \
    postgres:9.4
~~~~

> This is the official postgres image.

Postgres Community Docker Image:

~~~~
$ docker network create confluencenet
$ docker run --name postgres -d \
    --network confluencenet \
    -e 'DB_USER=confluencedb' \
    -e 'DB_PASS=jellyfish' \
    -e 'DB_NAME=confluencedb' \
    sameersbn/postgresql:9.4-12
~~~~

> This is the sameersbn/postgresql docker container I tested.

Now start the Confluence container and let it use the container. On first startup you have to configure your Confluence yourself and fill it with a test license.

1. Choose `Production Installation` because we have a postgres!
2. Enter license information
3. In `Choose a Database Configuration` choose `PostgeSQL` and press `External Database`
4. In `Configure Database` press `Direct JDBC`
5. In `Configure Database` fill out the form:

* Driver Class Name: `org.postgresql.Driver`
* Database URL: `jdbc:postgresql://postgres:5432/confluencedb`
* User Name: `confluencedb`
* Password: `jellyfish`

~~~~
$ docker run -d --name confluence \
	  --network confluencenet \
	  -p 80:8090 teamatldocker/confluence
~~~~

>  Start the Confluence and link it to the postgresql instance.

## MySQL

Let's take an MySQL container and set it up:

MySQL Official Docker Image:

~~~~
$ docker network create confluencenet
$ docker run -d --name mysql \
    --network confluencenet \
    -e 'MYSQL_ROOT_PASSWORD=verybigsecretrootpassword' \
    -e 'MYSQL_DATABASE=confluencedb' \
    -e 'MYSQL_USER=confluencedb' \
    -e 'MYSQL_PASSWORD=jellyfish' \
    mysql:5.6
~~~~

> This is the mysql docker container I tested.

MySQL Community Docker Image:

~~~~
$ docker network create confluencenet
$ docker run -d --name mysql \
    --network confluencenet \
    -e 'ON_CREATE_DB=confluencedb' \
    -e 'MYSQL_USER=confluencedb' \
    -e 'MYSQL_PASS=jellyfish' \
    tutum/mysql:5.6
~~~~

> This is the tutum/mysql docker container I tested.

Now start the Confluence container and let it use the container. On first startup you have to configure your Confluence yourself and fill it with a test license.

1. Choose `Production Installation` because we have a mysql!
2. Enter license information
3. In `Choose a Database Configuration` choose `MySQL` and press `External Database`
4. In `Configure Database` press `Direct JDBC`
5. In `Configure Database` fill out the form:

* Driver Class Name: `com.mysql.jdbc.Driver`
* Database URL: `jdbc:mysql://mysql/confluencedb?sessionVariables=storage_engine%3DInnoDB&useUnicode=true&characterEncoding=utf8`
* User Name: `confluencedb`
* Password: `jellyfish`

~~~~
$ docker run -d --name confluence \
	  --network confluencenet \
	  -p 80:8090 teamatldocker/confluence
~~~~

>  Start Confluence

> Confluence will be available at http://yourdockerhost

# Database Wait Feature

The confluence container can wait for the database container to start up. You have to specify the
host and port of your database container and Confluence will wait up to one minute for the database.

You can define the waiting parameters with the environment variables:

* `DOCKER_WAIT_HOST`: The host to poll. Mandatory!
* `DOCKER_WAIT_PORT`: The port to poll Mandatory!
* `DOCKER_WAIT_TIMEOUT`: The timeout in seconds. Optional! Default: 60
* `DOCKER_WAIT_INTERVAL`: The polling interval in seconds. Optional! Default:5

Example waiting for a postgresql database:

First start the polling container:

~~~~
$ docker run -d --name confluence \
    -e "DOCKER_WAIT_HOST=your_postgres_host" \
    -e "DOCKER_WAIT_PORT=5432" \
    -p 80:8090 teamatldocker/confluence
~~~~

> Waits at most 60 seconds for the database.

Start the database within 60 seconds:

~~~~
$ docker run --name postgres -d \
    --network jiranet \
    -v postgresvolume:/var/lib/postgresql \
    -e 'POSTGRES_USER=jira' \
    -e 'POSTGRES_PASSWORD=jellyfish' \
    -e 'POSTGRES_DB=jiradb' \
    -e 'POSTGRES_ENCODING=UTF8' \
    -e 'POSTGRES_COLLATE=C' \
    -e 'POSTGRES_COLLATE_TYPE=C' \
    postgres
~~~~

> Confluence will start after postgres is available!

# Confluence Configuration Properties

You can specify configuration entries for the Confluence configuration file `confluence.cfg.xml`. The entries will be added or
updated after the configuration file is available, e.g. after confluence installation. You can specify those entries with
enumerated environment variables, they will be executed at each container restart.

Environment Variables:

* `CONFLUENCE_CONFIG_PROPERTY`: The name of each configuration property.
* `CONFLUENCE_CONFIG_VALUE`: The value for each configuration property.

Example:

* Setting property `synchrony.btf` to `true`
* Adding property `confluence.webapp.context.path` to `/confluence`

~~~~
$ docker run -d -p 80:8090 \
    --name confluence \
    -e "CONFLUENCE_CONFIG_PROPERTY1=synchrony.btf" \
    -e "CONFLUENCE_CONFIG_VALUE1=true" \
    -e "CONFLUENCE_CONFIG_PROPERTY2=confluence.webapp.context.path" \
    -e "CONFLUENCE_CONFIG_VALUE2=/confluence" \
    teamatldocker/confluence
~~~~

> Each environment variable must be enumerated with a postfix number, starting with 1!

Note: When starting Confluence the first time there will be no configuration file `confluence.cfg.xml`. You will
have to restart your container `docker restart confluence` then your settings will take effect.

Note: Settings will be adjusted at each container restart. There are properties that can be changed inside Confluence. You may not want to overwrite your application setting at each restart.

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
    teamatldocker/confluence
~~~~

> Will set the values inside the server.xml in /opt/confluence/conf/server.xml

# NGINX HTTP Proxy

This is an example on running Atlassian Confluence behind NGINX with 2 Docker commands!

Prerequisite:

If you want to try the stack on your local compute then setup the following domains in your host settings (Mac/Linux: /etc/hosts):

~~~~
127.0.1.1	confluence.yourhost.com
~~~~

Then create a Docker network for communication between Confluence and Nginx:

~~~~
$ docker network create confluence
~~~~

First start Confluence:

~~~~
$ docker run -d --name confluence \
	  --network confluence \
	  -v confluencedata:/var/atlassian/confluence \
	  -e "CONFLUENCE_CONTEXT_PATH=/confluence" \
    -e "CONFLUENCE_PROXY_NAME=confluence.yourhost.com" \
    -e "CONFLUENCE_PROXY_PORT=80" \
    -e "CONFLUENCE_PROXY_SCHEME=http" \
    teamatldocker/confluence
~~~~

Then start NGINX:

~~~~
$ docker run -d \
    -p 80:80 \
    --name nginx \
    --network confluence \
    -e "SERVER1SERVER_NAME=confluence.yourhost.com" \
    -e "SERVER1REVERSE_PROXY_LOCATION1=/" \
    -e "SERVER1REVERSE_PROXY_PASS1=http://confluence:8090" \
    -e "SERVER1REVERSE_PROXY_APPLICATION1=confluence" \
    blacklabelops-legacy/nginx
~~~~

> Confluence will be available at http://confluence.yourhost.com.

# NGINX HTTPS Proxy

This is an example on running Atlassian Confluence behind NGINX with 2 Docker commands!

Note: This is a self-signed certificate! Trusted certificates by letsencrypt are supported. Documentation can be found here: [blacklabelops-legacy/nginx](https://github.com/blacklabelops-legacy/nginx)

Prerequisite:

If you want to try the stack on your local compute then setup the following domains in your host settings (Mac/Linux: /etc/hosts):

~~~~
127.0.1.1	confluence.yourhost.com
~~~~

Then create a Docker network for communication between Confluence and Nginx:

~~~~
$ docker network create confluence
~~~~

First start Confluence:

~~~~
$ docker run -d --name confluence \
    --network confluence \
    -e "CONFLUENCE_PROXY_NAME=confluence.yourhost.com" \
    -e "CONFLUENCE_PROXY_PORT=443" \
    -e "CONFLUENCE_PROXY_SCHEME=https" \
    teamatldocker/confluence
~~~~

Then start NGINX:

~~~~
$ docker run -d \
    -p 443:443 \
    --name nginx \
    --network confluence \
    -e "SERVER1REVERSE_PROXY_LOCATION1=/" \
    -e "SERVER1REVERSE_PROXY_PASS1=http://confluence:8090" \
    -e "SERVER1REVERSE_PROXY_APPLICATION1=confluence" \
    -e "SERVER1CERTIFICATE_DNAME=/CN=CrustyClown/OU=SpringfieldEntertainment/O=confluence.yourhost.com/L=Springfield/C=US" \
    -e "SERVER1HTTPS_ENABLED=true" \
    -e "SERVER1HTTP_ENABLED=false" \
    blacklabelops-legacy/nginx
~~~~

> Confluence will be available at https://confluence.yourhost.com.

# Build The Image

The build process can take the following argument:

* CONFLUENCE_VERSION: The specific Confluence version number.

Examples:

Build image with the default Confluence release:

~~~~
$ docker build -t teamatldocker/confluence .
~~~~

> Note: Dockerfile must be inside the current directory!

Build image with a specific Confluence release:

~~~~
$ docker build --build-arg CONFLUENCE_VERSION=6.0.2  -t teamatldocker/confluence .
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
      CONFLUENCE_VERSION: 6.0.2
~~~~

> Adjust CONFLUENCE_VERSION for your personal needs.

Build the latest release with docker-compose:

~~~~
$ docker-compose build
~~~~

# Catalina Webserver Properties

The Catalina webserver properties can be specified using environment variables.

The following environment variables can be used:

* `CATALINA_PARAMETER`: The name of the parameter value. You have to use full parameter flag, its name and assignment operator, e.g. `-Xms`, `-XX:` or `-Dsynchrony.proxy.enabled=`.
* `CATALINA_PARAMETER_VALUE`: Set the value of the parameter.

Example:

~~~~
$ docker run -d -p 80:8090 \
  	--name confluence \
  	-v confluencedata:/var/atlassian/confluence \
  	-e "CATALINA_PARAMETER1=-Dsynchrony.proxy.enabled=" \
  	-e "CATALINA_PARAMETER_VALUE1=true" \
    -e "CATALINA_PARAMETER2=-Xms" \
  	-e "CATALINA_PARAMETER_VALUE2=1024m" \
    -e "CATALINA_PARAMETER3=-Xmx" \
  	-e "CATALINA_PARAMETER_VALUE3=1024m" \
  	teamatldocker/confluence
~~~~

> Sets the synchrony proxy and memory settings.

# Container Permissions

Simply: You can set user-id and group-id matching to a user and group from your host machine!

Due to security considerations this image is not running in root mode! The Jenkins process user inside the container is `confluence` and the user's group is `confluence`. This project offers a simplified mechanism for user- and group-mapping. You can set the uid of the user and gid of the user's group during build time.

The process permissions are relevant when using volumes and mounted folders from the host machine. Confluence need read and write permissions on the host machine. You can set UID and GID of the Confluence's process during build time! UID and GID should resemble credentials from your host machine.

The following build arguments can be used:

* `CONTAINER_UID`: Set the user-id of the process. (default: 1000)
* `CONTAINER_GID`: Set the group-id of the process. (default: 1000)

Example:

~~~~
$ docker build --build-arg CONTAINER_UID=2000 --build-arg CONTAINER_GID=2000 -t teamatldocker/confluence .
~~~~

> The container will write and read files with UID 2000 and GID 2000.

# Container Language Settings

You can specify the images language and country code. This can help you when Confluence does not display the characters
of your language correcty.

The following build arguments can be used:

* `LANG_LANGUAGE`: Set the operating systems language code. (default: en)
* `LANG_COUNTRY`: Set the operating systems country code. (default: US)

Example:

~~~~
$ docker build --build-arg LANG_LANGUAGE=de --build-arg LANG_COUNTRY=DE -t teamatldocker/confluence .
~~~~

> Builds image for german language and country code. E.g. when `Ö` is not displayed correctly inside Confluence.

# A Word About Memory Usage

Confluence like any Java application needs a huge amount of memory. If you limit the memory usage by using the Docker --mem option make sure that you give enough memory. Otherwise your Confluence will begin to restart randomly.
You should give at least 1-2GB more than the JVM maximum memory setting to your container.

Example:

~~~~
$ docker run -d -p 80:8090 \
    --name confluence \
    -e "CATALINA_PARAMETER1=-Xms" \
	  -e "CATALINA_PARAMETER_VALUE1=1024m" \
    -e "CATALINA_PARAMETER2=-Xmx" \
	  -e "CATALINA_PARAMETER_VALUE2=2048m" \
    teamatldocker/confluence
~~~~

> CATALINA_OPTS sets webserver startup properties.

# Container Metadata

You can inspect image metadata with the following command:

~~~~
$ docker inspect --format='{{json .Config.Labels}}' teamatldocker/confluence
~~~~

> Displays image metadata, e.g. image build date.


# Confluence SSO With Crowd

You enable Single Sign On with Atlassian Crowd. What is crowd?

"Users can come from anywhere: Active Directory, LDAP, Crowd itself, or any mix thereof. Control permissions to all your applications in one place – Atlassian, Subversion, Google Apps, or your own apps." - [Atlassian Crowd](https://www.atlassian.com/software/crowd/overview)

This is controlled by the environment variable `CONFLUENCE_CROWD_SSO`. Possible values:

* `true`: Confluence configuration will be set to Crowd SSO authentication class at every restart.
* `false`: Confluence configuration will be set to Confluence Authentication class at every restart.
* `ignore` (Default): Config will not be touched, current image setting will be taken.

You need to configure an application user between confluence and crowd, see here: [Integrating Crowd with Atlassian Confluence](https://confluence.atlassian.com/crowd/integrating-crowd-with-atlassian-confluence-198573.html)

Crowd SSO needs the following environment variables:

`CROWD_SSO_APPLICATION_NAME`: The application username.
`CROWD_SSO_APPLICATION_PASSWORD`: The application user's password.
`CROWD_SSO_BASE_URL`: The base url of your crowd instance, e.g. `https://yourcrowd.yourhost.com/`
`CROWD_SSO_SESSION_VALIDATION`: Timeout for the validation token in minutes.

Example:

~~~~
$ docker run -d -p 80:8080 -v confluencevolume:/var/atlassian/confluence \
    -e "CONFLUENCE_CROWD_SSO=true" \
    -e "CROWD_SSO_APPLICATION_NAME=confluence_user" \
    -e "CROWD_SSO_APPLICATION_PASSWORD=your_secure_password" \
    -e "CROWD_SSO_BASE_URL=https://yourcrowd.yourhost.com/" \
    -e "CROWD_SSO_SESSION_VALIDATION=10" \
    --name confluence teamatldocker/confluence
~~~~

 > SSO will be activated, you will need Crowd in order to authenticate.

# Credits

This project is very grateful for code and examples from the repositories:

* [atlassianlabs/atlassian-docker](https://bitbucket.org/atlassianlabs/atlassian-docker)
* [cptactionhank/docker-atlassian-confluence](https://github.com/cptactionhank/docker-atlassian-confluence)

# References

* [Atlassian Confluence](https://www.atlassian.com/software/confluence)
* [Docker Homepage](https://www.docker.com/)
* [Docker Compose](https://docs.docker.com/compose/)
* [Docker Userguide](https://docs.docker.com/userguide/)
