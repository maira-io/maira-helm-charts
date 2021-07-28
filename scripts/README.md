This script will install temporal with separate cassandra cluster.
Currently cassandra cluster is deployed in a namespace `cass-operator` and temporal is installed in `temporal` namespace.

## Requirements:
* Install and setup `kubectl`
* Install `helm` commandline client
* Install `uuidgen` command - `apt install uuid-runtime`
* Install `yq` to manipulate yaml - `pip3 install yq`

## How to run this script?
This script has default values that may work for minikube.
You may have to update below variables by creating an env file with values to be overridden
source that env file and run this script.
This script must be executed under the directory where temporal helm chart repository is checked out

## TODO/issues
* Elasticsearch have to update vm.max_map_count sysctl value to the required minimum of 262144. But without privileged containers you will not be able to do it from within helmchart. 
  * Also gcp with autopilot mode doesnt support privileged container, also they dont give access to underlying nodes. This could be a problem to use autopilot mode with Elasticsearch.

### Example:
```
$ git checkout https://github.com/maira-io/temporal-helm-charts.git temporal-helm-charts
$ cd temporal-helm-charts/
# You may update sample.env with relevant details
$ ../maira-helm-charts/scripts/install.sh ../maira-helm-charts/scripts/sample.env
```

## Env variables that may be overridden
Default variables shall work for minikube, which may be overridden to work with other environments. See [sample.env](sample.env) file for reference.
| Variable Name | Description |
| :--- | :--- |
| CASSANDRA_CLUSTER_NAME | cassandra cluster name, default `cluster1` |
| CASSANDRA_STORAGE_CLASS | Cassandra storage class name, default `standard`
| CASSANDRA_STORAGE_SIZE |  Cassandra storage size, default `500Mi`
| CASSANDRA_DC_NAME  | Cassandra datacenter name, default `dc1`
| CASSANDRA_REPLICATION_FACTOR | Cassandra replication factor, default `1`
| CASSANDRA_CLUSTER_SIZE | Cassandra cluster size, default `1`
| TEMPORAL_RELEASE_NAME | Helm release name - only need to check if you run multiple temporal releases, default `t1`|

## Reference
* https://github.com/temporalio/samples-go/tree/master/child-workflow-continue-as-new
