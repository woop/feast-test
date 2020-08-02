#!/usr/bin/env bash

set -e

declare -A NOTEBOOK_PATH_LOOKUP
NOTEBOOK_PATH_LOOKUP=(
  ["basic"]="examples/basic/basic.ipynb"
  ["telecom"]="examples/feast-xgboost-churn-prediction-tutorial/Telecom Customer Churn Prediction (with Feast and XGBoost).ipynb"
  ["statistics"]="examples/statistics/Historical Feature Statistics with Feast, TFDV and Facets.ipynb"
)

if [ -z "$NOTEBOOK" ]; then
  echo "NOTEBOOK must be set to one of: basic, telecom, statistics"
  exit 1
else
  NOTEBOOK_PATH="${NOTEBOOK_PATH_LOOKUP[$NOTEBOOK]}"
  ls $NOTEBOOK_PATH
  echo "Found notebook $NOTEBOOK at $NOTEBOOK_PATH"
fi
test -z "${NOTEBOOK_ARTIFACT_BUCKET_NAME}" && NOTEBOOK_ARTIFACT_BUCKET_NAME="feast-test-notebook-artifacts"
test -z "${TEST_RUN_ID}" && export TEST_RUN_ID=notebook_run_$(date +%s)
test -z "${TEMP_BUCKET}" && export TEMP_BUCKET=gs://feast-test-notebook-staging

# Clean up on exit
clean_up() {
  ARG=$?

  kill $(jobs -p) || true

  exit $ARG
}
trap clean_up EXIT

export PROJECT_ROOT_DIR=$(git rev-parse --show-toplevel)
export SCRIPTS_DIR=${PROJECT_ROOT_DIR}/infra/scripts
source ${SCRIPTS_DIR}/setup-common-functions.sh

# Start infrastructure
${PROJECT_ROOT_DIR}/infra/scripts/setup-docker-compose-test-infra.sh &

until docker ps | grep core; do
  sleep 2
  echo "Waiting for containers to begin initialization"
done

# Get Feast Core container IP address
export FEAST_CORE_CONTAINER_IP_ADDRESS=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' feast_core_1)

# Wait for Feast Core to be ready
${PROJECT_ROOT_DIR}/infra/scripts/wait-for-it.sh ${FEAST_CORE_CONTAINER_IP_ADDRESS}:6565 --timeout=120

# Get Feast Online Serving container IP address
export FEAST_ONLINE_SERVING_CONTAINER_IP_ADDRESS=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' feast_online_serving_1)

# Wait for Feast Online Serving to be ready
${PROJECT_ROOT_DIR}/infra/scripts/wait-for-it.sh ${FEAST_ONLINE_SERVING_CONTAINER_IP_ADDRESS}:6566 --timeout=120

# Get Feast Historical Serving container IP address
export FEAST_HISTORICAL_SERVING_CONTAINER_IP_ADDRESS=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' feast_historical_serving_1)

# Wait for Feast Historical Serving to be ready
${PROJECT_ROOT_DIR}/infra/scripts/wait-for-it.sh ${FEAST_HISTORICAL_SERVING_CONTAINER_IP_ADDRESS}:6567 --timeout=120

# Start run
papermill -k python3 "${NOTEBOOK_PATH}" gs://${NOTEBOOK_ARTIFACT_BUCKET_NAME}/${TEST_RUN_ID}/$NOTEBOOK.ipynb

export NOTEBOOK_URL="https://nbviewer.jupyter.org/url/storage.googleapis.com/${NOTEBOOK_ARTIFACT_BUCKET_NAME}/${TEST_RUN_ID}/$NOTEBOOK.ipynb?flush_cache=true"

echo
echo
echo "Output notebook: ${NOTEBOOK_URL}"
echo
echo
