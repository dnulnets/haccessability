
build-portal:
	cd portal;spago build
	cd portal;spago bundle-app
	-rm -fR backend/static
	cd portal;parcel build -d ../backend/static index.html
	
build-backend:
	cd backend;stack build

build-certificate:
	openssl req -nodes -newkey rsa:4096 -sha512 -x509 -days 365 -subj '/CN=haccsrv/O=IoT Hub for Accessability, Sweden./C=SE' -out deployment/tls.pem -keyout deployment/tls.key

run:
	cd backend;./run.sh
	
image-purescript-build-env:	
	docker build -t paccbuild:1 -t paccbuild:1.0 -t paccbuild:latest -f deployment/Dockerfile.purescript-build-env .

image-db:	
	docker build -t haccdb:1 -t haccdb:1.0 -t haccdb:latest -f deployment/Dockerfile.db .

image-haskell-build-env:	
	docker build -t haccbuild:1 -t haccbuild:1.0 -t haccbuild:latest -f deployment/Dockerfile.haskell-build-env .

image-build-server:	
	docker build -t haccsvc:1 -t haccsvc:1.0 -t haccsvc:latest -f deployment/Dockerfile.build-server .
