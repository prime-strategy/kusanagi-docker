# How to use KUSANGI Runs on Docker

## About KUSANAGI Runs on Docker (RoD)

KUSANAGI Runs on Docker (RoD) provides the functionality of KUSANAGI using Docker compose.

The following operating systems have been confirmed for use with RoD.

- CentOS(and its compatible distributions) 9 or later
- Ubuntu18.04 or later(Docker CE)
- Windows11/Windows11(WSL2+Docker for Windows.)
- Windows11/Windows11(WSL2+Docker CE)
- Mac(with Docker for mac)

The software required to use RoD will be the following.

- bash(4.x and above)
- git
- sed
- awk
- grep
- gettext
- envsubst
- curl
- python3
- docker
- docker compose plugin(docker-compose is now deprecated)


## Installing the KUSANAGI RoD

Execute the following command to install the KUSANAGI RoD under $HOME/.kusanagi.

```shell
$ curl https://raw.githubusercontent.com/prime-strategy/kusanagi-docker/master/install.sh | bash 
cloning kusanagi-docker commands
Cloning into '/home/kusanagi/.kusanagi'...
remote: Enumerating objects: 193, done.
remote: Counting objects: 100% (193/193), done.
remote: Compressing objects: 100% (123/123), done.
remote: Total 573 (delta 124), reused 125 (delta 67), pack-reused 380
Receiving objects: 100% (573/573), 195.00 KiB | 452.00 KiB/s, done.
Resolving deltas: 100% (308/308), done.
check commands requires kusanagi-docker
kusanagi-docker command install completes.
Please add these line to .bashrc or .zshrc
export PATH=/home/kusanagi/.kusanagi/bin:$PATH
$
```

Please add $HOME/.kusanagi/bin to your PATH as shown in the message above.
When updating the KUSANAGI RoD, re-execute $HOME/.kusanagi/install.sh.
When updating the image used by KUSANAGI RoD to the latest version, execute $HOME/.kusanagi/ update_version.sh.



## KUSANAGI RoD Command

The main body of the KUSANAGI RoD command is $HOME/.kusanagi/bin/kusanagi-docker.

The following is a help message.

```shell
$ kusanagi-docker --help
///////////////////////////////////////////////////
High-Performance WordPress VirtualMachine
///////////////////////////////////////////////////
     __ ____  _______ ___    _   _____   __________
    / //_/ / / / ___//   |  / | / /   | / ____/  _/
   / ,< / / / /\__ \/ /| | /  |/ / /| |/ / __ / /
  / /| / /_/ /___/ / ___ |/ /|  / ___ / /_/ // /
 /_/ |_\____//____/_/  |_/_/ |_/_/  |_\____/___/

KUSANAGI-DOCKER CLI Subcommand inforamtion
Manual : http://en.kusanagi.tokyo/document/command/
---------------------
- help -
# kusanagi-docker [-h | --help | help]
show this snippet.
# kusanagi-docker [-V|--version]
show this version
---------------------
- create/remove target -
provision [options] --fqdn domainname target(like kusanagi.tokyo)
    [--wp|--wordpress|--WordPress [WPOPTION]|
    WPOPTION:
         --wplang lang(like en_US, ja)]
         [--admin-user admin] [--admin-pass pass] [--admin-email email]
         [--wp-title title] [--kusanagi-pass pass] [--noftp|--no-ftp] |
     --lamp|--c5|--concrete5|--concrete|
     --drupal|--drupal10|--drupal11]
    [--nginx|--httpd]
    [--nginx1.28|--nginx128|
     --nginx1.29|--nginx129|--nginx=version]
    [--http-port port][--tls-port port]
    [--php8.2|--php82|
     --php8.3|--php83|
     --php8.3|--php84|
     --php8.5|--php85|--php=version]
    [--mariadb10.6|--mariadb106|
     --mariadb10.11|--mariadb1011|
     --mariadb11.4|--mariadb114]
     --mariadb11.8|--mariadb118
    [--dbhost host]
    [--dbport port]
    [--dbrootpass pasword
    [--dbname dbname]
    [--dbuser username]
    [--dbpass password]
remove [-y] [target]
- configuration (runs on target dir) -
ssl [options]
    [--cert file --key file]
    [--redirect|--noredirect]
    [--hsts [on|off]]
    [--oscp [on|off]]
    [--ct [on|off]]
    [--help|help]
config command
    bcache [on|off]
    fcache [on|off]
    pull
    push
    dbdump [file]
    dbrestore [file]
    backup
    restore
    [--help|help]
wp [wpcli commands]
import/export
---------------------
- status (runs on target dir) -
start|stop|restart|status
----------------------
```

The main subcommands are as follows.

- provision
  Create the KUSANAGI RoD environment
- remove
  Remove the KUSANAGI RoD environment
