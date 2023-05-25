CREATE TABLE http_status_counts
WITH (
  KAFKA_TOPIC='http_status_counts',
  VALUE_FORMAT='AVRO',
  KEY='microservice_name'
) AS
SELECT
  microservice_name,
  SUM(CASE WHEN http_status_code = 200 THEN 1 ELSE 0 END) AS 200,
  SUM(CASE WHEN http_status_code = 404 THEN 1 ELSE 0 END) AS 404,
  SUM(CASE WHEN http_status_code = 502 THEN 1 ELSE 0 END) AS 502,
  SUM(CASE WHEN http_status_code = 503 THEN 1 ELSE 0 END) AS 503,
  SUM(CASE WHEN http_status_code >= 200 AND http_status_code < 300 THEN 1 ELSE 0 END) AS 2xx,
  SUM(CASE WHEN http_status_code >= 300 AND http_status_code < 400 THEN 1 ELSE 0 END) AS 3xx,
  SUM(CASE WHEN http_status_code >= 400 AND http_status_code < 500 THEN 1 ELSE 0 END) AS 4xx,
  SUM(CASE WHEN http_status_code >= 500 AND http_status_code < 600 THEN 1 ELSE 0 END) AS 5xx
FROM inbound_data
WINDOW TUMBLING (SIZE 1 MINUTE)
GROUP BY
  microservice_name,
  WINDOWSTART()
EMIT CHANGES
EXCEPTIONS INTO error_topic;

