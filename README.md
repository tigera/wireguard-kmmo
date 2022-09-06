# Wireguard via KMMO for OCP 4.x

## Can I use this?

### No. Don't.

This is still a work in progress. If you really insist, please only use if you know what you're doing!


### If you insist

PROCEED AT YOUR OWN RISK:

1. Clone this repo
1. Edit manifests 01-wireguard-kmmo.yaml BuildConfig buildArgs section so it matches your cluster setup 
1. `make setup` will create your Namespace, BuildConfig, ConfigMap on your Openshift Cluster. Wait until your imagestream is available
1. `make install` will create and start a daemonset driver container that will enable wireguard while it is up. It will also unload wireguard kmods if it's brought down.


## When can I use this?

Public documentation will be available when this solution makes it out for Tech Preview