- ssl
  Change the SSL-related settings of KUSANAGI RoD
- config
  Change the settings for KUSANAGI RoD
- wp
  Execute the WordPress CLI commands (WordPress only).
- import/export
  Import/export the files and DB information configured on Docker to the local directory
- start/stop/restart
  Start/stop/restart the KUSANAGI RoD environment
- status
  Check the status of the KUSANAGI RoD environment



## provision

The provision subcommand creates a directory under the current directory with the target name specified at the end, and creates the environment for KUSANAGI RoD.



### Options for the provison subcommand

The options for the provision subcommand are as follows.

| Option                                    | Environment variable             | Description                                                  |
| ----------------------------------------- | -------------------------------- | ------------------------------------------------------------ |
| --fqdn  Domain.Name(Required)             | FQDN                             | Specify the domain name of the site to be created.           |
| --wp/--wordpress/--WordPress              | APP=wp                           | Creates the WordPress environment. If you do not specify the environment variable APP or set --c5/ --lamp/ --drupal, etc., this option will be set. |
| --wplang lang                             | WP_LANG                          | Specify only one language for WordPress. If not specified, the language will be en_US. |
| --admin-user admin                        | ADMIN_USER                       | Specify the WordPress administrator user name. If not specified, it will be a random string. |
| --admin-pass pass                         | ADMIN_PASS                       | Specify the administrator password for WordPress. If not specified, it will be a random string. |
| --admin-email email                       | ADMIN_EMAIL                      | Specify the administrator's email address of WordPress. If not specified, it will be $ADMIN_USER@$FQDN. |
| --wp-title title                          | WP_TITLE                         | Specify the title of WordPress. If not specified, it will be "WordPress". |
| --kusanagi-pass pass                      | KUSANAGI_PASS                    | Specify the password of the kusanagi user used for updating with WordPress. If not specified, it will be a random string. |
| --noftp/--no-ftp                          |                                  | Do not use ftp for updating in WordPress.                    |
| --c5/--concrete5/--concrete               | APP=c5                           | Build the Concreate CMS environment. this use only php74 or php80. |
| --lamp/--LAMP                             | APP=lamp                         | Build a LAMP environment.                                    |
| --drupal10/--drupal                       | APP=drupal<br />DRUPAL_VERSION=10 | Build a drupal 10 environment.                                  |
| --drupal11                                | APP=drupal<br />DRUPAL_VERSION=11 | Build a drupal 11 environment.                                 |
| --httpd                                   |                                  | Use httpd (Apache 2.4). Cannot be specified at the same time as the --nginx option. |
| --nginx                                   |                                  | Use nginx. Cannot be specified at the same time as the --httpd option. If not specified, nginx will be used. |
| --nginx1.28/--nginx128                    |                                  | When using nginx, kusanagi-nginx:1.28.x is used.             |
| --nginx1.29/--nginx129                    |                                  | When nginx is used, kusanagi-nginx:1.29.x is used. When not specified, kusanagi-nginx:1.29.x is used. |
| --nginx=versions                          |                                  | When using nginx, you can use any version published on Docker Hub. Versions prior to 1.25 can be specified, but are not already updated, so use at your own risk. |
| --http-port num                           | HTTP_PORT                        | Specifies the http port number to be port-forwarded to the host. If not specified, 80 will be specified. If you select a port that is already in use, the build will fail. |
| --tls-port num                            | HTTP_TLS_PORT                    | Specifies the https port number to be port-forwarded to the host. If not specified, 443 will be specified. If you select a port that is already in use, the build will fail. |
| --php8.5/--php85                          |                                  | Use kusanagi-php:8.5.x. WordPress versions prior to 6.9 are not supported.|
| --php8.4/--php84                          |                                  | Use kusanagi-php:8.4.x.                                      |
| --php8.3/--php83                          |                                  | Use kusanagi-php:8.3.x. If php version not specified, kusanagi-php:8.3.x will be used. |
| --php8.2/--php82                          |                                  | Use kusanagi-php:8.2.x.                                      |
| --php=version                             |                                  | Use any version of PHP that is available on DockerHub.       |
| --mariadb11.8/--mariadb118                |                                  | Use mariadb:11.8.x-noble as the DB.                         |
| --mariadb11.4/--mariadb114                |                                  | Use mariadb:11.4.x-noble as the DB.                         |
| --mariadb10.11/--mariadb1011              |                                  | Use mariadb:10.11.x-jammy as the DB.                         |
| --mariadb10.6/--mariadb106                |                                  | Use mariadb:10.6.x-focal as the DB. When not specified, mariadb:10.6.x-focal is used. |
| --dbhost host                             | DBHOST                           | Specifies the DB host name to connect to. If not specified, localhost is used. |
| --dbport port                             | DBPORT                           | Specifies the DB port nnumber to connect to. If not specified, 3306 is used. |
| --dbrootpass pass                         | DB_ROOTPASS                      | Specifies the root password of the DB host to connect to. If not specified, it will be a random string. |
| --dbname name                             | DBNAME                           | Specify the DB name to connect. If not specified, it will be a random string. |
| --dbuser user                             | DBUSER                           | Specifies the DB user name to connect to. If not specified, it will be a random string. |
| --dbpass pass                             | DBPASS                           | Specify the DB password to connect. If not specified, it will be a random string. |

