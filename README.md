# Wireguard via KMMO for OCP 4.x

NOTE: TECH PREVIEW. This is still a work in progress and in testing.

Wireguard Kernel Module installed and managed via KMMO / Driver Toolkit. Read more about Driver toolkit [here](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.10/html/specialized_hardware_and_driver_enablement/driver-toolkit#doc-wrapper).

## Prerequisites

1. You have a running OpenShift Container Platform cluster (version 4.11.x).
1. You set the Image Registry Operator state to `Managed` for your cluster. ([Read more](https://docs.openshift.com/container-platform/4.8/registry/configuring-registry-operator.html))

    ```bash
    # check image registry operator state. Should be set to Managed
    oc get configs.imageregistry.operator.openshift.io/cluster -ojsonpath='{.spec.managementState}'
    ```

1. You installed the OpenShift CLI (`oc`).
1. You are logged into the OpenShift CLI as a user with `cluster-admin` privileges. 

## Quick start

1. Clone this repo
1. (Optional) Edit manifests` 01-wireguard-kmmo.yaml` `BuildConfig` `buildArgs` section so it matches your cluster setup 

    2.1. Update `driver-toolkit` image in the `dockerfile` section of the `BuildConfig` resource. You can use the code below to find the correct image for your OCP cluster version.

    ```bash
    OCP_VER=4.11.30
    oc adm release info $OCP_VER --image-for=driver-toolkit
    ```

    2.2. Update `WIREGUARD_ARCHIVE_NAME` and `WIREGUARD_ARCHIVE_SHA256` values in the `strategy.dockerStrategy.buildArgs` section of the `BuildConfig` resource if you want to use another version of Wireguard. 

    You can view available Wireguard versions at [https://git.zx2c4.com/wireguard-linux-compat](https://git.zx2c4.com/wireguard-linux-compat). 

    - Copy the package name without the extension `.tar.xz` and use it for the `WIREGUARD_ARCHIVE_NAME` value.  
    - Then download the package locally and use `sha256sum` utility to get the SHA256 for it and use it for the `WIREGUARD_ARCHIVE_SHA256` value.

        ```bash
        # example
        sha256sum ~/Downloads/wireguard-linux-compat-1.0.20210606.tar.xz

        3f5d990006e6eabfd692d925ec314fff2c5ee7dcdb869a6510d579acfdd84ec0  /tmp/wireguard-linux-compat-1.0.20210606.tar.xz
        ```

1. (Optional) Re-generate `manifests/01-helpers.yaml` by running `make manifests/01-helpers.yaml`. Do this if you have modified any of the files under `helpers`.
1. `make builder` will create your `Namespace`, `BuildConfig`, `ConfigMap` artifacts on your Openshift Cluster. Wait until your imagestream build is available (Run `oc get -f ./manifests -w` to monitor build status)
1. `make install` will create and start a daemonset driver container that will enable wireguard while it is up. It will also unload wireguard kmods if it's brought down.
1. `make remove` uninstalls everything

## Configuration

### BuildConfig buildArgs

```yaml
  strategy:
    dockerStrategy:
      buildArgs:
        # find your desired version / archive name here https://git.zx2c4.com/wireguard-linux-compat/
        - name: WIREGUARD_ARCHIVE_NAME
          value: "wireguard-linux-compat-1.0.20220627"
        # sha256sum value of the archive selected
        - name: WIREGUARD_ARCHIVE_SHA256
          value: "362d412693c8fe82de00283435818d5c5def7f15e2433a07a9fe99d0518f63c0"
        # if you wish to mirror the archive (e.g. for airgapped setups), use the below variable to set the location to download from e.g. http://localhost.run/blobs will result in http://localhost.run/blobs/wireguard-linux-compat-1.0.20211208.tar.xz
        - name: ARTIFACTS_LOCATION
          value: "https://git.zx2c4.com/wireguard-linux-compat/snapshot"
```

### Configure FelixConfiguration resource for each control plane node

Wireguard encryption should not be enabled for the OCP control plane nodes (a.k.a. master nodes). Configure control plane node specific `FelixConfiguration` resources to disable Wireguard encryption for those nodes.

```bash
# example config
cat <<EOF | oc apply -f-
apiVersion: projectcalico.org/v3
kind: FelixConfiguration
metadata:
  name: node.<NODE_NAME>
spec:
  logSeverityScreen: Info
  reportingInterval: 0s
  wireguardEnabled: false
  wireguardEnabledV6: false
EOF
```

An example script to configure the `FelixConfiguration` resource for each control plane node.

```bash
MASTER_NAMES=($(kubectl get nodes -l node-role.kubernetes.io/master= -ojsonpath='{.items[*].metadata.name}'))
for name in ${MASTER_NAMES[@]};do
  cat <<EOF | oc apply -f-
  apiVersion: projectcalico.org/v3
  kind: FelixConfiguration
  metadata:
    name: node.$name
  spec:
    logSeverityScreen: Info
    reportingInterval: 0s
    wireguardEnabled: false
    wireguardEnabledV6: false
EOF
done
```

### Example output

```text
➜  oc get -n tigera-wireguard-kmod all
NAME                                               READY   STATUS      RESTARTS   AGE
pod/tigera-wireguard-kmod-driver-container-5wv4m   1/1     Running     0          51m   # <-- ds pod
pod/tigera-wireguard-kmod-driver-container-khg6z   1/1     Running     0          51m   # <-- ds pod
pod/tigera-wireguard-kmod-driver-container-pvwqv   1/1     Running     0          51m   # <-- ds pod
pod/wireguard-kmod-driver-build-1-build            0/1     Completed   0          53m   # <- build pod

NAME                                                    DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                     AGE
daemonset.apps/tigera-wireguard-kmod-driver-container   3         3         3       3            3           node-role.kubernetes.io/worker=   51m

NAME                                                         TYPE     FROM         LATEST
buildconfig.build.openshift.io/wireguard-kmod-driver-build   Docker   Dockerfile   1

NAME                                                     TYPE     FROM         STATUS     STARTED          DURATION
build.build.openshift.io/wireguard-kmod-driver-build-1   Docker   Dockerfile   Complete   53 minutes ago   2m0s

NAME                                                             IMAGE REPOSITORY                                                                                         TAGS     UPDATED
imagestream.image.openshift.io/wireguard-kmod-driver-container   image-registry.openshift-image-registry.svc:5000/tigera-wireguard-kmod/wireguard-kmod-driver-container   latest   51 minutes ago
```

```text
➜  wireguard-kmmo git:(master) ✗ oc exec -it -n tigera-wireguard-kmod pod/tigera-wireguard-kmod-driver-container-5wv4m -- bash
[root@tigera-wireguard-kmod-driver-container-5wv4m wireguard]# journalctl --unit=wireguard.service
-- Logs begin at Tue 2022-09-06 15:48:26 UTC, end at Tue 2022-09-06 16:03:28 UTC. --
Sep 06 15:48:27 tigera-wireguard-kmod-driver-container-5wv4m systemd[1]: Starting Wireguard KMMO - ...
Sep 06 15:48:27 tigera-wireguard-kmod-driver-container-5wv4m bash[54]: Loading kernel modules using the kernel module container...
Sep 06 15:48:27 tigera-wireguard-kmod-driver-container-5wv4m bash[54]: /etc/wireguard/wireguard-kmod-load.sh 4.18.0-305.49.1.el8_4.x86_64
Sep 06 15:48:27 tigera-wireguard-kmod-driver-container-5wv4m bash[54]: INFO: Loading kernel module: udp_tunnel
Sep 06 15:48:27 tigera-wireguard-kmod-driver-container-5wv4m bash[54]: libkmod: kmod_module_get_holders: could not open '/sys/module/acpi_cpufreq/holders': No such file or directory
Sep 06 15:48:27 tigera-wireguard-kmod-driver-container-5wv4m bash[54]: INFO: Kernel module udp_tunnel already loaded
Sep 06 15:48:27 tigera-wireguard-kmod-driver-container-5wv4m bash[54]: INFO: Loading kernel module: ip6_udp_tunnel
Sep 06 15:48:27 tigera-wireguard-kmod-driver-container-5wv4m bash[54]: INFO: Kernel module ip6_udp_tunnel already loaded
Sep 06 15:48:27 tigera-wireguard-kmod-driver-container-5wv4m bash[54]: INFO: Loading kernel module: wireguard
Sep 06 15:48:27 tigera-wireguard-kmod-driver-container-5wv4m bash[54]: libkmod: kmod_module_get_holders: could not open '/sys/module/intel_uncore/holders': No such file or directory
Sep 06 15:48:27 tigera-wireguard-kmod-driver-container-5wv4m bash[54]: INFO: Kernel module wireguard already loaded
Sep 06 15:48:27 tigera-wireguard-kmod-driver-container-5wv4m systemd[1]: Started Wireguard KMMO - .
[root@tigera-wireguard-kmod-driver-container-5wv4m wireguard]# lsmod | grep wireguard
wireguard             212992  0
ip6_udp_tunnel         16384  1 wireguard
udp_tunnel             20480  1 wireguard
[root@tigera-wireguard-kmod-driver-container-5wv4m wireguard]# 
```
