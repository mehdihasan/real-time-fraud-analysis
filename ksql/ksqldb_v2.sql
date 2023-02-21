-- ensure topics are read from beginning
SET 'auto.offset.reset' = 'earliest';

-- create customer table
CREATE OR REPLACE STREAM fd_cust_raw_stream (
        op VARCHAR,
        after STRUCT <id INTEGER, first_name VARCHAR, last_name VARCHAR, dob VARCHAR, email VARCHAR, avg_credit_spend DOUBLE>
    ) WITH (KAFKA_TOPIC = 'v0.public.customers',
          VALUE_FORMAT = 'JSON');

-- Use the following statement to query fd_cust_raw_stream stream to ensure it's being populated correctly.
-- SELECT * FROM fd_cust_raw_stream EMIT CHANGES;


-- Create fd_customers table based on the fd_cust_raw_stream stream.
CREATE OR REPLACE TABLE fd_customers WITH (FORMAT='JSON') AS
    SELECT after->id                            AS customer_id,
           LATEST_BY_OFFSET(after->first_name)  AS first_name,
           LATEST_BY_OFFSET(after->last_name)   AS last_name,
           LATEST_BY_OFFSET(after->dob)         AS dob,
           LATEST_BY_OFFSET(after->email)       AS email,
           LATEST_BY_OFFSET(after->avg_credit_spend) AS avg_credit_spend
    FROM    fd_cust_raw_stream
    GROUP BY after->id;

CREATE OR REPLACE TABLE FD_CUSTOMERS_V4 (
        customer_id DOUBLE PRIMARY KEY,
        after STRUCT<first_name VARCHAR>
    ) WITH (KAFKA_TOPIC = 'v0.public.customers',
          VALUE_FORMAT = 'JSON');


CREATE OR REPLACE TABLE FD_CUSTOMERS_V5 (
        customer_id DOUBLE PRIMARY KEY,
        `after->first_name` VARCHAR
    ) WITH (KAFKA_TOPIC = 'v0.public.customers',
          VALUE_FORMAT = 'JSON');



CREATE OR REPLACE TABLE FD_CUSTOMERS_V3 (
        customer_id DOUBLE PRIMARY KEY,
        after STRUCT <id INTEGER, first_name VARCHAR, last_name VARCHAR, dob VARCHAR, email VARCHAR, avg_credit_spend DOUBLE>
    ) WITH (KAFKA_TOPIC = 'v0.public.customers',
          VALUE_FORMAT = 'JSON');

CREATE TABLE FD_CUSTOMERS_V1 (
  customer_id DOUBLE PRIMARY KEY
  ) WITH (KAFKA_TOPIC = 'v0.public.customers',KEY_FORMAT='JSON',VALUE_FORMAT = 'JSON');

-- Use the following statement to query fd_customers table to ensure it's being populated correctly.
-- SELECT * FROM FD_CUSTOMERS_V4;


-- create transactions stream from rabbitmq_transactions_v0 topic
CREATE OR REPLACE STREAM fd_transactions(
	userid INTEGER,
  	transaction_timestamp VARCHAR,
  	amount DOUBLE,
  	ip_address VARCHAR,
  	transaction_id INTEGER,
  	credit_card_number VARCHAR
	)
WITH(KAFKA_TOPIC='rabbitmq_transactions_v0', KEY_FORMAT='JSON', VALUE_FORMAT='JSON', timestamp ='transaction_timestamp', timestamp_format = 'yyyy-MM-dd HH:mm:ss');

-- Use the following statement to query fd_transactions stream to ensure it's being populated correctly.
-- SELECT * FROM fd_transactions EMIT CHANGES;


-- join transactions stream with customer table
CREATE OR REPLACE STREAM fd_transactions_enriched WITH (KAFKA_TOPIC = 'transactions_enriched') AS
  SELECT
    T.USERID,
    T.CREDIT_CARD_NUMBER,
    T.AMOUNT,
    T.TRANSACTION_TIMESTAMP,
    C.FIRST_NAME + ' ' + C.LAST_NAME AS FULL_NAME,
    C.AVG_CREDIT_SPEND,
    C.EMAIL
  FROM fd_transactions T
  INNER JOIN fd_customers C
  ON T.USERID = C.CUSTOMER_ID;

-- Use the following statement to query fd_transactions_enriched stream to ensure it's being populated correctly.
-- SELECT * FROM fd_transactions_enriched EMIT CHANGES;


-- Aggregate the stream of transactions for each account ID using a two-hour tumbling window,
-- and filter for accounts in which the total spend in a two-hour period is greater than the customer’s average.
-- Triggers fraud alert when dollar amount exceeds known avg spend
CREATE OR REPLACE TABLE fd_possible_stolen_card WITH (KAFKA_TOPIC = 'FD_possible_stolen_card', KEY_FORMAT = 'JSON', VALUE_FORMAT='JSON') AS
  SELECT
    TIMESTAMPTOSTRING(WINDOWSTART, 'yyyy-MM-dd HH:mm:ss') AS WINDOW_START,
    T.USERID,
    T.CREDIT_CARD_NUMBER,
    T.FULL_NAME,
    T.EMAIL,
    T.TRANSACTION_TIMESTAMP,
    SUM(T.AMOUNT) AS TOTAL_CREDIT_SPEND,
    MAX(T.AVG_CREDIT_SPEND) AS AVG_CREDIT_SPEND
  FROM fd_transactions_enriched T
  WINDOW TUMBLING (SIZE 2 HOURS)
  GROUP BY T.USERID, T.CREDIT_CARD_NUMBER, T.FULL_NAME, T.EMAIL, T.TRANSACTION_TIMESTAMP
  HAVING SUM(T.AMOUNT) > MAX(T.AVG_CREDIT_SPEND);

-- Use the following statement to query fd_possible_stolen_card table to ensure it's being populated correctly.
-- SELECT * FROM fd_possible_stolen_card;
