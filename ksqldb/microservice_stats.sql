CREATE TABLE microservice_stats (
    microservice_name VARCHAR,
    200_count BIGINT,
    404_count BIGINT,
    502_count BIGINT,
    503_count BIGINT,
    2xx_count BIGINT,
    3xx_count BIGINT,
    4xx_count BIGINT,
    5xx_count BIGINT,
    2xx_min BIGINT,
    2xx_max BIGINT,
    2xx_avg DOUBLE,
    2xx_95 DOUBLE,
    window_start BIGINT,
    window_end BIGINT
) WITH (
    KAFKA_TOPIC='microservice_stats',
    VALUE_FORMAT='AVRO'
);

CREATE STREAM inbound_data_stream (
    microservice_name VARCHAR,
    query_time BIGINT,
    http_status_code INT
) WITH (
    KAFKA_TOPIC='inbound_data',
    VALUE_FORMAT='JSON',
    TIMESTAMP='query_time'
);

INSERT INTO microservice_stats
SELECT
    microservice_name,
    COUNT(*) FILTER (WHERE http_status_code = 200) AS 200_count,
    COUNT(*) FILTER (WHERE http_status_code = 404) AS 404_count,
    COUNT(*) FILTER (WHERE http_status_code = 502) AS 502_count,
    COUNT(*) FILTER (WHERE http_status_code = 503) AS 503_count,
    COUNT(*) FILTER (http_status_code >= 200 AND http_status_code <= 299) AS 2xx_count,
    COUNT(*) FILTER (http_status_code >= 300 AND http_status_code <= 399) AS 3xx_count,
    COUNT(*) FILTER (http_status_code >= 400 AND http_status_code <= 499) AS 4xx_count,
    COUNT(*) FILTER (http_status_code >= 500 AND http_status_code <= 599) AS 5xx_count,
    MIN(CASE WHEN http_status_code >= 200 AND http_status_code <= 299 THEN query_time ELSE NULL END) AS 2xx_min,
    MAX(CASE WHEN http_status_code >= 200 AND http_status_code <= 299 THEN query_time ELSE NULL END) AS 2xx_max,
    AVG(CASE WHEN http_status_code >= 200 AND http_status_code <= 299 THEN query_time ELSE NULL END) AS 2xx_avg,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY query_time) FILTER (WHERE http_status_code >= 200 AND http_status_code <= 299) AS 2xx_95,
    WINDOWSTART() AS window_start,
    WINDOWEND() AS window_end
FROM inbound_data_stream
WINDOW TUMBLING (SIZE 1 MINUTE)
GROUP BY microservice_name
EMIT CHANGES;