- Options can be specified in the form --option value or --option=value.
- The order of precedence for option specification is: option specification, environment variable specification, and default value.
- If you specify a DBHOST other than localhost and the DB to be used has not been created, you need to specify DB_ROOTPASS correctly.
- If a DBHOST other than localhost is specified and the DB to be used is created, DBNAME/DBUSER/DBPASS must be specified correctly.

### Target Directory

If the provision succeeds, the following files and directories will be created in the target directory.

| File and directory name | Description                                                  |
| ----------------------- | ------------------------------------------------------------ |
| .kusanagi.\*            | Describes the environment variables to be used by docker-compose |
| docker-compose.yml      | docker-compose configuration file                            |
| contents                | Copy of the content directory created on Docker              |
| .git                    | A directory for Git                                          |

After the revision is finished, copy the files on Docker generated by the revision under the contents directory, and they will be Git-registered and manageable.



### Docker container to be created

After provisioning, the following Docker container will be launched.

| Name    | Description                                                  |
| ------- | ------------------------------------------------------------ |
| httpd   | The httpd container performs web services by port-forwarding HTTP/TLS ports from the host's network through the httpd bridge. httpd runs in the application directory in the kusanagi volume as the root directory as the root directory. |
| php     | It runs PHP-FPM and communicates with the httpd container by sharing the httpd network. The application is placed on the kusanagi volume, and the DB is connected to using a socket file on the DB volume. <br />The php container is equipped with the ssmtp command, which enables SMTP forwarding to external servers. |
| db      | MariaDB or PostgreSQL can be used. It is not created when using an external DB server. db uses a DB volume to place DB tables, etc., and communicates with php via a socket file. |
| config  | It is usually stopped, but it is started when kusanagi-docker config is used. <br />The kusanagi-docker config command manipulates the kusanagi and db volumes for application deployment, backup and restore. <br />When building WordPress, wpcli images are used to install and uninstall WorPress plugins, themes, languages, etc. |
| ftp     | Runs only when provisioned by WordPress. ftp communication from the php container to update WordPress core, plugins, and themes via the WordPress web page. |
| certbot | Obtain an SSL certificate from let's encrypt (we are currently experimenting with this and have not released instructions for use). |



![KUSANAGI RoD Image](RoD.png)



The docker-compose.yml file created after running provision contains only the minimum description.
If you want to change the logging method, use shared storage, swarm, etc., please modify docker-compose.yml to handle it. Also, docker-compose can be used to perform operations such as start/stop/ps/run/exec.



### Other environment variables

There are some items that can only be set by environment variables at provision runtime. These environment variables will be written in .kusanagi.\*.

| Environment variable  | Default value  | Description                                                  |
| --------------------- | -------------- | ------------------------------------------------------------ |
| DOCUMENTROOT          | DocumentRoot   | Specify the name of the application directory to be created under /home/kusanagi/$PROFILE, which is **public** for concrete5. |
| NO_USE_FCACHE         | 1              | Specifies whether or not to use FCACHE. Specify 1 if it is not used. This option is ignored when using httpd. |
| NO_USE_BCACHE         | 1              | Specifies whether or not to use BCACHE. Set this to 1 if not used. This option will be ignored except when using WordPress. |
| USE_SSL_CT            | off            | Specifies whether to enable CT (Certificate Transparency) for SSL, which can be on or off.USE_SSL_CT cannot be specified if SSL self-certificate is used. |
| USE_SSL_OSCP          | off            | Specifies whether to enable OCSP (Online Certificate Status Protocol).USE_SSL_OSCP cannot be specified when SSL self-certificate is used. |
| OSCP_RESOLV           |                | Specifies the DNS when OSCP is used. If not specified, 8.8.4.4 and 8.8.8.8 will be used. |
| NO_USE_NAXSI          | 1              | Specifies whether or not to use NAXSI. Set to 1 if not used. |
| NO_SSL_REDIRECT       | 1              | Specifies whether or not to redirect to the TLS port. Specify 1 if not used.。 |
| EXPIRE_DAYS           | 90             | Specify the number of days for the expires header in nginx.  |
| PHP_PORT              | 127.0.0.1:9000 | Specifies the LISTEN port for PHP-FPM.                       |
| PHP_MAX_CHILDLEN      | 500            | Specifies the number of child processes that may be processed simultaneously by PHP-FPM. |
| PHP_START_SERVERS     | 10             | Specifies the number of child processes spawned when a PHP-FPM process is started. |
| PHP_MIN_SPARE_SERVERS | 5              | Specifies the minimum number of waiting child processes of PHP-FPM. |
| PHP_MAX_SPARE_SERVERS | 10             | Specifies the maximum number of waiting child processes of PHP-FPM. |
| PHP_MAX_REQUESTS      | 500            | Specifies the number of requests that each child process of PHP-FPM will perform before it restarts. |
| MAILSERVER            | localhost      | Specifies the destination mail server for sending mail from the PHP container. |
| MAILDOMAIN            |                | Specifies the domain name for sending mails from the PHP container. |
| MAILUSER              |                | Specifies the user name for sending mails from the PHP container. |
| MAILPASS              |                | Specify the password to use for SMTP-AUTH when sending mails from the PHP container. |
| MAILAUTH              |                | Specifies the SMTP-AUTH method for sending mails from the PHP container. |



