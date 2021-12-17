from __future__ import print_function
import sys
from spark_on_gke.src.configure import config
from pyspark.sql import functions as F
from pyspark.sql.functions import col, round, current_timestamp, lit
from spark_on_gke.sparkutils import sparkstuff as s
from spark_on_gke.othermisc import usedFunctions as uf
from pyspark.sql.types import *
import datetime
import time
def main():
    start_time = time.time()
    appName = "RandomDataBigQuery"
    spark_session = s.spark_session(appName)
    spark_session = s.setSparkConfBQ(spark_session)
    spark_context = s.sparkcontext()
    spark_context.setLogLevel("ERROR")
    lst = (spark_session.sql("SELECT FROM_unixtime(unix_timestamp(), 'dd/MM/yyyy HH:mm:ss.ss') ")).collect()
    print("\nStarted at");uf.println(lst)
    randomdatabq = RandomData(spark_session, spark_context)
    dfRandom = randomdatabq.generateRamdomData()
    #dfRandom.printSchema()
    #dfRandom.show(20, False)
    randomdatabq.loadIntoBQTable(dfRandom)
    lst = (spark_session.sql("SELECT FROM_unixtime(unix_timestamp(), 'dd/MM/yyyy HH:mm:ss.ss') ")).collect()
    print("\nFinished at");uf.println(lst)
    end_time = time.time()
    time_elapsed = (end_time - start_time)
    print(f"""Elapsed time in seconds is {time_elapsed}""")
    spark_session.stop()

class RandomData:
    def __init__(self, spark_session, spark_context):
        self.spark = spark_session
        self.sc = spark_context
        self.config = config
        self.values = dict()

    def readDataFromBQTable(self):
        dataset = "test"
        tableName = "randomData"
        fullyQualifiedTableName = dataset+'.'+tableName
        read_df = s.loadTableFromBQ(self.spark, dataset, tableName)
        return read_df

    def getValuesFromBQTable(self):
        read_df = self.readDataFromBQTable()
        read_df.createOrReplaceTempView("tmp_view")
        rows = self.spark.sql("SELECT COUNT(1) FROM tmp_view").collect()[0][0]
        maxID = self.spark.sql("SELECT MAX(ID) FROM tmp_view").collect()[0][0]
        return {"rows":rows,"maxID":maxID}
  
    def generateRamdomData(self):
        self.values = self.getValuesFromBQTable()
        rows = self.values["rows"]
        maxID = self.values["maxID"]
        start = 0
        if (rows == 0):
          start = 1
        else:
          start = maxID + 1
        numRows = config['GCPVariables']['numRows']
        print(numRows)
        end = start + numRows
        print("starting at ID = ", start, ",ending on = ", end)
        Range = range(start, end)
        ## This traverses through the Range and increment "x" by one unit each time, and that x value is used in the code to generate random data through Python functions in a class
        rdd = self.sc.parallelize(Range). \
            map(lambda x: (x, uf.clustered(x, numRows), \
                           uf.scattered(x, numRows), \
                           uf.randomised(x, numRows), \
                           uf.randomString(50), \
                           uf.padString(x, " ", 50),
                           uf.padSingleChar("x", 50)))

        Schema = StructType([ StructField("ID", IntegerType(), False),
                      StructField("CLUSTERED", FloatType(), True),
                      StructField("SCATTERED", FloatType(), True),
                      StructField("RANDOMISED", FloatType(), True),
                      StructField("RANDOM_STRING", StringType(), True),
                      StructField("SMALL_VC", StringType(), True),
                      StructField("PADDING", StringType(), True)
                    ])
        df= self.spark.createDataFrame(rdd, schema = Schema)
        df = df. \
             withColumn("op_type", lit(config['MDVariables']['op_type'])). \
             withColumn("op_time", current_timestamp())
        #df.printSchema()
        #df.show(100,False)
        return df

    def loadIntoBQTable(self, df2):
        # write to BigQuery table
        dataset = "test"
        tableName = "randomData"
        fullyQualifiedTableName = dataset+'.'+tableName
        print(f"""\n writing to BigQuery table {fullyQualifiedTableName}""")
        s.writeTableToBQ(df2,"append",dataset,tableName)
        print(f"""\n Populated BigQuery table {fullyQualifiedTableName}""")
        print("\n rows written is ",  df2.count())
        print(f"""\n Reading from BigQuery table {fullyQualifiedTableName}\n""")
        # read data to ensure all loaded OK
        read_df = s.loadTableFromBQ(self.spark, dataset, tableName)
        new_rows = read_df.count()
        print("\n rows read in is ",  new_rows)
        read_df.select("ID").show(20,False)
        ## Tally the number of rows in BigQuery table with what is expected after adding new rows
        numRows = config['GCPVariables']['numRows']
        if (new_rows - self.values["rows"] - numRows)  == 0:
          print("\nRows tally in BigQuery table")
        else:
          print("\nRows do not tally in BigQuery table")
   

if __name__ == "__main__":
  main()
