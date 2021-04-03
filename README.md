# Terraform Kubernetes Provider in-cluster config test

This repo tests the kubernetes backend, both inside and outside of the cluster. It also tests the Kubernetes Provider's ability to provision resources from within a Pod.

## Setting up the test environment

Build the terraform core image using branch `k8s-backend-credentials`.

```
cd $HOME/go/src/github.com/hashicorp/terraform
TF_DEV=1 docker build . -t localhost/terraform:dev
```

Also build the terraform binary for local use.

```
cd $HOME/go/src/github.com/hashicorp/terraform
go install
```

Configure minikube with two clusters and push the image to it. (The script pushes some other images too, for kubernetes provider acceptance testing).

```
./scripts/minikube.sh both
```

Now that the clusters are ready, init and apply the terraform configurations from this repo.

```
$HOME/go/bin/terraform init
$HOME/go/bin/terraform apply --auto-approve
```

The test is not currently working. But you can view logs using these commands.

```
kubectl describe pod terraform-runner
kubectl logs terraform-runner -c copy-terraform-config
kubectl logs terraform-runner -c terraform-init
kubectl logs terraform-runner -c terraform-apply
```

This is the error currently preventing the init inside the terraform-runner pod.

```
$ kubectl logs terraform-runner -c terraform-init
Error from server (BadRequest): container "terraform-init" in pod "terraform-runner" is waiting to start: PodInitializing

$ kubectl logs terraform-runner -c terraform-init
2021-04-03T00:29:11.021Z [DEBUG] Adding temp file log sink: /tmp/terraform-log419460704
2021-04-03T00:29:11.021Z [INFO]  Terraform version: 0.15.0 dev
2021-04-03T00:29:11.022Z [INFO]  Go runtime version: go1.16
2021-04-03T00:29:11.022Z [INFO]  CLI args: []string{"/go/bin/terraform", "init"}
2021-04-03T00:29:11.022Z [DEBUG] Attempting to open CLI config file: /root/.terraformrc
2021-04-03T00:29:11.022Z [DEBUG] File doesn't exist, but doesn't need to. Ignoring.
2021-04-03T00:29:11.022Z [DEBUG] ignoring non-existing provider search directory terraform.d/plugins
2021-04-03T00:29:11.022Z [DEBUG] ignoring non-existing provider search directory /root/.terraform.d/plugins
2021-04-03T00:29:11.022Z [DEBUG] ignoring non-existing provider search directory /root/.local/share/terraform/plugins
2021-04-03T00:29:11.022Z [DEBUG] ignoring non-existing provider search directory /usr/local/share/terraform/plugins
2021-04-03T00:29:11.022Z [DEBUG] ignoring non-existing provider search directory /usr/share/terraform/plugins
2021-04-03T00:29:11.023Z [INFO]  CLI command args: []string{"init"}

Initializing the backend...
2021-04-03T00:29:11.029Z [TRACE] Meta.Backend: built configuration for "kubernetes" backend with hash value 801054573
2021-04-03T00:29:11.030Z [TRACE] Meta.Backend: backend has not previously been initialized in this working directory
2021-04-03T00:29:11.030Z [DEBUG] New state was assigned lineage "e7498877-995d-1d94-d294-6b655edd0678"
2021-04-03T00:29:11.030Z [TRACE] Meta.Backend: moving from default local state only to "kubernetes" backend
2021-04-03T00:29:11.031Z [DEBUG] checking for provisioner in "."
2021-04-03T00:29:11.031Z [DEBUG] checking for provisioner in "/go/bin"
2021-04-03T00:29:11.031Z [INFO]  Failed to read plugin lock file .terraform/plugins/linux_amd64/lock.json: open .terraform/plugins/linux_amd64/lock.json: no such file or directory
2021-04-03T00:29:11.031Z [TRACE] backend/local: state manager for workspace "default" will:
 - read initial snapshot from terraform.tfstate
 - write new snapshots to terraform.tfstate
 - create any backup at terraform.tfstate.backup
2021-04-03T00:29:11.031Z [TRACE] statemgr.Filesystem: reading initial snapshot from terraform.tfstate
2021-04-03T00:29:11.031Z [TRACE] statemgr.Filesystem: snapshot file has nil snapshot, but that's okay
2021-04-03T00:29:11.031Z [TRACE] statemgr.Filesystem: read nil snapshot
2021-04-03T00:29:11.032Z [TRACE] Meta.Backend: ignoring local "default" workspace because its state is empty
2021-04-03T00:29:11.033Z [DEBUG] New state was assigned lineage "afff5210-c811-f699-3e43-9d1a1122dff8"
2021-04-03T00:29:11.033Z [TRACE] Preserving existing state lineage "afff5210-c811-f699-3e43-9d1a1122dff8"

Successfully configured the backend "kubernetes"! Terraform will automatically
use this backend unless the backend configuration changes.
2021-04-03T00:29:11.047Z [TRACE] Meta.Backend: instantiated backend of type *kubernetes.Backend
2021-04-03T00:29:11.047Z [DEBUG] checking for provisioner in "."
2021-04-03T00:29:11.047Z [DEBUG] checking for provisioner in "/go/bin"
2021-04-03T00:29:11.047Z [INFO]  Failed to read plugin lock file .terraform/plugins/linux_amd64/lock.json: open .terraform/plugins/linux_amd64/lock.json: no such file or directory
2021-04-03T00:29:11.048Z [TRACE] Meta.Backend: backend *kubernetes.Backend does not support operations, so wrapping it in a local backend
Error loading state: secrets "tfstate-default-incluster" is forbidden: User "system:serviceaccount:default:terraform-runner" cannot update resource "secrets" in API group "" in the namespace "default"
                                Additionally, unlocking the state in Kubernetes failed:

                                Error message: "leases.coordination.k8s.io \"lock-tfstate-default-incluster\" is forbidden: User \"system:serviceaccount:default:terraform-runner\" cannot update resource \"leases\" in API group \"coordination.k8s.io\" in the namespace \"default\"\nLock Info:\n  ID:        dfa35778-df3d-36b6-0931-4c18a6c53545\n  Path:      \n  Operation: init\n  Who:       root@terraform-runner\n  Version:   0.15.0\n  Created:   2021-04-03 00:29:11.05151995 +0000 UTC\n  Info:      \n"
                                Lock ID (gen): dfa35778-df3d-36b6-0931-4c18a6c53545
                                Secret Name: tfstate-default-incluster

                                You may have to force-unlock this state in order to use it again.
                                The Kubernetes backend acquires a lock during initialization to ensure
                                the initial state file is created.

$ kubectl logs terraform-runner -c terraform-init
2021-04-03T00:29:11.903Z [DEBUG] Adding temp file log sink: /tmp/terraform-log692731982
2021-04-03T00:29:11.903Z [INFO]  Terraform version: 0.15.0 dev
2021-04-03T00:29:11.903Z [INFO]  Go runtime version: go1.16
2021-04-03T00:29:11.903Z [INFO]  CLI args: []string{"/go/bin/terraform", "init"}
2021-04-03T00:29:11.903Z [DEBUG] Attempting to open CLI config file: /root/.terraformrc
2021-04-03T00:29:11.903Z [DEBUG] File doesn't exist, but doesn't need to. Ignoring.
2021-04-03T00:29:11.903Z [DEBUG] ignoring non-existing provider search directory terraform.d/plugins
2021-04-03T00:29:11.903Z [DEBUG] ignoring non-existing provider search directory /root/.terraform.d/plugins
2021-04-03T00:29:11.903Z [DEBUG] ignoring non-existing provider search directory /root/.local/share/terraform/plugins
2021-04-03T00:29:11.903Z [DEBUG] ignoring non-existing provider search directory /usr/local/share/terraform/plugins
2021-04-03T00:29:11.903Z [DEBUG] ignoring non-existing provider search directory /usr/share/terraform/plugins
2021-04-03T00:29:11.904Z [INFO]  CLI command args: []string{"init"}
2021-04-03T00:29:11.905Z [TRACE] Meta.Backend: built configuration for "kubernetes" backend with hash value 801054573

Initializing the backend...
2021-04-03T00:29:11.906Z [TRACE] Preserving existing state lineage "afff5210-c811-f699-3e43-9d1a1122dff8"
2021-04-03T00:29:11.906Z [TRACE] Preserving existing state lineage "afff5210-c811-f699-3e43-9d1a1122dff8"
2021-04-03T00:29:11.906Z [TRACE] Meta.Backend: working directory was previously initialized for "kubernetes" backend
2021-04-03T00:29:11.906Z [TRACE] Meta.Backend: using already-initialized, unchanged "kubernetes" backend configuration
2021-04-03T00:29:11.914Z [TRACE] Meta.Backend: instantiated backend of type *kubernetes.Backend
2021-04-03T00:29:11.914Z [DEBUG] checking for provisioner in "."
2021-04-03T00:29:11.914Z [DEBUG] checking for provisioner in "/go/bin"
2021-04-03T00:29:11.914Z [INFO]  Failed to read plugin lock file .terraform/plugins/linux_amd64/lock.json: open .terraform/plugins/linux_amd64/lock.json: no such file or directory
2021-04-03T00:29:11.914Z [TRACE] Meta.Backend: backend *kubernetes.Backend does not support operations, so wrapping it in a local backend
Error loading state: the state is already locked by another terraform client
Lock Info:
  ID:        dfa35778-df3d-36b6-0931-4c18a6c53545
  Path:
  Operation: init
  Who:       root@terraform-runner
  Version:   0.15.0
  Created:   2021-04-03 00:29:11.05151995 +0000 UTC
  Info:
```

The test can be cleaned up by running the following:

```
$HOME/go/bin/terraform destroy --auto-approve
kube delete lease lock-tfstate-default-incluster
kube delete lease lock-tfstate-default-outside
kube delete secret tfstate-default-incluster
kube delete secret tfstate-default-outside
```

It can then be re-applied as many times as needed. When done, delete both minikube profiles.

```
minikube delete
minikube delete
```
