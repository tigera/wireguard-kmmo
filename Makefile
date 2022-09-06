.PHONY: manifests/01-helpers.yaml

# converts ./helpers dir to configmap that will be embedded in BuildConfig
manifests/01-helpers.yaml:
	kubectl create configmap wireguard-kmod-helpers \
	--dry-run=client 								\
	-n tigera-wireguard-kmod 						\
	--from-file=./helpers 							\
	-o yaml > $@

# applies and triggers the imagestream build
builder:
	oc apply -f ./manifests

# target to run when imagestream succeeds
install:
	oc apply -f ./1000-driver-container.yaml

# cleanup / uninstall
remove:
	-oc delete -f ./1000-driver-container.yaml
	-oc delete -f ./manifests

