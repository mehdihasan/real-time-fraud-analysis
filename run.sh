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
-d @connector-source-postgres-cdc.json

sleep 1m

python3 -m venv .venv

source .venv/bin/activate

pip install -r ./apps/requirements.txt

python3 ./apps/creditcard_send.py

curl -i -X POST \
-H "Accept:application/json" \
-H "Content-Type:application/json" \
localhost:8083/connectors/ \
-d @connector-source-rabbitmq.json

echo "... ... ... ... ... ... ... ... ... ..."

