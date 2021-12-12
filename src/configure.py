import yaml
import sys
import os

with open("/home/hduser/dba/bin/python/spark_on_gke/conf/config.yml", 'r') as file:
  config: dict = yaml.safe_load(file)
