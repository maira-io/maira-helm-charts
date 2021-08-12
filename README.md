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
$ ./install.sh -t ../../temporal-helm-charts -e sample.env
```
