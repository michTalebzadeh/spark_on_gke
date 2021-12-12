This repositoy includes what is necessary in Kubernetes AKA k8s for the deployment of Spark, which is an open-source distributed computing framework. One can utilize code developed in Python, Scala, SQL and others to create applications that can process large amount of data. Spark uses parallel processing to distribute the work-load across a cluster of physical hosts, for example, nodes of Kubernetes cluster.
I will explain the practical implementation of Spark on Kubernetes (Spark-on-k8s) and will leverage Google Kubernetes Engine (GKE) (Google was first to introduce and then open source Kubernetes) and show steps in implementing Spark on GKE cluster-manager by creating a simple yet effective example that uses PySpark to generate random test data in Spark, take that data and post it to Google BigQuery Data Warehouse table.

The directories are structured as below

1) src - RandomDataBigQuery.py, the main Python script that runs the code.
         configure.py, the Python scipt that reads the yaml file config.yml and creates a disctionary of variables 

2) sparkutils - sparkstuff.py is used to initialise Spark and set configuration parameters for Spark to access Google BigQuery database. It does so through JDBC connection

3) design - gke2.png, Includes the high level design document 

4) othermisc - Includes usedFunctions.py that has multiple functions for creating random data

5) deployment - Has src/scripts, shell scripts that are used to grant the necessary roles "grant-roles.sh" for the Kubernetes and bigQuery plus the main bash shell "gke.sh" that runs spark-submit code. In this case the code
                is only shown for gcp 
