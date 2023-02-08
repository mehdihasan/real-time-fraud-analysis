docker-compose up -d

echo "... ... ... ... ... ... ... ... ... ..."

sleep 30s

docker restart postgres

sleep 30s

echo "... ... ... ... ... ... ... ... ... ..."

docker ps

echo "... ... ... ... ... ... ... ... ... ..."

curl -i -X POST \
-H "Accept:application/json" \
-H "Content-Type:application/json" \
localhost:8083/connectors/ \
-d @postgres-cdc-source-connector.json

echo "... ... ... ... ... ... ... ... ... ..."