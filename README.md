# maira-helm-chart

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

Syntax: ./install.sh -t <temporal chart path> -k <key file> -c <cert file> |-e <env file>|
options:
t <temporal chart path>   Temporal helm chart path
e <env file>              env file path to pass environment variables
k <key file>              TLS key file path
c <cert file>             TLS certificate file path
h                         Print this help

Example: ./install.sh -t /home/user/temporal-helm-chart -k key.pem -c cert.pem -e sample.env

$ ./install.sh -t ../../temporal-helm-charts -k key.pem -c cert.pem -e sample.env
```
