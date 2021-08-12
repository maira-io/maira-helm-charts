#!/bin/bash

Help()
{
   # Display Help
   echo "Install maira services and dependencies using helm"
   echo
   echo "Syntax: $0 -t <temporal chart path> |-e <env file>|"
   echo "options:"
   echo "t <temporal chart path>   Temporal helm chart path"
   echo "e <env file>              env file path to pass environment variables"
   echo "h                         Print this help"
   echo

   echo "Example: $0 -t /home/user/temporal-helm-chart -e sample.env"
}

while getopts e:t:h flag
do
    case "${flag}" in
        e) envfile=${OPTARG};;
        t) temporal_chart_path=${OPTARG};;
        h)
          Help
          exit;;
    esac
done

#
set -a
# Optional first argument to this script is an env file which
# may used to override certain variable as mentioned below
if [ -n "$1" ]; then
  source $envfile
fi

## One may set appropriate environment variables to overrride below entries
CLUSTER_NAME=${CLUSTER_NAME}
if [ -z "${CLUSTER_NAME}" ]; then
  echo "ERROR! Please set a unique CLUSTER_NAME environment variable to use for ingress name"
  exit 1
fi
CASSANDRA_CLUSTER_NAME="${CASSANDRA_CLUSTER_NAME:-cluster1}"
CASSANDRA_STORAGE_CLASS="${CASSANDRA_STORAGE_CLASS:-standard}"
CASSANDRA_STORAGE_SIZE="${CASSANDRA_STORAGE_SIZE:-500Mi}"
CASSANDRA_DC_NAME="${CASSANDRA_DC_NAME:-dc1}"
CASSANDRA_REPLICATION_FACTOR="${CASSANDRA_REPLICATION_FACTOR:-1}"
CASSANDRA_CLUSTER_SIZE="${CASSANDRA_CLUSTER_SIZE:-1}"

# Below env vars will be used to limit pod memory/cpu for cassandra PODs
CASSANDRA_POD_MEMORY=${CASSANDRA_POD_MEMORY}
CASSANDRA_POD_CPU=${CASSANDRA_POD_CPU}

RELEASE_NAME="${RELEASE_NAME:-r1}"

########## One will not be able to override below variables
CASSANDRA_ADMIN_USERNAME="cass-superuser"
CASSANDRA_ADMIN_SECRET_NAME="cassandra-${CASSANDRA_CLUSTER_NAME}-admin"

# TODO: Once the operator can monitor multiple namespaces, we can use any namespace,
#   but currently it should be same as cassandra operator namespace
CASSANDRA_NAMESPACE="cass-operator"
CASSANDRA_CLUSTER_MANIFEST="https://raw.githubusercontent.com/k8ssandra/cass-operator/master/operator/example-cassdc-yaml/cassandra-3.11.x/example-cassdc-minimal.yaml"
CASSANDRA_PORT=9042

TEMPORAL_NAMESPACE="temporal"
TEMPORAL_KEYSPACE="temporal"
TEMPORAL_CASSANDRA_SECRET_NAME="temporal-cassandra-secret"
TEMPORAL_CASSANDRA_USERNAME='temporal'
TEMPORAL_CASSANDRA_PASSWORD='' # This will be set later in the code

TEMPORAL_VISIBILITY_KEYSPACE="temporal_visibility"
TEMPORAL_VISIBILITY_CASSANDRA_SECRET_NAME="temporal-visibility-cassandra-secret"
TEMPORAL_VISIBILITY_CASSANDRA_USERNAME='temporal_visibility'
TEMPORAL_VISIBILITY_CASSANDRA_PASSWORD='' # This will be set later in the code

MAIRA_NAMESPACE="maira"
set +a

# https://github.com/k8ssandra/cass-operator
# this will insttall a crd cassandradatacenters.cassandra.datastax.com in default namespace - why?
#      - without this crd, you cannor creeate cassandra datacenter
# TODO: Install operaator tthat caan monitor muliple namespaces - https://medium.com/swlh/watch-multiple-namespaces-with-cass-operator-81d04a5af741
install_cassandra_operator() {
  kubectl -n $CASSANDRA_NAMESPACE apply -f https://raw.githubusercontent.com/k8ssandra/cass-operator/v1.7.1/docs/user/cass-operator-manifests.yaml
}

create_temporal_ns() {
  kubectl get namespace $TEMPORAL_NAMESPACE -o name 2>/dev/null
  if [[ $? -ne 0 ]]; then
    kubectl create namespace $TEMPORAL_NAMESPACE
  fi
}

create_secret() {
  namespace=$1
  secret_name=$2
  username=$3
  # create secret for tempooral cassandra role
  kubectl -n $namespace  get secrets $secret_name -o name &> /dev/null
  if [[ $? -ne 0 ]]; then
    kubectl -n ${namespace} create secret generic $secret_name \
      --from-literal=username=${username} --from-literal=password=$(uuidgen)
  fi
}

