# 📨 Apache Kafka — Real-Time Data Streaming

## What is Kafka?
Apache Kafka is a **distributed event streaming platform** for real-time data pipelines.
It handles millions of events per second with fault tolerance.

## Kafka Core Concepts
| Concept | Description |
|---------|-------------|
| **Producer** | Sends (publishes) messages to a topic |
| **Consumer** | Reads (subscribes) messages from a topic |
| **Topic** | Named stream / category of messages |
| **Partition** | Topic split for parallelism |
| **Broker** | Kafka server that stores messages |
| **Consumer Group** | Multiple consumers sharing topic partitions |
| **Offset** | Position of a message in a partition |

## Python with Kafka
```python
from kafka import KafkaProducer, KafkaConsumer
import json

# Producer — send data
producer = KafkaProducer(bootstrap_servers="localhost:9092",
                         value_serializer=lambda v: json.dumps(v).encode())
producer.send("ml-predictions", {"input": [1,2,3], "prediction": 0.87})

# Consumer — receive data
consumer = KafkaConsumer("ml-predictions",
                         bootstrap_servers="localhost:9092",
                         value_deserializer=lambda m: json.loads(m.decode()))
for message in consumer:
    print(message.value)
```

## ML Use Cases
- Stream model predictions in real-time
- Log feature values for model monitoring
- Real-time fraud detection pipeline
- ETL: collect → transform → load to DB

## Learning Path
1. Install Kafka via Docker: `docker-compose up kafka`
2. `pip install kafka-python`
3. Producer → Consumer basics
4. Multiple consumers (consumer groups)
5. Kafka + ML model real-time inference pipeline

## What to Build
- [ ] Real-time fraud detection (Kafka + ML model)
- [ ] Streaming ETL pipeline (Kafka → process → MongoDB)
- [ ] ML model monitoring (log predictions to Kafka)

## Related Folders
- `data-science/ETLWeather-main/` — batch ETL comparison
- `big-data/Pyspark-With-Python-main/` — Spark Structured Streaming
- `cloud-deployment/mlops-main/` — MLOps pipeline