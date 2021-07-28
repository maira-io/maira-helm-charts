# maira-helm-chart

## How to install
1. Deploy temporal
  - Follow [install README](scripts/README.md)
2. Deploy maira-helm-chart using below command
```bash
# t1-temporal-frontend.temporal is the service name of temporal frontend '.' temporal namespace.
$ helm install -n maira t1 --set temporal.host=t1-temporal-frontend.temporal .
```
