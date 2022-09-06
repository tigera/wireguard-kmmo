# Wireguard via KMMO for OCP 4.x

NOTE: TECH PREVIEW. This is still a work in progress and in testing.

Wireguard Kernel Module installed and managed via KMMO / Driver Toolkit. Read more about Driver toolkit [here](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.10/html/specialized_hardware_and_driver_enablement/driver-toolkit#doc-wrapper).


## Prerequisites

1. You have a running OpenShift Container Platform cluster (version 4.10.x).
1. You set the Image Registry Operator state to `Managed` for your cluster. ([Read more](https://docs.openshift.com/container-platform/4.8/registry/configuring-registry-operator.html))
1. You installed the OpenShift CLI (`oc`).
1. You are logged into the OpenShift CLI as a user with `cluster-admin` privileges. 


## Quick start

1. Clone this repo
1. (Optional) Edit manifests` 01-wireguard-kmmo.yaml` `BuildConfig` `buildArgs` section so it matches your cluster setup 
1. (Optional) Re-generate `manifests/01-helpers.yaml` by running `make manifests/01-helpers.yaml`. Do this if you have modified any of the files under `helpers`.
1. `make builder` will create your `Namespace`, `BuildConfig`, `ConfigMap` artifacts on your Openshift Cluster. Wait until your imagestream build is available (Run `oc get -f ./manifests -w` to monitor build status)
1. `make install` will create and start a daemonset driver container that will enable wireguard while it is up. It will also unload wireguard kmods if it's brought down.
1. `make remove` uninstalls everything
