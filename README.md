# Real time fraud analysis using Kafka Streams

## What is happening here?

- Open source Debezium Postgres CDC and RabbitMQ Source connectors to stream customer data and credit card transactions in real time into Kafka Topic
- ksqlDB to process and enrich data streams in real time. Use aggregation and windowing to create a customer list of potentially stolen credit cards
- Open source Camel sink connector to load enriched data into MongoDB for real-time fraud analysis

## Setup

- Install Docker and Docker Compose
- Then run the following commands

> Terminal#1

```bash
git clone https://github.com/mehdihasan/real-time-fraud-analysis.git
cd real-time-fraud-analysis
./run.sh
```

> Terminal#2

```bash
cd real-time-fraud-analysis
./run.sh
```

## Teardown

> Terminal#3

```bash
./td.sh
```

## References

1. [Debezium connector for PostgreSQL](https://debezium.io/documentation/reference/2.1/connectors/postgresql.html)
2. [Change Data Capture (CDC) With Kafka® Connect and the Debezium PostgreSQL® Source Connector](https://www.instaclustr.com/blog/change-data-capture-cdc-with-kafka-connect-and-the-debezium-postgresql-source-connector/)
3. [Utilize Real-Time, Enriched Data in Your Cloud Database](https://www.confluent.io/use-case/database/)
4. [Camel-Kafka-connector RabbitMQ Source](https://github.com/apache/camel-kafka-connector-examples/tree/main/rabbitmq/rabbitmq-source)
