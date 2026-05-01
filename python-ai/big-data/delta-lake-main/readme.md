# 🏔️ Delta Lake — Lakehouse Storage for Reliable ML Data Pipelines

## What is Delta Lake?
Delta Lake is an open-source storage layer that brings ACID transactions, schema enforcement, and
time travel to Apache Parquet files on cloud object stores (S3, ADLS, GCS). It transforms a raw
data lake into a "lakehouse" — combining the low-cost storage of a lake with the reliability of a
data warehouse. For ML teams, it solves data pipeline unreliability: partial writes, schema drift,
and "which version of training data produced this model?" are all handled natively.

## Why Learn It?
- ACID transactions prevent partial writes from corrupting ML training datasets
- Time travel lets you re-train a model on the exact dataset snapshot used 3 months ago
- MERGE INTO enables CDC upserts — keep a clean "current state" feature table from event streams
- Schema enforcement catches upstream data quality issues before they silently corrupt models
- Medallion architecture (Bronze/Silver/Gold) gives ML a principled data quality progression

## Key Concepts
```python
from delta import DeltaTable, configure_spark_with_delta_pip
from pyspark.sql import SparkSession
import pyspark.sql.functions as F

spark = configure_spark_with_delta_pip(
    SparkSession.builder
    .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension")
    .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog")
).getOrCreate()

# --- Write Delta table (Parquet + _delta_log transaction log) ---
df.write.format("delta").mode("overwrite").save("s3://my-lake/silver/users")

# --- ACID time travel: query a past version ---
df_v3  = spark.read.format("delta").option("versionAsOf", 3).load("s3://my-lake/silver/users")
df_old = spark.read.format("delta").option("timestampAsOf", "2024-01-15").load("s3://my-lake/silver/users")

# --- Schema enforcement: write with extra column → raises AnalysisException ---
# Schema evolution: opt-in with mergeSchema option
df_new.write.format("delta").option("mergeSchema", "true").mode("append").save(...)

# --- MERGE INTO — upsert pattern for CDC (Change Data Capture) ---
target = DeltaTable.forPath(spark, "s3://my-lake/silver/users")
target.alias("t").merge(
    source=cdc_df.alias("s"),
    condition="t.user_id = s.user_id"
).whenMatchedUpdateAll() \
 .whenNotMatchedInsertAll() \
 .whenNotMatchedBySourceDelete() \
 .execute()

# --- OPTIMIZE + ZORDER: compact small files + co-locate data for fast queries ---
target.optimize().executeZOrderBy("user_id", "event_date")

# --- Streaming writes: Flink/Spark Structured Streaming → Delta ---
(stream_df.writeStream
    .format("delta")
    .outputMode("append")
    .option("checkpointLocation", "s3://my-lake/checkpoints/users")
    .start("s3://my-lake/bronze/raw_events"))

# --- Medallion architecture layers ---
# Bronze: raw ingest   spark.read.format("delta").load("s3://my-lake/bronze/raw_events")
# Silver: cleaned/joined             → "s3://my-lake/silver/users"
# Gold:   aggregated ML-ready features → "s3://my-lake/gold/user_features"

# --- Delta table history (audit log) ---
DeltaTable.forPath(spark, "s3://my-lake/silver/users").history().show()
```

## Learning Path
1. Install `delta-spark`; write and read a simple Delta table; inspect `_delta_log/` JSON logs
2. Test ACID: simulate a failed write mid-job; confirm table is uncorrupted
3. Use time travel (`versionAsOf`, `timestampAsOf`) to query past states
4. Implement a MERGE INTO upsert pipeline simulating a CDC stream from Debezium/Kafka
5. Run OPTIMIZE + ZORDER on a large partitioned table; measure query speedup
6. Build a streaming Bronze ingestion layer with Spark Structured Streaming
7. Design a full Bronze → Silver → Gold medallion pipeline for an ML feature table
8. Compare Delta Lake vs Apache Iceberg vs Apache Hudi: format, ecosystem, performance

## What to Build
- [ ] Bronze layer: raw event streaming writes from Kafka → Delta via Spark Structured Streaming
- [ ] Silver layer: dedup + clean Bronze data using MERGE INTO (handle late/duplicate records)
- [ ] Gold layer: user feature aggregations (30-day spend, session count) for ML training
- [ ] Time travel audit: script that re-creates training dataset from a specific date snapshot
- [ ] OPTIMIZE job that runs nightly to compact small files and ZORDER by query predicates

## Related Folders
- `big-data/apache-flink-main/` — Flink produces streaming data written to Delta Bronze layer
- `big-data/apache-spark-main/` — Spark batch jobs transform Delta Silver → Gold layers
- `mlops/mlflow-tracking-main/` — log Delta table version alongside MLflow model run for lineage
