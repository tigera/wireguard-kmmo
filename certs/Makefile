O ?= MyOrg
CN ?= MyModulesSigningKey
EMAIL ?= info@example.com
PEM_LOCATION ?= 

.PHONY:

all: x509.genkey signing-key.pem

x509.genkey:
	@echo "[ req ] \n\
	default_bits = 4096 \n\
	distinguished_name = req_distinguished_name \n\
	prompt = no \n\
	string_mask = utf8only \n\
	x509_extensions = myexts \n\
	[ req_distinguished_name ] \n\
	O = ${O} \n\
	CN = ${CN} \n\
	emailAddress = ${EMAIL} \n\
	\n\
	[ myexts ] \n\
	basicConstraints=critical,CA:FALSE \n\
	keyUsage=digitalSignature \n\
	subjectKeyIdentifier=hash \n\
	authorityKeyIdentifier=keyid" > x509.genkey

signing-key.pem:
	openssl req -x509 -new -nodes -utf8 -sha512 -days 36500 \
	-batch -config x509.genkey -outform DER 				\
	-out signing-key.der 									\
	-keyout signing-key.pem

install:
	mokutil --import signing-key.der
	cp signing-key.pem ${PEM_LOCATION}

clean:
	rm -f x509.genkey signing-key.pem signing-key.der