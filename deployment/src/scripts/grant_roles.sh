#!/bin/bash

# Create a Kubernetes Engine cluster

gcloud config set compute/zone europe-west2-c
gcloud iam service-accounts create spark-bq --display-name spark-bq

#Store the service account email address and your current project ID in environment variables to be used in later commands:

export SA_EMAIL=$(gcloud iam service-accounts list --filter="displayName:spark-bq" --format='value(email)')
export PROJECT=$(gcloud info --format='value(config.project)')

# The sample application must create and manipulate BigQuery datasets and tables and remove artifacts from Cloud Storage. Bind the bigquery.dataOwner, bigQuery.jobUser, and storage.admin roles to the service account:

gcloud projects add-iam-policy-binding $PROJECT --member serviceAccount:$SA_EMAIL --role roles/storage.admin
gcloud projects add-iam-policy-binding $PROJECT --member serviceAccount:$SA_EMAIL --role roles/bigquery.dataOwner
gcloud projects add-iam-policy-binding $PROJECT --member serviceAccount:$SA_EMAIL --role roles/bigquery.jobUser

# Download the service account JSON key and store it in a Kubernetes secret. Your Spark drivers and executors use this secret to authenticate with BigQuery:

gcloud iam service-accounts keys create spark-sa.json --iam-account $SA_EMAIL
kubectl create secret generic spark-sa --from-file=spark-sa.json -n spark
cp -f ./spark-sa.json /mnt/secrets

# Add permissions for Spark to be able to launch jobs in the Kubernetes cluster.

kubectl create clusterrolebinding user-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value account)
kubectl create clusterrolebinding --clusterrole=cluster-admin --serviceaccount=default:default spark-admin
kubectl create clusterrolebinding cluster-system-anonymous --clusterrole=cluster-admin --user=system:anonymous  -n spark
kubectl create namespace spark

kubectl create serviceaccount spark-bq -n spark
kubectl create clusterrolebinding spark-bq --clusterrole=cluster-admin --serviceaccount=spark:spark-bq --namespace=spark
 
