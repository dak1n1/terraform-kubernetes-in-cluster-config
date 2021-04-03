#/bin/bash
set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
set -o xtrace

#-----------------------------------------------------------------------
# Functions & Global vars
#-----------------------------------------------------------------------

# image versions
alpine="alpine:3.12.1"
busybox="busybox:1.32.0"
busybox1="busybox:1.31"
nginx="nginx:1.19.4"
nginx1="nginx:1.19.3"
terraform="terraform:dev"

function build_first() {
  export KUBECONFIG=$HOME/.kube/config
  minikube -p minikube start --vm-driver=kvm2 --container-runtime=docker --insecure-registry '10.0.0.0/24'
  minikube -p minikube addons enable registry
  minikube profile first
}

function build_second() {
  export KUBECONFIG=$HOME/.kube/second
  minikube -p second start --vm-driver=kvm2 --container-runtime=docker --insecure-registry '10.0.0.0/24'
  minikube -p second addons enable registry
  minikube profile second
}

function docker_push() {
  set +o errexit
  sleep 10s # wait for minikube registry
  docker images |grep -s alpine  || docker pull docker.io/library/${alpine}
  docker images |grep -s nginx   || docker pull docker.io/library/${nginx}
  docker images |grep -s busybox || docker pull docker.io/library/${busybox}

  minikube="$(minikube ip):5000"
  docker tag docker.io/library/${alpine} ${minikube}/${alpine}
  docker tag docker.io/library/${busybox} ${minikube}/${busybox}
  docker tag docker.io/library/${busybox} ${minikube}/${busybox1}
  docker tag docker.io/library/${nginx} ${minikube}/${nginx}
  docker tag docker.io/library/${nginx} ${minikube}/${nginx1}
  docker tag localhost/${terraform} ${minikube}/${terraform}

  until [ "$(curl http://${minikube} -o /dev/null -sL -w '%{http_code}')" == "200" ] ; do
    sleep 2s
    echo "Waiting for minikube registry to become available..."
  done

  docker push --tls-verify=false ${minikube}/${alpine}
  docker push --tls-verify=false ${minikube}/${busybox}
  docker push --tls-verify=false ${minikube}/${busybox1}
  docker push --tls-verify=false ${minikube}/${nginx}
  docker push --tls-verify=false ${minikube}/${nginx1}
  docker push --tls-verify=false ${minikube}/${terraform}
  set -o errexit
}


#-----------------------------------------------------------------------
# Main
#-----------------------------------------------------------------------

profile="${1:-}"

if [ -z ${profile} ] ; then
  echo "Please specify minikube cluster to build: 'first', 'second', or 'both'."
  echo "Usage: $0 <profile>"
  exit 1
fi

active_profiles="$(minikube profile list |awk '/kvm/ {print $2}' || echo empty)"

if [[ "${active_profiles}" =~ "${profile}" ]]; then
  echo "Profile ${profile} is already active."
  minikube profile list
  exit 1
fi

case ${profile} in
first)
  build_first
  docker_push
  ;;
second)
  build_second
  docker_push
  ;;
both)
  build_first
  docker_push
  build_second
  docker_push
  ;;
*)
  echo "Invalid profile specified. Must be one of 'minikube', 'second', 'both'"
  exit 1
  ;;
esac

minikube profile list
