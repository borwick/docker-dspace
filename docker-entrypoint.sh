#!/bin/bash
set -e

if [ -z "$POSTGRESQL_PORT_5432_TCP_ADDR" ]; then
	echo >&2 'error: missing POSTGRESQL_PORT_5432_TCP_ADDR environment variable'
	echo >&2 '  Did you forget to --link some_postgresql_container:postgresql ?'
	exit 1
fi

# if we're linked to Postgresql, and we're using the root user, and our linked
# container has a default "root" password set up and passed through... :)
: ${DSPACE_DB_USER:=root}
if [ "$DSPACE_DB_USER" = 'root' ]; then
	: ${DSPACE_DB_PASSWORD:=$POSTGRESQL_ENV_POSTGRES_PASSWORD}
fi
: ${DSPACE_DB_NAME:=dspace}

if [ -z "$DSPACE_DB_PASSWORD" ]; then
	echo >&2 'error: missing required DSPACE_DB_PASSWORD environment variable'
	echo >&2 '  Did you forget to -e DSPACE_DB_PASSWORD=... ?'
	echo >&2
	echo >&2 '  (Also of interest might be DSPACE_DB_USER and DSPACE_DB_NAME.)'
	exit 1
fi

# create user and DB if DB doesn't exist:
if \! echo '' | PGPASSWORD=$POSTGRESQL_ENV_POSTGRES_PASSWORD psql -h "$POSTGRES_PORT_5432_TCP_ADDR" -p "$POSTGRES_PORT_5432_TCP_PORT" -U postgres $DSPACE_DB_NAME
then
    PGPASSWORD=$POSTGRESQL_ENV_POSTGRES_PASSWORD createuser -h "$POSTGRES_PORT_5432_TCP_ADDR" -p "$POSTGRES_PORT_5432_TCP_PORT" -U postgres dspace
    PGPASSWORD=$POSTGRESQL_ENV_POSTGRES_PASSWORD createdb  -h "$POSTGRES_PORT_5432_TCP_ADDR" -p "$POSTGRES_PORT_5432_TCP_PORT" -U postgres --owner=dspace --encoding=UNICODE dspace
fi

# FIXME change build.properties here

# FIXME change to test for existing DSpace instance
if true; then
	echo >&2 "Dspace not found in $(pwd) - copying now..."
	if [ "$(ls -A)" ]; then
		echo >&2 "WARNING: $(pwd) is not empty - press Ctrl+C now if this is an error!"
		( set -x; ls -A; sleep 10 )
	fi

	# Right now this builds from source.
	rsync --archive --one-file-system --quiet /usr/src/dspace-src-release/ ./
	
	mvn package
	ant fresh_install
	
	echo >&2 "Complete! Dspace has been successfully copied to $(pwd)"
fi

# TODO handle Dspace upgrades magically

DSPACE_DB_HOST='postgresql'

set_config 'host' "$DSPACE_DB_HOST"
set_config 'username' "$DSPACE_DB_USER"
set_config 'password' "$DSPACE_DB_PASSWORD"
set_config 'dbname' "$DSPACE_DB_NAME"

# FIXME change dspace.cfg:
# dspace.install.dir - must be set to the [dspace] (installation) directory  (On Windows be sure to use forward slashes for the directory path!  For example: "C:/dspace" is a valid path for Windows.)
# dspace.hostname - fully-qualified domain name of web server.
# dspace.baseUrl - complete URL of this server's DSpace home page but without any context eg. /xmlui, /oai, etc.
# dspace.name - "Proper" name of your server, e.g. "My Digital Library".
# solr.server - complete URL of the Solr server. DSpace makes use of Solr for indexing purposes.  
# default.language
# db.driver
# db.url
# db.username - the database username used in the previous step.
# db.password - the database password used in the previous step.
# mail.server - fully-qualified domain name of your outgoing mail server.
# mail.from.address - the "From:" address to put on email sent by DSpace.
# mail.feedback.recipient - mailbox for feedback mail.
# mail.admin - mailbox for DSpace site administrator.
# mail.alert.recipient - mailbox for server errors/alerts (not essential but very useful!)
# mail.registration.notify- mailbox for emails when new users register (optional)


exec "$@"
