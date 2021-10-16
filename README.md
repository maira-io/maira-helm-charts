# maira-helm-chart

## Requirements:
* Install and setup `kubectl`
* Install `helm` commandline client
* Install `uuidgen` command
* Install `yq` to manipulate yaml - `pip3 install yq`

## How to install maira services in kubernetes

1.Fetch temporal helm chart from https://github.com/temporalio/helm-charts
```bash
$ git clone https://github.com/temporalio/helm-charts.git  temporal-helm-charts
```
2. Fetch maira helm chart from https://github.com/maira-io/maira-helm-charts
```bash
$ git clone https://github.com/maira-io/maira-helm-charts.git
```
2. Optionally create/update env file with all custom environment variables defined in the install.sh. Refer [sample.env](scripts/sample.env)
3. Run [install.sh](scripts/install.sh)
```bash
$ cd maira-helm-charts/scripts
$ ./install.sh -h
Install maira services and dependencies using helm

Syntax: ./install.sh -t <temporal chart path> |-e <env file>|
options:
t <temporal chart path>   Temporal helm chart path
e <env file>              env file path to pass environment variables
h                         Print this help

Example: ./install.sh -t /home/user/temporal-helm-chart -e sample.env

$ ./install.sh -t ../../temporal-helm-charts -e sample.env
```
## Set external secrets
We support passing external secrets either by passing them as environment variable,
or creating secrets in GCP secret manager and pass the secret name as environment variable.

### Setting TLS key and cert
There are two ways to do this.

1. Set as environment variables
  Create below environment variables with path of key and cert file and run install.sh
  ```
  TLS_KEY_FILE="/tmp/server.key"
  TLS_CERT_FILE="/tmp/server.crt"
  ```
2. Use gcp secret manager
  1. Create two GCP secret manager secrets - one for TLS key and other for certificate. Refer [GCP Documentation](https://cloud.google.com/secret-manager/docs/creating-and-accessing-secrets#secretmanager-add-secret-version-console)
  Note that no need to provide any extra permissions, install script will set appropriate permissions for kubernetes pods to access the secret.
  2. Set below environments and run install.sh with appropriate parameters
    ```
    TLS_CERT_SECRET_NAME="maira-tls-cert"
    TLS_KEY_SECRET_NAME="maira-tls-key"
    ```
### Setting mongodb url
1. Set as environment variables
  Create below environment variables and run install.sh
  ```
  MONGODB_HOST='cluster1.mongodb.net'
  MONGODB_USERNAME='maira'
  MONGODB_PASSWORD='password'
  ```
2. Use GCP secret manager
  1. Create secret in GCP secret manager for whole db url
     Note that one have to create whole db url in the secret
     something like `mongodb+srv://username:password@host/generated?retryWrites=true&w=majority`
  2. set environment name `MONGODB_PASSWORD_SECRET_NAME` with the secret name
