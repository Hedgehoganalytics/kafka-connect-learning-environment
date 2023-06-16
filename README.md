# Ingesting data into Elasticsearch without logstash

## Kafka Connect

### High level understanding

Kafka connect is a framework to run code which integrates Kafka brokers with other systems.

Kafka connect server is a Java application that can be clustered.
A Deployed Kafka connect server is refered to as a Worker.
Kafka connect-plugins are Java applications loaded by Kafka connect server when it starts. Mostly they are refered to as "Connectors".
A Kafka connect instance is deployed to a Kafka connect server cluster when:
- The JAR file has been loaded by all Workers.
- A configuration is submitted to a Worker.

A Kafka connector can comprise of one or more tasks. Typically one would consider there to be a relationship between the count of partitions being consumed from and the count of tasks. A cluster is able to dynamically scale the number of running tasks and distribute tasks across the Workers providing high availability and scalability.

There are quite a few open source connector-plugins and also some closed source ones.
https://www.confluent.io/hub/ is a good place to find connectors. There is a filter to only show open source connectors.

Some highlights:
- https://www.confluent.io/hub/confluentinc/kafka-connect-elasticsearch
- https://www.confluent.io/hub/dariobalinzo/kafka-connect-elasticsearch-source
- https://www.confluent.io/hub/confluentinc/kafka-connect-s3
- https://www.confluent.io/hub/redis/redis-enterprise-kafka
- https://www.confluent.io/hub/confluentinc/kafka-connect-jdbc

# NOTE: LOTS OF WHAT FOLLOWS HAS BEEN REPLACED WITH TASK TARGETS.

### Managing Kafka connect

Interact with Kafka Connect either through Redpanda Console or curl.
The following examples demonstrate the API.

#### Get installed plugins

Note that we expect to see the Elasticsearch and the S3 plugins installed.
```
curl -s localhost:8083/connector-plugins | jq '.'
[

etc...

  {
    "class": "com.redpanda.kafka.connect.s3.S3SinkConnector",
    "type": "sink",
    "version": "1.0.838"
  },

etc...

  {
    "class": "io.confluent.connect.elasticsearch.ElasticsearchSinkConnector",
    "type": "sink",
    "version": "14.0.5"
  },

etc...

]
```

#### Get the list of configured connectors

```
curl -s -X GET "http://localhost:8083/connectors/"
["sink-elastic-01","nginx"]%
```

#### Show the configurtion of a connector

```
curl -s -X GET -H  "Content-Type:application/json" http://localhost:8083/connectors/nginx/config | jq '.'
{
  "connector.class": "io.confluent.connect.elasticsearch.ElasticsearchSinkConnector",
  "topics": "nginx",
  "name": "nginx",
  "connection.url": "http://elastic-01:9200,http://elastic-02:9200,http://elastic-03:9200",
  "key.ignore": "true",
  "value.converter": "org.apache.kafka.connect.json.JsonConverter",
  "schema.ignore": "true"
}
```

#### Get the status of all connectors

```
curl -s "http://localhost:8083/connectors?expand=info&expand=status" | \
        jq '. | to_entries[] | [ .value.info.type, .key, .value.status.connector.state,.value.status.tasks[].state, .value.info.config."connector.class"] |join(":|:")' | \
        column -s : -t| sed 's/\"//g'| sort
sink  |  nginx            |  RUNNING  |  RUNNING  |  io.confluent.connect.elasticsearch.ElasticsearchSinkConnector
sink  |  sink-elastic-01  |  PAUSED   |  PAUSED   |  io.confluent.connect.elasticsearch.ElasticsearchSinkConnector
```

#### Delete a connector

```
curl -s -X DELETE "http://localhost:8083/connectors/nginx"
```

#### Deploy a connector

```
curl -i -X PUT -H  "Content-Type:application/json" http://localhost:8083/connectors/nginx/config \
-d '{
  "connector.class": "io.confluent.connect.elasticsearch.ElasticsearchSinkConnector",
  "topics": "nginx",
  "name": "nginx",
  "connection.url": "http://elastic-01:9200,http://elastic-02:9200,http://elastic-03:9200",
  "key.ignore": "true",
  "value.converter": "org.apache.kafka.connect.json.JsonConverter",
  "schema.ignore": "true"
}'
```

#### Pause, Unpause a connector

```
curl -s -X PUT "http://localhost:8083/connectors/nginx/pause"
curl -s -X PUT "http://localhost:8083/connectors/nginx/resume"
```

#### Restart a connector, restart one of the connector's tasks, get the status of the task


```
curl -s -X POST "http://localhost:8083/connectors/nginx/restart"
curl -s -X POST "http://localhost:8083/connectors/nginx/tasks/0/restart"
curl -s -X GET "http://localhost:8083/connectors/nginx/tasks/0/status" | jq '.'
```
