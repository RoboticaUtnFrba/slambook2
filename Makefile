.PHONY: slambook-docker
slambook-docker:
	docker build --build-arg uid=$(shell id -u) -t slambook-docker .
