include .env

TRIVY_VERSION := ${ENV_TRIVY_VERSION}
TRIVY_API_VERSION := ${ENV_TRIVY_API_VERSION}

IMAGE_API := ${ENV_REGISTRY}/${ENV_IMAGE_API}:$(ENV_IMAGE_API_TAG)
IMAGE_DB := ${ENV_REGISTRY}/${ENV_IMAGE_DB}:$(ENV_IMAGE_DB_TAG)

REGISTRY := ${ENV_REGISTRY}
REGISTRY_LOGIN := ${ENV_REGISTRY_LOGIN}
REGISTRY_PASSWORD := ${ENV_REGISTRY_PASSWORD}

.PHONY: build-api
build-api:
	docker build --no-cache -t ${IMAGE_API} \
		-f ci_cd/Dockerfile.api \
		--build-arg TRIVY_VERSION=${TRIVY_VERSION} \
		--build-arg TRIVY_API_VERSION=${TRIVY_API_VERSION} .

.PHONY: build-db
build-db:
	docker build --no-cache -t ${IMAGE_DB} -f ci_cd/Dockerfile.db .

.PHONY: registry-login
registry-login: 
	echo ${REGISTRY_PASSWORD} | docker login -u ${REGISTRY_LOGIN} --password-stdin ${REGISTRY}

.PHONY: deploy-api
deploy-api: build-api registry-login
	docker push ${IMAGE_API}

.PHONY: deploy-db
deploy-db: build-db registry-login
	docker push ${IMAGE_DB}
	curl -LO https://github.com/oras-project/oras/releases/download/v0.12.0/oras_0.12.0_linux_amd64.tar.gz
	tar -xvf ./oras_0.12.0_linux_amd64.tar.gz
	./oras push ${IMAGE_DB} --manifest-config /dev/null:application/vnd.aquasec.trivy.config.v1+json  \
		db.tar.gz:application/vnd.aquasec.trivy.db.layer.v1.tar+gzip -u ${ENV_REGISTRY_LOGIN} -p ${ENV_REGISTRY_PASSWORD}

PHONY: deploy
deploy: deploy-api deploy-db