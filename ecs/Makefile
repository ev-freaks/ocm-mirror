ifeq ($(AWS_PROFILE),)
  $(error please setup the AWS_PROFILE env var)
endif

APP_NAME := ocm-mirror-prod
ECS_CLUSTER_NAME := chargev-io-t4g
APP_SERVICE_NAME := ${APP_NAME}

OCM_SYSTEM_REPO_URL := https://github.com/ev-freaks/ocm-system.git
OCM_SYSTEM_BRANCH := testing

# OCM_SYSTEM_REPO_URL := https://github.com/openchargemap/ocm-system
# OCM_SYSTEM_BRANCH := master
OCM_DOTNET_TAG := 6.0-alpine

REPO_NAME := ocm-mirror
REPO_URL := $(shell aws ecr describe-repositories --repository-name ${REPO_NAME} --query 'repositories[0].repositoryUri' --output text)
TAG := latest
DOCKERFILE_PATH := ..

.PNONY: clean init all info build-image ecr-login create-repo reload task-definition create-service update-service register-task

all: ecr-login buildx

clean:
	rm -rf ${TMPDIR}

TMPDIR := .tmp

${TMPDIR}:
	mkdir -p ${TMPDIR}

# we do assume that there is a log group ${APP_NAME} available
${TMPDIR}/task-definition.json: ${TMPDIR} task-definition.json
	jq -r "\
      .family = \"${APP_NAME}\" \
      | .containerDefinitions[0].image = \"${REPO_URL}:${TAG}\" \
      | .containerDefinitions[].logConfiguration.options.\"awslogs-group\" = \"${APP_NAME}\" \
      " < task-definition.json > $@

init: create-repo

info:
	$(info REPO_URL: ${REPO_URL})


PLATFORM := linux/amd64,linux/arm64

buildx-init:
	docker buildx ls | awk '{print $1}' | grep builder &>/dev/null || docker buildx create --name builder --use && docker buildx use builder

buildx: buildx-init
	docker buildx build --push --platform ${PLATFORM} -t ${REPO_URL}:latest ${DOCKERFILE_PATH} --build-arg REPO_URL=${OCM_SYSTEM_REPO_URL} --build-arg REPO_BRANCH=${OCM_SYSTEM_BRANCH} --build-arg DOTNET_TAG=${OCM_DOTNET_TAG}

ecr-login:
	aws ecr get-login-password | docker login --username AWS --password-stdin ${REPO_URL}

create-repo:
	aws ecr create-repository --repository-name ${REPO_NAME}

reload:
	aws ecs update-service --force-new-deployment --service ${APP_SERVICE_NAME} --cluster ${ECS_CLUSTER_NAME}

# Important Notice: the folowing setup is quite tailored to our ECS setup on AWS, override the defaults accordingly.

AWS_ACCOUNT := $(shell aws sts get-caller-identity --query Account --output text)

register-task: ECSTaskRoleArn :=arn:aws:iam::${AWS_ACCOUNT}:role/${ECS_CLUSTER_NAME}-ecs-task
register-task: ECSTaskExecRoleArn := arn:aws:iam::${AWS_ACCOUNT}:role/${ECS_CLUSTER_NAME}-ecs-task-exec
register-task: ${TMPDIR}/task-definition.json
	@aws ecs register-task-definition \
        --cli-input-json "file://$<" \
        --task-role-arn "${ECSTaskRoleArn}" \
        --execution-role-arn "${ECSTaskExecRoleArn}" \
        --query 'taskDefinition.taskDefinitionArn' --output text

create-service: TargetGroupArn := arn:aws:elasticloadbalancing:eu-central-1:${AWS_ACCOUNT}:targetgroup/ocm-mirror-prod/3bb6be1850e982e4
create-service: ECSServiceRoleArn := arn:aws:iam::${AWS_ACCOUNT}:role/${ECS_CLUSTER_NAME}-ecs-service
create-service: task_arn = $(shell ${MAKE} -s register-task)
create-service: clean
	aws ecs create-service \
        --load-balancers targetGroupArn=${TargetGroupArn},containerName=app,containerPort=80 --role ${ECSServiceRoleArn} \
        --cluster "${ECS_CLUSTER_NAME}" \
        --service-name "${APP_NAME}" \
        --desired-count "2" \
        --task-definition "$(task_arn)" \
        --deployment-configuration maximumPercent=200,minimumHealthyPercent=100 \
        --query 'service.taskDefinition' --output text

update-service: task_arn = $(shell ${MAKE} -s register-task)
update-service: clean
	aws ecs update-service \
        --cluster "${ECS_CLUSTER_NAME}" \
        --service "${APP_NAME}" \
        --task-definition "$(task_arn)" \
        --query 'service.taskDefinition' --output text
