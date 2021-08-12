# maira-helm-chart

## How to install maira services in kubernetes
Deploy maira services and all dependencies like temporal using [install.sh](scripts/install.sh)
```bash
# Update sample.env
$ cd scripts
$ ./install.sh -t ../../temporal-helm-charts -e sample.env
```
