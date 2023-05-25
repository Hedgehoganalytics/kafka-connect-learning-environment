CREATE STREAM nginx_inbound (
    microservice_name VARCHAR,
    query_time BIGINT,
    status_code INT
) WITH (
    kafka_topic='nginx',
    value_format='JSON'
);
