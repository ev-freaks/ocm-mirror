OCM Mirror
====

Abstract
----

Docker Environment to host an OCM Mirror. See https://github.com/openchargemap/ocm-system/issues/148 and https://github.com/openchargemap/ocm-system/tree/master/API/OCM.Net/OCM.API.Worker.

This also implements an additional `haproxy` container to add gzip compression and logging.

Instructions
----

Make sure the docker subsysten is up and running. Then just do a docker-compose up:

```bash
docker-compose up -d
```

Initially, this will also build the docker image.

### Re-Build the Docker Image, Build Args

To rebuild the docker image, do:

```bash
docker-compose build
```

To use a different repo url and branch for the "ocm-system" repository you can leverage the existing `REPO_URL` and `REPO_BRANCH` docker build args:

```bash
docker-compose build \
  --build-arg REPO_URL=https://github.com/ev-freaks/ocm-system.git \
  --build-arg REPO_BRANCH=testing
```

OR, e.g.:

```bash
docker-compose build \
  --build-arg DOTNET_TAG=5.0-alpine
```

To use the alpine flavour of the .net docker images (smaller footprint ~ 50%)

Then you should be able to perform OCM API Requests, e.g. using:

```bash
curl http://localhost:8080/api/v3/poi
```

Author
----

* Remus Lazar (remus at ev-freaks.com)