## remove

Delete the RoD environment created in provision.
In this case, stop/delete the created Docker containers, volumes, and bridges, and delete the target directory.
This command needs to work on the parent directory of the target directory.



## ssl

Change the settings around SSL in the RoD environment.

This command needs to work on the target directory.

| Option                           | Description                                                  | Default Value             |
| -------------------------------- | ------------------------------------------------------------ | ------------------------- |
| --cert file --key file           | Use the SSL certificate and key set as the SSL key.          | Self-Certificate SSL file |
| --redirect \|<br /> --noredirect | Specifies whether to redirect to SSL.                        | <none>                    |
| --hsts on\|off                   | Specifies whether or not to turn on hsts (HTTP Strict Transport Security) | off                       |
| --oscp on\|off                   | Specifies whether to turn on OSCP (Online Certificate Status Protocol). | off                       |
| --ct on\|off                     | Specifies whether CT (Certificate Transparency) is turned on or not | off                       |

Note: The options --hsts, --oscp, and --ct cannot be specified if a self-SSL certificate is specified.



## config

The config command is used to configure the RoD environment and to backup/restore information.

This command needs to work on the target directory.

| Sub command      | Description                                                  |
| ---------------- | ------------------------------------------------------------ |
| bcache on \| off | Set bcache on/off (default value is off).                    |
| fcache on \| off | Set fcache on/off (default value is off, enabled only when using nginx). |
| pull             | Download the kusanagi volume information under contens.      |
| push             | Upload the following contents of contens to the KUSANAGI volume. |
| dbdump [file]    | Output DB dump information to a data file on the target directory (dbdump when not specified). |
| dbrestore [file] | Restore the data file on the target directory (or dbdump when not specified) to the DB. |
| backup           | Perform pull and dbdump at the same time.                    |
| restore          | Perform push and dbrestore at the same time.                 |

Running pull and dbdump will not automatically commit to Git. Please use the git command to manage them as appropriate.



## wp

Available only when using WordPress. wpcli commands can be specified to operate on WordPress.

This command must be running on the target directory.



## import/export

It works the same as kusanagi-docker config backup/restore.

This command needs to work on the target directory.



## start/stop/restart/status

start/stop/restart starts, stops, and restarts Docker containers in the RoD environment.
status can be used to check the status of Docker containers.
You can also specify a container name such as httpd/php/db/ftp to start/stop/restart a specific container.

This command needs to run on the target directory.

These commands are wrappers for the docker-compose command, so you can use docker-compose on the target directory.



## Docker images to be used

Images for KUSANAGI RoD are already available on [DockerHub](https://hub.docker.com).
All images are based on alpine10, but this may change in the future.
To use the recommended version (the current latest version), please run $HOME/.kusanagi/update_version periodically.

| Name                                                         | Description                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [kusanagi-nginx](https://hub.docker.com/r/primestrategy/kusanagi-nginx) | nginx image (recommended is the latest version of mainline). |
| [kusanagi-httpd](https://hub.docker.com/r/primestrategy/kusanagi-httpd) | httpd(Apache 2.4) image.                                     |
| [kusanagi-php](https://hub.docker.com/r/primestrategy/kusanagi-php) | PHP-FPM image (recommended is the latest version of 8.3)     |
| [kusanagi-config](https://hub.docker.com/r/primestrategy/kusanagi-config) | Image for kusanagi config command                            |
| [wordpress:cli](https://hub.docker.com/_/wordpress)          | Config command image for building WordPress                  |
| [kusanagi-ftpd](https://hub.docker.com/r/primestrategy/kusanagi-ftpd) | Container image to run vsftpd, used only when building WordPress. |
| [mariadb](https://hub.docker.com/_/mariadb)                  | MariaDB image                                                  |


