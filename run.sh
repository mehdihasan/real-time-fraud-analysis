##############################################
## Download the connectors if needed
## debezium-connector-postgresql  >> version 2.0.1
## camel-rabbitmq-kafka-connector >> veriosn 0.11.5
## mongodb-kafka-connect-mongodb  >> version 1.9.0
##############################################

CONNECTOR_DIR=./connect/connectors
CDC_DIR=./connect/connectors/debezium-debezium-connector-postgresql-2.0.1
RABBIT_DIR=./connect/connectors/camel-rabbitmq-kafka-connector
MONGO_DIR=./connect/connectors/mongodb-kafka-connect-mongodb-1.9.0

if [ ! -d "$CONNECTOR_DIR" ]; then
  mkdir -p $CONNECTOR_DIR
fi

if [ ! -d "$CDC_DIR" ]; then
  echo "$CDC_DIR does not exist. Let's create."
  wget -P $CONNECTOR_DIR https://d1i4a15mxbxib1.cloudfront.net/api/plugins/debezium/debezium-connector-postgresql/versions/2.0.1/debezium-debezium-connector-postgresql-2.0.1.zip
  unzip $CONNECTOR_DIR/debezium-debezium-connector-postgresql-2.0.1.zip -d $CONNECTOR_DIR
  rm $CONNECTOR_DIR/debezium-debezium-connector-postgresql-2.0.1.zip
fi

if [ ! -d "$RABBIT_DIR" ]; then
  echo "$RABBIT_DIR does not exist. Let's create"
  wget -P $CONNECTOR_DIR https://repo1.maven.org/maven2/org/apache/camel/kafkaconnector/camel-rabbitmq-kafka-connector/0.11.5/camel-rabbitmq-kafka-connector-0.11.5-package.tar.gz
  tar -xvf $CONNECTOR_DIR/camel-rabbitmq-kafka-connector-0.11.5-package.tar.gz -C $CONNECTOR_DIR
  rm -rf $CONNECTOR_DIR/docs
  rm $CONNECTOR_DIR/camel-rabbitmq-kafka-connector-0.11.5-package.tar.gz
fi

if [ ! -d "$MONGO_DIR" ]; then
  echo "$MONGO_DIR does not exist. Let's create."
  wget -P $CONNECTOR_DIR https://d1i4a15mxbxib1.cloudfront.net/api/plugins/mongodb/kafka-connect-mongodb/versions/1.9.0/mongodb-kafka-connect-mongodb-1.9.0.zip
  unzip $CONNECTOR_DIR/mongodb-kafka-connect-mongodb-1.9.0.zip -d $CONNECTOR_DIR
  rm $CONNECTOR_DIR/mongodb-kafka-connect-mongodb-1.9.0.zip
fi



##############################################
## Initiate docker containers
##############################################

docker-compose up -d

sleep 30s

docker restart postgres

sleep 30s

docker ps

##############################################
## Deploying the Postgres CDC source connector
## Deploying the MongoDB sink connector
##############################################

curl -i -X POST \
-H "Accept:application/json" \
-H "Content-Type:application/json" \
localhost:8083/connectors/ \
-d @connector-source-postgres-cdc.json

curl -i -X POST \
-H "Accept:application/json" \
-H "Content-Type:application/json" \
localhost:8083/connectors/ \
-d @connector-sink-mongodb.json

sleep 1m

##############################################
## Start transaction flow
##############################################

python3 -m venv .venv

source .venv/bin/activate

pip install -r ./apps/requirements.txt

##############################################
## Deploy RabbirMQ source connector to get
## the transaction data
##############################################

curl -i -X POST \
-H "Accept:application/json" \
-H "Content-Type:application/json" \
localhost:8083/connectors/ \
-d @connector-source-rabbitmq.json

python3 ./apps/creditcard_send.py -d

