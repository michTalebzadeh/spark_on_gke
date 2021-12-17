#!/bin/bash

function F_USAGE
{
   echo "USAGE: ${1##*/} -M '<Mode>'"
   echo "USAGE: ${1##*/} -A '<Application>'"
   echo "USAGE: ${1##*/} -P '<SP>'"
   echo "USAGE: ${1##*/} -H '<HELP>' -h '<HELP>'"
   exit 10
}
#
# Main Section
#
if [[ "${1}" = "-h" || "${1}" = "-H" ]]; then
   F_USAGE $0
fi
## MAP INPUT TO VARIABLES
while getopts M:A:P: opt
do
   case $opt in
   (M) MODE="$OPTARG" ;;
   (A) APPLICATION="$OPTARG" ;;
   (P) SP="$OPTARG" ;;
   (*) F_USAGE $0 ;;
   esac
done

[[ -z ${MODE} ]] && echo "You must specify a run mode: Local, Standalone, k8s or Yarn or gcp" && F_USAGE $0
MODE=`echo ${MODE}|tr "[:upper:]" "[:lower:]"`
if [[ "${MODE}" != "local" ]] && [[ "${MODE}" != "standalone" ]] && [[ "${MODE}" != "yarn" ]] && [[ "${MODE}" != "k8s" ]] && [[ "${MODE}" != "docker" ]] && [[ "${MODE}" != "gcp" ]]
then
        echo "Incorrect value for build mode. The run mode can only be local, standalone, docker, k8s or yarn or gcp"  && F_USAGE $0
fi
[[ -z ${APPLICATION} ]] && echo "You must specify an application value " && F_USAGE $0
#
if [[ -z ${SP} ]]
then
        export SP=4040
fi

#set -e
NAMESPACE="spark"
pyspark_venv="pyspark_venv"
source_code="spark_on_gke"
property_file="/home/hduser/dba/bin/python/spark_on_gke/deployment/src/scripts//properties"
IMAGEDRIVER="eu.gcr.io/axial-glow-224522/spark-py:3.1.1-scala_2.12-8-jre-slim-buster-container"
ZONE="europe-west2-c"

CURRENT_DIRECTORY=`pwd`
CODE_DIRECTORY="/home/hduser/dba/bin/python/"
CODE_DIRECTORY_CLOUD="gs://axial-glow-224522-spark-on-k8s/codes/"
cd $CODE_DIRECTORY
[ -f ${source_code}.zip ] && rm -r -f ${source_code}.zip
echo `date` ", ===> creating source zip directory from  ${source_code}"
# zip needs to be done at root directory of code
zip -rq ${source_code}.zip ${source_code}
gsutil cp ${source_code}.zip $CODE_DIRECTORY_CLOUD
gsutil cp /home/hduser/dba/bin/python/spark_on_gke/src/${APPLICATION} $CODE_DIRECTORY_CLOUD
cd $CURRENT_DIRECTORY

echo `date` ", ===> Submitting spark job"

# example ./gke.sh -M gcp -A RandomDataBigQuery.py

#unset PYTHONPATH

if [[ "${MODE}" = "gcp" ]]
then
        # turn on Kubernetes cluster
         NODES=3
         NEXEC=$((NODES-1))
      
        echo `date` ", ===> Resizing GKE cluster with $NODES nodes"
        gcloud container clusters resize spark-on-gke --num-nodes=$NODES --zone europe-west2-c --quiet
        unset PYSPARK_DRIVER_PYTHON
        export PYSPARK_PYTHON=/usr/bin/python3
        gcloud config set compute/zone $ZONE
        export PROJECT=$(gcloud info --format='value(config.project)')
        export CODE_DIRECTORY="gs://$PROJECT-spark-on-k8s/codes"
        gcloud container clusters get-credentials spark-on-gke --zone $ZONE
        export KUBERNETES_MASTER_IP=$(gcloud container clusters list --filter name=spark-on-gke --format='value(MASTER_IP)')
        echo `date` ", ===> Starting spark-submit"
        spark-submit \
           --properties-file ${property_file} \
           --master k8s://https://$KUBERNETES_MASTER_IP:443 \
           --deploy-mode cluster \
           --name sparkBQ \
           --py-files $CODE_DIRECTORY/spark_on_gke.zip \
           --conf spark.kubernetes.namespace=$NAMESPACE \
           --conf spark.network.timeout=300 \
           --conf spark.executor.instances=$NEXEC \
           --conf spark.kubernetes.allocation.batch.size=3 \
           --conf spark.kubernetes.allocation.batch.delay=1 \
           --conf spark.driver.cores=3 \
           --conf spark.executor.cores=3 \
           --conf spark.driver.memory=8192m \
           --conf spark.executor.memory=8192m \
           --conf spark.dynamicAllocation.enabled=true \
           --conf spark.dynamicAllocation.shuffleTracking.enabled=true \
           --conf spark.kubernetes.driver.container.image=${IMAGEDRIVER} \
           --conf spark.kubernetes.executor.container.image=${IMAGEDRIVER} \
           --conf spark.kubernetes.authenticate.driver.serviceAccountName=spark-bq \
           --conf spark.driver.extraJavaOptions="-Dio.netty.tryReflectionSetAccessible=true" \
           --conf spark.executor.extraJavaOptions="-Dio.netty.tryReflectionSetAccessible=true" \
           $CODE_DIRECTORY/${APPLICATION}
           echo `date` ", ===> Completed spark-submit"
           DRIVER_POD_NAME=`kubectl get pods -n $NAMESPACE |grep driver|awk '{print $1}'`
           kubectl describe pod $DRIVER_POD_NAME -n $NAMESPACE
           kubectl logs $DRIVER_POD_NAME -n $NAMESPACE
           kubectl delete pod $DRIVER_POD_NAME -n $NAMESPACE
           echo `date` ", ===> Resizing GKE cluster to zero nodes"
           # set the Kubernetes cluster number of nodes to zero
           gcloud container clusters resize spark-on-gke --num-nodes=0 --zone $ZONE --quiet
fi
