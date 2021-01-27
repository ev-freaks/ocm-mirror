ifeq ($(AWS_PROFILE),)
  $(error please setup the AWS_PROFILE env var)
endif

APP_NAME := ocm-mirror
TAG := latest
AWS := aws
REPO_NAME := ${APP_NAME}
REPO_URL := $(shell aws ecr describe-repositories --repository-name ${REPO_NAME} --query 'repositories[0].repositoryUri' --output text)
DOCKERFILE_PATH := ..
TMPDIR := tmp

clean:
	rm -rf ${TMPDIR}

tmp:
	mkdir -p ${TMPDIR}

task-definition: ${TMPDIR}/task-definition.json

# we do assume that there is a log group ${APP_NAME} available
${TMPDIR}/task-definition.json: tmp task-definition.json
	jq -r "\
      .family = \"${APP_NAME}\" \
      | .containerDefinitions[0].image = \"${REPO_URL}-app:${TAG}\" \
      | .containerDefinitions[].logConfiguration.options.\"awslogs-group\" = \"${APP_NAME}\" \
      " < task-definition.json > $@

init: create-repo

all: build-image push-image

info:
	$(info REPO_URL: ${REPO_URL})

build-image:
	docker build -t ${REPO_URL}-app:latest ${DOCKERFILE_PATH}

push-image: ecr-login
	docker push ${REPO_URL}-app:${TAG}

ecr-login:
	${AWS} ecr get-login-password | docker login --username AWS --password-stdin ${REPO_URL}

create-repo:
	${AWS} ecr create-repository --repository-name ${REPO_NAME}

reload:
	${AWS} ecs update-service --force-new-deployment --service ${APP_SERVICE_NAME} --cluster ${ECS_CLUSTER_NAME}

.PNONY: clean init all info build-image ecr-login create-repo reload task-definition