install_cassandra_cluster() {
  # create temporal namespace 
  create_temporal_ns
  # create secret for cassandra superuser
  create_secret $CASSANDRA_NAMESPACE $CASSANDRA_ADMIN_SECRET_NAME $CASSANDRA_ADMIN_USERNAME

  export CASSANDRA_ADMIN_PASSWORD=$(kubectl -n $CASSANDRA_NAMESPACE get secret $CASSANDRA_ADMIN_SECRET_NAME -o json | jq -r '.data.password' | base64 --decode)
  # Copy secret to  temporal namespace - secret is local to namespace.
  # TODO: once operator can monitor other namespaces, we may install cassandra also in same namespace
  kubectl -n $TEMPORAL_NAMESPACE  get secrets $CASSANDRA_ADMIN_SECRET_NAME -o name &> /dev/null
  if [[ $? -ne 0 ]]; then
    kubectl -n $CASSANDRA_NAMESPACE get secret $CASSANDRA_ADMIN_SECRET_NAME -o yaml | \
      grep -v "namespace:" |kubectl -n $TEMPORAL_NAMESPACE apply -f -
  fi

  # Add secret name for superuser, update storage class name and size
  # It use yq - install yq using pip install yq
  # You may have to add the install path to $PATH
  yml=$(curl -s ${CASSANDRA_CLUSTER_MANIFEST} | yq -r '
    .spec += {"superuserSecretName": env.CASSANDRA_ADMIN_SECRET_NAME} |
    .spec.storageConfig.cassandraDataVolumeClaimSpec.storageClassName=env.CASSANDRA_STORAGE_CLASS |
    .spec.storageConfig.cassandraDataVolumeClaimSpec.resources.requests.storage=env.CASSANDRA_STORAGE_SIZE |
    .spec.size=(env.CASSANDRA_CLUSTER_SIZE | tonumber) |
    .metadata.name=env.CASSANDRA_DC_NAME
  ')

  if [ -n "$CASSANDRA_POD_MEMORY" ]; then
    yml=$(echo "$yml" | yq -r '
      .spec.resources.requests.memory=env.CASSANDRA_POD_MEMORY |
      .spec.resources.limit.memory=env.CASSANDRA_POD_MEMORY
    ')
  fi

  if [ -n "$CASSANDRA_POD_CPU" ]; then
    yml=$(echo "$yml" | yq -r '
      .spec.resources.requests.cpu=env.CASSANDRA_POD_CPU |
      .spec.resources.limit.cpu=env.CASSANDRA_POD_CPU
    ')
  fi

  echo "$yml" | kubectl -n $CASSANDRA_NAMESPACE apply -f -
  
  echo -n "Waiting for cassandra cluster to come up"
  # Wait till cassandra cluster is up
  until [[ `kubectl -n $CASSANDRA_NAMESPACE get cassdc/${CASSANDRA_DC_NAME} -o "jsonpath={.status.cassandraOperatorProgress}"` == 'Ready' ]]; do
    sleep 5
    echo -n .
  done
  echo
}

create_cassandra_keyspace() {
  name=$1
  replication_factor=$2
  kubectl -n $CASSANDRA_NAMESPACE exec -ti ${CASSANDRA_CLUSTER_NAME}-${CASSANDRA_DC_NAME}-default-sts-0 -c cassandra -- \
    sh -c "cqlsh -u '$CASSANDRA_ADMIN_USERNAME' -p '$CASSANDRA_ADMIN_PASSWORD' --execute \
      \"CREATE KEYSPACE IF NOT EXISTS ${name} with replication={'class': 'SimpleStrategy', 'replication_factor' : ${replication_factor}};\"
    "
}

create_cassandra_role_for_keyspace() {
  username=$1
  password=$2
  keyspace=$3
  kubectl -n $CASSANDRA_NAMESPACE exec -ti ${CASSANDRA_CLUSTER_NAME}-${CASSANDRA_DC_NAME}-default-sts-0  -c cassandra -- sh -c "\
    cqlsh -u '$CASSANDRA_ADMIN_USERNAME' -p '$CASSANDRA_ADMIN_PASSWORD' --execute \
      \"CREATE ROLE IF NOT EXISTS $username WITH PASSWORD = '${password}' AND LOGIN = true;\
      GRANT ALL PERMISSIONS on KEYSPACE $keyspace to ${username};\""
}

create_temporal_keyspaces() {
  # Create tetmporal keyspace
  create_cassandra_keyspace $TEMPORAL_KEYSPACE $CASSANDRA_REPLICATION_FACTOR
  
  create_secret $TEMPORAL_NAMESPACE $TEMPORAL_CASSANDRA_SECRET_NAME  $TEMPORAL_CASSANDRA_USERNAME
  export TEMPORAL_CASSANDRA_PASSWORD=$(kubectl -n $TEMPORAL_NAMESPACE get secret $TEMPORAL_CASSANDRA_SECRET_NAME -o json | jq -r '.data.password' | base64 --decode)

  # Create temporal role with password and grant permission to temporal keyspace
  create_cassandra_role_for_keyspace $TEMPORAL_CASSANDRA_USERNAME $TEMPORAL_CASSANDRA_PASSWORD $TEMPORAL_KEYSPACE

  create_cassandra_keyspace $TEMPORAL_VISIBILITY_KEYSPACE $CASSANDRA_REPLICATION_FACTOR
  
  create_secret $TEMPORAL_NAMESPACE $TEMPORAL_VISIBILITY_CASSANDRA_SECRET_NAME  $TEMPORAL_VISIBILITY_CASSANDRA_USERNAME
  export TEMPORAL_VISIBILITY_CASSANDRA_PASSWORD=$(kubectl -n $TEMPORAL_NAMESPACE get secret $TEMPORAL_VISIBILITY_CASSANDRA_SECRET_NAME -o json | jq -r '.data.password' | base64 --decode)

  # Create temporal role with password and grant permission to temporal keyspace
  create_cassandra_role_for_keyspace $TEMPORAL_VISIBILITY_CASSANDRA_USERNAME $TEMPORAL_VISIBILITY_CASSANDRA_PASSWORD $TEMPORAL_VISIBILITY_KEYSPACE
}

install_temporal() {
  # This should be executed from within temporal helm chart cloned directory
  # https://github.com/temporalio/helm-charts
  pushd $temporal_chart_path
  rm -fr charts/*
  helm dependencies update
  helm_op="install"
  helm -n $TEMPORAL_NAMESPACE list -q | grep -q "^$RELEASE_NAME$"
  if [ $? == 0 ]; then
    helm_op=upgrade
  fi
  helm ${helm_op} -n $TEMPORAL_NAMESPACE \
    --set schema.setup.enabled=true \
    --set elasticsearch.antiAffinity=soft \
    --set server.replicaCount=1 \
    --set elasticsearch.minimumMasterNodes=1 \
    --set cassandra.enabled=false \
    --set prometheus.enabled=true \
    --set grafana.enabled=true \
    --set grafana.service.type=NodePort \
    --set grafana.ingress.enabled=true \
    --set grafana.ingress.path="/*" \
    --set grafana.ingress.hosts={"grafana.${CLUSTER_NAME}.maira.local"} \
    --set grafana.ingress.tls[0].hosts={"grafana.${CLUSTER_NAME}.maira.local"} \
    --set elasticsearch.enabled=true \
    --set server.config.persistence.default.cassandra.hosts=${CASSANDRA_CLUSTER_NAME}-${CASSANDRA_DC_NAME}-service.${CASSANDRA_NAMESPACE} \
    --set server.config.persistence.default.cassandra.port=${CASSANDRA_PORT} \
    --set server.config.persistence.default.cassandra.keyspace=${TEMPORAL_KEYSPACE} \
    --set server.config.persistence.default.cassandra.user=${TEMPORAL_CASSANDRA_USERNAME} \
    --set server.config.persistence.default.cassandra.password=${TEMPORAL_CASSANDRA_PASSWORD} \
    --set server.config.persistence.default.cassandra.replicationFactor=${CASSANDRA_REPLICATION_FACTOR} \
    --set server.config.persistence.visibility.cassandra.hosts=${CASSANDRA_CLUSTER_NAME}-${CASSANDRA_DC_NAME}-service.${CASSANDRA_NAMESPACE} \
    --set server.config.persistence.visibility.cassandra.port=${CASSANDRA_PORT} \
    --set server.config.persistence.visibility.cassandra.keyspace=${TEMPORAL_VISIBILITY_KEYSPACE} \
    --set server.config.persistence.visibility.cassandra.user=${TEMPORAL_VISIBILITY_CASSANDRA_USERNAME} \
    --set server.config.persistence.visibility.cassandra.password=${TEMPORAL_VISIBILITY_CASSANDRA_PASSWORD} \
    --set server.config.persistence.visibility.cassandra.replicationFactor=${CASSANDRA_REPLICATION_FACTOR} \
    $RELEASE_NAME .
  popd
}

install_maira() {
  helm_op="install"
  kubectl get ns $MAIRA_NAMESPACE -o name 2>/dev/null
  if [[ $? -ne 0 ]]; then
    kubectl create ns $MAIRA_NAMESPACE
  fi
  helm -n $MAIRA_NAMESPACE list -q | grep -q "^$RELEASE_NAME$"
  if [ $? == 0 ]; then
    helm_op=upgrade
  fi
  helm ${helm_op} -n $MAIRA_NAMESPACE \
    --set temporal.host=${RELEASE_NAME}-temporal-frontend.${TEMPORAL_NAMESPACE} \
    $RELEASE_NAME ../
}

main() {
  red='\033[0;31m'
  reset='\033[0m'
  create_temporal_ns
  echo -e "${red}Installing cassandra operator${reset}"
  install_cassandra_operator
  echo -e "${red}Installing cassandra cluster${reset}"
  install_cassandra_cluster
  echo -e "${red}Creating cassandra keyspaces for temporal${reset}"
  create_temporal_keyspaces
  echo -e "${red}Installing temporal${reset}"
  install_temporal
  echo -e "${red}Installing maira services${reset}"
  install_maira
}

main

# Get grafana admin password by
# kubectl get secret --namespace temporal t1-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo  