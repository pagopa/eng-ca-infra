#!/bin/bash

CLUSTER=vault-ecs-cluster

#aws ecs register-task-definition --cli-input-json file://tasks/busybox.json 


aws ecs create-service --cluster $CLUSTER \
--service-name busybox \
--task-definition busybox:11 --desired-count 1 \
--launch-type "FARGATE" \
--network-configuration "awsvpcConfiguration={subnets=[subnet-0eee4fbf118818f3f,subnet-085a6327873f67a94,subnet-009b3a0a93304b674],securityGroups=[sg-0d5b5a7ff3d54b50e],assignPublicIp=ENABLED}" \
--enable-execute-command

 
aws ecs list-services --cluster $CLUSTER


aws ecs execute-command \
  --region eu-west-1 \
  --cluster vault-ecs-cluster \
  --task 6752cad04f614bcb98d405559fa77a97 \
  --container busybox \
  --command "sh" \
  --interactive


  $ bash <( curl -Ls https://raw.githubusercontent.com/aws-containers/amazon-ecs-exec-checker/main/check-ecs-exec.sh ) vault-ecs-cluster 6752cad04f614bcb98d405559fa77a97