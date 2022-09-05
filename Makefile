.PHONY: all

all: certs

generate-certs:
	make -C certs
certs: generate-certs
	kubectl create secret generic signing-artifacts \
	-n tigera-wireguard-kmod 						\
	--dry-run=client 								\
	--from-file=./certs/signing-key.pem 			\
	--from-file=./certs/signing-key.der 			\
	-o yaml > manifests/01-certs.yaml

install:
	oc apply -f ./manifests

clean:
	-oc delete -f ./manifests

