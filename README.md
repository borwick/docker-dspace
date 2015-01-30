This is modified from `docker-omeka`. I tried to use the official
Docker Dockerfiles as a reference.

Commands
---

    make

    docker run --name dspace-postgresql \
      -e POSTGRES_PASSWORD=mysecretpassword -d postgres

    docker run --name dspace-app \
      --link dspace-postgresql:postgresql \
      -p 8080:8080 \
      -d dspace

Or for review:

    docker exec -t -i dspace-app /bin/bash

To reset the app:

    docker stop dspace-app && docker rm dspace-app
