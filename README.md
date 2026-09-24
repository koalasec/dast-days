# dast-days

[[_TOC_]]

Aiming to build a true local and ci agnostic task capability to dast scan a zarf package in uds-core utilizing owasp zap.

Will need a uds `k3d-core-slim-dev` deployment - potentially one without keycloak for speed / simplicity.

## Prereqs
- `uds-cli`
- `docker`
- `k3d`

- a zarf package with an included manifest that exposes a service.
  - example package.yaml manifest
  ```
    apiVersion: uds.dev/v1alpha1
    kind: Package
    metadata:
    name: dos-games
    namespace: dos-games
    spec:
    network:
        expose:
        - service: game
            podLabels:
            app: game
            host: game
            gateway: tenant
            port: 8000

        allow:
        - direction: Egress
            selector:
            app.kubernetes.io/name: game
            remoteGenerated: Anywhere
            port: 443
    ```

From nothing, 
- deploy uds-core-slim (eventually w/o keycloak)
  - TODO build uds-ozempic (slim-dev without keycloak, auth too much for dash days dasting)
- deploy an app from a zarf package
- run a task that uses a docker in docker based image to run the latest owasp-zap image against the deployed apps <app>.uds.dev end point
- collect dast scan results

## Features

### ZAP Scan a zarf package
Deploy and Scan a local zarf package
`uds run dast-scan-package --set ZARF_PKG_PATH=<path-to-pkg>`

Deploy and scan a zarf package from OCI
`uds run dast-scan-package --set ZARF_PKG_PATH=oci://<oci_path>`


Given: a zarf yaml and the desire to dast scan the app it will deploy
When I run: `uds run dast-scan-package --set ZARF_PKG_PATH="<path-to-pkg>"`
Then the UDS task will:
  - [x] verify that a uds cluster is initialized or not
    - deploys `k3d-core-slim-dev:0.26.0` if not
  - [ ] create my zarf package (if not an oci ref)
  - [x] deploy the package
  - [x] check if it exposes an end point
  - [x] dast scan the endpont(s)
  - [x] store dast results as html and json output `<package_name>.<app_name>.domain-report.html` and `<package_name>.<app_name>.domain-report.json`

### ZAP Scan every exposed endpoint in your cluster
If you just want to scan any know endpoint in your cluster run: 
`uds run dast-scan-everything`

Your local directory will have 3 types of formatted ZAP reports for each endpoint:
- `html` - `${APP_ENDPOINT}.report.html`
- `json` - `${APP_ENDPOINT}.report.json`
- `markdown` - `${APP_ENDPOINT}.report.md`

:info:
A default uds core slim dev cluster will have Keycloak exposed on 2 endpoints `keycloak.admin.uds.dev` and `keycloak.sso.uds.dev`.

Given I want to dast scan any exposed endpoints on my cluster
When I run `uds run dast-master`
the UDS task will:
  - verify that a uds cluster is initialized or not
    - deploys `k3d-core-slim-dev:0.26.0` if not
  - get list of all namespaces
  - check for packages in all namespaces
  - for list of packages get exposed endpoints
  - for exposed end point DAST scan that B
  - store dast results in `<package_name>.<app_name>.domain-report.html` and `<package_name>.<app_name>.domain-report.json`




<details> <summary>Click to expand unfinished CI notes</summary> 

## Building Docker in Docker image to zap scan in ci...
`docker build -t ephemeral-dast .`

In a ci environment we'll want to likely use a docker in docker base image. We made a `Dockerfile` based off the `docker:dind` image so that we could have `uds` and some other tools their image doesn't include installed to run our tasks. 


### DAST Task

`docker run --privileged -it --rm --name ephem-dind ephemeral-dast:latest sleep 10 && docker run --network="host" -t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py -t https://podinfo.uds.dev`

Get results from the dind container by mounting local volume:
`docker run --privileged -it --rm --name ephem-dind ephem-dind:latest sleep 10 && docker run --network="host" -v $(pwd):/zap/wrk -t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py -t https://podinfo.uds.dev -r report.html`

# DAST via Docker in docker locally

## Magical command TLDR
`docker run --privileged -it --rm --name ephem-dind ephemeral-dast:latest sleep 10 && docker run --network="host" -t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py -t https://podinfo.uds.dev`

## Deploy podinfo
Using the [podinfo repo](https://gitlab.devops.nswccd.navy.mil/project-blue/certificate-to-ship/example-projects/podinfo.git) `@feature/dast-scan`

create for mac book - `zarf package create . -a arm64`
for ci env - `zarf package create . -a amd64`

deploy pod info with the local DOMAIN set `zarf package deploy zarf-package-podinfo-arm64-6.3.5.tar.zst --set=DOMAIN=uds.dev --confirm`

### when in doubt just sleep it out
Apparently not detaching the docker run for the `dind` image doesn't fully let docker initialize properly, BUT by sleeping it works like a champ locally...

To avoid having to run a `-d` detached image you can just sleep the dind container run and then you wont have to `docker kill <image-id>` the detached container and `docker rmi <your-image>`

```docker run --privileged -it --rm --name ephem-dind ephemeral-dast:latest sleep 30 && /bin/sh  ```

</details>

# Security Pipeline 

## Complete Security Pipeline on your local computer
the objective of this task is to give you an example of a complete cicd pipeline for security scans that can be run locally

The security pipeline task uses only free and open source tools that do not require you to create an account.

We also output all reports in json format to give you artifacts to play with.

We intentionally omit various other jobs like formatters and linters as we only care about security tests

### Pre-reqs
You will require the following pre-reqs:
  - jq
  - docker
  - kubectl
  - a local kubernetes cluster (we've includes example apps in the project)
  - trivy
  - opengrep
  - conftest

### How to
In order to run the security pipeline locally make sure you have your cluster running and then run:
```uds run security-pipeline```

 