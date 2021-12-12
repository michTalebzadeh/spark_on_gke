#!/bin/bash


export PROJECT_ID=$(gcloud info --format='value(config.project)')
export GCP_CR=eu.gcr.io/${PROJECT_ID}

BASE_OS="buster"
SPARK_VERSION="3.1.1"
SCALA_VERSION="scala_2.12"
DOCKERFILE="container"
DOCKERIMAGETAG="8-jre-slim"
ADDEDPACKAGES="ForContainer"
cd $SPARK_HOME

# Building Docker image from provided Dockerfile base 11
cd $SPARK_HOME
/opt/spark/bin/docker-image-tool.sh \
              -r $GCP_CR \
              -t ${SPARK_VERSION}-${SCALA_VERSION}-${DOCKERIMAGETAG}-${BASE_OS}-${DOCKERFILE} \
              -b java_image_tag=${DOCKERIMAGETAG} \
              -p ./kubernetes/dockerfiles/spark/bindings/python/${DOCKERFILE} \
               build

docker images

# docker save pytest-repo/spark-py:3.1.1 |gzip > pytest-repo_spark-py_3.1.1.tar.gz
# cat pytest-repo_spark-py_3.1.1.tar.gz | docker import - spark:latest

#docker push eu.gcr.io/axial-glow-224522/spark-py:3.1.1-scala_2.12-8-jre-slim-buster-container
