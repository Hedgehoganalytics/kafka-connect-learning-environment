Ignore most of this.
If you look at something expect it to be at least half broken.


# Things that need to be done by hand

## 3rd party connectors
They should be extracted under a "plugins" folder and will get auto loaded by kafka connect.

eg:
```
mkdir -p plugins/{confluentinc-kafka-connect-datagen,confluentinc-kafka-connect-elasticsearch,confluentinc-kafka-connect-s3}
cd plugins/confluentinc-kafka-connect-datagen
# Follow instructions below to compile and install datagen plugin
```

## Getting data into the platform
Currently, there are a couple of options for getting data into the platform

### flog and kaf

1. Install flog
  - https://github.com/mingrammer/flog
2. Install kaf
  - https://github.com/birdayz/kaf
3. Run flog
  ```
   flog -d1 -f json | kaf -b localhost:19092 produce nginx
  ```

### kafka-connect-datagen

1. Install Maven
  ```
  asdf plugin add maven
  asdf install maven 3.9.1
  echo "maven 3.9.1" >> ~/.tool-versions
  ```
2. Compile kafka-connect-datagen
  ```
  git clone https://github.com/confluentinc/kafka-connect-datagen.git
  cd kafka-connect-datagen
  git checkout v0.6.0
  mvn clean package
  ```
3. Copy compiled plugin into package
  ```
  cd ../next-gen-ingest/
  mkdir -p plugins/confluentinc-kafka-connect-datagen
  cd confluentinc-kafka-connect-datagen
  unzip ../../kafka-connect-datagen/target/components/packages/confluentinc-kafka-connect-datagen-0.6.0.zip
  ```
4. Ensure the plugin is mounted in the connect container
  ```
    volumes:
      - ${PWD}/plugins/confluentinc-kafka-connect-datagen:/opt/kafka/redpanda-plugins/confluentinc-kafka-connect-datagen
  ```
5. Start the platform
  ```
  docker-compose up
  ```
6. Define a connector instance running datagen
  FIXME: NEED TO DEFINE A NGINX LOOKING AVRO SCHEMA AND CONVERT IT TO JSON. USING THE PROVIDED PAGEVIEWS SCHEMA AS A PLACEHOLDER
  ```
  curl -i -X PUT -H  "Content-Type:application/json" http://localhost:8083/connectors/pageviews-source/config \
  -d '
  {
    "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
    "kafka.topic": "pageviews",
    "quickstart": "pageviews",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": "false",
    "max.interval": 100,
    "iterations": 10000000,
    "tasks.max": "1"
  }'
  ```

## Write out to S3

The redpanda s3 output plugin might not be the best option for local testing.

1. Download the latest confluent S3 sinck connector
  - See https://www.confluent.io/hub/confluentinc/kafka-connect-s3 for a download link
2. Extract the zip file into the plugins directory
  ```
  mkdir -p plugins/confluentinc-kafka-connect-s3
  mv confluentinc-kafka-connect-s3-10.4.2.zip plugins/confluentinc-kafka-connect-s3/
  cd plugins/confluentinc-kafka-connect-s3
  unzip confluentinc-kafka-connect-s3-10.4.2.zip
  rm *zip
  ```
3. Start the platform
4. Configure a s3 connect instance
  ```
  curl -i -X PUT -H  "Content-Type:application/json" http://localhost:8083/connectors/s3test/config \
  -d '
  {
    "connector.class": "io.confluent.connect.s3.S3SinkConnector",
    "topics": "s3test",
    "s3.bucket.name": "s3test",
    "s3.region": "eu-west-2",
    "s3.part.size": "26214400",
    "s3.compression.type": "none",
    "store.url": "http://s3:9000",
    "tasks.max": "1",
    "flush.size": "100",
    "rotate.interval.ms": "-1",
    "storage.class": "io.confluent.connect.s3.storage.S3Storage",
    "format.class": "io.confluent.connect.s3.format.json.JsonFormat",
    "partitioner.class": "io.confluent.connect.storage.partitioner.DefaultPartitioner",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "org.apache.kafka.connect.storage.StringConverter",
    "schema.compatibility": "NONE"
  }'
  ```
