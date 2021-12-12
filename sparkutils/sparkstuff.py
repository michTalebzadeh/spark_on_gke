import sys

import pyspark
from pyspark.sql import SparkSession
from pyspark import SparkContext, SparkConf

from spark_on_gke.src.configure import config
from pyspark.sql import SQLContext, HiveContext

def spark_session(appName):
  return SparkSession.builder \
    .appName(appName) \
    .enableHiveSupport() \
    .getOrCreate()


def sparkcontext():
  return SparkContext.getOrCreate()

def hivecontext():
  return HiveContext(sparkcontext())

def spark_session_local(appName):
    return SparkSession.builder \
        .master('local[1]') \
        .appName(appName) \
        .enableHiveSupport() \
        .getOrCreate()

def setSparkConfBQ(spark):
    try:
        spark.conf.set("BigQueryProjectId", config['GCPVariables']['projectId'])
        spark.conf.set("BigQueryParentProjectId", config['GCPVariables']['projectId'])
        spark.conf.set("BigQueryDatasetLocation", config['GCPVariables']['datasetLocation'])
        spark.conf.set("google.cloud.auth.service.account.enable", "true")
        spark.conf.set("fs.gs.project.id", config['GCPVariables']['projectId'])
        spark.conf.set("fs.gs.impl", "com.google.cloud.hadoop.fs.gcs.GoogleHadoopFileSystem")
        spark.conf.set("fs.AbstractFileSystem.gs.impl", "com.google.cloud.hadoop.fs.gcs.GoogleHadoopFS")
        spark.conf.set("temporaryGcsBucket", config['GCPVariables']['tmp_bucket'])
        spark.conf.set("spark.sql.streaming.checkpointLocation", config['GCPVariables']['tmp_bucket'])
        spark.conf.set("spark.sql.execution.arrow.pyspark.enabled","true")
        return spark
    except Exception as e:
        print(f"""{e}, quitting""")
        sys.exit(1)

def loadTableFromBQ(spark,dataset,tableName):
    try:
        read_df = spark.read. \
            format("bigquery"). \
            option("project", config['GCPVariables']['projectId']). \
            option("parentProject", config['GCPVariables']['projectId']). \
            option("dataset", dataset). \
            option("table", tableName). \
            load()
        return read_df
    except Exception as e:
        print(f"""{e}, quitting""")
        sys.exit(1)

def writeTableToBQ(dataFrame,mode,dataset,tableName):
    try:
        dataFrame. \
            write. \
            format("bigquery"). \
            option("project", config['GCPVariables']['projectId']). \
            option("parentProject", config['GCPVariables']['projectId']). \
            mode(mode). \
            option("dataset", dataset). \
            option("table", tableName). \
            save()
    except Exception as e:
        print(f"""{e}, quitting""")
        sys.exit(1)
