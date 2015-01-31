#!/bin/bash
set -e
set -v

# --- SET VARIABLES
if [ -z "$POSTGRESQL_PORT_5432_TCP_PORT" ]; then
	echo >&2 'error: missing POSTGRESQL_PORT_5432_TCP_ADDR environment variable'
	echo >&2 '  Did you forget to --link some_postgresql_container:postgresql ?'
	exit 1
fi

# if we're linked to Postgresql, and we're using the root user, and our linked
# container has a default "root" password set up and passed through... :)
: ${DSPACE_DB_USER:=postgres}
if [ "$DSPACE_DB_USER" = 'postgres' ]; then
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


# --- PREPARE DB
# create user and DB if DB doesn't exist:
if ! echo '' | PGPASSWORD=$POSTGRESQL_ENV_POSTGRES_PASSWORD psql -h "$POSTGRESQL_PORT_5432_TCP_ADDR" -p "$POSTGRES_PORT_5432_TCP_PORT" -U $DSPACE_DB_USER $DSPACE_DB_NAME
then
    PGPASSWORD=$POSTGRESQL_ENV_POSTGRES_PASSWORD createuser -h "$POSTGRESQL_PORT_5432_TCP_ADDR" -p "$POSTGRESQL_PORT_5432_TCP_PORT" -U postgres dspace
    PGPASSWORD=$POSTGRESQL_ENV_POSTGRES_PASSWORD createdb  -h "$POSTGRESQL_PORT_5432_TCP_ADDR" -p "$POSTGRESQL_PORT_5432_TCP_PORT" -U postgres --owner=dspace --encoding=UNICODE dspace
fi

# === BUILD
cd /usr/src/dspace-src-release/

# --- UPDATE CONFIG
set_config() {
    key="$1"
    value="$2"
    sed_escaped_value="$(echo "$value" | sed 's/[\/&]/\\&/g')"

    sed -ri "s/^$key\s*=.*/$key=$sed_escaped_value/" build.properties
}

set_config 'dspace.install.dir' '/var/www/dspace'
set_config 'dspace.hostname' $HOSTNAME
set_config 'db.url' "jdbc:postgresql://${POSTGRESQL_PORT_5432_TCP_ADDR}:${POSTGRESQL_PORT_5432_TCP_PORT}/$DSPACE_DB_NAME"
set_config 'db.username' $DSPACE_DB_USER
set_config 'db.password' $DSPACE_DB_PASSWORD

mvn package
( cd ./dspace/target/dspace-installer && ant fresh_install )
	

# TODO handle Dspace upgrades magically

# solr.server - complete URL of the Solr server. DSpace makes use of Solr for indexing purposes. # mail.server - fully-qualified domain name of your outgoing mail server.
# mail.from.address - the "From:" address to put on email sent by DSpace.
# mail.feedback.recipient - mailbox for feedback mail.
# mail.admin - mailbox for DSpace site administrator.
# mail.alert.recipient - mailbox for server errors/alerts (not essential but very useful!)
# mail.registration.notify- mailbox for emails when new users register (optional)


cd /var/www/dspace
exec "$@"
