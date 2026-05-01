# 🌊 Apache Flink — Stream Processing for Real-Time ML Features

## What is Apache Flink?
Apache Flink is a distributed stream processing framework designed for stateful computations over
unbounded data streams with true event-by-event processing (not micro-batches). Unlike Spark
Streaming's micro-batch model, Flink processes each record as it arrives, enabling sub-second
latency for real-time ML feature engineering, fraud detection, and recommendation pipelines.
It offers exactly-once semantics, event-time processing, and native Kafka integration.

## Why Learn It?
- Compute ML features in real time (rolling averages, session counts) for online inference
- True streaming beats Spark micro-batch when latency < 1 second is required
- Watermarks handle late-arriving data gracefully in event-time windows
- Stateful operators (ValueState, ListState) maintain per-key aggregates across millions of users
- Flink SQL lowers the barrier — write streaming queries with standard SQL syntax

## Key Concepts
```python
# PyFlink — DataStream API basics
from pyflink.datastream import StreamExecutionEnvironment
from pyflink.datastream.connectors.kafka import KafkaSource
from pyflink.common.watermark_strategy import WatermarkStrategy
from pyflink.datastream.window import TumblingEventTimeWindows
from pyflink.common import Duration, Time

env = StreamExecutionEnvironment.get_execution_environment()
env.set_parallelism(4)

# Kafka source with event-time watermarks (handles 5-second late data)
source = KafkaSource.builder() \
    .set_bootstrap_servers("kafka:9092") \
    .set_topics("user-events") \
    .set_value_only_deserializer(SimpleStringSchema()) \
    .build()

stream = env.from_source(
    source,
    WatermarkStrategy
        .for_bounded_out_of_orderness(Duration.of_seconds(5))
        .with_timestamp_assigner(MyTimestampAssigner()),
    "kafka-source",
)

# Real-time feature: count events per user in 1-minute tumbling windows
feature_stream = (
    stream
    .map(lambda e: (e["user_id"], 1))           # parse
    .key_by(lambda e: e[0])                      # partition by user_id
    .window(TumblingEventTimeWindows.of(Time.minutes(1)))
    .reduce(lambda a, b: (a[0], a[1] + b[1]))   # sum counts
)

# Stateful processing — running total with ValueState
from pyflink.datastream import KeyedProcessFunction
from pyflink.datastream.state import ValueStateDescriptor

class RunningTotal(KeyedProcessFunction):
    def open(self, ctx):
        self.total = ctx.get_state(ValueStateDescriptor("total", Types.LONG()))

    def process_element(self, value, ctx):
        current = self.total.value() or 0
        self.total.update(current + value[1])
        yield (value[0], self.total.value())

# Flink SQL — streaming aggregation
table_env.execute_sql("""
    CREATE TABLE user_events (
        user_id STRING,
        event_type STRING,
        event_time TIMESTAMP(3),
        WATERMARK FOR event_time AS event_time - INTERVAL '5' SECOND
    ) WITH ('connector' = 'kafka', 'topic' = 'user-events', ...)
""")

table_env.execute_sql("""
    SELECT user_id,
           TUMBLE_START(event_time, INTERVAL '1' MINUTE) AS window_start,
           COUNT(*) AS event_count
    FROM user_events
    GROUP BY user_id, TUMBLE(event_time, INTERVAL '1' MINUTE)
""")

env.execute("real-time-feature-pipeline")
```

## Learning Path
1. Understand Flink vs Spark Streaming: true streaming vs micro-batch latency trade-offs
2. Run Flink locally via Docker; submit a word-count job with the DataStream API
3. Learn event time vs processing time; implement watermarks for late data
4. Build tumbling, sliding, and session windows on a simulated event stream
5. Add stateful processing with `ValueState` / `ListState` for per-key aggregates
6. Connect a Kafka source and sink; implement checkpointing for exactly-once semantics
7. Write the same pipeline in Flink SQL; compare expressiveness vs DataStream API
8. Build a real-time feature store: Kafka → Flink aggregations → Redis for online inference

## What to Build
- [ ] Word count job on a live socket stream using DataStream API
- [ ] 1-minute tumbling window user event counter with Kafka source
- [ ] Fraud detection signal: flag users with > 10 transactions in a 5-minute sliding window
- [ ] Real-time feature engineering pipeline feeding a Redis feature store
- [ ] Flink SQL job joining two Kafka topics (events + user profiles) with temporal joins

## Related Folders
- `big-data/delta-lake-main/` — persist Flink stream outputs to Delta Lake (Bronze layer)
- `big-data/apache-spark-main/` — Spark for batch processing; compare with Flink streaming
- `ml-pipelines/feature-store-main/` — serve Flink-computed features to online ML models
