.PHONY: all manifests/01-helpers.yaml

all: manifests/01-helpers.yaml setup


# converts ./helpers dir to configmap that will be embedded in BuildConfig
manifests/01-helpers.yaml:
	kubectl create configmap wireguard-kmod-helpers \
	--dry-run=client 								\
	-n tigera-wireguard-kmod 						\
	--from-file=./helpers 							\
	-o yaml > $@

setup:
	oc apply -f ./manifests

install:
	oc apply -f ./1000-driver-container.yaml

clean:
	-oc delete -f ./1000-driver-container.yaml
	-oc delete -f ./manifests

