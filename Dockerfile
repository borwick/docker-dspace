FROM tomcat:8-jre7

# See https://wiki.duraspace.org/display/DSDOC5x/Installing+DSpace#InstallingDSpace-PrerequisiteSoftware

# Needs Maven 3.0.5+
# Needs Ant
# Needs PostgreSQL 9+

RUN apt-get update && apt-get install -y maven \
    && apt-get install -y ant \
    && apt-get install -y openjdk-7-jdk \
    && apt-get install -y rsync \
    && apt-get install -y bzip2 \
    && apt-get install -y postgresql-client \
    && rm -r /var/lib/apt/lists/*

RUN useradd -m dspace

ENV DSPACE_VERSION 5.0
ENV DSPACE_SHA1 752afe864826da5536545f37938cf7885a3aa960

RUN curl -o dspace.tar.bz2 -SL http://downloads.sourceforge.net/project/dspace/DSpace%20Stable/${DSPACE_VERSION}/dspace-${DSPACE_VERSION}-src-release.tar.bz2 \
    && echo "$DSPACE_SHA1 *dspace.tar.bz2" | sha1sum -c - \
    && tar xjvf dspace.tar.bz2 -C /usr/src \
    && mv /usr/src/dspace-${DSPACE_VERSION}-src-release /usr/src/dspace-src-release \
    && rm dspace.tar.bz2

# TODO should these files have reloadable="False" ?
ADD tomcat-config/* /usr/local/tomcat/conf/Catalina/localhost/

COPY docker-entrypoint.sh /entrypoint.sh

VOLUME /var/www/dspace
# USER dspace

ENTRYPOINT ["/entrypoint.sh"]
CMD ["catalina.sh", "run"]
# CMD /bin/bash
